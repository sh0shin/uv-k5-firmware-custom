FROM docker.io/library/alpine:3.21

# hadolint ignore=DL3018
RUN \
apk add --no-cache \
bash \
build-base \
gcc-arm-none-eabi \
newlib-arm-none-eabi \
python3 \
py3-crcmod \
py3-pip \
git

WORKDIR /app
COPY . .
#RUN git submodule update --init --recursive
