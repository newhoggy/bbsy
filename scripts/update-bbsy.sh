#!/usr/bin/env bash

mkdir -p wiki/data/blobs

download_file=$(mktemp)
data_file=$(mktemp)

curl -s https://asx.api.markitdigital.com/asx-research/1.0/bbsw/history > $download_file

download_sha=$(cat $download_file | sha256sum | cut -d ' ' -f 1)

mv $download_file wiki/data/blobs/$download_sha

for file in wiki/data/blobs/*; do
  cat $file | base64 >> $data_file
done

cat $data_file | jq -nR '
    [ inputs
    | @base64d
    | fromjson
    | .data.items[]
    ]
  | map({(.date): .
  | del(.date)})
  | add
  | to_entries
  | sort_by(.key)
  | from_entries
' | yq eval -P > wiki/data/bbsw.yaml
