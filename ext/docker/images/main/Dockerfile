FROM citac/environments:base_ubuntu-14.04

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -qy graphviz

# Citac Installation

RUN mkdir -p /opt/citac
ADD citac.tar.gz /opt/citac

RUN touch /opt/citac/incontainer
