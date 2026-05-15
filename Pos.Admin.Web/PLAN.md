# Admin Web for POS API — React + Vite + Fluent UI

## Context

The repo already contains a multi-tenant POS REST API at [Pos.Api/](Pos.Api/) (ASP.NET Core .NET 10, SQL Server + EF Core, JWT auth, row-level tenant isolation via the `restaurant_id` claim and `TenantContextMiddleware`). There is no UI yet — every workflow today goes through Swagger.

This plan adds a sibling React project, **Pos.Admin.Web**, that exposes the management surface of the API to tenant staff (Admin / Manager roles). It is the operator console: a tenant signs up, logs in, configures stores/categories/products/printers, manages staff, and reviews orders. It is *not* the cashier POS — order creation is left to a future till-app.

The build is phased: scaffold + auth shell first, then one CRUD resource at a time using a shared list/form pattern. Wireframes below are the visual contract the user signs off on before any code is written.

---

## Tech stack

| Concern | Choice | Why |
|---|---|---|
| Build tool | Vite (React + TypeScript template) | Fast dev server, matches API's CORS allowlist (`http://localhost:5173`) |
| UI kit | `@fluentui/react-components` v9 (Fluent UI v9) | Microsoft's current React kit; DataGrid, Dialog, Drawer, FluentProvider theming |
| Icons | `@fluentui/react-icons` | Companion icon pack |
| Routing | `react-router-dom` v6 | Nested routes for shell layout + protected routes |
| Server state | `@tanstack/react-query` v5 | Caching, refetch-on-focus, mutation invalidation |
| Client state | `zustand` (with `persist` middleware) | Holds JWT + user identity in `localStorage` |
| HTTP | `axios` with one interceptor | Attaches `Authorization: Bearer <jwt>`; 401 handler clears auth |
| Forms | `react-hook-form` + `zod` resolver | Matches the API's `[Required]` / `MaxLength` / `Range` validation rules |
| Notifications | Fluent UI `Toaster` / `useToastController` | Success/error toasts on mutations |

No SSR, no Next.js, no design-system fork. Plain Vite SPA served on `:5173` in dev, talking to API on `http://localhost:5202`.

---

## Project location & layout

Sibling folder: `c:\Repo\POC\POC\Pos.Admin.Web\`

```
Pos.Admin.Web/
├─ index.html
├─ package.json
├─ tsconfig.json
├─ vite.config.ts             # proxies /api → http://localhost:5202
├─ .env.development           # VITE_API_BASE_URL=http://localhost:5202
├─ .env.production            # VITE_API_BASE_URL=<prod url>
└─ src/
   ├─ main.tsx                # FluentProvider (webLightTheme) + QueryClientProvider + RouterProvider
   ├─ App.tsx                 # Route tree
   ├─ api/
   │  ├─ client.ts            # axios instance + interceptors
   │  ├─ auth.ts              # login(), signup()
   │  ├─ tenants.ts           # getMe(), updateMe()
   │  ├─ users.ts             # list/create/update/delete
   │  ├─ stores.ts
   │  ├─ categories.ts
   │  ├─ products.ts
   │  ├─ orders.ts            # list/get/updateStatus
   │  └─ printers.ts
   ├─ auth/
   │  ├─ authStore.ts         # zustand: { token, user, login(), logout() }
   │  ├─ ProtectedRoute.tsx   # redirects to /login when no token
   │  └─ RoleGate.tsx         # hides children based on role (Admin/Manager/Cashier)
   ├─ layout/
   │  ├─ AppShell.tsx         # Fluent NavDrawer + top bar + <Outlet/>
   │  ├─ TopBar.tsx           # Restaurant name, user menu, logout
   │  └─ SideNav.tsx          # NavCategory + NavItems
   ├─ components/
   │  ├─ DataTable.tsx        # Wraps Fluent DataGrid with loading/empty/error states
   │  ├─ ConfirmDialog.tsx    # Reusable "are you sure?" Dialog
   │  ├─ FormDrawer.tsx       # Right-side Drawer hosting react-hook-form
   │  ├─ FieldText.tsx        # Fluent Input + react-hook-form Controller + error
   │  ├─ FieldNumber.tsx
   │  ├─ FieldSelect.tsx      # For Role, PrinterType, Category dropdowns
   │  └─ FieldSwitch.tsx      # For IsActive
   ├─ pages/
   │  ├─ Login.tsx
   │  ├─ Signup.tsx
   │  ├─ Dashboard.tsx
   │  ├─ users/{Users.tsx, UserFormDrawer.tsx}
   │  ├─ stores/{Stores.tsx, StoreFormDrawer.tsx}
   │  ├─ categories/{Categories.tsx, CategoryFormDrawer.tsx}
   │  ├─ products/{Products.tsx, ProductFormDrawer.tsx}
   │  ├─ orders/{Orders.tsx, OrderDetail.tsx}      # detail is a Dialog; can record payment + change status
   │  ├─ printers/{Printers.tsx, PrinterFormDrawer.tsx}
   │  └─ settings/TenantSettings.tsx
   └─ types/
      └─ api.ts               # Hand-written TS mirrors of the C# DTOs
