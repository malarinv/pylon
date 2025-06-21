FROM --platform=$BUILDPLATFORM debian:bookworm-slim as build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN apt-get update -qq && apt-get install -y   build-essential git make pkg-config cmake libssl-dev file

COPY ./ /code
WORKDIR /code

# Enhanced make release step for diagnostics
RUN   if [ "$TARGETPLATFORM" = "linux/arm64" ]; then     echo "Building for ARM64 (TARGETPLATFORM: $TARGETPLATFORM) with verbose output...";     # Attempt to enable verbose make, and ensure failure is propagated
    # The actual build command for libzt is within ext/libzt/build.sh,
    # which is called by the main Makefile's 'make release' target.
    # We hope 'make V=1' or similar might be respected by the sub-build.
    make release V=1 || (echo "make release failed!"; cat ./ext/libzt/config.log ./ext/libzt/ext/ZeroTierOne/config.log && exit 1);     echo "Post 'make release' diagnostics for ARM64:";     echo "Listing /code/pylon:";     ls -l /code/pylon;     echo "Running 'file' on /code/pylon:";     file /code/pylon;     echo "Running 'head -n 1' on /code/pylon (to check for script-like content):";     head -n 1 /code/pylon;   else     echo "Building for $TARGETPLATFORM...";     make release;   fi

# Existing diagnostic RUN block (now potentially redundant for file and initial check but good for ldd)
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then     echo "Running further diagnostics for ARM64 build (TARGETPLATFORM: $TARGETPLATFORM)...";     # 'file /code/pylon' was already run above, but ldd is still useful here.
    ldd /code/pylon;     echo "Attempting to get help output from pylon binary:";     /code/pylon --help || /code/pylon help || /code/pylon -h || echo "No help command succeeded, or pylon exited.";     fi

FROM debian:bookworm-slim
COPY --from=build /code/pylon /usr/local/bin
# EXPOSE 443
# EXPOSE 9993/udp
# ENV ZT_PYLON_SECRET_KEY=
# ENV ZT_PYLON_WHITELISTED_PORT=
ENTRYPOINT [ "/usr/local/bin/pylon" ]
CMD ["reflect"]
