#!/bin/bash

VERSION=1
SUCCESS=true
SUBJECT_TOKEN_TYPE="urn:ietf:params:oauth:token-type:jwt"
EXPIRATION_TIME=$(date --date='30 minutes' +"%s")
read SUBJECT_TOKEN EXPIRATION_TIME < <(echo $(curl -s \
  "http://169.254.169.254/metadata/identity/oauth2/token?resource=api://f8110aeb-f6a1-40af-ab68-bcd3a272455a&api-version=2018-02-01" \
  -H "Metadata: true" | 
     jq -r '.access_token, .expires_on'))

JSON_STRING=$( jq -n \
                  --arg ver "$VERSION" \
                  --arg sc "$SUCCESS" \
                  --arg tt "$SUBJECT_TOKEN_TYPE" \
                  --arg id "$SUBJECT_TOKEN" \
                  --arg ex "$EXPIRATION_TIME" \
                  '{version: ($ver|tonumber), success: ($sc|tostring|fromjson), token_type: $tt, id_token: $id, expiration_time: ($ex|tonumber)}' )
echo "{\"access_token\": \"$SUBJECT_TOKEN\"}" > file_content.json
echo $JSON_STRING
