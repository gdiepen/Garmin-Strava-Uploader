FROM ubuntu


RUN mkdir /app
RUN mkdir /data


RUN apt-get update 
RUN apt-get install -y usbutils
RUN apt-get install -y inotify-tools
RUN apt-get install -y garmin-forerunner-tools
RUN apt-get install -y curl
RUN apt-get install -y libxml2-utils 
RUN apt-get install -y default-jre-headless
RUN apt-get install -y git

RUN cd /app
RUN git clone https://github.com/cstrelioff/garmin-dev.git


VOLUME /data

ADD app /app

CMD ["/app/update_runs_to_strava.sh"]
