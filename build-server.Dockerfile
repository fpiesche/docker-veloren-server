FROM alpine:3.16.1 AS downloader

WORKDIR /veloren
RUN apk add --no-cache wget unzip \
    && wget https://download.veloren.net/latest/linux/$(uname -m)/nightly \
    && unzip nightly

FROM debian:buster-slim AS server

LABEL com.centurylinklabs.watchtower.stop-signal="SIGUSR1"

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends --assume-yes ca-certificates \
    && rm -rf /var/lib/apt/lists/*;

WORKDIR /veloren
COPY --from=downloader /veloren/veloren-server-cli /veloren/

COPY --from=downloader /veloren/assets/common /veloren/assets/common
COPY --from=downloader /veloren/assets/server /veloren/assets/server
COPY --from=downloader /veloren/assets/world /veloren/assets/world

CMD ["/veloren/veloren-server-cli"]