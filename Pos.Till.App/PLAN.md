# Flutter Android POS Till — `Pos.Till.App`

## Context

The repo already has the backend ([Pos.Api](Pos.Api/)) and the admin console ([Pos.Admin.Web](Pos.Admin.Web/)). What's missing is the **device cashier staff actually touch** — a tablet app that takes orders, fires receipt and kitchen printers, opens the cash drawer, runs the EFTPOS terminal, and mirrors the order to a customer-facing screen on a second Android device.

This plan adds a sibling Flutter project, **Pos.Till.App**, targeting Android tablets in landscape. It is an *online-only* till for v1 — the API must be reachable on the LAN.

Per the latest decision we're **skipping till-manager features** for v1: no tables, no refunds with money flow, no X/Z reports, no order voids beyond a plain status change. Those land in a later phase (some need API additions). The shipped surface is the core take-an-order workflow plus the customer-display companion.

Two cross-cutting requirements added on top of the original surface:

- **Split tender is opt-in per customer**, not a forced flow. A customer paying with a single method just taps one tile and pays in full; a customer who wants `Cash $20 + EFTPOS $17.85` taps two tiles. The payment screen treats one-row and multi-row as the same code path — "Complete sale" stays disabled until `Remaining ≤ 0`, no other gating.
- **Bilingual item names** — each product can carry an alternative localized name (typically Vietnamese for the kitchen). The cashier-facing till uses the primary name; kitchen tickets, receipts, and the customer display each have a configurable language preference (`primary`, `alt`, or `both`) so a store can print Vietnamese to the kitchen while keeping English on the customer-facing screen.

The same Flutter codebase ships **two app flavors**:
- `pos_till` (default `main.dart`) — the cashier tablet
- `pos_customer_display` (`main_customer.dart`) — the customer-facing mirror

---

## Tech stack

| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter (stable channel) + Material 3 (`useMaterial3: true`) | Required by user; Material 3 gives tablet-friendly defaults |
| Target | Android only for v1 (`flutter create --platforms android`) | iOS not requested; smaller surface, faster ship |
| State management | `riverpod` + `flutter_riverpod` v2 | Compile-safe DI, simple `StateNotifier`/`AsyncNotifier`, no codegen required |
| Routing | `go_router` | Declarative routes, easy guards for auth/role |
| HTTP | `dio` + `dio_smart_retry` (transient retries only) | Interceptors for JWT + 401 logout, multipart-ready if needed later |
| Secure storage | `flutter_secure_storage` | Per-user cached JWTs and PIN hashes; uses Android Keystore |
| Local KV (non-secret) | `shared_preferences` | Active store id, paired customer-display IP, printer ids |
| Models | `freezed` + `json_serializable` | TS-DTO-equivalent immutable types; matches the C# DTO shapes |
| ESC/POS printing | `esc_pos_utils` (commands) + raw `Socket` to `printer.IpAddress:port` | Direct TCP to network printers as configured in the API's `Printer` entity. Same socket fires the cash drawer kick. |
| Cash drawer | ESC/POS kick command (`ESC p 0 50 250`) sent to the receipt printer | The drawer is wired to the printer via RJ12; no separate connection |
| EFTPOS | `EftposProvider` Dart interface with `MockEftposProvider` implementation for v1 | Real terminal SDK is vendor-specific; stub keeps the workflow intact |
| Local server (cashier side) | `shelf` + `shelf_web_socket` | Streams cart state to the customer-display device over LAN WebSocket |
| Service discovery | `bonsoir` (mDNS) with manual-IP fallback | Customer display auto-finds the till; tap to pair |
| Logging | `logger` | Plain dev logging |
| Localization | Native `Intl` + a per-product `nameLocalized` map sourced from the API | No `intl_translation` codegen needed; UI strings stay English in v1, only product names are bilingual |

No Bluetooth, no NFC, no SignalR/server-push from the API.

---

## Project location & layout

