FROM --platform=$BUILDPLATFORM debian:bookworm-slim as build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apt-get update -qq &&   DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends   build-essential git make pkg-config cmake libssl-dev file   $(if [ "$TARGETPLATFORM" = "linux/arm64" ]; then echo "g++-aarch64-linux-gnu gcc-aarch64-linux-gnu"; fi)

COPY ./ /code
WORKDIR /code

RUN make release TARGETPLATFORM=$TARGETPLATFORM

RUN if [ ! -f /code/pylon ]; then     echo "ERROR: /code/pylon not found after make release!" >&2 && exit 1;   else     echo "/code/pylon found, details:";     ls -l /code/pylon;     file /code/pylon;   fi

FROM debian:bookworm-slim
COPY --from=build /code/pylon /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/pylon" ]
CMD ["reflect"]
