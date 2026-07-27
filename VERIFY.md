# Proof of Isolation

Run this after `make apply ENV=<staging|production>`:

```bash
make verify ENV=staging
```

That calls `scripts/verify-isolation.sh staging`, which does two probes.

## How the probe actually works

My first attempt just did `docker exec <container> nc -z ...` straight
into the target container. That works fine for nginx (it's Alpine-based,
has a shell), but fails outright against the api container — it runs
`hashicorp/http-echo`, which is a scratch image with no shell and no
package manager, so there's nothing to exec into. Confirmed this by trying
`docker exec staging-api-0 sh -c "echo hi"` and getting "executable file
not found in $PATH".

So the script instead launches a throwaway `busybox` container attached to
the *target's* network namespace (`--network container:<name>`), and runs
the probe from there. Network-wise that's equivalent to running it inside
the container itself — same IP, same routes, same reachability — but it
doesn't care what's actually installed inside the target image.

## Probe 1 — API (compute tier) → Postgres:5432 — expect SUCCESS

```bash
docker run --rm --network container:staging-api-0 busybox:1.36 \
  nc -z -w 3 staging-postgres 5432
```

`api` and `postgres` are both on `staging-db-net`, so this connects.
Expected output from the script:

```
[1/2] API (compute tier) -> Postgres:5432  expect SUCCESS ... PASS (reachable, as expected)
```

## Probe 2 — nginx (edge tier) → Postgres:5432 — expect FAILURE

```bash
docker run --rm --network container:staging-nginx busybox:1.36 \
  nc -z -w 3 staging-postgres 5432
```

nginx is only attached to `staging-edge-net` and `staging-app-net` — no
attachment to `staging-db-net` at all, so Docker's embedded DNS won't even
resolve `staging-postgres` from here, let alone route to it. Expected
output:

```
[2/2] Nginx (edge tier) -> Postgres:5432  expect FAILURE ... PASS (unreachable, as expected - no shared network with db_internal)
```

## Why this counts as a real proof, not just a demo

This isn't a firewall rule that someone could misconfigure — it's the
*absence* of a `networks_advanced` block for `db_internal` on
`docker_container.nginx` in `modules/app-stack/main.tf`. If a PR ever adds
`db_internal` to nginx's network list, that's a one-line diff, visible in
review, and it's the entire isolation boundary — there's no other place
the control could quietly break.

## Manual double-check (optional)

```bash
docker network inspect staging-db-net --format '{{range .Containers}}{{.Name}} {{end}}'
# -> staging-api-0  staging-postgres
# (nginx isn't in this list)
```
