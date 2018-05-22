# Publisher
#
# This image is used to publish files into other docker containers
#
# For usage please see the following support files:
#   ./compile_image.sh
#   ./run_image.sh

FROM 32bit/ubuntu:16.04
MAINTAINER Roger Santos (http://rogeriodossantos.github.io)

WORKDIR /root/

RUN mkdir -p /work \
      mkdir -p /docker \
      mkdir -p /src

COPY ./docker/run_image.sh /docker/
COPY ./docker/entrypoint.sh /docker/
COPY ./docker/launcher.sh /docker/
COPY ./docker/README.md /docker/

COPY ./src /src

ENTRYPOINT ["/docker/entrypoint.sh"]
