# blind-peer-docker

Docker image for [blind-peer-cli](https://github.com/holepunchto/blind-peer-cli),
published to `ghcr.io/holepunchto/blind-peer-docker`. See the blind-peer-cli README
for the available CLI arguments.

## Running

The image is intended to run with host networking (`--network host`), so the
blind peer binds its DHT port directly on the host instead of behind Docker's NAT:

```sh
docker run -d --name blind-peer \
  --network host \
  -v blind-peer-store:/home/blind-peer/store \
  ghcr.io/holepunchto/blind-peer-docker:v1 \
  --port 49737
```

Extra CLI arguments are passed after the image name. Storage lives in the
`/home/blind-peer/store` volume.

On Kubernetes, set `hostNetwork: true` on the pod spec.

## Variants

Both variants are built from the same release tag and lockfile, for `linux/amd64`
and `linux/arm64`.

| Variant        | Runtime | Release tag                     | Promoted tags                                                                    | Build                          |
| -------------- | ------- | ------------------------------- | -------------------------------------------------------------------------------- | ------------------------------ |
| bare (default) | Bare    | `v1.15.1-r1-bare`, `v1.15.1-r1` | `v1-bare`, `v1.15-bare`, `v1.15.1-bare`, `latest-bare`, `v1`, `v1.15`, `v1.15.1`, `latest` | `docker build .`               |
| node           | Node.js | `v1.15.1-r1-node`               | `v1-node`, `v1.15-node`, `v1.15.1-node`, `latest-node`                           | `docker build --target node .` |

## Advanced usage

### Health checks

Readiness is checked over the control socket (`/home/blind-peer/.blind-peer.sock`)
with `/home/blind-peer/docker-entrypoint.sh readiness-probe`.

### Arguments file

Set `BLIND_PEER_ARGS_FILE` to a file with one or more arguments per line, e.g. a
mounted Kubernetes Secret, to keep secrets and config out of the command line.
Arguments after the image name are appended after the file's.
