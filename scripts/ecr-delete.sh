REPO_EXISTS=$(aws ecr describe-repositories \
    --repository-names $PROJECT_NAME \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    2>/dev/null)
[[ -z "$REPO_EXISTS" ]] && { warn warn no ecr repository found; exit 0; }

aws ecr delete-repository \
    --repository-name $PROJECT_NAME \
    --force \
    --region $AWS_REGION \
    --profile $AWS_PROFILE \
    1>/dev/null

rm --force "$PROJECT_DIR/.ecr"

info deleted ecr repository