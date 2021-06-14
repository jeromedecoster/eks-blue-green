# check if user already exists (return something if user exists, otherwise return nothing)
exists=$(aws iam list-user-policies \
    --user-name $PROJECT_NAME \
    --profile $AWS_PROFILE \
    2>/dev/null)
    
[[ -n "$exists" ]] && { warn warb user $PROJECT_NAME already exists; exit 0; }

# create a user named $PROJECT_NAME
log create iam user $PROJECT_NAME
aws iam create-user \
    --user-name $PROJECT_NAME \
    --profile $AWS_PROFILE \
    1>/dev/null

aws iam attach-user-policy \
    --user-name $PROJECT_NAME \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
    --profile $AWS_PROFILE

aws iam attach-user-policy \
    --user-name $PROJECT_NAME \
    --policy-arn arn:aws:iam::aws:policy/IAMFullAccess \
    --profile $AWS_PROFILE

key=$(aws iam create-access-key \
    --user-name $PROJECT_NAME \
    --query 'AccessKey.{AccessKeyId:AccessKeyId,SecretAccessKey:SecretAccessKey}' \
    --profile $AWS_PROFILE \
    2>/dev/null)

AWS_ACCESS_KEY_ID=$(echo "$key" | jq '.AccessKeyId' --raw-output)
log AWS_ACCESS_KEY_ID $AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq '.SecretAccessKey' --raw-output)
log AWS_SECRET_ACCESS_KEY $AWS_SECRET_ACCESS_KEY

# envsubst tips : https://unix.stackexchange.com/a/294400
# create .key file
cd "$PROJECT_DIR"
# export variables for envsubst
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
envsubst < .key.tmpl > .key

info created file .key