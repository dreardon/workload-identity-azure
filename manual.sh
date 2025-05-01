printf "\n"
SUBJECT_TOKEN_TYPE="urn:ietf:params:oauth:token-type:jwt"
SUBJECT_TOKEN=$(curl \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=[AUDIENCE]" \
  -H "Metadata: true" | jq -r .access_token)
echo "Obtain credentials from the local Azure API token service:"
echo $SUBJECT_TOKEN
printf "\n"
echo "Use the Security Token Service API to exchange the credential against a short-lived access token:"
STS_TOKEN=$(curl https://sts.googleapis.com/v1/token \
    --data-urlencode "audience=//iam.googleapis.com/projects/[PROJECT_NUMBER]/locations/global/workloadIdentityPools/[WORKLOAD_IDENTITY_POOL]/providers/[WORKLOAD_PROVIDER]" \
    --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:token-exchange" \
    --data-urlencode "requested_token_type=urn:ietf:params:oauth:token-type:access_token" \
    --data-urlencode "scope=https://www.googleapis.com/auth/cloud-platform" \
    --data-urlencode "subject_token_type=$SUBJECT_TOKEN_TYPE" \
    --data-urlencode "subject_token=$SUBJECT_TOKEN" | jq -r .access_token)
echo $STS_TOKEN
printf "\n"
echo "Use the token from the Security Token Service to invoke the generateAccessToken method of the IAM Service Account Credentials API to obtain an access token:"
ACCESS_TOKEN=$(curl -0 -X POST https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/[SERVICE_ACCOUNT]:generateAccessToken \
    -H "Content-Type: text/json; charset=utf-8" \
    -H "Authorization: Bearer $STS_TOKEN" \
    -d @- <<EOF | jq -r .accessToken
    {
        "scope": [ "https://www.googleapis.com/auth/cloud-platform" ]
    }
EOF
)
echo $ACCESS_TOKEN
printf "\n"
curl -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "x-goog-user-project: [PROJECT_ID]" \
    -H "Content-Type: application/json; charset=utf-8" \
    https://vision.googleapis.com/v1/images:annotate -d @manual_request.json