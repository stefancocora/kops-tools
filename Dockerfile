FROM alpine:3.6
MAINTAINER "Stefan Cocora <stefan.cocora@googlemail.com>"

# inspired by
# https://github.com/hashicorp/docker-hub-images/blob/master/terraform/Dockerfile-light
# https://github.com/wernight/docker-kubectl/blob/master/Dockerfile
# https://github.com/lachie83/k8s-helm/blob/v2.6.1/Dockerfile

ENV AWSCLI_VERSION="1.11.185"
ENV TERRAFORM_VERSION=0.10.8
ENV TERRAFORM_SHA256SUM=b786c0cf936e24145fad632efd0fe48c831558cc9e43c071fffd93f35e3150db
ENV TOOLSET_NAME="kops-tools"
ENV CWD="/${TOOLSET_NAME}"
ENV UNPRIVILEDGED_USER="kops"
ENV KUBECTL_VERSION="v1.8.2"
ENV HELM_VERSION="v2.6.2"
ENV YAML_VERSION=1.13.1
ENV YAML_SHASUM=28308a7231905030a62f20c92d41513e570d24f1984c1864198cbc4e039d3bec
ENV KOPS_RELEASE_ID=8410205


RUN apk add --update --no-cache ca-certificates coreutils py2-pip util-linux openssl tree

# install terraform
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

# kops
ADD elf/kops /usr/local/bin/kops
RUN chmod +x /usr/local/bin/kops

# RUN apk add --no-cache --update ca-certificates vim curl jq && \
#     KOPS_URL=$(curl -s https://api.github.com/repos/kubernetes/kops/releases/${KOPS_RELEASE_ID} | jq -r ".assets[] | select(.name == \"kops-linux-amd64\") | .browser_download_url") && \
#     curl -SsL --retry 5 "${KOPS_URL}" > /usr/local/bin/kops && \
#     chmod +x /usr/local/bin/kops && \
#     KUBECTL_VERSION=$(curl -SsL --retry 5 "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_TRACK}") && \
#     curl -SsL --retry 5 "https://storage.googleapis.com/${KUBECTL_SOURCE}/${KUBECTL_VERSION}/bin/${KUBECTL_ARCH}/kubectl" > /usr/local/bin/kubectl && \
#     chmod +x /usr/local/bin/kubectl


ADD https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/kubectl
RUN wget http://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -xvf helm-${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin \
    && rm -f /helm-${HELM_VERSION}-linux-amd64.tar.gz

# install yaml
RUN curl -L https://github.com/mikefarah/yaml/releases/download/${YAML_VERSION}/yaml_linux_amd64 > /usr/local/bin/yaml && \
    chmod +x /usr/local/bin/yaml && \
    sha256sum /usr/local/bin/yaml | grep $YAML_SHASUM

USER ${UNPRIVILEDGED_USER}

ENTRYPOINT ["/bin/sh"]