Sibling folder: `c:\Repo\POC\POC\Pos.Till.App\`

```
Pos.Till.App/
├─ pubspec.yaml
├─ android/ ios/ ...           # Flutter scaffold (iOS dir kept disabled)
├─ lib/
│  ├─ main.dart                # Till flavor entry: runApp(TillApp())
│  ├─ main_customer.dart       # Customer-display flavor entry: runApp(CustomerDisplayApp())
│  ├─ app/
│  │  ├─ till_app.dart         # MaterialApp.router(theme: M3, routerConfig: tillRouter)
│  │  ├─ customer_app.dart     # MaterialApp.router(theme: M3, routerConfig: customerRouter)
│  │  ├─ theme.dart            # ColorScheme.fromSeed + density tweaks for tablet
│  │  └─ router.dart           # go_router config + auth guards
│  ├─ api/
│  │  ├─ api_client.dart       # Dio instance + JWT interceptor + 401 handler
│  │  ├─ auth_api.dart
│  │  ├─ products_api.dart
│  │  ├─ categories_api.dart
│  │  ├─ stores_api.dart
│  │  ├─ printers_api.dart
│  │  ├─ orders_api.dart
│  │  ├─ payments_api.dart
│  │  └─ users_api.dart
│  ├─ models/                  # freezed DTO mirrors of Pos.Api/DTOs/*.cs
│  │  ├─ login_response.dart
│  │  ├─ product.dart
│  │  ├─ category.dart
│  │  ├─ store.dart
│  │  ├─ printer.dart
│  │  ├─ user.dart
│  │  ├─ order.dart
│  │  └─ payment.dart
│  ├─ state/
│  │  ├─ device_state.dart     # device JWT, restaurant info, active store id
│  │  ├─ session_state.dart    # current cashier (user id + token), idle timer
│  │  ├─ cart_state.dart       # current OrderDraft (lines, discounts, totals)
│  │  └─ providers.dart        # Riverpod top-level providers
│  ├─ services/
│  │  ├─ secure_credentials.dart  # Per-user cached JWT + PIN hash via flutter_secure_storage
│  │  ├─ idle_logout.dart         # 5-min activity timer that pops to user picker
│  │  ├─ printer_service.dart     # Builds ESC/POS payloads + sends to TCP socket
│  │  ├─ drawer_service.dart      # Fires drawer kick via printer_service
│  │  ├─ localization_service.dart # Resolves product.name vs nameLocalized per surface (kitchen/receipt/display)
│  │  ├─ eftpos/
│  │  │  ├─ eftpos_provider.dart    # abstract interface
│  │  │  └─ mock_eftpos_provider.dart
│  │  ├─ customer_display_server.dart  # shelf_web_socket server on the till
│  │  ├─ customer_display_client.dart  # WebSocketChannel client on the display
│  │  └─ pairing_service.dart       # bonsoir advertise + discover
│  ├─ screens/
│  │  ├─ splash.dart
│  │  ├─ device_setup.dart           # First-run: admin signs in, picks store
│  │  ├─ user_picker.dart            # Cashier tiles + PIN entry
│  │  ├─ add_user.dart               # Cashier adds themselves: email/password → PIN
│  │  ├─ till_home.dart              # Main 3-pane layout
│  │  ├─ payment.dart                # Split tender modal
│  │  ├─ order_summary.dart          # Receipt preview before print/pay
│  │  ├─ settings.dart               # Printer assignment, drawer test, display pairing
│  │  └─ customer/
│  │     ├─ customer_pairing.dart    # Customer-app: discover/pair the till
│  │     └─ customer_display.dart    # Customer-app: live cart mirror
│  └─ widgets/
│     ├─ pin_pad.dart
│     ├─ product_grid.dart
│     ├─ category_chip_strip.dart
│     ├─ cart_panel.dart
│     ├─ amount_keypad.dart
│     └─ status_bar.dart
└─ test/                       # widget tests for cart math + pin_pad
```

---

## Flavors and entry points

Two top-level `main` files. Build commands:

```powershell
# Cashier till (default debug + release):
flutter run -t lib/main.dart

