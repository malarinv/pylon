FROM --platform=$BUILDPLATFORM debian:bookworm-slim as build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apt-get update -qq && apt-get install -y   build-essential git make pkg-config cmake libssl-dev file # Added 'file' back for diagnostics

COPY ./ /code
WORKDIR /code

RUN make release

RUN if [ ! -f /code/pylon ]; then     echo "ERROR: /code/pylon not found after make release!" >&2 && exit 1;   else     echo "/code/pylon found, details:";     ls -l /code/pylon;     file /code/pylon;   fi

FROM debian:bookworm-slim
COPY --from=build /code/pylon /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/pylon" ]
CMD ["reflect"]
