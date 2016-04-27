#!/bin/bash

# Copyright (c) 2016 Guido Diepen
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


retrieveConvertAndUpload () {
	sleep 2
	garmin_save_runs 

	#Now we need to verify which runs are new and which ones we already knew
	find . -type f -name "*.gmn" | while read garminFileFullPath 
	do
		garminFilename=`basename $garminFileFullPath .gmn`

		tcxFilename="$garminFilename.tcx"
		tcxFilenameFullPath="/data/tcx/$tcxFilename"
		if [ ! -f "$tcxFilenameFullPath" ] 
		then
			echo "Converting the new file $garminFilename to a TCX file"

			/app/garmin-dev/gmn2tcx "$garminFileFullPath" > "$tcxFilenameFullPath" 2>/dev/null

			
			#Now check if the tcx file contains a track node in the xml file.
			#If not, it means that the device did not save the file internally completely yet and the gmn
			#file only contains the total averages for the activity
			#In that case, we must delete not only the tcx file, but also the gmn file to ensure it will
			#be downloaded automatically next time again from the device
			
			numberOfTrackpoints=`cat "$tcxFilenameFullPath" | grep "<Trackpoint>" | wc -l`
		

			#If the number of trackpoints > 0, then upload this to strava.
			#Otherwise, delete both the tcx and the garmin file
		
			if [ $numberOfTrackpoints -gt 0 ]
			then
				echo "Uploading the new TCX file to strava"
				echo "Strava-key: ${STRAVA_KEY}" >> /data/key.txt
				
				if [ "${STRAVA_KEY}" != "" ] 
				then 	
					stravaUploadResult=`curl -X POST https://www.strava.com/api/v3/uploads \
								    -H "Authorization: Bearer ${STRAVA_KEY}" \
								    -F activity_type=run \
								    -F file=@$tcxFilenameFullPath \
								    -F data_type=tcx`

					stravaUploadID=`echo $stravaUploadResult |  sed 's/.*"id"://' |  sed 's/,.*//'`

					stravaAuthorizationError=`echo ${stravaUploadID} | grep "Authorization Error" | wc -l`

					if [ $stravaAuthorizationError -gt 0 ] 
					then
						echo "There was an authorization error while uploading the data to strava."
						echo "Please check your API key"
				       	else	
						echo "Waiting 8 seconds"
						sleep 8
						echo "Status of latest upload (${stravaUploadID}):"
						curl -G https://www.strava.com/api/v3/uploads/$stravaUploadID \
						    -H "Authorization: Bearer ${STRAVA_KEY}"
						echo ""
					fi
				else
					echo "Not uploading as no strava-key is present"
				fi

			else
				echo "The tcx/gmn file only contains average information. Deleting both files to ensure full activity"
				echo "will be downloaded next time we connect"

				rm "$tcxFilenameFullPath"
				rm "$garminFileFullPath"
			fi
		fi
	done
}





#First thing we need to do is ensure we get all the data
cd /data
mkdir gmn
mkdir tcx
cd gmn

#When we start, check if the device is already connected
garminDeviceWasConnected=$(lsusb | grep "ID 091e:0003" | wc -l)

if [[ ( "$garminDeviceWasConnected" == 1 ) ]] ; 
then
	retrieveConvertAndUpload 
fi

#now start listening to the devices being created
inotifywait -r -m /dev/bus/usb -e CREATE | while read newDevicePluggedIn; 
do 
	#check if the garmin device is now connected
	garminDeviceIsConnected=$(lsusb | grep "ID 091e:0003" | wc -l)

	#Check if the new device plugged in is garmin	
	#this means that if it was not connected before, but it is connected now, we must
	#perform the actions
	if [[  ( "$garminDeviceWasConnected" == 0) && ( "$garminDeviceIsConnected" == 1) ]] ; 
	then
		retrieveConvertAndUpload 
	fi

	#Now update the wasConnected to the isConnected for the next iteration
	garminDeviceWasConnected=${garminDeviceIsConnected}
done