# Customer display:
flutter run -t lib/main_customer.dart
```

Production: build two separate APKs with `flutter build apk --target lib/main.dart` and `--target lib/main_customer.dart`. App-IDs and labels are differentiated via `--flavor` in `android/app/build.gradle` so both can be installed side-by-side during dev.

---

## Multi-user login (no API change in v1)

The API has no PIN field, so the v1 approach caches a JWT *per user* on the device and uses a local PIN as the unlock:

1. **Device setup** (one-time per tablet): An Admin or Manager signs in with email+password, picks the active store, and gets a "device" JWT cached on the device. This token's job is to seed the user list — the user picker calls `GET /api/users` with it.
2. **Add cashier to tablet**: From the user picker, a manager taps **Add cashier**, picks a user from the API's user list, and that cashier types their **password once** plus chooses a **4-digit PIN**. The app does a real `POST /api/auth/login` with their password to get a JWT, then encrypts that JWT using a key derived from the PIN and stores it via `flutter_secure_storage`. The password itself is **not** stored.
3. **Subsequent shifts**: The cashier taps their tile, types the PIN, the app decrypts their cached JWT and starts a session. Their `userId` becomes `CreatedByUserId` on all orders.
4. **Idle logout**: 5 min of no touch returns to the user picker, clearing the in-memory token. The encrypted blob stays on disk for next-PIN-entry.
5. **Token expiry**: JWTs expire (480 min default). On 401 the app drops back to the user picker; that user must re-enter their password to refresh. The device-token path handles its own re-login similarly.

The user-picker tile is shown for any user currently registered on this tablet — not the full tenant user list. To roll out across tablets, each tablet repeats the add-cashier step. This is acceptable given the small scale of a single restaurant.

> **Trade-off accepted:** This is per-tablet ceremony. The cleaner long-term answer is `PinHash` on `User` in the API — flagged as a future enhancement but **not** in v1.

---

## Wireframes

Wireframes assume a 10″ landscape tablet (~1280×800). Material 3 components throughout: `FilledButton`, `NavigationRail`, `SegmentedButton`, `BottomSheet`, `ModalBottomSheet`, `SearchBar`.

### 1. Splash — boot check

```
+--------------------------------------------------------+
|                                                        |
|                                                        |
|                   ⏳  POS TILL                         |
|                  Checking device…                      |
|                                                        |
+--------------------------------------------------------+
```
Reads device JWT + store id from storage. Routes to Device Setup if missing, else User Picker.

### 2. Device setup — first run only

```
+--------------------------------------------------------+
|  Pair this tablet                                      |
|                                                        |
|  Sign in as Admin or Manager to register this device.  |
|                                                        |
|   Email     [ manager@restaurant.com              ]    |
|   Password  [ ********                            ]    |
|                                                        |
|   Active store                                         |
|   ( ) Main St                                          |
|   (●) Airport                                          |
|   ( ) Warehouse                                        |
|                                                        |
|                        [ Pair tablet ]                 |
+--------------------------------------------------------+
```

### 3. User picker — between shifts / on app open

```
+--------------------------------------------------------+
|  Sunset Bistro · Airport                       [ ⚙ ]   |  ← top app bar
|                                                        |
|     Who's working?                                     |
|                                                        |
|   +---------+ +---------+ +---------+ +---------+      |
|   |  Jane   | |  Sam    | |  Ana    | |    +    |      |
|   |  Doe    | |  Singh  | |  Brown  | |  Add    |      |
|   | (Admin) | |(Manager)| |(Cashier)| | cashier |      |
|   +---------+ +---------+ +---------+ +---------+      |
|                                                        |
+--------------------------------------------------------+
```
Tap a tile → PIN pad slides up. "Add cashier" requires the device-JWT user to be Admin/Manager.

### 4. PIN entry

```
+--------------------------------------------------------+
|  Hi, Ana                                               |
|  Enter your PIN          ●  ●  ●  ○                    |
|                                                        |
|                  +---+ +---+ +---+                     |
|                  | 1 | | 2 | | 3 |                     |
|                  +---+ +---+ +---+                     |
|                  | 4 | | 5 | | 6 |                     |
|                  +---+ +---+ +---+                     |
|                  | 7 | | 8 | | 9 |                     |
|                  +---+ +---+ +---+                     |
|                  | ⌫ | | 0 | | ↵ |                     |
|                  +---+ +---+ +---+                     |
|  Wrong PIN? [ Sign in with password instead ]          |
+--------------------------------------------------------+
```
3 wrong attempts → re-prompt password. Successful entry → Till Home.

### 5. Till Home — main screen

```
+----------------------------------------------------------------------+
|  Sunset Bistro · Airport · Ana (Cashier) · 11:02            [ ⚙ ]    |  ← app bar
+---+------------------------------------------+-----------------------+
| C |  [ Coffee ] [ Tea ] [ Bakery ] [ All ▾ ] |  Order #ORD-20260515-0042 |
| O |  -------------------------------------- |  ------------------------|
| F |  +--------+ +--------+ +--------+ +----+|  1× Flat White    $5.50  |
| F |  | Flat   | | Cappu- | | Latte  | |Mac.||  2× Cappuccino   $11.00  |
| E |  | White  | | ccino  | |        | |    ||  4× Croissant    $16.80  |
| E |  | $5.50  | | $5.50  | | $6.00  | |$5.5||                          |
|   |  +--------+ +--------+ +--------+ +----+|  ----------------------- |
| T |  +--------+ +--------+ +--------+ +----+|  Subtotal        $33.30  |
| E |  | Iced   | | Mocha  | | Espresso|       |  Discount         -$0.00 |
| A |  | Latte  | | $5.80  | | $4.00   |       |  Tax 15%          $4.55  |
|   |  | $6.00  | |        | |         |       |  -----------------------|
| ━━|  +--------+ +--------+ +--------+         |  Total           $37.85 |
| B |                                          |                          |
| A |  [ 🔍  Search name / SKU / barcode    ]  |  [ Send to kitchen ]    |
| K |                                          |  [ Pay $37.85   ▸ ]     |
+---+------------------------------------------+-----------------------+
```
Left: vertical category rail (Material `NavigationRail`).
Center: product grid (Wrap of cards). Tap to add to cart.
Right: cart panel. Tap a line for quantity/discount sheet. "Send to kitchen" prints kitchen-printer items + advances order status to `Sent`. "Pay" opens payment.

### 6. Cart-line edit sheet

```
       +---------------------------------------+
       |  Croissant                            |
       |                                       |
       |   Qty:  [ - ]   4   [ + ]             |
       |   Unit price:  $4.20                  |
       |   Discount:    [  0.00  ]             |
       |   Line total:  $16.80                 |
       |                                       |
       |  [ Remove ]               [ Done ]    |
       +---------------------------------------+
