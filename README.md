# blind-peer-docker

Docker image for blind-peer, published to `ghcr.io/holepunchto/blind-peer-docker`.

## Variants

Both variants are built from the same release tag and lockfile.

| Variant        | Runtime | Release tag                     | Promoted tags                                                                    | Build                          |
| -------------- | ------- | ------------------------------- | -------------------------------------------------------------------------------- | ------------------------------ |
| bare (default) | Bare    | `v1.15.1-r1-bare`, `v1.15.1-r1` | `v1-bare`, `v1.15-bare`, `v1.15.1-bare`, `latest-bare`, `v1`, `v1.15`, `v1.15.1`, `latest` | `docker build .`               |
| node           | Node.js | `v1.15.1-r1-node`               | `v1-node`, `v1.15-node`, `v1.15.1-node`, `latest-node`                           | `docker build --target node .` |

## Releasing

Images are only built from release tags of the form `vX.Y.Z-rN`, where `X.Y.Z`
is the blind-peer-cli version in `package.json` and `N` is the image revision (bump it to
rebuild the same blind-peer version, e.g. for base image updates). Plain `vX.Y.Z`
tags are not built.

1. Update `package.json` / `package-lock.json` and commit.
2. Tag and push:

   ```sh
   git tag v1.15.1-r1
   git push origin v1.15.1-r1
   ```

   The `publish.yml` workflow builds both variants, smoke tests them, then tags
   `v1.15.1-r1-bare` + `v1.15.1-r1` (bare) and `v1.15.1-r1-node`.

## Promoting

Once a release image is verified, run the `promote.yml` workflow manually
(Actions → Promote Docker image → Run workflow) with the release tag, e.g. `v1.15.1-r1`.
It retags the existing images (same digest, no rebuild):

- `v1.15.1-r1-bare` → `v1`, `v1.15`, `v1.15.1`, `latest`, `v1-bare`, `v1.15-bare`, `v1.15.1-bare`, `latest-bare`
- `v1.15.1-r1-node` → `v1-node`, `v1.15-node`, `v1.15.1-node`, `latest-node`

```sh
gh workflow run promote.yml -f tag=v1.15.1-r1
```

Promoting an older release moves the tags back to it, which can be used for rollbacks.

## Running

Extra CLI arguments can be passed after the image name, or provided one or more
per line in an args file whose path is set in `BLIND_PEER_ARGS_FILE` (the container
exits with an error if it is set but the file does not exist). Storage lives in the `/home/blind-peer/store` volume.

The control socket defaults to `/home/blind-peer/.blind-peer.sock`. The image
`HEALTHCHECK` uses it, and Kubernetes can use the same command as an exec readiness probe:

```sh
/home/blind-peer/docker-entrypoint.sh readiness-probe
```

```sh
docker run -v blind-peer-store:/home/blind-peer/store ghcr.io/holepunchto/blind-peer-docker:v1
```
