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

Both variants are built from the same release tag and lockfile.

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

## Contributing

### Releasing

Images are built only from `vX.Y.Z-rN` tags, where `X.Y.Z` is the blind-peer-cli
version in `package.json` and `N` is the image revision (bump it to rebuild the same
version, e.g. for base image updates).

```sh
git tag v1.15.1-r1
git push origin v1.15.1-r1
```

`publish.yml` builds and smoke tests both variants, then pushes `v1.15.1-r1-bare`,
`v1.15.1-r1` and `v1.15.1-r1-node`.

### Promoting

Once verified, run the `promote.yml` workflow (Actions → Promote Docker image) with
the release tag. It retags the existing images (same digest) with the promoted tags
listed under [Variants](#variants). Promoting an older release rolls the tags back.