```
Modal bottom sheet.

### 7. Payment — single or split tender (customer's choice)

The screen shape is the same regardless of how many tenders the customer wants. One row → single payment. Multiple rows → split. The cashier never has to "switch modes": they just tap the next method tile if the customer asks to split.

```
+----------------------------------------------------------------------+
|  ←  Pay  Order #ORD-20260515-0042                   Total $37.85     |
+----------------------------------------------------------------------+
|                                                                       |
|  Tendered                                  Remaining                  |
|   Cash         $20.00            ✎ 🗑      $17.85                      |
|   EFTPOS       $17.85   (auth …) ✎ 🗑                                  |
|                                                                       |
|  +-----------------+ +-----------------+ +-----------------+          |
|  |  Cash            | |  EFTPOS         | |   Card (manual) |          |
|  |  💵              | |  📡             | |   💳            |          |
|  +-----------------+ +-----------------+ +-----------------+          |
|                                                                       |
|     +-----------+----+----+----+                                      |
|     | Amount    | 7  | 8  | 9  |   [ Exact ]  $17.85                  |
|     | $______   +----+----+----+                                      |
|     |           | 4  | 5  | 6  |   [ +5 ] [ +10 ] [ +20 ]             |
|     |           +----+----+----+                                      |
|     |           | 1  | 2  | 3  |                                      |
|     |           +----+----+----+                                      |
|     |           | ⌫  | 0  | .  |                                      |
|     +-----------+----+----+----+                                      |
|                                                                       |
|                                          [ Complete sale ▸ ]          |
+----------------------------------------------------------------------+
```
- Tap a method tile, enter amount via keypad, **Add** → row appears in "Tendered". Repeat until "Remaining" reaches $0.
- `EFTPOS` tile invokes `EftposProvider.charge(amount)`; mock provider asks for a confirm tap and returns an auth code.
- **Complete sale** disabled until remaining ≤ 0. On tap: posts payments via `POST /api/orders/{id}/payments` one per row, updates status to `Paid`, prints receipt, fires drawer (Cash payments only), screen returns to a fresh Till Home with toast "Order paid".

### 8. Order summary — pre-print preview (optional)

```
+----------------------------------------------------+
|         SUNSET BISTRO  ·  Airport                  |
|  -----------------------------------------------   |
|   ORD-20260515-0042         15 May 2026 11:02      |
|   Cashier: Ana Brown                               |
|                                                    |
|   1 × Flat White                    $5.50          |
|   2 × Cappuccino                   $11.00          |
|   4 × Croissant                    $16.80          |
|                                                    |
|                                Subtotal  $33.30    |
|                                  Tax 15%   $4.55   |
|                                    Total $37.85    |
|                                                    |
|   Paid:    Cash    $20.00                          |
|            EFTPOS  $17.85   (auth 90021)           |
|   Change:           $0.00                          |
|                                                    |
|   Thanks!                                          |
+----------------------------------------------------+
                  [ Print + Open drawer ]
