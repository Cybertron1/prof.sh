#!/bin/sh

# https://github.com/fearside/ProgressBar
function ProgressBar {
  let _progress=(${1}*100/${2}*100)/100
  let _done=(${_progress}*4)/10
  let _left=40-$_done
  # Build progressbar string lengths
  _done=$(printf "%${_done}s")
  _left=$(printf "%${_left}s")
  printf "\rProgress : [${_done// /#}${_left// /-}] ${_progress}%%"
}

if [ $# > 1 ];
then
  mode=$1
fi

if [[ ${mode} != "list" ]] && [[ ${mode} != "expired" ]];
then
  echo "Please use this program with either one of the following parameters: output / expired (remove)"
  echo "Example: - sh prof.sh list"
  echo "         - sh prof.sh expired"
  echo "         - sh prof.sh expired remove"
  exit 0
fi

i=0
array=()
count=`find ~/Library/MobileDevice/Provisioning\ Profiles/ -type f -name "*.mobileprovision" | wc -l`
for provisioning_profile in ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision;
do
    file=$(security cms -D -i "${provisioning_profile}")
    ((i++))
    ProgressBar ${i} ${count}
    appId=`/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /dev/stdin <<< ${file}`
    devices=`/usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' /dev/stdin <<< ${file}} 2>/dev/null`
    exitCode=$?
    provisioningType=$([ ${exitCode} != 0 ] && echo "App Store" || echo "Development")
    if [[ ${mode} == "list" ]];
    then
      array+=("${provisioning_profile##*/} - ${provisioningType} - ${appId}")
    elif [[ ${mode} == "expired" ]];
    then
      expirationDate=`/usr/libexec/PlistBuddy -c 'Print :ExpirationDate' /dev/stdin <<< ${file}`
      read dow month day time timezone year <<< "${expirationDate}"
      ymd_expiration=`date -jf"%a %e %b %Y" "${dow} ${day} ${month} ${year}" +%Y%m%d`
      ymd_today=`date +%Y%m%d`

      if [ ${ymd_today} -ge ${ymd_expiration} ];
      then
        echo "${provisioning_profile} EXPIRED"
        if [ $# > 2 ];
        then
          if [ $2 == "remove" ];
          then
            rm  "${provisioning_profile}"
          fi
        fi
      fi
    fi
done

echo '\n'

IFS=$'\n' sorted=($(sort -k2r <<<"${array[*]}"));
unset IFS
printf "%s\n" "${sorted[@]}"
