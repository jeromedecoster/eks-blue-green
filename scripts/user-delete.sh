# check if user already exists (return something if user exists, otherwise return nothing)
exists=$(aws iam list-users \
    --profile $AWS_PROFILE \
    --query "Users[?UserName=='$PROJECT_NAME'].UserName" \
    --output text)
    
[[ -z "$exists" ]] && { error abort "user $PROJECT_NAME do not exists"; exit 0; }

# delete a user named $PROJECT_NAME
log delete iam user $PROJECT_NAME

# detach all attached policies
POLICIES=$(aws iam list-attached-user-policies \
    --user-name $PROJECT_NAME \
    --query "AttachedPolicies[*].PolicyArn" \
    --output text)
for ARN in $POLICIES
do
    log detach user policy $ARN
    aws iam detach-user-policy \
        --user-name $PROJECT_NAME \
        --policy-arn $ARN \
        --profile $AWS_PROFILE
done

source "$PROJECT_DIR/.key"
aws iam delete-access-key \
    --user-name $PROJECT_NAME \
    --access-key-id $AWS_ACCESS_KEY_ID

aws iam delete-user \
    --user-name $PROJECT_NAME \
    --profile $AWS_PROFILE

rm --force "$PROJECT_DIR/.key"

info deleted file .key