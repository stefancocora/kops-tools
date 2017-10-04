FROM alpine:3.6
MAINTAINER "Stefan Cocora <stefan.cocora@googlemail.com>"

# inspired by https://github.com/hashicorp/docker-hub-images/blob/master/terraform/Dockerfile-light

ENV AWSCLI_VERSION="1.11.162"
ENV TERRAFORM_VERSION=0.10.6
ENV TERRAFORM_SHA256SUM=fbb4c37d91ee34aff5464df509367ab71a90272b7fab0fbd1893b367341d6e23
ENV TOOLSET_NAME="kops-tools"
ENV CWD="/${TOOLSET_NAME}"
ENV UNPRIVILEDGED_USER="kops"


RUN apk add --update --no-cache ca-certificates py2-pip util-linux openssl tree

# install terraform
# ADD commands are not cached by docker, using wget
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS -O  terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform_${TERRAFORM_VERSION}_SHA256SUMS && sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin
RUN rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN rm -f terraform_${TERRAFORM_VERSION}_SHA256SUMS

WORKDIR ${CWD}

RUN adduser -h /home/${UNPRIVILEDGED_USER} -D -G users -s /bin/sh ${UNPRIVILEDGED_USER}
RUN chown ${UNPRIVILEDGED_USER}:users -R ${CWD}

ADD elf/kops.* /usr/bin/kops

USER ${UNPRIVILEDGED_USER}

ENTRYPOINT ["/bin/bash"]
