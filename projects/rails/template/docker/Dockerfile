FROM ruby:2.6.3

RUN apt-get update -qq && apt-get install -y nodejs postgresql-client

ARG APP_ENV
ENV APP_ENV ${APP_ENV}
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD . $APP_HOME
RUN rm -rf Dockerfile docker-compose.yml
RUN if [ "${APP_ENV}" = "development" ]; then bundle install; else bundle install --without development test; fi

RUN echo 'rails s -p 80 -b 0.0.0.0' > start.sh

EXPOSE 80

CMD ["sh", "start.sh"]
