Create an ASP.NET Core Web API backend for a simple multi-tenant (multi-restaurant) POS system.

Tech stack:
- ASP.NET Core Web API
- .NET 8 or latest stable .NET
- Entity Framework Core
- SQL Server
- JWT authentication
- Swagger/OpenAPI enabled
- Clean layered structure

Project name:
Pos.Api

Architecture:
Use a simple clean architecture style with these folders:

/Controllers
/Data
/Entities
/DTOs
/Services
/Repositories
/Mapping
/Middleware
/Helpers
/Tenancy

Core requirements:
The API will be used by:
1. Flutter Android/iOS POS app
2. Admin web app

Multi-tenancy model:
- Each Restaurant is an isolated tenant (SaaS multi-tenant).
- A Restaurant has many Stores (physical locations).
- Catalog (Categories and Products) is per-restaurant.
- Each User belongs to exactly one Restaurant.
- Tenancy strategy: shared database, shared schema, row-level isolation via RestaurantId + EF Core global query filters.

Create the following database entities:

1. Restaurant (tenant root)
- Id: Guid
- Name: string (required)
- Slug: string (required, unique, must match ^[a-z0-9-]{3,40}$, reserved denylist: admin, api, me, signup, auth)
- ContactEmail: string (required)
- Phone: string?
- IsActive: bool
- CreatedAt: DateTime

2. User
- Id: Guid
- RestaurantId: Guid (required, FK to Restaurant, indexed)
- FullName: string
- Email: string
- PasswordHash: string
- Role: string
- IsActive: bool
- CreatedAt: DateTime
- Email uniqueness is per-tenant: unique on (RestaurantId, Email), not globally.

3. Store
- Id: Guid
- RestaurantId: Guid (required, FK to Restaurant, indexed)
- Name: string
- Address: string?
- Phone: string?
- IsActive: bool
- CreatedAt: DateTime

4. Category
- Id: Guid
- RestaurantId: Guid (required, FK to Restaurant, indexed)
- Name: string
- DisplayOrder: int
- IsActive: bool
- CreatedAt: DateTime

5. Product
- Id: Guid
- RestaurantId: Guid (required, FK to Restaurant, indexed)
- CategoryId: Guid
- Name: string
- Description: string?
- Sku: string?
- Barcode: string?
- Price: decimal
- CostPrice: decimal?
- ImageUrl: string?
- IsActive: bool
- CreatedAt: DateTime
- Service-layer invariant: Product.RestaurantId must equal Product.Category.RestaurantId. Enforce on create and update.

6. Order
- Id: Guid
- RestaurantId: Guid (required, FK to Restaurant, indexed)
- StoreId: Guid
- OrderNumber: string
- Status: string
- Subtotal: decimal
- TaxAmount: decimal
- DiscountAmount: decimal
- TotalAmount: decimal
- PaymentStatus: string
- CreatedByUserId: Guid
- CreatedAt: DateTime
- OrderNumber uniqueness is per-tenant: unique on (RestaurantId, OrderNumber).

7. OrderLine
- Id: Guid
- RestaurantId: Guid (required, denormalized from Order, indexed)
- OrderId: Guid
- ProductId: Guid
- ProductName: string
- Quantity: decimal
- UnitPrice: decimal
- DiscountAmount: decimal
- LineTotal: decimal

8. Payment
- Id: Guid
- RestaurantId: Guid (required, denormalized from Order, indexed)
- OrderId: Guid
- PaymentMethod: string
- Amount: decimal
- Reference: string?
- PaidAt: DateTime

9. Printer
- Id: Guid
- RestaurantId: Guid (required, FK to Restaurant, indexed)
- StoreId: Guid
- Name: string
- IpAddress: string
- Port: int
- PrinterType: string
- IsActive: bool
- CreatedAt: DateTime

Entity relationships:
- Restaurant has many Users
- Restaurant has many Stores
- Restaurant has many Categories
- Restaurant has many Products
- Restaurant has many Orders (and through them, OrderLines and Payments)
- Restaurant has many Printers
- Category has many Products
- Store has many Orders
- Store has many Printers
- Order has many OrderLines
- Order has many Payments
- Product has many OrderLines
- User has many Orders

Use DbContext:
Create PosDbContext with DbSet properties for all entities.
Configure decimal precision for prices and totals.
Configure required fields and relationships in OnModelCreating.
Configure unique indexes:
- Restaurant.Slug unique
- User unique on (RestaurantId, Email)
- Order unique on (RestaurantId, OrderNumber)

Tenant isolation:
Create a /Tenancy folder containing the tenant-isolation primitives.

- ITenantContext (scoped lifetime):
  - Exposes CurrentRestaurantId (Guid?) read from the restaurant_id JWT claim of the current request.
  - Resolved via a middleware that runs after JWT validation.
  - Must be scoped, not singleton, so its lifetime matches DbContext.
  - Tenant value must be immutable per request once set.

