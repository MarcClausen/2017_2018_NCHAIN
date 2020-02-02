#!/bin/bash
#starting backup script
#sh /home/user1/DEPLOY2018/PRODUCTION/Backupper.sh &

while :
do
time_stamp=$(date +'%Y%m%d%H%M%S')


main()
{

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

echo "contents of activatorfile:"
cat /tmp/activatorfile
echo "content shown above this line"
sleep 2
curl -H "x-secret: SUPERSECRET_SUPERKEY" xxx.xxx.xxx.xxx:xxxx/activatorfile > /tmp/activatorfile &
sleep 4

curl -H "x-secret: SUPERSECRET_SUPERKEY" xxx.xxx.xxx.xxx:xxxx/pic_settings > /tmp/pic_settings &
sleep 4

# Test if activator file exists, and run picture taking if so
# Detector code starts
if cat /tmp/activatorfile | grep A01 ;
then
nuke_camproc
rm /tmp/activatorfile
echo -e "beginning picture taking"
curl -H "x-secret: SUPERSECRET_SUPERKEY" -X POST -d asd xxx.xxx.xxx.xxx:xxxx/activatorfile &
sleep 4

#run with old settings unless new are present
  mv /tmp/pic_settings /tmp/pic_settings_old
  params_jpg=$(cat /tmp/pic_settings_old)
  localdir=/tmp/pic_download/MT""$time_stamp""/
#Defining variables

ip1=1

rm -rf /tmp/pic_download/*
mkdir -p $localdir

camerize()
{
  #Beginning of picture taking
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
#Run camera
ssh -o "StrictHostKeyChecking no" pi@"$full_ip" "raspistill ""$full_params"" " &
sleep 10 && scp -o "StrictHostKeyChecking no" pi@"$full_ip":/tmp/camera_jpg/*.jpg ""$localpic"" &
done
}
camerize & 
sleep 20

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

 # restoring backup script
 sh /home/user1/DEPLOY2018/PRODUCTION/Backupper.sh &
 
 
#Detector code is ending  
else echo "running tests"


#running ssh tests
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
