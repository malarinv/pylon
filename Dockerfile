FROM --platform=$BUILDPLATFORM debian:bookworm-slim as build
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# file utility is no longer needed in this simplified build stage
RUN apt-get update -qq && apt-get install -y   build-essential git make pkg-config cmake libssl-dev

COPY ./ /code
WORKDIR /code

RUN make release

FROM debian:bookworm-slim
COPY --from=build /code/pylon /usr/local/bin
ENTRYPOINT [ "/usr/local/bin/pylon" ]
CMD ["reflect"]
