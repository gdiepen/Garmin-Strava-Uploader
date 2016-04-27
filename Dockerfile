FROM ubuntu


RUN mkdir /app
RUN mkdir /data


RUN apt-get update 
RUN apt-get install -y usbutils inotify-tools garmin-forerunner-tools curl libxml2-utils default-jre-headless git

RUN cd /app
RUN git clone https://github.com/cstrelioff/garmin-dev.git


VOLUME /data

ADD app /app

CMD ["/app/update_runs_to_strava.sh"]
