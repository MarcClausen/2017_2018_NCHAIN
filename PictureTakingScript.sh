#!/bin/bash
#starting backup script
#sh /home/user1/DEPLOY2018/PRODUCTION/Backupper.sh &

while :
do
time_stamp=$(date +'%Y%m%d%H%M%S')

#Everything is contained in this function
main()
{

# This function purges any processes interacting with the camera modules.
# To better make sure we have no loose ends / collisions.
nuke_camproc()
{
  pkill -f 'Backupper.sh'
  pkill -f 'raspistill'
  pkill -f 'scp'
  ip2=1
  ip1=1
  for ((ip2=1;ip2<=180;ip2++)); do
  full_ip=192.168."$ip1"."$ip2"
  ssh -o "StrictHostKeyChecking no" pi@"$full_ip" "pkill -f raspistill &"
  done
}

# Download the file to trigger picture taking: activatorfile. This has no content.
# The pic_settings file contains parameters for the camera.
sleep 2
curl -H "x-secret: SUPERSECRET_SUPERKEY" xxx.xxx.xxx.xxx:xxxx/activatorfile > /tmp/activatorfile &
sleep 4

curl -H "x-secret: SUPERSECRET_SUPERKEY" xxx.xxx.xxx.xxx:xxxx/pic_settings > /tmp/pic_settings &
sleep 4
# sleep (waiting time) is inserted to provide some slack.


# Test if activator file exists, and run picture taking if so
if cat /tmp/activatorfile | grep A01 ;
then
nuke_camproc #again purging any processes, if they have hung from an earlier/interrupted job.
rm /tmp/activatorfile #eat the activator file, as we are beginning the picture taking job.
echo -e "beginning picture taking"

# Also delete the activator file from remote location, to confirm the job is accepted.
curl -H "x-secret: SUPERSECRET_SUPERKEY" -X POST -d asd xxx.xxx.xxx.xxx:xxxx/activatorfile &
sleep 4 #slack

#run with old settings unless new are present
  mv /tmp/pic_settings /tmp/pic_settings_old
  params_jpg=$(cat /tmp/pic_settings_old)
  localdir=/tmp/pic_download/MT""$time_stamp""/


ip1=1 # this is used in the'camerize' function below

# Ready folders
rm -rf /tmp/pic_download/*
mkdir -p $localdir


# Function to do picture taking stuff. Does the same for each IP address.
# The '&' helps to parallelize the individual camera jobs.
camerize()
{
for ((ip2=1;ip2<=180;ip2++)); do
full_ip=192.168."$ip1"."$ip2"
params_name=""Cam""$ip2""_MT""$time_stamp"".jpg""
full_params=""$params_jpg""""$params_name""
localpic=""$localdir""Cam""$ip2""_MT""$time_stamp"".jpg
#Prepare folders
  mkdir -p $localdir
  ssh -o "StrictHostKeyChecking no" pi@"$full_ip" "rm -R /tmp/camera_jpg/* &"
  sleep 0.1
  ssh -o "StrictHostKeyChecking no" pi@"$full_ip" "mkdir -p /tmp/camera_jpg" &
  sleep 0.1
  
#Run camera command
ssh -o "StrictHostKeyChecking no" pi@"$full_ip" "raspistill ""$full_params"" " &
sleep 10 && scp -o "StrictHostKeyChecking no" pi@"$full_ip":/tmp/camera_jpg/*.jpg ""$localpic"" &
done
}

# execute the function above and wait 20 seconds before starting to detect QR codes.
camerize & 
sleep 20

# Detect QR codes
  for ((ip2=1;ip2<=180;ip2++)); do
  full_ip=192.168."$ip1"."$ip2"
    params_name=""Cam""$ip2""_MT""$time_stamp"".jpg""
    full_params=""$params_jpg""""$params_name""
    localpic=""$localdir""Cam""$ip2""_MT""$time_stamp"".jpg
  QRDATA=$(nice zbarimg --raw -q $localpic | awk 'length<=5' | sort -n | grep '\S' | sort -n |  tr '\n' '_' | head -c -1)
  jpgname2=""$localdir""Cam""$ip2""_MT""$time_stamp""_""$QRDATA"".jpg
  mv $localpic $jpgname2
  done
  
  
  
  tar -cvvf /tmp/pic_download/MT""$time_stamp"".tar ""$localdir""*
  sleep 1
#Transfer the tar file and do md5

  curl -H "x-secret: SUPERSECRET_SUPERKEY" -T /tmp/pic_download/MT""$time_stamp"".tar xxx.xxx.xxx.xxx:xxxx &
  sleep 4
  
  md5sum /tmp/pic_download/MT""$time_stamp"".tar > /tmp/pic_download/MT""$time_stamp"".tar.md5
  
  curl -H "x-secret: SUPERSECRET_SUPERKEY" -T /tmp/pic_download/MT""$time_stamp"".tar.md5 xxx.xxx.xxx.xxx:xxxx &
  sleep 4

 # restoring backup routine
 sh /home/user1/DEPLOY2018/PRODUCTION/Backupper.sh &
 
 
#Detector code is ending  
else echo "running tests"


# running ssh camera tests
        ip1=1
        sleep 2 && rm /tmp/selftest*
        touch /tmp/selftest""$time_stamp""
	for ((ip2=1;ip2<=180;ip2++)); do
	full_ip=192.168."$ip1"."$ip2"
	if ssh -o "StrictHostKeyChecking no" -q -o BatchMode=yes -o ConnectTimeout=1 pi@"$full_ip" "echo testing cam""$ip2""";
	then echo "cam""$ip2"" is ok" >> /tmp/selftest""$time_stamp"";
	else echo "cam""$ip2"" is down" >> /tmp/selftest""$time_stamp"";
	fi
        done
#include free space and backup-files in the test
echo ""#LIST OF DIRECTORIES AND FREE SPACE:"" >> /tmp/selftest""$time_stamp""
        df >> /tmp/selftest""$time_stamp""
        echo ""#LIST OF BACKUP DIRECTORY AND SIZES:"" >> /tmp/selftest""$time_stamp""
        ls -l /home/user1/DEPLOY2018/PRODUCTION/backup/ >> /tmp/selftest""$time_stamp""
        echo ""#TEMPERATURES:"" >> /tmp/selftest""$time_stamp""
        echo "NO SENSOR INFORMATION THIS YEAR" >> /tmp/selftest""$time_stamp""
#Upload self-test
	curl -H "x-secret: SUPERSECRET_SUPERKEY" -T /tmp/selftest""$time_stamp"" xxx.xxx.xxx.xxx:xxxx &
	sleep 5
	rm /tmp/selftest""$time_stamp""


#clear /tmp
rm -r /tmp/pic_download/*
fi

}

main &
sleep 300


done

exit 0
