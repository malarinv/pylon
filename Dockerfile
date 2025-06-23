FROM --platform=$BUILDPLATFORM debian:bookworm-slim as build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apt-get update -qq && apt-get install -y   build-essential git make pkg-config cmake libssl-dev file

COPY ./ /code
WORKDIR /code

# Enhanced make release step for diagnostics, using sh -c '...'
RUN sh -c ' \
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
    echo "Building for ARM64 (TARGETPLATFORM: $TARGETPLATFORM) with verbose output..."; \
    make release V=1 || (echo "make release failed!" >&2; cat ./ext/libzt/config.log ./ext/libzt/ext/ZeroTierOne/config.log >&2 && exit 1); \
    echo "Post \'make release\' diagnostics for ARM64:"; \
    echo "Listing /code/pylon:"; \
    ls -l /code/pylon; \
    echo "Running \'file\' on /code/pylon:"; \
    file /code/pylon; \
    echo "Running \'head -n 1\' on /code/pylon (to check for script-like content):"; \
    head -n 1 /code/pylon; \
  else \
    echo "Building for $TARGETPLATFORM..."; \
    make release; \
  fi \
'

# Existing diagnostic RUN block
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
    echo "Running further diagnostics for ARM64 build (TARGETPLATFORM: $TARGETPLATFORM)..."; \
    ldd /code/pylon; \
    echo "Attempting to get help output from pylon binary:"; \
    /code/pylon --help || /code/pylon help || /code/pylon -h || echo "No help command succeeded, or pylon exited."; \
    fi

FROM debian:bookworm-slim
COPY --from=build /code/pylon /usr/local/bin
# EXPOSE 443
# EXPOSE 9993/udp
# ENV ZT_PYLON_SECRET_KEY=
# ENV ZT_PYLON_WHITELISTED_PORT=
ENTRYPOINT [ "/usr/local/bin/pylon" ]
CMD ["reflect"]
