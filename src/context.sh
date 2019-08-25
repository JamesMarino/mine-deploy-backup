#!/usr/bin/env ash

backupDate=$(date +%s)
volumeName=${EBS_VOLUME_NAME}
remoteBackupAddress="s3://${S3_BUCKET_NAME}/${INSTANCE_NAME}/${INSTANCE_NAME}-${backupDate}.zip"
localBackupAddress="/root/backup/backup.zip"
localBackupDirectory="/root/backup"
localMinecraftDataDirectory="/root/data"
awsRegion=${AWS_REGION}
awsAZ=${AWS_AZ}
backupVolumeName="BackupVolume"

volumeId=$(aws ec2 describe-volumes --filters Name=tag:Name,Values=${volumeName} --region ${awsRegion} | jq -r '.Volumes|.[0]|.VolumeId')
snapshotId=$(aws ec2 create-snapshot --volume-id ${volumeId} --region ${awsRegion} | jq -r '.SnapshotId')

currentSnapshotStatus="pending"

while [[ "$currentSnapshotStatus" != "completed" ]]
do
    sleep 5
    currentSnapshotStatus=$(aws ec2 describe-snapshots --snapshot-id ${snapshotId} --region ${awsRegion} | jq -r '.Snapshots|.[0]|.State')
    echo "[INFO] Waiting for Snapshot to be created"
done

backupVolumeId=$(aws ec2 create-volume --snapshot-id ${snapshotId} --tag-specification 'ResourceType=volume,Tags=[{Key=Name,Value='"${backupVolumeName}"'}]' --availability-zone ${awsAZ} --region ${awsRegion} | jq -r '.VolumeId')

backupVolumeStatus="unavailable"

while [[ "$backupVolumeStatus" != "available" ]]
do
    sleep 5
    backupVolumeStatus=$(aws ec2 describe-volumes --volume-id ${backupVolumeId} --region ${awsRegion} | jq -r '.Volumes|.[0]|.State')
    echo "[INFO] Waiting for Volume to be created"
done

docker run \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume ${localBackupDirectory}:${localBackupDirectory} \
    --volume ${backupVolumeName}:${localMinecraftDataDirectory} \
    --rm \
    alpine tar -czvf ${localBackupAddress} ${localMinecraftDataDirectory}

aws ec2 delete-volume --volume-id ${backupVolumeId} --region ${awsRegion}
aws ec2 delete-snapshot --snapshot-id ${snapshotId} --region ${awsRegion}

echo "[INFO] Starting copy to S3 Bucket '${S3_BUCKET_NAME}'"
aws s3 cp ${localBackupAddress} ${remoteBackupAddress}
echo "[INFO] Backup Address is: '${remoteBackupAddress}'"
echo "[INFO] Backup Success"
