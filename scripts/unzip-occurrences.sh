#!/bin/bash

zips=($(ls downloads/occurrences | grep zip))
echo  "  - ${#zips[@]} files to unzip"

echo " ================ START ================ "

for f in echo ${zips[@]}:
do
  unzip "downloads/occurrences/$f"
  mv "$(unzip -Z1 downloads/occurrences/$f)" "downloads/occurrences/${f%%.*}.tsv"
done

wc -l downloads/occurrences/*.tsv | sort -h

echo " ================ END ================ "
