FROM ruby:2.6.5-alpine3.11

ENV LANG C.UTF-8
ENV APP_ROOT /usr/src/rubicure_api

RUN mkdir ${APP_ROOT}
WORKDIR ${APP_ROOT}

ADD Gemfile      ${APP_ROOT}/Gemfile
ADD Gemfile.lock ${APP_ROOT}/Gemfile.lock

RUN apk update && \
apk upgrade && \
apk add --update --no-cache --virtual=build-dependencies build-base && \
apk add --update --no-cache git tzdata && \
git config --global url."https://".insteadOf git:// && \
bundle install -j4 && \
apk del build-dependencies

ADD . ${APP_ROOT}

EXPOSE 3000
CMD ["bundle", "exec", "foreman", "s"]
