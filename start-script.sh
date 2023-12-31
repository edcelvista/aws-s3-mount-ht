#!/bin/bash
# Usage: mount-s3 [OPTIONS] <BUCKET_NAME> <MOUNT_POINT>

# Arguments:
#   <BUCKET_NAME>  Name of bucket to mount
#   <MOUNT_POINT>  Mount point for file system

# Options:
#   -l, --log-directory <LOG_DIRECTORY>  Log file directory [default: $HOME/.mountpoint-s3]
#   -f, --foreground                     Run as foreground process
#   -h, --help                           Print help
#   -V, --version                        Print version

# Bucket options:
#       --prefix <PREFIX>              Prefix inside the bucket to mount, ending in '/' [default: mount the entire bucket] [default: ]
#       --region <REGION>              AWS region of the bucket [default: auto-detect region]
#       --endpoint-url <ENDPOINT_URL>  S3 endpoint URL [default: auto-detect endpoint]
#       --virtual-addressing           Force virtual-host-style addressing
#       --path-addressing              Force path-style addressing
#       --requester-pays               Set the 'x-amz-request-payer' to 'requester' on S3 requests

# Mount options:
#       --auto-unmount           Automatically unmount on exit
#       --allow-root             Allow root user to access file system
#       --allow-other            Allow other non-root users to access file system
#       --uid <UID>              Owner UID [default: current user's UID]
#       --gid <GID>              Owner GID [default: current user's GID]
#       --dir-mode <DIR_MODE>    Directory permissions [default: 0755]
#       --file-mode <FILE_MODE>  File permissions [default: 0644]

# Client options:
#       --throughput-target-gbps <N>  Desired throughput in Gbps [default: 10]
#       --thread-count <N>            Number of FUSE daemon threads [default: 1]
#       --part-size <PART_SIZE>       Part size for multi-part GET and PUT [default: 8388608]

# AWS credentials options:
#       --no-sign-request    Do not sign requests. Credentials will not be loaded if this argument is provided.
#       --profile <PROFILE>  Use a specific profile from your credential file.

# 2023-07-02T12:04:13.844183Z  WARN mountpoint_s3_client::s3_crt_client: meta request failed duration=204.765857297s request_result=MetaRequestResult { response_status: 0, crt_error: Error(2073, "aws-c-http: AWS_ERROR_HTTP_CHANNEL_THROUGHPUT_FAILURE, Http connection channel shut down due to failure to meet throughput minimum"), error_response_headers: None, error_response_body: None }
# 2023-07-02T12:04:13.844576Z ERROR mountpoint_s3::fs: write failed: put request failed

# oc adm policy add-scc-to-user -z default privileged -n arrow-ops-quarkus-stg


if [[ -z "${SIDECAR_LOG_MONITORING_ENABLED}" ]]; then
    echo "SIDECAR_LOG_MONITORING_ENABLED not set"
    echo "SideCar Log Monitoring Status: Disabled"
    sleep infinity
fi

if [[ "${SIDECAR_LOG_MONITORING_ENABLED}" != "true" ]]; then
    echo "SideCar Log Monitoring Status: Disabled"
    sleep infinity
else
    echo "SideCar Log Monitoring Status: Enabled"
    UUID=$(cat /proc/sys/kernel/random/uuid)
    DT=$(date +"%Y-%m-%d")
    mkdir -p $LOGROTATE_ARCHIVE
    touch $LOGROTATE_STATE
    chmod o-rw $LOGROTATE_STATE

    [ -d "$S3_MOUNT_DIRECTORY" ] && echo "Directory $S3_MOUNT_DIRECTORY exists." || echo "Creating: Directory $S3_MOUNT_DIRECTORY..."; mkdir -p $S3_MOUNT_DIRECTORY

cat <<EOT >> /etc/logrotate.d/$APP_LABEL.conf
$LOGROTATE_APP_LOG_FILE {
    #firstaction
    #    echo "start rotation \$(date)" >> /tmp/rotation.log
    #endscript
    rotate $LOGROTATE_APP_LOG_RETAIN
    $LOGROTATE_DURATION
    maxsize $LOGROTATE_MAXSIZE
    maxage 3
    copytruncate
    notifempty
    missingok
    dateext
    dateformat -%Y-%m-%d-%s.log
    olddir $LOGROTATE_ARCHIVE
    sharedscripts
    postrotate
        [ -d "$S3_MOUNT_DIRECTORY/$APP_LABEL/$DT" ] && echo "Directory $S3_MOUNT_DIRECTORY/$APP_LABEL/$DT exists." || echo "Creating: Directory $S3_MOUNT_DIRECTORY/$APP_LABEL/$DT..."; mkdir -p $S3_MOUNT_DIRECTORY/$APP_LABEL/$DT
        cp $LOGROTATE_ARCHIVE/*.log $S3_MOUNT_DIRECTORY/$APP_LABEL/$DT
        rm $LOGROTATE_ARCHIVE/*.log
    endscript
    #lastaction
    #    echo "complete rotation \$(date)" >> /tmp/rotation.log
    #endscript
}
EOT

    touch /etc/cron.d/logrotate-cron
    echo "$LOGROTATE_FREQUENCY /usr/sbin/logrotate /etc/logrotate.d/$APP_LABEL.conf --state $LOGROTATE_STATE" >> /etc/cron.d/logrotate-cron
    # echo "$LOGROTATE_FREQUENCY /usr/sbin/logrotate -f /etc/logrotate.d/$APP_LABEL.conf" >> /etc/cron.d/logrotate-cron
    chmod 0644 /etc/cron.d/logrotate-cron
    crontab /etc/cron.d/logrotate-cron
    service cron start

cat <<EOT >> ~/.aws/credentials
[default]
aws_access_key_id = $AWS_ACCESS_KEY
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOT
    mount-s3 -f $S3_BUCKET_NAME $S3_MOUNT_DIRECTORY --prefix $S3_PATH --allow-other --dir-mode 0755 --file-mode 0755 --thread-count $FUSE_THREAD_COUNT --throughput-target-gbps $FUSE_THROUGHPUT_TARGET_GBPS
fi