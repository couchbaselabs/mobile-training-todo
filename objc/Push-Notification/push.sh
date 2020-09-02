if [[ ! ${1} ]] ; then echo "Use: ${0} <Certificate .pem file> <Device-Token>" ; exit 1 ; fi
if [[ ! ${2} ]] ; then echo "Use: ${0} <Certificate .pem file> <Device-Token>" ; exit 1 ; fi

curl -v \
-H 'apns-topic: com.couchbase.MobileTrainingTodo' \
-H 'apns-priority: 5' \
-H 'apns-push-type: background' \
-d '{"aps":{"alert": {}, "content-available": 1}}' \
--http2 \
--cert ${1}  \
https://api.sandbox.push.apple.com/3/device/${2}
