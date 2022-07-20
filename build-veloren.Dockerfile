# Base container for building the server.
# Pass --build-arg BUILD_ARGS="--release" to build in Release mode.
FROM rust:1.62.1-slim-bullseye as builder
ARG BUILD_ARGS=""

RUN apt update && apt install -y git
ADD . /build
WORKDIR /build/veloren
ENV RUST_BACKTRACE=full BUILD_ARGS=$BUILD_ARGS
RUN cargo build ${BUILD_ARGS} --bin veloren-server-cli

# Empty container to export using docker build --target=exporter --outputs=tar,veloren.tar
FROM scratch as exporter
COPY --from=builder /build/veloren/target/debug/veloren-server-cli /opt/veloren/veloren-server-cli
COPY --from=builder /build/veloren/target/debug/git* /opt/veloren/
COPY --from=builder /build/veloren/assets/common /opt/veloren/assets/common
COPY --from=builder /build/veloren/assets/server /opt/veloren/assets/server
COPY --from=builder /build/veloren/assets/world /opt/veloren/assets/world

# Build a proper server image
FROM debian:bullseye-slim as server
ARG VELOREN_VERSION=unknown
ARG VELOREN_COMMIT=unknown

COPY --from=builder /build/veloren/target/debug/veloren-server-cli /opt/veloren/veloren-server-cli
COPY --from=builder /build/veloren/target/debug/git* /opt/veloren/
COPY --from=builder /build/veloren/assets/common /opt/veloren/assets/common
COPY --from=builder /build/veloren/assets/server /opt/veloren/assets/server
COPY --from=builder /build/veloren/assets/world /opt/veloren/assets/world

VOLUME /opt/veloren/userdata
ENV VELOREN_VERSION=${VELOREN_VERSION} VELOREN_COMMIT=${VELOREN_COMMIT}
ENV VELOREN_USERDATA=/opt/veloren/userdata OUT_DIR=/opt/veloren/
EXPOSE 14004 14005
CMD "/opt/veloren/veloren-server-cli"
