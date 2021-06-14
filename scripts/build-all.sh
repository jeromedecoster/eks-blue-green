cd "$PROJECT_DIR/website"
log BUILD $PROJECT_NAME:1.0.0
docker image build \
    --tag $PROJECT_NAME:1.0.0 \
    .

log BUILD $PROJECT_NAME:1.1.0
docker image build \
    --build-arg TITLE='Green Parrot' \
    --build-arg IMAGE='parrot-2.jpg' \
    --build-arg VERSION='1.1.0' \
    --tag $PROJECT_NAME:1.1.0 \
    .

log BUILD $PROJECT_NAME:1.2.0
docker image build \
    --build-arg TITLE='Red Parrot' \
    --build-arg IMAGE='parrot-3.jpg' \
    --build-arg VERSION='1.2.0' \
    --tag $PROJECT_NAME:1.2.0 \
    .
