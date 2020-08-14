How to test start replication in background with push notification.

1. Enable kSyncWithPushNotification in AppDelegate
2. Run the application and login.
3. Get the device token from the console log by searching with the word 'token'.
4. Bring the app into background
5. Go to Push-Notification folder and double click PushCertificates.p12 to install the Certificate and Keys in the KeyChain (password = pass)
6. Run ./export_push_certificate.sh to export only certificate from the PushCertificates.p12
7. Run ./push.sh with the certificate exported from the Step 6 and the device token from Step 3
8. Observe the console log that the push notification is received and the replication is started.