```

### 9. Settings — printer + display pairing (Admin/Manager)

```
+--------------------------------------------------------+
|  ←  Settings                                           |
+--------------------------------------------------------+
|                                                        |
|  Active store           Airport            [ Change ]  |
|                                                        |
|  Receipt printer        Front counter      [ Change ]  |
|    Language             (●) English  ( ) Vietnamese    |
|                         ( ) Both (Eng / Viet)          |
|  Kitchen printer        Kitchen 1          [ Change ]  |
|    Language             ( ) English  (●) Vietnamese    |
|                         ( ) Both (Eng / Viet)          |
|  Cash drawer            Linked to Front counter        |
|                          [ Test drawer kick ]          |
|                                                        |
|  Customer display       Paired: 192.168.1.84           |
|    Language             (●) English  ( ) Vietnamese    |
|                         ( ) Both (Eng / Viet)          |
|                          [ Unpair ] [ Re-discover ]    |
|                                                        |
|  Tablet identity        Jane (Manager)                 |
|                          [ Sign out & wipe device ]    |
+--------------------------------------------------------+
```
"Change" opens a list of printers from `GET /api/stores/{storeId}/printers` filtered by type. Customer-display re-discovery scans mDNS for `_postill._tcp`.

### 10. Customer display app — pairing screen

```
+--------------------------------------------------------+
|                                                        |
|             Customer Display                           |
|         Pair this screen with a till                   |
|                                                        |
|     Discovered tills nearby                            |
|     +------------------------------------+             |
|     | Sunset Bistro - Tablet A           |  [ Pair ]   |
|     | 192.168.1.45                       |             |
|     +------------------------------------+             |
|     | Sunset Bistro - Tablet B           |  [ Pair ]   |
|     | 192.168.1.46                       |             |
|     +------------------------------------+             |
|                                                        |
|     Or enter IP manually   [ 192.168.1.__ ] [ Pair ]   |
|                                                        |
+--------------------------------------------------------+
```

### 11. Customer display app — live mirror (idle)

```
+--------------------------------------------------------+
|                                                        |
|                    SUNSET BISTRO                       |
|                                                        |
|              ☕  Welcome to Airport ☕                  |
|                                                        |
|                   Tap to begin                         |
|                                                        |
|                                                        |
+--------------------------------------------------------+
```

### 12. Customer display app — order in progress

```
+--------------------------------------------------------+
|  Your order                          Order #ORD-…0042  |
+--------------------------------------------------------+
|                                                        |
|   1 × Flat White                              $5.50    |
|   2 × Cappuccino                             $11.00    |
|   4 × Croissant                              $16.80    |
|                                                        |
|                                                        |
+--------------------------------------------------------+
|   Subtotal                                   $33.30    |
|   Tax                                         $4.55    |
|                                                        |
|   TOTAL DUE                                  $37.85    |
+--------------------------------------------------------+
```
Auto-updates on every cart change via WebSocket push.

### 13. Customer display app — payment in progress

```
+--------------------------------------------------------+
|  Please pay                                            |
+--------------------------------------------------------+
|                                                        |
|   TOTAL DUE                                  $37.85    |
|                                                        |
|   Paid so far                                          |
|     Cash                                     $20.00    |
|                                                        |
|   Remaining                                 $17.85     |
|                                                        |
|       Insert or tap your card on the terminal          |
|                          ⬇                             |
|                                                        |
+--------------------------------------------------------+
```

### 14. Customer display app — thank you

```
+--------------------------------------------------------+
|                                                        |
|                    ✅  Thank you!                       |
|                                                        |
|             Your receipt is being printed.             |
|                                                        |
+--------------------------------------------------------+
```
Returns to idle after 5 seconds.

---

## State management overview (Riverpod)

| Provider | Holds | Lifetime |
|---|---|---|
| `deviceStateProvider` | `DeviceJwt`, `activeStoreId`, `restaurantId`, `tenantName`, per-surface language prefs (`receiptLang`, `kitchenLang`, `displayLang` ∈ `en` / `vi` / `both`) | app-wide; persists to `flutter_secure_storage` + `shared_preferences` |
| `sessionProvider` | Current cashier (`User`, in-memory JWT, idle timer) | wiped on idle/logout |
| `cartProvider` (`StateNotifier<OrderDraft>`) | Lines, line discounts, order discount, tax computed value, server-issued OrderId once created | wiped on `Complete sale` |
| `productsProvider` (`FutureProvider`) | `List<Product>` for active store/tenant | cached for 5 minutes |
| `printersProvider` (`FutureProvider`) | `List<Printer>` for active store | cached for 5 minutes |
| `eftposProvider` | `EftposProvider` impl (mock in v1) | singleton |
| `customerDisplayServerProvider` | Running shelf server, list of paired clients | singleton, started on app boot |

The cart provider rebroadcasts every state change to connected customer-display WebSocket clients via `customer_display_server.dart`.

---

## API integration

| Action | Endpoint | When |
|---|---|---|
| Device pair / cashier login | `POST /api/auth/login` | Device setup; Add cashier |
| Tenant header | `GET /api/tenants/me` | After login |
| Cashier list | `GET /api/users` | When manager taps **Add cashier** |
| Store list | `GET /api/stores` | Device setup, Settings |
| Printer list | `GET /api/stores/{storeId}/printers` | Settings; cart provider on first kitchen send |
| Menu | `GET /api/products`, `GET /api/categories` | Till Home boot |
| Send to kitchen | `POST /api/orders` with status implied as `Open` (server default) → then PUT to `Sent` | "Send to kitchen" button |
| Pay | `PUT /api/orders/{id}/status` → `Paid`; `POST /api/orders/{id}/payments` (one per row) | Complete sale |
| Cancel | `PUT /api/orders/{id}/status` → `Cancelled` | Cart "Discard order" |

Dio interceptor mirrors the admin web: inject `Authorization`, treat 401 as session-dead and pop to user picker. Dev base URL: configurable via `--dart-define=API_BASE_URL=http://192.168.1.20:5202`; release default points at the LAN address provided at device-setup time (TODO field on device-setup screen — defaults to host the manager used to authenticate).

