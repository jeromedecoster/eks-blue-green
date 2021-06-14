repo=$(aws ecr describe-repositories \
    --repository-names $PROJECT_NAME \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    2>/dev/null)
[[ -n "$repo" ]] && { warn warn repository already exists; exit 0; }

REPOSITORY_URI=$(aws ecr create-repository \
    --repository-name $PROJECT_NAME \
    --query 'repository.repositoryUri' \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    --output text \
    2>/dev/null)

log REPOSITORY_URI $REPOSITORY_URI

# envsubst tips : https://unix.stackexchange.com/a/294400
# create .ecr file
cd "$PROJECT_DIR"
# export variables for envsubst
export REPOSITORY_URI
envsubst < .ecr.tmpl > .ecr

info created file .ecr