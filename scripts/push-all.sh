# root account id
ACCOUNT_ID=$(aws sts get-caller-identity \
    --query 'Account' \
    --profile $AWS_PROFILE \
    --output text)
log ACCOUNT_ID $ACCOUNT_ID

# add login data into /home/$USER/.docker/config.json
aws ecr get-login-password \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    | docker login \
    --username AWS \
    --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

source "$PROJECT_DIR/.ecr"

log push $REPOSITORY_URI:1.0.0
docker tag $PROJECT_NAME:1.0.0 $REPOSITORY_URI:1.0.0
docker push $REPOSITORY_URI:1.0.0

log push $REPOSITORY_URI:1.1.0
docker tag $PROJECT_NAME:1.1.0 $REPOSITORY_URI:1.1.0
docker push $REPOSITORY_URI:1.1.0

log push $REPOSITORY_URI:1.2.0
docker tag $PROJECT_NAME:1.2.0 $REPOSITORY_URI:1.2.0
docker push $REPOSITORY_URI:1.2.0
