chdir="/home/eb97ziwi/gbif"
downdir="$chdir/downloads/occurrences"
secret_file="$chdir/gbif.secret"

function check_status() {
  summary=$(curl -Ss https://api.gbif.org/v1/occurrence/download/"$1")
  status=$(echo $summary | jq . | grep status | cut -d ' ' -f 4 | tr -d '",')
  echo $status
}

pwd=$(cut "$secret_file" -d ',' -f 2)
pwd=$(echo $pwd | cut -d ' ' -f 2)

echo " ========= Download GBIF occurrence data ========= "

mapfile -t keys < "$chdir/taxonkeys.csv"

i=0
for sp in "${keys[@]}"
do
  (( i+=1 ))
  if (( $i % 5 == 0 ))
  then
    echo "  - Species $i of ${#keys[@]}"
  fi
  if [[ -e "$downdir/$sp".zip ]]
  then
    echo "  - $sp: already downloaded"
    continue
  fi
  # request download
  echo "  - $sp: request download"
  creator='{"creator": "emilio.berti",'
  address='"notificationAddresses": ["emilio.berti90@gmail.com"],'
  send='"sendNotification": false,'
  format='"format": "SIMPLE_CSV",'
  predicates='{"type": "equals", "key": "HAS_COORDINATE", "value": "true"}, {"type": "in", "key": "COUNTRY", "values": ["US", "MX", "CA"]}, {"type": "greaterThan", "key": "YEAR", "value": "1978"}, {"type": "lessThan", "key": "YEAR", "value": "2019"}, {"type": "equals", "key": "HAS_GEOSPATIAL_ISSUE", "value": "false"}, {"type": "equals", "key": "TAXON_KEY", "value": "'"$sp"'"}'
  predicate=$(echo '"predicate": {"type": "and", "predicates": [' $predicates ']}}')
  query=$(echo "$creator" "$address" "$send" "$format" $predicate)
  request="https://api.gbif.org/v1/occurrence/download/request"
  
  # check status of request
  echo "  - Wait for download to be ready"
  id=$(curl -sD --include --user emilio.berti:"$pwd" --header "Content-Type: application/json" --data "$query" "$request")
  status=$(check_status "$id")
  while [[ $status != 'SUCCEEDED' ]]
  do
    status=$(check_status "$id")
    sleep 5
  done
  summary=$(curl -Ss https://api.gbif.org/v1/occurrence/download/"$downdir")
  echo $summary | jq . > "$downdir"/"$area"/"$sp".log
  
  # download and unzip
  echo "  - Download"
  curl -sS --location https://api.gbif.org/v1/occurrence/download/request/"$id".zip -o "$downdir"/"$sp".zip
  echo "  - Downloaded"
done

echo " ============================================= "
