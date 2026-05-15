# POS Multi-Tenant POC

Two projects under one solution:

| Project | What it is | Run on |
|---|---|---|
| [Pos.Api](Pos.Api/) | ASP.NET Core Web API + EF Core + SQL Server + JWT. Multi-tenant POS backend. | `:5202` |
| [Pos.Admin.Web](Pos.Admin.Web/) | React + Vite + Fluent UI v9 admin console for tenant staff. Wireframes and design in [Pos.Admin.Web/PLAN.md](Pos.Admin.Web/PLAN.md). | `:5173` |

Each tenant is a `Restaurant`. A Restaurant has many `Stores` (physical locations). Catalog (Categories, Products) and Users are scoped per restaurant. Tenant isolation is enforced at the data layer via EF Core global query filters on a `RestaurantId` column carried on every tenant-bound entity.

See [instruction.md](instruction.md) for the original backend spec.

---

## Running the full stack

Open **two terminals** from the repo root.

```powershell
# Terminal 1 — API on :5202
cd Pos.Api
dotnet run

# Terminal 2 — Admin web on :5173
cd Pos.Admin.Web
npm install   # first time only
npm run dev
```

Open <http://localhost:5173>. Sign in with the seeded demo admin (`admin@pos.local` / `Admin123!`) or click *Create a restaurant* to sign up a fresh tenant. Detailed admin-web setup is in [Pos.Admin.Web/README.md](Pos.Admin.Web/README.md); API-only setup continues below.

---

# Pos.Api

---

## Prerequisites

- .NET SDK 10.0 (or .NET 9 — adjust `TargetFramework` in `Pos.Api/Pos.Api.csproj`)
- SQL Server (LocalDB is fine — that's the default connection string)
- `dotnet-ef` global tool: `dotnet tool install --global dotnet-ef`

## First-time setup

1. Clone the repo and `cd` into it.
2. Update `Pos.Api/appsettings.json`:
   - Replace `Jwt:Key` with a long random string (32+ chars).
   - Adjust `ConnectionStrings:DefaultConnection` if you're not using LocalDB.
   - Set `Tenancy:SignupKey` to a non-empty value if you want to require an `X-Signup-Key` header for tenant signup. Leave empty for open signup (POC default).
3. From the repo root:

```powershell
cd Pos.Api
dotnet restore
dotnet build
```

## Run

```powershell
cd Pos.Api
dotnet run
```

On startup the app applies pending EF Core migrations and idempotently seeds a demo tenant. Swagger UI opens at `/swagger`.

### Demo credentials

| Field | Value |
| --- | --- |
| Restaurant | Demo Restaurant Co. (slug `demo`) |
| Email | `admin@pos.local` |
| Password | `Admin123!` |
| Role | Admin |

---

## EF Core migrations

The app calls `db.Database.Migrate()` on startup, so you usually don't need to run anything manually.

Add a new migration after editing entities:

```powershell
cd Pos.Api
dotnet ef migrations add <Name> --output-dir Data/Migrations
```

Apply migrations manually (without running the app):

```powershell
cd Pos.Api
dotnet ef database update
```

Drop and recreate the database (destructive — local dev only):

```powershell
cd Pos.Api
dotnet ef database drop --force
dotnet ef database update
```

---

## API quick reference

All endpoints are under `/api`. Everything except `POST /api/tenants/signup` and `POST /api/auth/login` requires `Authorization: Bearer <token>`.

| Method | Path | Roles |
| --- | --- | --- |
| POST | `/api/tenants/signup` | (public) |
| GET | `/api/tenants/me` | Admin/Manager/Cashier |
| PUT | `/api/tenants/me` | Admin |
| POST | `/api/auth/login` | (public) |
| GET/POST/PUT/DELETE | `/api/users` | Admin |
| GET | `/api/categories`, `/api/products`, `/api/stores`, `/api/orders`, `/api/orders/{id}/payments`, `/api/stores/{storeId}/printers`, `/api/printers/{id}` | any authenticated |
| POST/PUT/DELETE | `/api/categories`, `/api/products`, `/api/printers` | Admin/Manager |
| POST | `/api/orders`, `/api/orders/{id}/payments` | any authenticated |
| POST/PUT | `/api/stores` | Admin |

`POST /api/orders` derives `CreatedByUserId` from the JWT — do not pass it in the body.

---

## Sample requests

### 1. Log in as the demo admin

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@pos.local",
  "password": "Admin123!"
}
```

Response includes `token`, `restaurantId`, `restaurantName`, `restaurantSlug`. Click **Authorize** in Swagger and paste the token.

### 2. Sign up a second tenant

```http
POST /api/tenants/signup
Content-Type: application/json

