#!/usr/bin/env bash

run=0
until [ $run -ge 10 ]
do
  tempered_value=`/usr/local/bin/tempered`
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
  --no-progress-meter \
  --data "$data"
else
  echo "Error getting temperature"
fi
