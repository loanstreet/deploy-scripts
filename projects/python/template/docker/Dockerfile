FROM python:3.8.2

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev python3-venv

ARG APP_ENV
ENV APP_ENV ${APP_ENV}
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD . $APP_HOME
# ADD deploy/environments/${APP_ENV}/assets/local_settings.py $APP_HOME/cover_api
RUN rm -rf Dockerfile docker-compose.yml

RUN python3 -m venv venv
RUN . venv/bin/activate && pip install -U pip && pip install -r requirements.txt
RUN echo 'cd /app\n. venv/bin/activate\npython run_tornado.py --port=3000' > start.sh

EXPOSE 3000

CMD ["sh", "start.sh"]
