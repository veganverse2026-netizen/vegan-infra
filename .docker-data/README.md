Per-service `node_modules`/`.next`, bind-mounted here instead of into the app
repos, so container-installed (Linux) native binaries don't collide with
whatever you've installed on the host (macOS/etc) when running the apps
natively outside Docker too.

**Deliberately plain host directories, not Docker named volumes.** An earlier
version of this compose file used named volumes for this (`admin_node_modules:
/app/node_modules` etc.) alongside the whole-repo bind mount at `/app`. That
combination — a named volume nested under a bind mount — hit a real Docker
Desktop bug where removing the container wiped everything in the bind-mounted
repo outside the volume-shadowed paths (lost an entire repo's working tree
once). Bind-mount-to-bind-mount doesn't have that failure mode. Don't change
these back to named volumes.

Safe to delete this whole folder any time — it'll be repopulated by the next
`npm install`/`pnpm install` inside the containers.
