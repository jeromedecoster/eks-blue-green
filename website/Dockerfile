FROM softonic/node-prune AS prune

FROM node:16.3-slim AS build
ENV NODE_ENV production
WORKDIR /app
COPY --from=prune /go/bin/node-prune /usr/local/bin/
ADD . .
RUN npm install

FROM node:16.3-slim
ENV NODE_ENV production
ARG TITLE='Blue Parrot'
ARG IMAGE='parrot-1.jpg'
ARG VERSION='1.0.0'
ENV WEBSITE_TITLE $TITLE
ENV WEBSITE_IMAGE $IMAGE
ENV WEBSITE_VERSION $VERSION
WORKDIR /app
COPY --from=build /app .
ADD . .
EXPOSE 3000
CMD ["node", "server.js"]
