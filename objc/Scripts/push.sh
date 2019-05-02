if [[ ! ${1} ]] ; then echo "Use: ${0} <Certificate .pem file> <Device-Token>" ; exit 1 ; fi
if [[ ! ${2} ]] ; then echo "Use: ${0} <Certificate .pem file> <Device-Token>" ; exit 1 ; fi

curl -v \
-d '{"aps":{"content-available": 1}}' \
-H "apns-topic: com.couchbase.MobileTrainingTodo" \
-H "apns-priority: 10" \
--http2 \
--cert ${1}  \
https://api.development.push.apple.com/3/device/${2}
