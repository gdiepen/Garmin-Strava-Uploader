# Garmin-Strava-Uploader

The goal of this project is to automatically download all activities from your Garmin Forerunner 305 the moment you connect it via USB to your computer. After all activities have been downloaded, it will convert all new runs to a TCX format (instead of the binary gmn format created by the garmin-forerunner-tools) and any new TCX file that is created is automatically uploaded to your Strava account (if you have provided a strava key with write-access).



## Instructions

Because the script has been modified to work directly with Docker, communication about the destination directory and the Strava API key are communicated with the script via the following two environment variables:
- __GARMIN_DATA_DIR__: Under this directory, all gmn files and tcx will be stored.
- __STRAVA_KEY__: Provide the script with your Strava API key. Details about how to set this up will be added to this Readme

## Docker version

As I recently got started playing around with Docker, I decided that after the script was finished I was going to make it my first Docker project also! 

You can run the docker container as follows:
``` bash

docker run  	--privileged \
		-v /dev/bus/usb:/dev/bus/usb  \
		-i \
		-e STRAVA_KEY='<FILL IN YOUR STRAVA API KEY' \
		-e GARMIN_DATA_DIR='/data'  \
		-t gdiepen/garmin-strava-uploader
```

Please note that I am still working on learning about docker and have not yet figured out all the details about the data containers/volumes. At the moment I map the /data directory in the container to the host directory ~/.garmin-strava-uploader.

Note that you need to map the host /dev/bus/usb directory to the container and allow the container to access the devices by using the privileged argument

