FROM python:3.8-alpine

ARG APP_ENV
ENV APP_ENV ${APP_ENV}
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY requirements.txt ${APP_HOME}/
RUN apk update && apk add --no-cache libpq libstdc++ \
	&& apk add --no-cache --virtual .build-deps \
	postgresql-dev \
	gcc \
	musl-dev \
	linux-headers \
	alpine-sdk \
	&& pip install -U pip \
	&& pip install --no-cache-dir -r requirements.txt \
	&& apk del --no-cache .build-deps

ADD . $APP_HOME

RUN rm -rf Dockerfile docker-compose.yml && echo $'cd /app\npython manage.py runserver 0.0.0.0:80' > start.sh

EXPOSE 80

CMD ["sh", "start.sh"]
