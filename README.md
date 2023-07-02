docker rm s3fs --force && \
docker run --privileged -d -t -i -e AWS_ACCESS_KEY_ID='<omitted>' \
-e AWS_SECRET_ACCESS_KEY='<omitted>' \
-e AWS_DEFAULT_REGION='us-east-1' \
-e S3_MOUNT_DIRECTORY='mnt' \
-e S3_BUCKET_NAME='edcelvistadotcom' \
-e S3_PATH=test/ \
-e FUSE_THREAD_COUNT=1 \
-e FUSE_THROUGHPUT_TARGET_GBPS=1 \
--name s3fs s3fs:latest

# fallocate -l $((1*1024*1024*1024)) example.file1
# mkfile -n 1g example.file2