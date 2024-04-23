#!/usr/bin/env bash

set -euo pipefail

mkdir -p wiki/blobs

download_file=$(mktemp)
data_file=$(mktemp)

curl -s https://asx.api.markitdigital.com/asx-research/1.0/bbsw/history > $download_file

download_sha=$(cat $download_file | sha256sum | cut -d ' ' -f 1)

echo "====="
cat $download_file | yq eval -P
echo "====="

mv $download_file wiki/blobs/$download_sha

for file in wiki/blobs/*; do
  ((cat $file | base64 -w 0) && echo "") >> $data_file
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
' > wiki/bbsw-data.json

cat wiki/bbsw-data.json | yq eval -P > wiki/bbsw-data.yaml

cat wiki/bbsw-data.json | jq -r '
  . | to_entries
    | ( [["Date", "1 Month", "2 Months", "3 Months", "4 Months", "5 Months", "6 Months"]]
      + ( map
          ( [ .key
            , (.value.m1 | tostring)
            , (.value.m2 | tostring)
            , (.value.m3 | tostring)
            , (.value.m4 | tostring)
            , (.value.m5 | tostring)
            , (.value.m6 | tostring)
            ]
          )
        )
      )
    | ( [ "| \(.[0] | join(" | ")) |"
        , "|\(.[0] | map("------") | join("|"))|"
        ]
      + ( .[1:]
        | map
          ( "| \(join(" | ")) |"
          )
        )
      )
    | .[]
  ' > wiki/bbsw.md