{
  "restaurant": {
    "name": "Acme Cafe",
    "slug": "acme",
    "contactEmail": "owner@acme.test",
    "phone": null
  },
  "admin": {
    "fullName": "Acme Owner",
    "email": "owner@acme.test",
    "password": "Acme1234!"
  }
}
```

Returns a token for the new admin. Log in as this admin and `GET /api/products` — you'll see an empty list, while the demo admin sees four products. That's the tenant filter at work.

### 3. Create an order

```http
POST /api/orders
Authorization: Bearer <demo admin token>
Content-Type: application/json

{
  "storeId": "<paste storeId from GET /api/stores>",
  "discountAmount": 0,
  "taxAmount": 0,
  "paymentMethod": "Cash",
  "paymentReference": null,
  "paymentAmount": 12.40,
  "lines": [
    {
      "productId": "<paste productId from GET /api/products (Coffee)>",
      "quantity": 1,
      "unitPrice": 4.50,
      "discountAmount": 0
    },
    {
      "productId": "<paste productId from GET /api/products (Sandwich)>",
      "quantity": 1,
      "unitPrice": 8.90,
      "discountAmount": 1.00
    }
  ]
}
```

`OrderNumber` is generated automatically (per-tenant). Payment is recorded inline because `paymentMethod` and `paymentAmount` are present.

### 4. Verify the JWT carries `restaurant_id`

Decode the token at [jwt.io](https://jwt.io). The payload includes:
- `sub` — UserId
- `restaurant_id` — RestaurantId
- `role`, `email`

Swagger is configured to display the bearer token in the Authorize dialog so you can copy it out.

---

## Tenant isolation: what to look for

- `Restaurant.Slug` must match `^[a-z0-9-]{3,40}$` and isn't in the reserved denylist (`admin`, `api`, `me`, `signup`, `auth`).
- Login bypasses the tenant filter (the user doesn't know their tenant yet); after login, every other read/write is filtered to the caller's `RestaurantId`.
- Cross-tenant writes are rejected by service-layer guards (e.g. `POST /api/products` rejects a `categoryId` that doesn't belong to the caller's restaurant).
- Restaurants disabled via `IsActive=false` cannot issue tokens — login is rejected.

---

## Project layout

```
Pos.Api/
  Controllers/      MVC controllers
  Data/             PosDbContext, SeedData, Migrations
  DTOs/             Request and response records
  Entities/         9 EF Core entities
  Helpers/          Roles, AppException, SlugRules
  Middleware/       ExceptionHandlingMiddleware
  Services/         Domain services (Auth, Tenant, User, Product, ...)
  Tenancy/          ITenantContext + middleware that reads the JWT claim
  appsettings.json  Connection string, JWT settings, Tenancy:SignupKey
  Program.cs        DI wiring, auth, Swagger, CORS, pipeline
```

---

## What v1 does NOT include

By design, scoped to keep the POC tight:

- No SystemAdmin role, no cross-tenant admin endpoints
- No billing / subscriptions / usage metering
- No subdomain-per-tenant routing (`acme.pos.local`) — single host, JWT claim drives tenancy
- No schema-per-tenant or database-per-tenant isolation
- No password reset, email verification, or MFA
- No background jobs (tenant context is request-scoped only)
- No inventory tracking, refunds, loyalty, or offline sync
