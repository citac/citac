FROM citac/environments:base_ubuntu-14.04

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qy pkg-config libaugeas-dev \
 && gem install --no-ri --no-rdoc ruby-augeas

RUN gem install --no-ri --no-rdoc puppet --version 3.7.5

# Citac Installation

RUN mkdir -p /opt/citac
ADD citac.tar.gz /opt/citac
