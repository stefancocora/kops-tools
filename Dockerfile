FROM alpine:3.6
MAINTAINER "Stefan Cocora <stefan.cocora@googlemail.com>"

# inspired by
# https://github.com/hashicorp/docker-hub-images/blob/master/terraform/Dockerfile-light
# https://github.com/wernight/docker-kubectl/blob/master/Dockerfile
# https://github.com/lachie83/k8s-helm/blob/v2.6.1/Dockerfile

ENV AWSCLI_VERSION="1.11.166"
ENV TERRAFORM_VERSION=0.10.7
ENV TERRAFORM_SHA256SUM=8fb5f587fcf67fd31d547ec53c31180e6ab9972e195905881d3dddb8038c5a37
ENV TOOLSET_NAME="kops-tools"
ENV CWD="/${TOOLSET_NAME}"
ENV UNPRIVILEDGED_USER="kops"
ENV KUBECTL_VERSION="v1.7.8"
ENV HELM_VERSION="v2.6.1"


RUN apk add --update --no-cache ca-certificates coreutils py2-pip util-linux openssl tree

# install terraform
# ADD commands are not cached by docker, using wget
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS -O  terraform_${TERRAFORM_VERSION}_SHA256SUMS
# RUN echo "${TERRAFORM_SHA256SUM}  terraform_${TERRAFORM_VERSION}_linux_amd64.zip" > terraform_${TERRAFORM_VERSION}_SHA256SUMS && sha256sum -cs terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin
RUN rm -f terraform_${TERRAFORM_VERSION}_linux_amd64.zip
RUN rm -f terraform_${TERRAFORM_VERSION}_SHA256SUMS

# install awscli
RUN pip --disable-pip-version-check install awscli==$AWSCLI_VERSION && \
	apk --purge -v del openssl ca-certificates && \
	rm /var/cache/apk/*

WORKDIR ${CWD}

RUN adduser -h /home/${UNPRIVILEDGED_USER} -D -G users -s /bin/sh ${UNPRIVILEDGED_USER}
RUN chown ${UNPRIVILEDGED_USER}:users -R ${CWD}

ADD elf/kops /usr/local/bin/kops

ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN wget http://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -xvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin \
    && rm -f /helm-${HELM_VERSION}-linux-amd64.tar.gz

USER ${UNPRIVILEDGED_USER}

ENTRYPOINT ["/bin/sh"]