---

## Printing & cash drawer (ESC/POS over TCP)

`PrinterService` opens a TCP `Socket` to `printer.ipAddress:port`, sends ESC/POS bytes built with `esc_pos_utils` + `CapabilityProfile.load()`, then closes. No persistent connection.

Pipelines:

- **Kitchen ticket** — filtered to kitchen-relevant lines (in v1 = all lines on the order; later we can flag products as kitchen-vs-bar). Sent to every printer whose `printerType == 'Kitchen'` for the active store. Line names rendered through `LocalizationService.resolve(line, surface: kitchen)` so each kitchen prints in the configured language (typically Vietnamese; `both` stacks the alt name underneath in smaller text).
- **Receipt** — full order with totals and tendered payments. Sent to the printer chosen as "Receipt printer" in Settings. Same `LocalizationService.resolve(..., surface: receipt)` so the customer-facing receipt can stay English or print bilingual.
- **Cash drawer kick** — `ESC p 0 50 250`. Sent to the receipt printer only when at least one payment row has `paymentMethod == 'Cash'`. A **Test drawer kick** button in Settings sends the same command standalone for setup.

Errors (timeout, refused, write error) surface as a snackbar with retry; the order is still saved on the server so cashiers don't lose it.

---

## EFTPOS — provider interface

```dart
abstract class EftposProvider {
  Future<EftposResult> charge({required double amount, required String orderRef});
  Future<EftposResult> refund({required double amount, required String authCode}); // unused in v1
}

class EftposResult {
  final bool approved;
  final String? authCode;
  final String? cardLast4;
  final String? terminalReceipt;
  final String? declineReason;
}
```

v1 ships `MockEftposProvider` which shows a confirmation dialog ("Approve?/Decline?") and returns a fake auth code on approve. The Payment row written to the API stores `authCode` in the `reference` field.

Real terminal integration is a future swap — vendor SDKs are wildly different. The provider boundary keeps the payment screen untouched.

---

## Localization — bilingual item names

The till is monolingual at the UI-chrome level (English buttons and labels in v1), but **product names are bilingual**. Each product carries an optional alternative name plus its language code; the same data shape extends to a third language later without further migrations.

### Data shape

Product DTO gains two optional fields:

```jsonc
{
  "id": "...",
  "name": "Beef Pho",            // primary, always present
  "nameLocalized": "Phở Bò",     // optional alt name (typically Vietnamese)
  "altLanguageCode": "vi",       // ISO-639-1 of nameLocalized; null if no alt
  // ... existing fields
}
```

Category gets the same two optional fields so the category rail can also localize when configured.

> **Backend impact — this lifts the "no backend changes in v1" rule.** Adds nullable `NameLocalized` and `AltLanguageCode` columns to `Product` and `Category` in `Pos.Api`, exposes them on the DTOs, and surfaces an input in the admin web's product/category editors. Migration is additive and non-breaking — existing rows just leave the new columns null and behave exactly as today.

### Resolution rules — `LocalizationService.resolve(item, surface)`

For each surface (`kitchen`, `receipt`, `display`, `cashier`) the till checks the device-level `*Lang` preference (`en` / `vi` / `both`):

| Preference | Rendered |
|---|---|
| `en` (primary) | `name` |
| `vi` (alt) | `nameLocalized` if non-null, else fall back to `name` |
| `both` | `name` on the first line, `nameLocalized` underneath in smaller text (if non-null) |

The cashier-facing till always uses `cashier` surface → `en` (the cashier reads the language they trained on). Kitchen/receipt/display surfaces follow Settings. This is intentional: the cashier sees one stable list, while each output channel can be tuned to its audience.

### Customer-display payload extension

The WebSocket cart JSON adds an optional `nameLocalized` per line. The customer display resolves locally using its own preference, so the same till can serve multiple display devices on different language settings if a future store needs it.

```jsonc
{ "orderNumber": "...", "lines": [
  { "name": "Beef Pho", "nameLocalized": "Phở Bò", "qty": 1, "unit": 12.0, "total": 12.0 }
], "subtotal": 12.0, "tax": 1.80, "total": 13.80, "status": "Open" }
```

### Admin entry

The dual-language data is entered once, in the admin web's product/category editor — not on the till. Each product gets an "Alternative name (e.g. Vietnamese)" text field plus a language-code dropdown. The till just reads what's there. This keeps the till device-config-only (no menu CRUD on the tablet).

---

## Customer display — LAN pairing protocol

