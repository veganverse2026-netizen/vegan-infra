# Deploying VeganFit

Nothing is live yet — all four repos are local-only today. This is the order that
avoids the chicken-and-egg problem (backend needs the frontend/admin URLs for CORS,
frontend/admin need the backend URL to call it):

1. **Backend → Render** (get its URL first)
2. **Admin → Vercel**, **Frontend → Vercel** (now you have their URLs)
3. **Back to Render** — fill in `FRONTEND_URL` / `ADMIN_URL` with the real Vercel URLs
4. **Mobile (EAS)** — point `preview`/`production` build profiles at the real backend/frontend URLs

Free tiers only, matching the free-at-launch pricing decision — check current
Render/Vercel pricing pages before relying on exact limits, they change.

---

## 1. Backend → Render

`vegan-backend/render.yaml` is a Render Blueprint: it provisions the web service *and*
a Postgres database in one shot.

1. Push `vegan-backend` (including the new `render.yaml`) to GitHub.
2. In the Render dashboard: **New → Blueprint**, pick the `veg-backend` repo.
3. Render reads `render.yaml` and shows the `veganfit-backend` service + `veganfit-db`
   database it's about to create. Confirm.
4. Fill in the env vars marked `sync: false` in the Render dashboard (these are real
   secrets, not committed anywhere):

   | Key | Where it comes from |
   |---|---|
   | `JWT_SECRET` | generate a new long random string — don't reuse a local dev value |
   | `GOOGLE_CLIENT_ID` | Google Cloud Console OAuth client |
   | `SMTP_HOST` / `SMTP_PORT` / `SMTP_SECURE` / `SMTP_USER` / `SMTP_PASS` | your SMTP provider |
   | `AUTH_FROM_EMAIL` | sender address for OTP emails |
   | `INTERNAL_SECRET` | generate a new random string — **must match** the same value set on the frontend (step 2) |
   | `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | Cloudinary dashboard |
   | `ANTHROPIC_API_KEY` | Anthropic console — needed for `/ai-assistant/chat` |
   | `ANTHROPIC_MODEL` | e.g. `claude-sonnet-5` |
   | `FRONTEND_URL` / `ADMIN_URL` | placeholder for now — come back and set these after step 2 |

5. Deploy. Note the resulting URL (`https://veganfit-backend.onrender.com` or similar) —
   the CORS config (`FRONTEND_URL`/`ADMIN_URL` env vars) only allows requests from the
   URLs you set, so nothing else works until step 3.

Render's free Postgres tier has restrictions (rows/storage caps, may pause on
inactivity) — fine for pre-launch testing, revisit before real users show up.

---

## 2. Admin & Frontend → Vercel

Both are plain Next.js apps — Vercel needs no config beyond env vars.

### Admin (`veg-admin`)

1. Vercel → **Add New → Project** → import `veg-admin`.
2. Framework preset: Next.js (auto-detected). No root directory override needed.
3. Env vars:

   | Key | Value |
   |---|---|
   | `NEXT_PUBLIC_BACKEND_URL` | the Render backend URL from step 1 |

4. Deploy. Note the resulting Vercel URL.

### Frontend (`veg-frontend`)

1. Vercel → **Add New → Project** → import `veg-frontend`.
2. If deploying from the `dev` branch (the actual working branch — see repo notes),
   set that as the Production Branch in Vercel's Git settings.
3. Env vars:

   | Key | Value |
   |---|---|
   | `NEXT_PUBLIC_BACKEND_URL` | the Render backend URL from step 1 |
   | `NEXT_PUBLIC_APP_URL` | this app's own Vercel URL (fill in after first deploy, then redeploy) |
   | `BACKEND_URL` | same as `NEXT_PUBLIC_BACKEND_URL`, used server-side in API routes |
   | `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | same Google OAuth client as the backend |
   | `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Stripe dashboard (publishable key) |
   | `STRIPE_SECRET_KEY` | Stripe dashboard (secret key) |
   | `STRIPE_WEBHOOK_SECRET` | Stripe webhook endpoint secret, once the webhook is registered against this URL |
   | `INTERNAL_SECRET` | the **same** random string set on the backend in step 1 — this app's Stripe webhook calls the backend to create orders using this shared secret |

4. Deploy. Note the resulting Vercel URL.

---

## 3. Back to Render — close the loop

Update the backend's `FRONTEND_URL` and `ADMIN_URL` env vars on Render with the real
Vercel URLs from step 2, then redeploy the backend service so CORS allows them.

---

## 4. Mobile — EAS build profiles

The mobile app isn't deployed via Vercel/Render — it's built natively through EAS.
`veganverse-mobile/eas.json`'s `preview` and `production` profiles still point
`EXPO_PUBLIC_API_BASE_URL` / `EXPO_PUBLIC_WEB_APP_URL` at placeholder `*.example.com`
domains (flagged in that repo's own README). Once steps 1–3 are live, replace those
placeholders with the real Render/Vercel URLs before running
`eas build --profile preview|production`.
