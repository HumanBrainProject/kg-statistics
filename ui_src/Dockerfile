
FROM node:11.12.0-alpine as build-stage
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ENV PATH /usr/src/app/node_modules/.bin:$PATH
COPY package.json /usr/src/app/package.json
COPY gulpfile.js /usr/src/app/gulpfile.js
COPY . /usr/src/app
RUN npm i natives
RUN npm install -g gulp-cli && npm install
RUN gulp build

FROM nginx:1.15.9-alpine
COPY config/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-stage /usr/src/app/build /usr/share/nginx/html
CMD ["nginx", "-g", "daemon off;"]