- EF Core global query filters:
  - Apply HasQueryFilter(e => e.RestaurantId == _tenant.CurrentRestaurantId) in OnModelCreating to every tenant-bound entity:
    User, Store, Category, Product, Order, OrderLine, Payment, Printer.
  - The Restaurant entity itself is not filtered (it is the tenant root).

- Explicit allowlist of callers that bypass the filter via IgnoreQueryFilters():
  1. Login: find user by Email before tenant is known.
  2. Tenant signup: no tenant exists yet.
  3. (Future) admin diagnostics, if ever added.
  No ad-hoc IgnoreQueryFilters() calls outside this list.

- Cross-tenant validation in services (defense in depth beyond the filter):
  - When creating an Order: verify StoreId belongs to current tenant.
  - When creating a Product: verify CategoryId belongs to current tenant.
  - When creating a Printer: verify StoreId belongs to current tenant.
  - When creating a Payment on an Order: verify the Order belongs to current tenant.

- HasData seeding bypasses query filters. This is intentional and not a leak.

Authentication:
Implement JWT authentication.

Create endpoints:
POST /api/tenants/signup
POST /api/auth/login

POST /api/tenants/signup (public, optionally gated by X-Signup-Key header from config):
Request:
- Restaurant: Name, Slug, ContactEmail, Phone?
- Admin user: FullName, Email, Password
Behavior:
- Validate Slug regex and denylist; verify Slug is unique.
- Validate ContactEmail is a valid email.
- Create Restaurant and the first Admin user atomically in one transaction.
- Bypass tenant query filter (no tenant exists yet).
- Return the new Restaurant info and a Token for the admin user (same shape as login response).

POST /api/auth/login (public):
Login request:
- Email
- Password
Behavior:
- Bypass the tenant query filter (look up user by Email globally), then derive tenant from the loaded user.
- Reject login if User.IsActive == false OR Restaurant.IsActive == false.
Login response:
- Token
- UserId
- FullName
- Email
- Role
- RestaurantId
- RestaurantName
- RestaurantSlug

JWT claims must include:
- sub (UserId)
- restaurant_id (RestaurantId)
- role
- email

Use password hashing. Do not store plain text passwords.

The original open POST /api/auth/register endpoint is removed. Creating additional users inside a tenant is done by an Admin via POST /api/users (see UsersController).

Authorization:
Roles (all scoped within a single Restaurant; there is no SystemAdmin role in v1):
- Admin
- Manager
- Cashier

All authorized endpoints are implicitly scoped to the caller's Restaurant via the tenant filter.

- Admin: everything within their Restaurant, including user management, store config, and printer config.
- Manager: products, categories, orders, payments, stores (read), printers (read).
- Cashier:
  - view products and categories
  - create orders
  - create payments
  - view printer settings

Controllers to create:

1. TenantsController
- POST /api/tenants/signup        (public)
- GET  /api/tenants/me            (any authenticated role)
- PUT  /api/tenants/me            (Admin)

2. AuthController
- POST /api/auth/login

