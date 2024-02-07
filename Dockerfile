FROM ruby:alpine

LABEL "repository"="https://github.com/fueledbyjordan/lake-depth-monitor" \
  "homepage"="https://github.com/fueledbyjordan/lake-depth-monitor" \
  "maintainer"="jordan <djm@murrayfoundry.com>"

ENV XDG_CONFIG_HOME="/config"

ARG USER_NAME="waterbot"
ARG USER_ID="1111"

ENV LOCALTIME_FILE="/tmp/localtime"

COPY Gemfile ./
RUN bundle install && \
    rm Gemfile Gemfile.lock

RUN apk add --no-cache bash supercronic tzdata \
 && ln -sf "${LOCALTIME_FILE}" /etc/localtime \
 && addgroup --gid "${USER_ID}" "${USER_NAME}" \
 && adduser -u "${USER_ID}" -Ds /bin/sh -G "${USER_NAME}" "${USER_NAME}"

WORKDIR /app
COPY src/* /app/
RUN chmod +x /app/*
ENTRYPOINT ["/app/entrypoint.sh"]
