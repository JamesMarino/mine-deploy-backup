# Mine Deploy Backup Script

Note - EBS can only be accessed through an AWS VPC. Make sure you are running
the following on an EC2 instance in your VPC.

## Building, Running and Pushing

```bash
docker build -t minedeploy/backup:latest .
docker push minedeploy/backup:latest
docker run \
	--volume /var/run/docker.sock:/var/run/docker.sock \
	--volume /root/backup:/root/backup \
	--env INSTANCE_NAME=test-namespace \
	--env S3_BUCKET_NAME=test-backups-mine \
	--env EBS_VOLUME_NAME=TestMinecraftVolume \
	--env AWS_REGION=ap-southeast-2 \
	--env AWS_AZ=ap-southeast-2a \
	--rm \
	minedeploy/backup:latest
```

## Testing Using Volume on Amazon EC2

1.  Spin up a `t1.nano` with `SSH Access` Jump Box

### Install Docker Amazon Linux

```bash
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
docker info
```

### Install Docker

```bash
docker plugin install rexray/ebs \
    --grant-all-permissions \
    EBS_REGION=ap-southeast-2 \
    EBS_ACCESSKEY=AKIA123 \
    EBS_SECRETKEY=qwerty

docker volume create \
    --driver rexray/ebs \
    --name TestVolume

docker run \
    --name alpine \
    --interactive \
    --tty \
    --volume TestVolume:/data \
    alpine /bin/ash

docker exec \
    --interactive \
    --tty \
    alpine /bin/ash
```

## Docker

# Mine Deploy Backup Script Image

Required Environment Variables:

* INSTANCE_NAME
* S3_BUCKET_NAME
* EBS_VOLUME_NAME
* AWS_REGION
* AWS_AZ


## Backup Retrieval Instructions

Buckets are public and backups are in the format of `instanceName/instanceName-unixTimeStamp`.

They can be accessed through the following example.

```bash
s3BucketName="myBucketName"
instanceName="myInstanceName"

# List Bucket Contents
aws s3 ls ${myBucketName}/${instanceName}/ --no-sign-request

# Download file via HTTP
curl "https://${myBucketName}/${instanceName}/${instanceName}-1559912573.zip"
```

