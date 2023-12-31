#!/usr/bin/env bash

set -euo pipefail

mkdir -p data/blobs

download_file=$(mktemp)
data_file=$(mktemp)

curl -s https://asx.api.markitdigital.com/asx-research/1.0/bbsw/history > $download_file

download_sha=$(cat $download_file | sha256sum | cut -d ' ' -f 1)

mv $download_file data/blobs/$download_sha

for file in data/blobs/*; do
  cat $file | base64 -w 0 >> $data_file
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
' | yq eval -P > data/bbsw.yaml

echo '```yaml' > data/bbsw.md
cat data/bbsw.yaml >> data/bbsw.md
echo '```' >> data/bbsw.md
