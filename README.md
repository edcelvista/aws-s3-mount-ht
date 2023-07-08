# High-Throughput S3 Mountpoint Module

Mount your s3 bucket as normal mountpoint in unix / linux operating system.


## Docker Setup

Install and build container image and run the module.

```sh
docker build . 
docker tag <image> s3fs:latest
```

## Docker Run
```sh
docker rm s3fs --force && docker run --privileged -d -t -i \
-e SIDECAR_LOG_MONITORING_ENABLED='true' \
-e AWS_ACCESS_KEY_ID='<omitted>' \
-e AWS_SECRET_ACCESS_KEY='<omitted>' \
-e AWS_DEFAULT_REGION='us-east-1' \
-e S3_MOUNT_DIRECTORY='/mnt' \
-e S3_BUCKET_NAME='edcelvistadotcom' \
-e S3_PATH='test/' \
-e FUSE_THREAD_COUNT=1 \
-e FUSE_THROUGHPUT_TARGET_GBPS=1 \
-e LOGROTATE_STATE='~/logrotate-state' \
-e LOGROTATE_ARCHIVE='/var/log/archive/my-app' \
-e LOGROTATE_APP_LOG_FILE='/var/log/my-app.log' \
-e LOGROTATE_FREQUENCY='*/1 * * * *' \
-e LOGROTATE_APP_LOG_RETAIN='10' \
-e LOGROTATE_DURATION='hourly' \
-e LOGROTATE_MAXSIZE='25M' \
-e APP_LABEL='edcelvistadotcom' --name s3fs s3fs:latest
```

Create Dummy file...

```sh
fallocate -l $((26*1024*1024)) my-app.log
```
```sh
mkfile -n 1g my-app.log
```

## RUN
```sh
docker exec -it s3fs /bin/bash
```
```sh
fallocate -l $((26*1024*1024)) /var/log/my-app.log && logrotate /etc/logrotate.d/my-app.conf --state ~/logrotate-state
```
