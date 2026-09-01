# veganverse-infra

Local dev orchestration, shared CI, and deployment configs for the VeganFit/VeganVerse
project — so you don't have to hand-juggle four separate repos.

## The 4 repos

| Repo | What it is | Runs on |
|---|---|---|
| [`vegan-backend`](../vegan-backend) | Express + Prisma API, Postgres | `:4000` |
| [`vegan-Admin`](../vegan-Admin) | Next.js admin console | `:3001` |
| [`VeganFit_Next-Frontend`](../VeganFit_Next-Frontend) | Next.js consumer web app | `:3000` |
| [`veganverse-mobile`](../veganverse-mobile) | Expo/React Native app (not containerized, run natively) | Expo dev server |

This repo (`veganverse-infra`) must sit **next to the other three** in the same
parent folder — that's already how they're laid out locally. `docker-compose.yml`
build-contexts and bind-mounts the sibling repos by relative path (`../vegan-backend`
etc.), so it works straight out of a fresh `git clone` of all four into one folder.

## Local dev — one command

```bash
git clone https://github.com/veganverse2026-netizen/veg-backend.git vegan-backend
git clone https://github.com/veganverse2026-netizen/veg-admin.git vegan-Admin
git clone https://github.com/veganverse2026-netizen/veg-frontend.git VeganFit_Next-Frontend
git clone https://github.com/veganverse2026-netizen/veganverse-infra.git

cd veganverse-infra
make up
```

`make up` runs `scripts/bootstrap.sh`, which:

1. Checks the three sibling repos are actually there.
2. Seeds any missing `.env` / `.env.local` files from each repo's own `.env.example`
   (or minimal local defaults for the frontend) — it never overwrites one that exists.
3. Runs `docker compose up --build`: Postgres, then backend (installs deps, runs
   `prisma generate` + `prisma migrate deploy`, starts `tsx watch`), then admin and
   frontend (`next dev`, hot-reloading via bind mount).

First run: `http://localhost:3000` (frontend), `http://localhost:3001` (admin),
`http://localhost:4000` (backend API).

Other commands:

```bash
make logs       # tail all service logs
make down       # stop everything
make restart    # restart containers without rebuilding
make migrate    # run `prisma migrate dev` interactively (creating a new migration)
make reset-db   # wipe the local Postgres volume and start fresh
```

Editing app secrets (SMTP, Cloudinary, Anthropic key, Stripe, ...)? Edit the real
`.env`/`.env.local` file in the relevant app repo directly — `docker-compose.yml`
only overrides the handful of values that need to point at container hostnames
(`DATABASE_URL`, `PORT`, `FRONTEND_URL`, `ADMIN_URL`, `NEXT_PUBLIC_BACKEND_URL`,
`NEXT_PUBLIC_APP_URL`); everything else is read straight from each app's own env file
since the repo is bind-mounted into its container.

### Mobile

Not part of `docker compose` — Expo needs a real device/simulator and doesn't gain
anything from a container. Run it natively against the same local backend:

```bash
cd ../veganverse-mobile
npm install
cp .env.example .env   # defaults already point at http://localhost:4000
npx expo start
```

## CI

[`.github/workflows/node-ci.yml`](.github/workflows/node-ci.yml) is a *reusable*
workflow (install → lint → typecheck → build, `--if-present` so a missing script is
a no-op, not a failure). Each of the 4 app repos has a two-line
`.github/workflows/ci.yml` that calls it:

```yaml
jobs:
  ci:
    uses: veganverse2026-netizen/veganverse-infra/.github/workflows/node-ci.yml@main
    with:
      package-manager: npm   # or pnpm, for the frontend
```

Node is pinned to **22** everywhere — Node 24 causes `tsc` to exit non-zero with
zero error output on this dependency tree (bit the backend and mobile repos before).

**One-time setup after this repo is pushed:** GitHub only lets a reusable workflow be
called from another repo in the same org if that's allowed — on `veganverse-infra`,
go to **Settings → Actions → General → Access** and allow access from repositories
in the `veganverse2026-netizen` org (or make the repo public). Without this, the
four callers' CI runs will fail to resolve the reusable workflow.

## Deployment

See [`DEPLOY.md`](DEPLOY.md) — backend → Render, admin/frontend → Vercel, in the
order that avoids the CORS chicken-and-egg problem, plus the exact env vars each
service needs.