3. UsersController (Admin only; all actions scoped to caller's Restaurant)
- GET    /api/users
- POST   /api/users                (creates Manager or Cashier within caller's tenant)
- PUT    /api/users/{id}
- DELETE /api/users/{id}           (soft-delete via IsActive)

4. ProductsController
- GET    /api/products
- GET    /api/products/{id}
- GET    /api/products/barcode/{barcode}
- POST   /api/products
- PUT    /api/products/{id}
- DELETE /api/products/{id}

5. CategoriesController
- GET    /api/categories
- GET    /api/categories/{id}
- POST   /api/categories
- PUT    /api/categories/{id}
- DELETE /api/categories/{id}

6. OrdersController
- GET /api/orders
- GET /api/orders/{id}
- POST /api/orders
- PUT /api/orders/{id}/status

POST /api/orders should accept:
- StoreId
- DiscountAmount
- TaxAmount
- PaymentMethod
- PaymentReference
- List of order lines:
  - ProductId
  - Quantity
  - UnitPrice
  - DiscountAmount

CreatedByUserId is NOT accepted from the request body. It is derived from the JWT sub claim. Accepting it from the body in a multi-tenant system is a user-spoofing vector.

When creating an order:
- Generate an OrderNumber automatically (unique per tenant).
- Verify StoreId belongs to caller's Restaurant.
- Calculate line totals.
- Calculate subtotal.
- Calculate total.
- Stamp RestaurantId on Order, every OrderLine, and the Payment (if any).
- Save Order.
- Save OrderLines.
- Save Payment if payment method and amount are provided.
- Return full order details.

7. PaymentsController
- GET  /api/orders/{orderId}/payments
- POST /api/orders/{orderId}/payments
Before creating a payment, verify the Order belongs to caller's Restaurant.

8. StoresController
- GET  /api/stores
- GET  /api/stores/{id}
- POST /api/stores
- PUT  /api/stores/{id}

9. PrintersController
- GET    /api/stores/{storeId}/printers
- GET    /api/printers/{id}
- POST   /api/printers
- PUT    /api/printers/{id}
- DELETE /api/printers/{id}

All controllers above (except TenantsController.signup and AuthController.login) require authentication. Every read/write is implicitly scoped to caller's Restaurant via the global query filter; do not add manual RestaurantId == ... checks in queries unless explicitly bypassing the filter.

DTOs:
Create request and response DTOs. Do not expose entity classes directly from controllers.

Use service classes:
- TenantService
- UserService
- AuthService
- ProductService
- CategoryService
- OrderService
- PaymentService
- StoreService
- PrinterService

Use repository classes if helpful, but keep the code simple and understandable.

Validation:
Add basic validation:
- Tenant signup: Slug matches ^[a-z0-9-]{3,40}$, is not in the reserved denylist, and is unique.
- Tenant signup: ContactEmail is a valid email.
- User: Email unique within Restaurant.
- Product name required
- Product price must be >= 0
- Category name required
- Order must have at least one order line
- Quantity must be > 0
- Order: StoreId must belong to caller's Restaurant.
- Product: CategoryId must belong to caller's Restaurant.
- Printer: StoreId must belong to caller's Restaurant.
- Store name required
- Printer IP address required
- Printer port required

Error handling:
Add global exception middleware.
Return consistent error responses:
{
  "message": "Error message",
  "details": "Optional details"
}

Configuration:
Use appsettings.json for:
- ConnectionStrings:DefaultConnection
- Jwt:Key
- Jwt:Issuer
- Jwt:Audience
- Jwt:ExpiresInMinutes
- Tenancy:SignupKey

Tenancy:SignupKey is an optional shared secret for the signup endpoint.
- If empty: tenant signup is fully open (POC default).
- If set: POST /api/tenants/signup requires header X-Signup-Key with this value.
This is POC-only; production should replace this with a proper invite/onboarding flow.

Enable:
- Swagger
- CORS
- JWT bearer authentication
- EF Core migrations

CORS:
Allow local development origins:
- http://localhost:3000
- http://localhost:5173
- http://localhost:5000
- http://localhost:5001

Also allow Flutter mobile app access during development.

Note: CORS is configured for localhost origins only in v1. If a future version adopts subdomain-per-tenant routing (e.g. acme.pos.local), switch to a regex origin policy.

Swagger:
- Make the JWT decode visible in Swagger so developers can confirm the restaurant_id claim is present in their token.
- Add example requests for POST /api/tenants/signup and POST /api/auth/login (log in as the demo admin).

Seed data:
Create seed data for:
- One demo Restaurant
- One admin user belonging to that Restaurant
- One default store under that Restaurant
- Several categories under that Restaurant
- Several sample products under that Restaurant
- One sample printer under that Restaurant's default store

Sample restaurant:
Name: Demo Restaurant Co.
Slug: demo
ContactEmail: admin@pos.local
IsActive: true

Sample admin user:
Email: admin@pos.local
Password: Admin123!
Role: Admin
RestaurantId: demo restaurant

Sample categories (all under demo restaurant):
- Drinks
- Food
- Snacks

Sample products (all under demo restaurant, linked to the categories above):
- Coffee, price 4.50
- Tea, price 3.50
- Sandwich, price 8.90
- Muffin, price 4.00

Sample printer (under demo restaurant's default store):
Name: Front Counter Printer
IP: 192.168.1.50
Port: 9100
PrinterType: ESC/POS

Important:
- Multi-tenant isolation is enforced at the data layer; every persisted tenant-bound entity must carry RestaurantId.
- Do not implement a SystemAdmin role, billing, subscriptions, cross-tenant reporting, or subdomain-per-tenant routing yet.
- Do not implement schema-per-tenant or database-per-tenant isolation yet.
- Make the API easy to test from Swagger.
- Add comments where useful.
- Keep the first version simple and working.
- Do not implement advanced inventory, refunds, loyalty, email verification, password reset, MFA, or offline sync yet.
- Focus on tenant signup, product management, order creation, payments, login, and printer configuration.

Please generate:
1. Full project structure
2. Entity classes (including Restaurant and RestaurantId on every tenant-bound entity)
3. DTO classes (including TenantSignupRequest, TenantResponse, UserCreateRequest)
4. DbContext (with global query filters and unique indexes described above)
5. Services (including TenantService and UserService)
6. Controllers (including TenantsController and UsersController; no AuthController.register)
7. JWT setup (with restaurant_id claim)
8. Tenant isolation primitives in /Tenancy (ITenantContext, middleware)
9. Program.cs configuration (registers ITenantContext as scoped; wires the tenancy middleware after authentication)
10. appsettings.json example (including Tenancy:SignupKey)
11. EF Core migration instructions
12. Example API requests for testing in Swagger or Postman, including:
    - POST /api/tenants/signup (create a second tenant)
    - POST /api/auth/login (as demo admin and as the new tenant's admin)
    - GET /api/products as each tenant, demonstrating that the results are disjoint
