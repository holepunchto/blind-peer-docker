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
  ghcr.io/holepunchto/blind-peer-docker:v1
```

Extra CLI arguments are passed after the image name. Storage lives in the
`/home/blind-peer/store` volume.

## Tags

The image is built for `linux/amd64` and `linux/arm64` and runs blind-peer on
[Bare](https://github.com/holepunchto/bare).

| Release tag  | Promoted tags                      | Build            |
| ------------ | ---------------------------------- | ---------------- |
| `v1.15.1-r1` | `v1`, `v1.15`, `v1.15.1`, `latest` | `docker build .` |

## Advanced usage

### Health checks

The image defines a Docker `HEALTHCHECK`, so `docker ps` and `docker inspect` report the
container as `starting`, then `healthy` once the blind peer is listening on the DHT,
or `unhealthy` if the check keeps failing. The check runs
`/home/blind-peer/docker-entrypoint.sh readiness-probe`, which queries the peer over its
control socket (`/home/blind-peer/.blind-peer.sock`).

Use the same command for Compose `healthcheck`, or as a Kubernetes readiness probe
(`exec` probe), since Kubernetes ignores the image `HEALTHCHECK`.

### Arguments file

Set `BLIND_PEER_ARGS_FILE` to a file with one or more arguments per line, e.g. a
mounted Kubernetes Secret, to keep secrets and config out of the command line.
Arguments after the image name are appended after the file's.
