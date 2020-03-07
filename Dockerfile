FROM elixir:1.10-alpine

ENV TERM xterm
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV APP_PATH /opt/app

COPY mix.exs $APP_PATH/mix.exs

WORKDIR $APP_PATH

RUN apk update && \
    apk upgrade && \
    apk add --no-cache --update build-base inotify-tools

RUN mix local.hex --force && mix local.rebar --force

CMD ["/bin/sh"]