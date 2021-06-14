#!/bin/bash

#
# variables
#

# AWS variables
AWS_PROFILE=default
AWS_REGION=eu-west-3
# project name
PROJECT_NAME=eks-blue-green
# the directory containing the script file
PROJECT_DIR="$(cd "$(dirname "$0")"; pwd)"

export AWS_PROFILE AWS_REGION PROJECT_NAME PROJECT_DIR


log()   { echo -e "\e[30;47m ${1^^} \e[0m ${@:2}"; }        # $1 uppercase background white
info()  { echo -e "\e[48;5;28m ${1^^} \e[0m ${@:2}"; }      # $1 uppercase background green
warn()  { echo -e "\e[48;5;202m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background orange
error() { echo -e "\e[48;5;196m ${1^^} \e[0m ${@:2}" >&2; } # $1 uppercase background red

# https://unix.stackexchange.com/a/22867
export -f log info warn error

# log $1 in underline then $@ then a newline
under() {
    local arg=$1
    shift
    echo -e "\033[0;4m${arg}\033[0m ${@}"
    echo
}

usage() {
    under usage 'call the Makefile directly: make dev
      or invoke this file directly: ./make.sh dev'
}

#
# npm install + terraform init + create ecr repository
#
setup() {
    cd "$PROJECT_DIR/website"
    npm install

    # terraform init
    cd "$PROJECT_DIR/infra"
    terraform init

    cd "$PROJECT_DIR"
    bash scripts/ecr-create.sh
    # bash scripts/user-create.sh
}


# local development
dev() {
    cd "$PROJECT_DIR/website"
    NODE_ENV=development node .
}

# local 1.0.0 version — blue parrot
local-1.0.0() {
    cd "$PROJECT_DIR/website"
    NODE_ENV=development \
    WEBSITE_PORT=3000 \
    WEBSITE_TITLE='Blue Parrot' \
    WEBSITE_IMAGE='parrot-1.jpg' \
    WEBSITE_VERSION=1.0.0 \
    node .
}

# local 1.1.0 version — green parrot
local-1.1.0() {
    cd "$PROJECT_DIR/website"
    NODE_ENV=development \
    WEBSITE_PORT=3000 \
    WEBSITE_TITLE='Green Parrot' \
    WEBSITE_IMAGE='parrot-2.jpg' \
    WEBSITE_VERSION=1.1.0 \
    node .
}

# local 1.2.0 version — red parrot
local-1.2.0() {
    cd "$PROJECT_DIR/website"
    NODE_ENV=development \
    WEBSITE_PORT=3000 \
    WEBSITE_TITLE='Red Parrot' \
    WEBSITE_IMAGE='parrot-3.jpg' \
    WEBSITE_VERSION=1.2.0 \
    node .
}

# build all 1.x.0 versions
build-all() {
    bash scripts/build-all.sh
}

# push all 1.x.0 versions to ecr
push-all() {
    bash scripts/push-all.sh
}

# terraform validate
tf-validate() {
    cd "$PROJECT_DIR/infra"
    terraform fmt -recursive
    terraform validate
}

# terraform plan + terraform apply
tf-apply() {
    cd "$PROJECT_DIR/infra"
    terraform plan
    terraform apply -auto-approve
}

# setup kubectl config
kube-config() {
    cd "$PROJECT_DIR/infra"
    aws eks update-kubeconfig \
        --name $(terraform output -raw cluster_name) \
        --region $(terraform output -raw region)
}

# publish the 1.0.0 version
k8s-1.0.0() {
    cd "$PROJECT_DIR/k8s"
    kubectl apply --filename namespace.yaml

    source "$PROJECT_DIR/.ecr"
    export DOCKER_IMAGE=$REPOSITORY_URI:1.0.0
    export LABEL_VERSION=1-0-0
    log DOCKER_IMAGE $DOCKER_IMAGE
    log LABEL_VERSION $LABEL_VERSION
    envsubst < deployment.yaml | kubectl apply --filename -
    envsubst < service.yaml | kubectl apply --filename -

    # replace with loop + break if not empty test
    sleep 3
    LOAD_BALANCER=$(kubectl get services \
            parrot \
            --namespace eks-blue-green \
            --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    log LOAD_BALANCER $LOAD_BALANCER
}

# publish the 1.1.0 version as green
k8s-1.1.0-green() {
    cd "$PROJECT_DIR/k8s"

    source "$PROJECT_DIR/.ecr"
    export DOCKER_IMAGE=$REPOSITORY_URI:1.1.0
    export LABEL_VERSION=1-1-0
    log DOCKER_IMAGE $DOCKER_IMAGE
    log LABEL_VERSION $LABEL_VERSION
    envsubst < deployment.yaml | kubectl apply --filename -
    
    # service-green.yaml creates the `parrot-green` service
    envsubst < service-green.yaml | kubectl apply --filename -

    # replace with loop + break if not empty test
    sleep 3
    LOAD_BALANCER=$(kubectl get services \
            parrot-green \
            --namespace eks-blue-green \
            --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    log LOAD_BALANCER $LOAD_BALANCER
}

# target the 1.1.0 version — new blue
k8s-1.1.0() {
    cd "$PROJECT_DIR/k8s"
    export LABEL_VERSION=1-1-0
    log LABEL_VERSION $LABEL_VERSION
    # `parrot` service target now labeled version 1-1-0
    envsubst < service.yaml | kubectl apply --filename -
}

# delete previous blue deployment + green service
k8s-delete-1.0.0() {
    kubectl delete deployments parrot-1-0-0 --namespace eks-blue-green
    kubectl delete services parrot-green --namespace eks-blue-green
}

# publish the 1.2.0 version as green
k8s-1.2.0-green() {
    cd "$PROJECT_DIR/k8s"

    source "$PROJECT_DIR/.ecr"
    export DOCKER_IMAGE=$REPOSITORY_URI:1.2.0
    export LABEL_VERSION=1-2-0
    log DOCKER_IMAGE $DOCKER_IMAGE
    log LABEL_VERSION $LABEL_VERSION
    envsubst < deployment.yaml | kubectl apply --filename -
    
    # service-green.yaml creates the `parrot-green` service
    envsubst < service-green.yaml | kubectl apply --filename -

    # replace with loop + break if not empty test
    sleep 3
    LOAD_BALANCER=$(kubectl get services \
            parrot-green \
            --namespace eks-blue-green \
            --output jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    log LOAD_BALANCER $LOAD_BALANCER
}

# target the 1.2.0 version — new blue
k8s-1.2.0() {
    cd "$PROJECT_DIR/k8s"
    export LABEL_VERSION=1-2-0
    log LABEL_VERSION $LABEL_VERSION
    # `parrot` service target now labeled version 1-2-0
    envsubst < service.yaml | kubectl apply --filename -
}

# delete eks content + terraform destroy + delete ecr repository
destroy() {
    # delete eks content
    kubectl delete deployments --all --namespace eks-blue-green
    kubectl delete services --all --namespace eks-blue-green
    kubectl delete namespace eks-blue-green

    # terraform destroy
    cd "$PROJECT_DIR/infra"
    terraform destroy -auto-approve

    
    # delete ecr repository
    cd "$PROJECT_DIR"
    bash scripts/ecr-delete.sh
    # bash scripts/user-delete.sh
}


# if `$1` is a function, execute it. Otherwise, print usage
# compgen -A 'function' list all declared functions
# https://stackoverflow.com/a/2627461
FUNC=$(compgen -A 'function' | grep $1)
[[ -n $FUNC ]] && { info execute $1; eval $1; } || usage;
exit 0
