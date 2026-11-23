# syntax=docker/dockerfile:1@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

ARG RUST_IMAGE=rust:1-bookworm@sha256:ade39a710ef85f3506cffcfec3e8a24ba090badef1dff2fb798f71d878833fea
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian12:nonroot@sha256:9dac0a79194e45a7da0158a9c6da57b217585af0786db3845d1f0ec1a0dd182f

FROM ${RUST_IMAGE} AS build

ARG BOBBIN_REPO=https://tangled.org/tangled.org/core
ARG BOBBIN_REF=dc0dabd366879d4922841e364a8183fe33ab1744

RUN apt-get update \
 && apt-get install -y --no-install-recommends cmake \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone "${BOBBIN_REPO}" . \
 && git checkout --detach "${BOBBIN_REF}"

# Use the toolchain supplied by the pinned builder image.
RUN rm -f rust-toolchain.toml

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=/src/target \
    cargo build --release --locked --bin bobbin --package bobbin \
 && cp target/release/bobbin /usr/local/bin/bobbin

FROM ${RUNTIME_IMAGE} AS runtime

COPY --from=build /usr/local/bin/bobbin /usr/local/bin/bobbin

ENV BOBBIN_BIND=0.0.0.0:8090

EXPOSE 8090
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/bobbin"]