- Till app starts a WebSocket server on `0.0.0.0:7124` via `shelf_web_socket`.
- Till app advertises mDNS service `_postill._tcp` on the LAN with attributes `{ tenantId, storeId, deviceName }`.
- Customer-display app discovers services via `bonsoir`, lists them on the pairing screen.
- On pair: customer app opens `ws://<till-ip>:7124/cart` and stores the IP in `shared_preferences` for auto-reconnect.
- Cart state sent as JSON on every change: `{ orderNumber, lines:[{name,nameLocalized?,qty,unit,total}], subtotal, tax, total, status, payments:[{method,amount}], remaining }`. The customer display picks `name` vs `nameLocalized` based on its own language preference (see Localization).
- The till treats display clients as best-effort — if no client is connected, payments still proceed.

---

## Material 3 theming

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0F6CBD)),
  visualDensity: VisualDensity.adaptivePlatformDensity,
  // Bigger touch targets on tablet
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: Size(0, 56)),
  ),
);
```

Layout breakpoints: under 720dp width → fall back to a stacked layout (phone fallback for testing on emulator), at/above → 3-pane (rail / grid / cart) on Till Home.

---

## Build phases

1. **Scaffold + theming + routing** (~half day)
   - `flutter create Pos.Till.App --platforms android --org com.adaptable`
   - Add deps, configure Material 3 theme, set up `go_router` with stub screens, two `main` entry points.

2. **API + auth + device setup + user picker + PIN flow** (~1–2 days)
   - Dio client, freezed models, secure-credentials service, device-setup screen, user picker with add-cashier flow, PIN pad widget, idle-logout service.

3. **Till Home + cart + send to kitchen + receipt** (~2 days)
   - Product grid, category rail, cart provider, ESC/POS printer service, kitchen + receipt pipelines, drawer kick. `LocalizationService` wired in so kitchen/receipt rendering respects per-surface language.

4. **Payment + EFTPOS mock + complete sale** (~1 day)
   - Payment screen, amount keypad, split-tender model (handles single or multi-tender as the same flow), mock EFTPOS, complete-sale orchestration.

5. **Customer display flavor + pairing** (~1 day)
   - `main_customer.dart`, customer screens, shelf WebSocket server in till, bonsoir mDNS, JSON cart broadcast (incl. `nameLocalized`).

6. **Settings + polish** (~half day)
   - Printer selection, drawer test, display unpair/re-discover, per-surface language toggles, error states, empty states.

7. **Backend additive migration for localized names** (~half day, parallelizable with phase 3)
   - Add nullable `NameLocalized` + `AltLanguageCode` to `Product` and `Category` in `Pos.Api` (EF migration), expose on DTOs, add editor fields to `Pos.Admin.Web` product/category screens. No till code depends on phase 7 landing first — until the columns exist they read as null and the till behaves single-language.

Rough total: ~7–9 days of focused work.

---

## Critical files to create

| Path | Purpose |
|---|---|
| [Pos.Till.App/pubspec.yaml](Pos.Till.App/pubspec.yaml) | Deps and asset declarations |
| [Pos.Till.App/lib/main.dart](Pos.Till.App/lib/main.dart) | Till entry |
| [Pos.Till.App/lib/main_customer.dart](Pos.Till.App/lib/main_customer.dart) | Customer display entry |
| [Pos.Till.App/lib/app/theme.dart](Pos.Till.App/lib/app/theme.dart) | Material 3 ThemeData |
| [Pos.Till.App/lib/app/router.dart](Pos.Till.App/lib/app/router.dart) | go_router with auth guard |
| [Pos.Till.App/lib/api/api_client.dart](Pos.Till.App/lib/api/api_client.dart) | Dio + JWT interceptor (mirror of [Pos.Admin.Web/src/api/client.ts](Pos.Admin.Web/src/api/client.ts)) |
| [Pos.Till.App/lib/services/secure_credentials.dart](Pos.Till.App/lib/services/secure_credentials.dart) | Per-user encrypted JWT + PIN hash |
| [Pos.Till.App/lib/services/printer_service.dart](Pos.Till.App/lib/services/printer_service.dart) | ESC/POS TCP send |
| [Pos.Till.App/lib/services/localization_service.dart](Pos.Till.App/lib/services/localization_service.dart) | Resolves primary vs `nameLocalized` per surface (kitchen/receipt/display/cashier) |
| [Pos.Till.App/lib/services/eftpos/eftpos_provider.dart](Pos.Till.App/lib/services/eftpos/eftpos_provider.dart) | Provider interface + mock |
| [Pos.Till.App/lib/services/customer_display_server.dart](Pos.Till.App/lib/services/customer_display_server.dart) | shelf_web_socket on the till |
| [Pos.Till.App/lib/services/pairing_service.dart](Pos.Till.App/lib/services/pairing_service.dart) | mDNS advertise + discover |
| [Pos.Till.App/lib/screens/till_home.dart](Pos.Till.App/lib/screens/till_home.dart) | The main 3-pane till |
| [Pos.Till.App/lib/screens/payment.dart](Pos.Till.App/lib/screens/payment.dart) | Split-tender payment |
| [Pos.Till.App/lib/screens/customer/customer_display.dart](Pos.Till.App/lib/screens/customer/customer_display.dart) | Live cart mirror |

Backend changes in v1: one additive migration on `Product` and `Category` (`NameLocalized`, `AltLanguageCode`, both nullable) plus DTO + admin-web editor fields. No schema changes elsewhere.

---

## Reusable artefacts from earlier projects

- **C# DTO shapes** at [Pos.Api/DTOs/](Pos.Api/DTOs/) — hand-port to freezed models in `lib/models/`.
- **Auth interceptor pattern** in [Pos.Admin.Web/src/api/client.ts](Pos.Admin.Web/src/api/client.ts) — same shape in `api_client.dart` (Dio).
- **Printer entity + types** ([Pos.Api/Entities/Printer.cs](Pos.Api/Entities/Printer.cs), [Pos.Api/DTOs/PrinterDtos.cs](Pos.Api/DTOs/PrinterDtos.cs)) drive Settings → Printer assignment.
- **Roles** at [Pos.Api/Helpers/Roles.cs](Pos.Api/Helpers/Roles.cs) — drive who can pair the tablet and who appears in the user picker.

---

## Verification

End-to-end happy path after each phase:

1. Run API: `dotnet run --project Pos.Api`.
2. Run till on an Android tablet (or emulator with `--device-id` set to a 10″ tablet config): `flutter run -t lib/main.dart --dart-define=API_BASE_URL=http://<host-ip>:5202`.
3. **Device setup**: sign in as the seeded `admin@pos.local` / `Admin123!`, pick a store → user picker loads.
4. **Add cashier**: tap **Add cashier**, pick a user, enter their password and a 4-digit PIN → tile appears.
5. **Cashier sign in**: tap the tile, type PIN → Till Home loads with products.
6. **Build an order**: tap 3–4 products, change qty on one, apply a line discount → totals match on screen and on the connected customer display.
7. **Send to kitchen**: tap **Send to kitchen** → kitchen printer prints (or socket logs the bytes if no printer attached in dev), order status becomes `Sent` via the API.
8. **Pay (single tender)**: tap **Pay**, tap **Cash**, **Exact**, **Complete sale** → receipt prints, drawer kicks, one `POST /payments` row, status `Paid`.
9. **Pay (split tender, on customer request)**: re-run an order, tap **Cash $20** then **EFTPOS $17.85**, **Complete sale** → two `POST /payments` rows, status `Paid`, drawer kicks (because Cash is present), customer display shows **Thank you**. Confirms single- and multi-tender share the same flow.
10. **Bilingual print**: in the admin web, give one product a Vietnamese alt name (e.g. `Phở Bò`); in till Settings, set Kitchen language to Vietnamese; send a kitchen order → kitchen printout shows Vietnamese, receipt + customer display stay English. Flip kitchen to **Both** → ticket stacks `Beef Pho` over `Phở Bò`. Products without an alt name keep printing English on every surface.
11. **Idle logout**: leave the till untouched 5 min → bounce to user picker.
12. **Customer-display flavor**: install `main_customer.dart` build on a second tablet, on the same Wi-Fi → till appears in **Discovered tills**, pair, observe live cart sync end-to-end.

If any of step 7–9 fails the issue is almost certainly in `printer_service.dart`, the printer entity's IP/port, or the EFTPOS mock — not the API. If step 10 fails the issue is in `localization_service.dart` resolution or the DTO mapping for `nameLocalized`.

---

## Explicit non-goals for v1

To prevent scope creep:

- No tables / table layout.
- No refunds with money flow (`POST /payments` rejects negatives today).
- No voids beyond `PUT /status = Cancelled`.
- No X/Z reports or end-of-day summaries.
- No tip handling, no gratuity, no surcharges.
- No printer auto-discovery — printers come from the API, configured by the admin web.
- No iOS build.
- No offline mode — Wi-Fi to the API is required.
- No real EFTPOS terminal integration — provider interface only, mock impl.
- No translated UI chrome — only product/category *names* are bilingual in v1. Buttons, labels, error messages, settings strings stay English. Adding a full UI translation layer (Flutter `intl` ARB files) is a later phase.
- No third language beyond the alt slot — the schema is flexible (any `altLanguageCode`), but v1 ships with English primary + one configurable alt (typically Vietnamese). Three+ simultaneous languages waits until at least one store actually asks for it.

These are deliberate "till manager" features deferred per the latest decision.