```

---

## Wireframes

Wireframes use the same vocabulary across pages — a top bar, a left side-nav, and a content area. Each CRUD page is a header + table + form drawer (right side, slides in).

### 1. Login — `/login`

```
+--------------------------------------------------------------+
|                                                              |
|                     POS  ADMIN  CONSOLE                      |
|                                                              |
|              +--------------------------------+              |
|              |  Sign in to your restaurant    |              |
|              |                                |              |
|              |  Email                         |              |
|              |  [ admin@restaurant.com     ]  |              |
|              |                                |              |
|              |  Password                      |              |
|              |  [ ********                 ]  |              |
|              |                                |              |
|              |  [  Sign in  ]                 |              |
|              |                                |              |
|              |  ----------- or -------------  |              |
|              |  New here?  Create a restaurant|              |
|              +--------------------------------+              |
|                                                              |
+--------------------------------------------------------------+
```
On success: store JWT + user via `authStore.login()`, navigate to `/`.
Backend: `POST /api/auth/login`.

### 2. Signup — `/signup` (public)

```
+--------------------------------------------------------------+
|              Create your restaurant on POS Admin             |
|                                                              |
|  Restaurant                                                  |
|    Name      [ Sunset Bistro                              ]  |
|    Slug      [ sunset-bistro          ]  (URL-safe, ≤40)     |
|    Email     [ hello@sunsetbistro.com                     ]  |
|    Phone     [ +64 9 555 0100        ]  (optional)           |
|                                                              |
|  Admin user                                                  |
|    Full name [ Jane Doe                                   ]  |
|    Email     [ jane@sunsetbistro.com                      ]  |
|    Password  [ ******** ]  (min 8 chars)                     |
|                                                              |
|              [ Create restaurant & sign in ]                 |
|                                                              |
|              Already have an account?  Sign in               |
+--------------------------------------------------------------+
```
Backend: `POST /api/tenants/signup` returns a `LoginResponse` (JWT) directly — auto-login on success.

### 3. App shell (every authenticated page)

```
+----------------------------------------------------------------------+
|  POS Admin · Sunset Bistro                  Jane Doe (Admin)  [⌄]    |  ← TopBar
+--------------+-------------------------------------------------------+
|              |                                                       |
|  📊 Dashboard|                                                       |
|  📦 Products |                                                       |
|  🏷  Categories                  CONTENT AREA                        |
|  🏬 Stores   |          (page wireframes below)                      |
|  🧾 Orders   |                                                       |
|  🖨  Printers|                                                       |
|  👥 Users    |                                                       |
|  ⚙  Settings |                                                       |
|              |                                                       |
+--------------+-------------------------------------------------------+
```
- TopBar user menu: "View profile", "Sign out".
- SideNav uses Fluent UI `NavDrawer`. Items hidden via `<RoleGate>`: Users + Settings are Admin-only.

### 4. Dashboard — `/`

```
+---------------------- Dashboard ----------------------+
|                                                       |
|  +-------------+  +-------------+  +-------------+    |
|  | Orders today|  | Revenue today|  | Active staff|   |
|  |     42      |  |   $1,284.50 |  |      7      |    |
|  +-------------+  +-------------+  +-------------+    |
|                                                       |
|  Recent orders                            [View all]  |
|  ----------------------------------------------------- |
|  # ORD-1042  | Main St   | Paid   | $34.50 | 11:02am  |
|  # ORD-1041  | Main St   | Open   | $12.00 | 10:58am  |
|  # ORD-1040  | Airport   | Paid   | $54.20 | 10:51am  |
|  ...                                                  |
+-------------------------------------------------------+
```
Stats are computed client-side from `GET /api/orders` (filter by today's date). No new endpoints needed.

### 5. Products — `/products`

```
+---------------------- Products ----------------------+
|  [ 🔍 Search name/SKU/barcode      ]   [ + New product ]
|  Category filter: [ All ▾ ]   Active only: [✓]        |
|                                                       |
|  | Name         | Category | SKU     | Price | Active |
|  |--------------|----------|---------|-------|--------|
|  | Flat White   | Coffee   | COF-001 | $5.50 |   ✓    |
|  | Cappuccino   | Coffee   | COF-002 | $5.50 |   ✓    |
|  | Croissant    | Bakery   | BAK-014 | $4.20 |   ✓    |
|  | Iced Latte   | Coffee   | COF-018 | $6.00 |   ✗    |
|  | ...                                              ✎🗑|
+-------------------------------------------------------+

  Row click → opens edit drawer (right side):
  +-----------------------------+
  |  Edit product       [ X ]   |
  |-----------------------------|
  |  Category   [ Coffee   ▾ ]  |
  |  Name       [ Flat White  ] |
  |  Description[ ........... ] |
  |  SKU        [ COF-001     ] |
  |  Barcode    [ 9421000123  ] |
  |  Price      [ 5.50        ] |
  |  Cost price [ 1.80        ] |
  |  Image URL  [ https://... ] |
  |  Active     [●─────] On     |
  |                             |
  |  [ Cancel ]   [ Save ]      |
  +-----------------------------+
```
Backend: `GET /api/products`, `GET /api/categories` (for the dropdown), `POST/PUT/DELETE /api/products/{id}`.

### 6. Categories — `/categories`

```
+--------------------- Categories ---------------------+
|                                  [ + New category ]   |
|  | Display order | Name      | Active | Created      |
|  |---------------|-----------|--------|--------------|
|  |       1       | Coffee    |   ✓    | 2026-01-04   |
|  |       2       | Tea       |   ✓    | 2026-01-04   |
|  |       3       | Bakery    |   ✓    | 2026-01-04   |
|  |       4       | Specials  |   ✗    | 2026-02-19   |
|  |                                                ✎🗑|
+-------------------------------------------------------+
```
Drawer fields: Name, Display order (number), Active (switch).

### 7. Stores — `/stores`

```
+----------------------- Stores -----------------------+
|                                     [ + New store ]   |
|  | Name        | Address              | Phone | Active|
|  |-------------|----------------------|-------|-------|
|  | Main St     | 12 Main St, Akl      | 555-1 |   ✓   |
|  | Airport     | T2 Departures Hall   | 555-2 |   ✓   |
|  | Warehouse   | Unit 4, Penrose      |   —   |   ✗   |
|  |                                              ✎     |
+-------------------------------------------------------+
```
Drawer fields: Name, Address, Phone, Active. No delete (API has no `DELETE /api/stores/{id}`).

### 8. Orders — `/orders`

```
+----------------------- Orders -----------------------+
|  Store: [ All ▾ ]  Status: [ All ▾ ]  Date: [Today ▾] |
|                                                       |
|  | #         | Store    | Status | Payment | Total  | When   |
|  |-----------|----------|--------|---------|--------|--------|
|  | ORD-1042  | Main St  | Open   | Unpaid  | $34.50 | 11:02  |
|  | ORD-1041  | Main St  | Paid   | Paid    | $12.00 | 10:58  |
|  | ORD-1040  | Airport  | Paid   | Paid    | $54.20 | 10:51  |
|                                                       |
+-------------------------------------------------------+

  Row click → Order detail dialog:
  +-------------------------------------------------+
  | Order ORD-1042                Status: [ Open ▾] |
  |-------------------------------------------------|
  | Store: Main St      Created: 2026-05-15 11:02   |
  | By: Jane Doe                                    |
  |                                                 |
  | Lines                                           |
  |  Flat White       1 × $5.50            $5.50    |
  |  Cappuccino       2 × $5.50           $11.00    |
  |  Croissant        4 × $4.20           $16.80    |
  |  Discount                              -$0.00   |
  |  Tax (15%)                              $4.55   |
  |  --------------------------------------------   |
  |  Total                                 $34.85   |
  |                                                 |
  | Payments                       [ + Record ]     |
  |  Cash      $20.00     —            11:03        |
  |  EFTPOS    $14.85     ref:90021    11:04        |
  |                                                 |
  | [ Close ]                                       |
  +-------------------------------------------------+
```
- Status dropdown options: `Open`, `Paid`, `Cancelled`, `Refunded` (whatever the API accepts via `PUT /api/orders/{id}/status`).
- "+ Record" opens a small payment form: Method, Amount, Reference → `POST /api/orders/{id}/payments`.

### 9. Printers — `/printers`

```
+---------------------- Printers ----------------------+
|  Store: [ Main St ▾ ]                [ + New printer]|
|                                                       |
|  | Name          | Type     | IP            | Port  | Active|
|  |---------------|----------|---------------|-------|-------|
|  | Front counter | Receipt  | 192.168.1.50  | 9100  |   ✓   |
|  | Kitchen       | Kitchen  | 192.168.1.51  | 9100  |   ✓   |
|  |                                                ✎🗑|
+-------------------------------------------------------+
```
Drawer fields: Store (locked to the filter), Name, IP, Port, Printer type (select: `Receipt`, `Kitchen`, `Label`), Active.

### 10. Users — `/users` (Admin-only)

```
+------------------------ Users ------------------------+
|                                       [ + New user ]  |
|  | Full name      | Email                | Role     | Active|
|  |----------------|----------------------|----------|-------|
|  | Jane Doe       | jane@sunsetbistro.com| Admin    |   ✓   |
|  | Sam Singh      | sam@sunsetbistro.com | Manager  |   ✓   |
|  | Ana Brown      | ana@sunsetbistro.com | Cashier  |   ✓   |
|  | Old Account    | old@sunsetbistro.com | Cashier  |   ✗   |
|  |                                                ✎🗑|
+-------------------------------------------------------+
```
Create drawer requires password (≥8); edit drawer omits password (API has no password change endpoint in `UserUpdateRequest`).

### 11. Tenant Settings — `/settings` (Admin-only)

```
+--------------------- Tenant Settings ----------------+
|                                                       |
|  Restaurant name   [ Sunset Bistro                 ]  |
|  Contact email     [ hello@sunsetbistro.com        ]  |
|  Phone             [ +64 9 555 0100                ]  |
|                                                       |
|  Slug              sunset-bistro          (read-only) |
|  Status            Active                 (read-only) |
|  Created           2026-01-04             (read-only) |
|                                                       |
|                                       [ Save ]        |
+-------------------------------------------------------+
```
Backend: `GET /api/tenants/me`, `PUT /api/tenants/me`. Slug is immutable per the DTO.

---

## Auth & API integration

- **Storage**: `authStore` persists `{ token, user }` to `localStorage` via `zustand/middleware/persist`. On page load the store rehydrates so a refresh keeps the user signed in.
- **Axios interceptor** in [api/client.ts](Pos.Admin.Web/src/api/client.ts):
  - Request: inject `Authorization: Bearer ${authStore.getState().token}` if present.
  - Response: on 401, call `authStore.logout()` and `window.location.href = "/login"`.
- **Vite proxy** (`vite.config.ts`): forward `/api` → `http://localhost:5202` in dev so the browser sees same-origin requests (sidesteps CORS friction even though the API already allows `:5173`).
- **Role-based UI gating**:
  - `<ProtectedRoute>` wraps every authenticated route.
  - `<RoleGate roles={['Admin']}>` hides Users + Settings nav entries from Manager/Cashier.
  - Buttons that hit Admin-only endpoints are also gated; if a Manager somehow calls one the 403 path shows a toast.
- **Tenant context** is implicit — the JWT carries `restaurant_id` and the API applies query filters, so the frontend never sends a tenant id.

---

## Build phases

1. **Scaffold** (~30 min)
   - `npm create vite@latest Pos.Admin.Web -- --template react-ts`
   - Install: `@fluentui/react-components @fluentui/react-icons react-router-dom @tanstack/react-query zustand axios react-hook-form zod @hookform/resolvers`
   - Set up `vite.config.ts` proxy, `.env.development`, `FluentProvider` in `main.tsx`, `QueryClientProvider`, base router.

2. **Auth shell** (~1 hr)
   - `authStore`, `api/client.ts`, `api/auth.ts`, `Login.tsx`, `Signup.tsx`, `ProtectedRoute.tsx`, `AppShell.tsx` (empty content area + working logout).
   - Acceptance: signup → land on empty dashboard; refresh keeps you signed in; logout returns to /login.

3. **Shared components** (~1 hr)
   - `DataTable`, `FormDrawer`, `ConfirmDialog`, `Field*` wrappers, `useToastController` plumbing.

4. **Resource pages, one per slice** (~30–60 min each)
   - Order: Categories → Products → Stores → Printers → Users → Tenant Settings → Orders (most complex, leave last).
   - Each slice = `api/<resource>.ts` + page + form drawer + react-query hooks + invalidation on mutate.

5. **Dashboard** (~30 min) — derives stats from cached `orders` data; no new endpoints.

6. **Polish** (~1 hr) — empty states, loading skeletons, error boundary, favicon, page titles.

Rough total: ~7–9 hours of focused work.

---

## Critical files to create

| Path | Purpose |
|---|---|
| [Pos.Admin.Web/vite.config.ts](Pos.Admin.Web/vite.config.ts) | Dev server proxy `/api` → `:5202` |
| [Pos.Admin.Web/src/main.tsx](Pos.Admin.Web/src/main.tsx) | FluentProvider + QueryClient + Router roots |
| [Pos.Admin.Web/src/api/client.ts](Pos.Admin.Web/src/api/client.ts) | Axios + 401 logout interceptor |
| [Pos.Admin.Web/src/auth/authStore.ts](Pos.Admin.Web/src/auth/authStore.ts) | Zustand store with `persist` |
| [Pos.Admin.Web/src/auth/ProtectedRoute.tsx](Pos.Admin.Web/src/auth/ProtectedRoute.tsx) | Route guard |
| [Pos.Admin.Web/src/layout/AppShell.tsx](Pos.Admin.Web/src/layout/AppShell.tsx) | NavDrawer + TopBar + Outlet |
| [Pos.Admin.Web/src/components/DataTable.tsx](Pos.Admin.Web/src/components/DataTable.tsx) | Fluent DataGrid wrapper |
| [Pos.Admin.Web/src/components/FormDrawer.tsx](Pos.Admin.Web/src/components/FormDrawer.tsx) | Reusable side drawer for create/edit |
| [Pos.Admin.Web/src/types/api.ts](Pos.Admin.Web/src/types/api.ts) | TS mirrors of [Pos.Api/DTOs/](Pos.Api/DTOs/) |

The API side is **not** modified. CORS already allows `http://localhost:5173`, so no backend changes are required.

---

## Reusable backend artefacts referenced

- DTO shapes for hand-written TS types come straight from [Pos.Api/DTOs/](Pos.Api/DTOs/) — `LoginRequest/Response`, `TenantSignupRequest`, `UserCreateRequest`, etc.
- Roles list at [Pos.Api/Helpers/Roles.cs](Pos.Api/Helpers/Roles.cs) — drives the role dropdown and `<RoleGate>` checks (`Admin`, `Manager`, `Cashier`).
- Swagger at `http://localhost:5202/swagger/index.html` — useful for ad-hoc verification while wiring each page.

---

## Verification

End-to-end happy path, run after each phase finishes:

1. Start API: `dotnet run --project Pos.Api` → confirm `http://localhost:5202/swagger` loads.
2. Start admin web: `npm run dev` in `Pos.Admin.Web/` → opens `http://localhost:5173`.
3. **Signup**: create a fresh tenant via `/signup`, confirm redirect to dashboard, confirm `localStorage` has the JWT.
4. **Refresh test**: hard-refresh — should stay signed in.
5. **CRUD smoke** (per resource, each phase): create one record, edit it, deactivate it, delete it where allowed. Confirm Fluent toast on each mutation, confirm table refetches automatically.
6. **Auth gates**:
   - Create a Cashier user via Users page; sign out; sign in as Cashier; verify Users and Settings nav entries are hidden and that `/users` direct-nav redirects or shows an empty state on 403.
   - Sign back in as Admin; confirm full access.
7. **Order detail**: open an existing order, change status, record a partial payment, confirm payment list updates and the order's `PaymentStatus` reflects the new total.
8. **Tenant isolation sanity**: sign up a second tenant in a private window — confirm zero data crossover (no shared products/users/orders).

If any of step 6–8 fails the issue is almost certainly in the JWT/role plumbing, not the API.
