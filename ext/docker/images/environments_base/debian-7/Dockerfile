FROM debian:wheezy

# Required Packages

RUN echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qy \
    ca-certificates wget curl \
    make gcc g++ \
    ruby ruby-dev \
    net-tools \
 && gem install --no-ri --no-rdoc thor rest-client hashdiff \
 && curl -sSL https://get.docker.com/ | sh

# Install specific version of Docker
RUN mv /usr/bin/docker /usr/bin/docker-old \
 && wget https://get.docker.com/builds/Linux/x86_64/docker-1.8.3 -O /usr/bin/docker \
 && chmod +x /usr/bin/docker

# Strace 4.10 Installation (compilation from source)

RUN wget http://downloads.sourceforge.net/project/strace/strace/4.10/strace-4.10.tar.xz -O /tmp/strace-4.10.tar.xz \
 && tar -C /tmp -xf /tmp/strace-4.10.tar.xz \
 && cd /tmp/strace-4.10 && ./configure \
 && make -C /tmp/strace-4.10 \
 && make -C /tmp/strace-4.10 install \
 && rm -rf /tmp/strace-4.10 /tmp/strace-4.10.tar.xz

ENV PATH /opt/citac/bin:/opt/citac/bin/docker:$PATH
