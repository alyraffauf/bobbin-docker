# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

ARG RUST_IMAGE=rust:1-bookworm@sha256:e12566d5abc17a0da741628782cdb504b68b8961f5bfcf677936bf3e8b32de29
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian12:nonroot@sha256:9dac0a79194e45a7da0158a9c6da57b217585af0786db3845d1f0ec1a0dd182f

FROM ${RUST_IMAGE} AS build

ARG BOBBIN_REPO=https://tangled.org/tangled.org/core
ARG BOBBIN_REF=e0ef7981da82fe1516cbdc2992b3023f4b2ca717

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
