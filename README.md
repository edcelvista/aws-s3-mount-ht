## RUN ##
```docker rm s3fs --force && docker run --privileged -d -t -i -e AWS_ACCESS_KEY_ID='<omitted>' -e AWS_SECRET_ACCESS_KEY='<omitted>' -e AWS_DEFAULT_REGION='us-east-1' -e S3_MOUNT_DIRECTORY='/mnt' -e S3_BUCKET_NAME='edcelvistadotcom' -e S3_PATH='test/' -e FUSE_THREAD_COUNT=1 -e FUSE_THROUGHPUT_TARGET_GBPS=1 -e LOGROTATE_STATE='~/logrotate-state' -e LOGROTATE_ARCHIVE='/var/log/archive/my-app' -e LOGROTATE_CONF='/etc/logrotate.d/my-app.conf' -e LOGROTATE_APP_LOG_FILE='/var/log/my-app.log' -e LOGROTATE_FREQUENCY='*/1 * * * *' --name s3fs s3fs:latest```
## Create dummy file ##
```fallocate -l $((26*1024*1024)) my-app.log```

```mkfile -n 1g example.file2```

## Run log rotation
```docker exec -it s3fs /bin/bash```
```fallocate -l $((26*1024*1024)) /var/log/my-app.log && logrotate /etc/logrotate.d/my-app.conf --state ~/logrotate-state```