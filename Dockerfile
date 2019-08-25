FROM alpine:3.9

ENV INSTANCE_NAME mine-deploy-instance
ENV S3_BUCKET_NAME mine-deploy-backup-bucket
ENV EBS_VOLUME_NAME my-ebs-volume
ENV AWS_REGION ap-southeast-2
ENV AWS_AZ ap-southeast-2a

COPY src/context.sh /root/scripts/context.sh

RUN apk update
RUN apk add python3 docker jq
RUN pip3 install awscli --upgrade

RUN export PATH=/root/.local/bin:$PATH
RUN chmod +x /root/scripts/context.sh

CMD /root/scripts/context.sh
