#!/usr/bin/env bash

cmd="/usr/local/bin/tempered"
#cmd="docker run --rm --device=/dev/hidraw0:/dev/hidraw0 --device=/dev/hidraw1:/dev/hidraw1 tempered"

run=0
until [ $run -ge 10 ]
do
  tempered_value=`$cmd`
  if [ ! -z "$tempered_value" ]
  then
    break
  fi

  echo "Retrying $run"
  run=$((run+1))
  sleep 7
done

if [ ! -z "$tempered_value" ]
then
  arrIN=(${tempered_value//,/ })
  temperature=${arrIN[0]}
  humidity=${arrIN[1]}

  data="{ \"temperature\": $temperature, \"humidity\": $humidity }"
  echo $data

  curl --request POST \
  --url "$WEBHOOK_URL" \
  --header 'Content-Type: application/json' \
  --data "$data"
else
  echo "Error getting temperature"
fi
