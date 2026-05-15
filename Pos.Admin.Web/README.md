# Pos.Admin.Web

React + Vite + Fluent UI v9 admin console for the [Pos.Api](../Pos.Api/) multi-tenant POS backend. Tenant Admin and Manager staff use it to manage stores, products, categories, printers, users, and orders.

The original design — including wireframes for every page — is in [PLAN.md](PLAN.md).

---

## Prerequisites

- **Node.js 20+** and **npm 10+** (`node --version`, `npm --version`)
- The [Pos.Api](../Pos.Api/) backend, set up per its [README](../README.md) (SQL Server LocalDB + EF migrations)

The admin web has no other system requirements.

---

## First-time setup

From the repo root:

```powershell
cd Pos.Admin.Web
npm install
```

That installs Fluent UI v9, React Router, TanStack Query, Zustand, axios, react-hook-form + zod, and `@types/node`. No further config is needed — the dev proxy is hard-coded to forward `/api` to `http://localhost:5202`.

---

## Run

You need **both** the API and the admin web running. Open two terminals:

**Terminal 1 — API on `:5202`**

```powershell
cd Pos.Api
dotnet run
```

Wait for `Now listening on: http://localhost:5202`. Verify Swagger at <http://localhost:5202/swagger>.

**Terminal 2 — admin web on `:5173`**

```powershell
cd Pos.Admin.Web
npm run dev
```

Wait for `Local: http://localhost:5173/`, then open it in your browser.

> If you forget to start the API, the proxy now returns a clear `502` with the message *"Could not reach http://localhost:5202. Is dotnet run --project Pos.Api running?"* instead of a generic 500.

### First-time tenant

Two ways in:

| Goal | Steps |
|---|---|
| Use the API's seeded demo tenant | Click **Sign in**, use `admin@pos.local` / `Admin123!`. |
| Create a fresh tenant | Click **Create a restaurant** on the login page and fill in the signup form. The new admin user is signed in automatically. |

---

## What's where

```
Pos.Admin.Web/
├─ PLAN.md                 # Original design + wireframes
├─ vite.config.ts          # Dev server + /api proxy
├─ .env.development        # VITE_API_BASE_URL=/api (uses dev proxy)
├─ .env.production         # Override for prod builds
└─ src/
   ├─ main.tsx             # FluentProvider + QueryClient + Router + Toaster
   ├─ App.tsx              # Route tree
   ├─ index.css            # Tiny global reset
   ├─ api/                 # 1 axios client + 1 file per resource
   ├─ auth/                # Zustand store, ProtectedRoute, RoleGate
   ├─ layout/              # AppShell + TopBar + SideNav
   ├─ components/          # DataTable, FormDrawer, ConfirmDialog, field wrappers, toast helper, PageHeader
   ├─ pages/
   │  ├─ Login.tsx
   │  ├─ Signup.tsx
   │  ├─ Dashboard.tsx
   │  ├─ categories/  (Categories.tsx, CategoryFormDrawer.tsx)
   │  ├─ products/
   │  ├─ stores/
   │  ├─ printers/
   │  ├─ users/        (Admin-only)
   │  ├─ orders/       (Orders.tsx + OrderDetail.tsx dialog)
   │  └─ settings/     (TenantSettings.tsx — Admin-only)
   └─ types/api.ts          # Hand-written TS mirrors of the C# DTOs
```

---

## How auth works

- Login or signup returns a JWT containing the `restaurant_id` claim.
- The JWT + user info is persisted to `localStorage` (key `pos-admin-auth`) by Zustand's `persist` middleware. Refreshing the page keeps you signed in.
- Every axios request injects `Authorization: Bearer <jwt>` via an interceptor in [src/api/client.ts](src/api/client.ts).
- A `401` response anywhere clears auth and bounces you back to `/login`.
- `<ProtectedRoute>` guards every authenticated route; `<ProtectedRoute roles={['Admin']}>` extends that to `/users` and `/settings`.
- The side nav uses `<RoleGate roles={['Admin']}>` to hide Admin-only links from Manager/Cashier users.

Tenant context is implicit — the JWT carries `restaurant_id`, EF Core applies query filters, and the frontend never sends a tenant id.

---

## Scripts

| Command | What it does |
|---|---|
| `npm run dev` | Start Vite dev server on `:5173` with HMR and the `/api → :5202` proxy |
| `npm run build` | `tsc -b` then `vite build`; emits a static bundle to `dist/` |
| `npm run preview` | Serve the production bundle locally to spot-check the build |

---

## Smoke test after pulling

Quickest way to make sure both ends are talking:

```powershell
# Terminal 1
cd Pos.Api ; dotnet run

# Terminal 2 — verify proxy without opening a browser
curl -s -o NUL -w "API:   %{http_code}`n" http://localhost:5202/swagger/index.html
curl -s -o NUL -w "Vite:  %{http_code}`n" http://localhost:5173/
curl -s -o NUL -w "Proxy: %{http_code}`n" -X POST http://localhost:5173/api/auth/login `
     -H "Content-Type: application/json" -d '{\"email\":\"none\",\"password\":\"bad\"}'
```

Expected: `API: 200`, `Vite: 200`, `Proxy: 401` (bad creds — proves the proxy forwards and the API responds).

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Signup or login shows toast `Could not reach http://localhost:5202…` | API isn't running. Start `dotnet run --project Pos.Api`. |
| `npm run dev` says `Port 5173 is in use, trying another one…` | An earlier Vite instance is still alive. Either use the new port shown in the terminal, or kill the old `node` process. Note that picking a different port means the API's CORS allowlist won't include it, but the proxy still works fine. |
| Signup fails with HTTP `409 Slug is already taken` | Pick a different slug — slugs are globally unique across tenants. |
| Authenticated request returns `401` and bounces to `/login` | The token expired (default 480 min). Sign in again. |
| Admin-only nav items missing | You're signed in as Manager or Cashier. Sign in as an Admin user to see Users + Tenant settings. |
| Fluent UI components look unstyled | Make sure `FluentProvider` wraps `<App />` in [src/main.tsx](src/main.tsx). Don't render Fluent components outside it. |

---

## What's not built yet

- Order creation UI — order creation lives in the future till app. Today the admin web only lists orders, changes status, and records payments. To exercise the order detail dialog, create an order via Swagger first.
- No password reset, no MFA, no email verification — out of scope per the original spec.
- No dark theme toggle — `FluentProvider` is currently fixed to `webLightTheme`. Swap to `webDarkTheme` in [src/main.tsx](src/main.tsx) for dark mode.
