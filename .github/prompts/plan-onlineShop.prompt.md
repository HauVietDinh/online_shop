## Plan: Online Shop MVP (Phoenix LiveView)

Build a learning-focused MVP in phases: establish a robust Accounts foundation first (email/password auth + strict seller/buyer role separation), then add catalog/inventory, cart + vouchers, and simulated checkout/order lifecycle. Use LiveView end-to-end for UI, keep payment simulated but model it cleanly so a real gateway can be added later.

**Steps**
1. Phase 1 - Foundation and Auth (blocking for all other phases)
1.1 Define domain boundaries and contexts: Accounts (identity/profile), Catalog (items), Cart (active basket), Orders (checkout + payment state), Promotions (voucher rules).
1.2 Add dependencies and scaffolding strategy: use Phoenix auth scaffolding patterns for session/login/logout, but customize schema and flows for two mutually-exclusive roles.
1.3 Create user/account data model with required fields:
- Shared: name, mobile, bank_account, email, hashed_password, role (seller|buyer).
- Seller-only profile fields: shop_name, website, shop_description.
- Enforce role-specific validations at changeset level.
1.4 Implement auth/session flows (register, login, logout) with role-aware post-login routing:
- Seller -> seller dashboard.
- Buyer -> buyer storefront/cart.
1.5 Build profile edit flow for each role (single LiveView with role-conditional sections, or two LiveViews using shared context APIs).

2. Phase 2 - Seller Inventory Management (depends on Phase 1)
2.1 Create Catalog item model with seller ownership and required fields: item_code (business ID), name, type/category, price, amount(stock).
2.2 Implement seller-only CRUD surface:
- Add item
- Remove item
- Increase/decrease amount
2.3 Add authorization checks in context + LiveView handlers so sellers only modify their own items.
2.4 Use stream-based listing for seller inventory to follow LiveView collection best practices.

3. Phase 3 - Buyer Shopping and Cart (depends on Phases 1-2)
3.1 Build buyer browsing/listing UI for available items (stock > 0).
3.2 Create cart model (per buyer active cart) and cart item model (quantity, unit_price_snapshot).
3.3 Implement cart operations:
- Add item
- Remove item
- Edit quantity
- Recalculate subtotal/total on each mutation
3.4 Introduce voucher application (percentage discount):
- Store voucher code + percent + validity window + active flag.
- Apply max one voucher per cart in v1.
- Persist discount amount snapshot into checkout order.

4. Phase 4 - Simulated Checkout and Payment State (depends on Phase 3)
4.1 Checkout transaction flow:
- Validate stock availability for all cart items.
- Create order + order_items snapshots.
- Decrement stock atomically.
- Mark payment_status as simulated_paid (or paid) and order_status as placed.
4.2 Preserve financial snapshots on order:
- subtotal, discount_total, grand_total, voucher_code_used.
4.3 Clear/close active cart after successful checkout.
4.4 Build buyer order history + seller order intake views.

5. Phase 5 - Testing, Hardening, and UX polish (parallelizable per phase but finalized here)
5.1 Data/Context tests:
- Role validation
- Authorization boundaries
- Stock decrement + insufficient stock
- Voucher percentage calculations and edge cases
5.2 LiveView tests:
- Auth redirects by role
- Seller item lifecycle UI
- Buyer cart mutation UI
- Checkout success/failure paths
5.3 Run full quality gates and fix issues:
- mix format
- mix test
- mix precommit

6. Delivery sequencing and parallelism guidance
6.1 Parallel track A (after Phase 1): seller inventory UI + tests.
6.2 Parallel track B (after Phase 1): buyer browse/cart UI + tests.
6.3 Merge track C (after A+B): checkout transactional logic and cross-role order views.

**Relevant files**
- /repo/haudinh/learning/online_shop/mix.exs — dependency updates and aliases confirmation.
- /repo/haudinh/learning/online_shop/lib/online_shop/application.ex — ensure any new workers/supervisors if needed.
- /repo/haudinh/learning/online_shop/lib/online_shop_web/router.ex — auth routes, role-guarded live_session blocks, seller/buyer route separation.
- /repo/haudinh/learning/online_shop/lib/online_shop_web.ex — shared web imports/macros used by new LiveViews.
- /repo/haudinh/learning/online_shop/lib/online_shop_web/components/layouts.ex — ensure current_scope usage and navigation for role-aware menus.
- /repo/haudinh/learning/online_shop/lib/online_shop_web/components/core_components.ex — reuse input/form/table patterns, avoid custom raw inputs.
- /repo/haudinh/learning/online_shop/test/support/data_case.ex — context-level test pattern and helpers.
- /repo/haudinh/learning/online_shop/test/support/conn_case.ex — web-level integration/auth test setup.
- New modules under /repo/haudinh/learning/online_shop/lib/online_shop/ for accounts/catalog/cart/orders/promotions contexts + schemas.
- New LiveView modules/templates under /repo/haudinh/learning/online_shop/lib/online_shop_web/live/ for auth, seller, buyer, cart, checkout, and orders.
- New migrations under /repo/haudinh/learning/online_shop/priv/repo/migrations/ for users, items, carts, vouchers, orders.
- New tests under /repo/haudinh/learning/online_shop/test/online_shop/ and /repo/haudinh/learning/online_shop/test/online_shop_web/.

**Verification**
1. Generate and migrate DB schema; confirm constraints/indexes compile and migrate cleanly.
2. Validate auth flows manually:
- seller register/login/logout/edit profile
- buyer register/login/logout/edit profile
- forbidden cross-role page access is redirected.
3. Validate seller inventory actions manually: add/remove/adjust quantity, ensure only owner edits succeed.
4. Validate buyer cart workflow manually: add/edit/remove items, voucher apply/remove, total recalculation.
5. Validate checkout manually: successful order creation decrements stock and clears cart; insufficient stock shows safe error.
6. Run automated tests per layer:
- mix test test/online_shop
- mix test test/online_shop_web
- mix precommit

**Decisions**
- Included in scope:
- Separate roles per account (exactly one role per user).
- Email + password auth.
- Full LiveView UI for all listed flows.
- Simulated payment only.
- Voucher type is percentage discount.
- Explicitly excluded from v1:
- External payment gateway integration.
- Multi-vendor cart split checkout logic (single checkout path first).
- Advanced voucher stacking/rules engine.

**Further Considerations**
1. Role profile modeling option:
- Option A: single users table with nullable seller fields (faster for learning MVP; recommended).
- Option B: users + seller_profiles and buyer_profiles tables (cleaner normalization, more boilerplate).
2. Item type modeling option:
- Option A: free-text category string (faster).
- Option B: dedicated categories table (better long-term consistency).
3. Checkout consistency option:
- Option A: strict DB transaction with row-level locking on inventory (recommended).
- Option B: optimistic check + retry (simpler but more race-prone).

## Self-Implementation Mode (No Code Generation)

You implement everything yourself. Use this guide for recommendations, checkpoints, and commands only.

### Collaboration Rules
- I give architecture advice, acceptance criteria, debugging help, and command suggestions.
- I do not generate or edit project code unless you explicitly ask.
- You implement each step, then share errors/output for review.

### Suggested Milestone Order
1. Accounts and authentication
2. Role boundaries (seller vs buyer)
3. Seller inventory management
4. Buyer cart and voucher
5. Simulated checkout and orders
6. Tests and hardening

### Commands by Milestone

#### Milestone 1: Foundation and Auth
- mix phx.routes
- mix test
- mix help phx.gen.auth
- mix ecto.gen.migration create_accounts_users
- mix ecto.migrate
- mix format
- mix test

Recommendation:
- Use one users table with a role field (seller or buyer).
- Keep seller-only fields nullable in DB and enforce role rules in changeset validations.

#### Milestone 2: Seller Inventory
- mix ecto.gen.migration create_catalog_items
- mix ecto.migrate
- mix phx.routes
- mix test test/online_shop
- mix test test/online_shop_web

Recommendation:
- Each item belongs to a seller account.
- Add constraints for non-negative price and stock.
- Add unique index on seller_id + item_code.

#### Milestone 3: Buyer Cart and Voucher
- mix ecto.gen.migration create_cart_and_cart_items
- mix ecto.gen.migration create_promotions_vouchers
- mix ecto.migrate
- mix test

Recommendation:
- Store unit_price_snapshot in cart items.
- Keep one active cart per buyer.
- Support one percentage voucher per cart in v1.

#### Milestone 4: Checkout and Orders
- mix ecto.gen.migration create_orders_and_order_items
- mix ecto.migrate
- mix test --failed
- mix test

Recommendation:
- Execute checkout in one DB transaction.
- Lock inventory rows during checkout to prevent oversell.
- Persist order money snapshots: subtotal, discount_total, grand_total.

#### Milestone 5: Final Quality Gate
- mix test
- mix precommit

### Acceptance Criteria Checklist
- Seller can register, login, logout, edit profile, and manage own items only.
- Buyer can register, login, logout, edit profile, browse items, and manage cart.
- Voucher applies percentage discount correctly and updates totals.
- Checkout decrements stock atomically and creates order snapshots.
- Role-based route protection blocks cross-role pages.
- Test suite passes and precommit is green.

## Daily Execution Checklist

### Day 0: Setup and Alignment
Goal: verify environment, conventions, and scope before writing features.

Commands:
- mix --version
- mix deps.get
- mix ecto.create
- mix ecto.migrate
- mix phx.routes
- mix test

Checklist:
- Database is reachable and migrations run cleanly.
- Route map is reviewed and initial auth/cart/order paths are planned.
- Context/module naming is decided (Accounts, Catalog, Cart, Orders, Promotions).
- Role model is confirmed as exactly one role per account.
- Voucher scope is confirmed as single percentage voucher per cart.
- Simulated payment status values are defined for v1.

Done when:
- The app boots, tests run, and you have a clear naming/routing plan for Day 1.

### Day 1: Auth and Roles
Goal: finish register/login/logout + seller or buyer role routing.

Commands:
- mix phx.routes
- mix help phx.gen.auth
- mix ecto.gen.migration create_accounts_users
- mix ecto.migrate
- mix test

Checklist:
- Users table includes role and required profile fields.
- Registration creates exactly one role per account.
- Login redirects seller and buyer to different destinations.
- Protected pages reject unauthenticated users.
- Cross-role access is blocked.

Done when:
- You can register seller and buyer accounts and both can login/logout successfully.

### Day 2: Seller Inventory + Buyer Cart
Goal: seller manages stock, buyer manages cart with voucher.

Commands:
- mix ecto.gen.migration create_catalog_items
- mix ecto.gen.migration create_cart_and_cart_items
- mix ecto.gen.migration create_promotions_vouchers
- mix ecto.migrate
- mix test test/online_shop
- mix test test/online_shop_web

Checklist:
- Seller can add/remove items and adjust amount.
- Only owner seller can edit/remove own items.
- Buyer can add/remove/edit cart quantities.
- Cart totals recalculate on each change.
- Voucher applies percentage discount correctly.

Done when:
- End-to-end demo works: seller creates stock, buyer adds to cart, applies voucher, and sees correct totals.

### Day 3: Checkout, Orders, and Hardening
Goal: complete simulated checkout transaction and stabilize with tests.

Commands:
- mix ecto.gen.migration create_orders_and_order_items
- mix ecto.migrate
- mix test --failed
- mix test
- mix precommit

Checklist:
- Checkout validates stock before confirming order.
- Inventory is decremented atomically.
- Order and order items keep money snapshots.
- Cart is cleared after successful checkout.
- Buyer order history and seller order intake views work.

Done when:
- Full suite passes and mix precommit is green.

### If You Get Stuck
- Share the exact error output.
- Share the migration or changeset involved.
- Share the command you ran and expected behavior.

## Definition of Done by Phase

| Phase | Functional Done | Data/Integrity Done | Test Done |
|---|---|---|---|
| Phase 1: Auth and Roles | Register, login, logout, profile edit work for seller and buyer. | One-role-per-account enforced. Required fields validated by role. | Auth flow tests pass, cross-role access tests pass. |
| Phase 2: Seller Inventory | Seller can add/remove items and adjust stock from UI. | Item ownership enforced. Non-negative price/stock constraints active. | Seller inventory tests pass (success + unauthorized paths). |
| Phase 3: Buyer Cart and Voucher | Buyer can add/remove/edit cart items and apply one voucher. | Cart totals and discount math are consistent and deterministic. | Cart/voucher tests pass for normal and edge cases. |
| Phase 4: Checkout and Orders | Buyer can checkout and see order history; seller can see intake orders. | Checkout is transactional, stock decremented atomically, snapshots persisted. | Checkout tests pass for success and insufficient stock failures. |
| Phase 5: Hardening | UX flow is coherent and role navigation is clean. | No known data race or authorization gaps in defined scope. | `mix test` and `mix precommit` both pass. |

## Exit Criteria (Project Complete)
- All phase definitions-of-done are satisfied.
- Manual end-to-end walkthrough succeeds: seller creates stock -> buyer adds cart + voucher -> buyer checks out -> seller sees order.
- Quality gates are green with no pending failed tests.

## Risk Log and Prevention Checks

### Top Risks

| Risk | Why It Happens | Prevention Check | Recovery Action |
|---|---|---|---|
| Role leakage (seller accesses buyer-only flow or inverse) | Missing route guards or inconsistent checks in handlers | Verify role checks at router and context boundaries | Add explicit authorization checks and regression tests for forbidden paths |
| Overselling stock during checkout | Concurrent checkouts update inventory without transactional lock | Confirm checkout uses one transaction and row-level lock on inventory rows | Roll back failed checkout and re-run availability checks before retry |
| Voucher miscalculation | Mixed rounding rules or discount applied twice | Define one rounding strategy and test edge values (0, 1, 100 percent) | Normalize calculation order and snapshot totals at order creation |
| Cart totals drift from source of truth | UI recomputes differently from backend logic | Keep totals computed in one backend path and returned to UI | Replace duplicated client/server math with single backend computation |
| Broken profile validation by role | Nullable seller fields accepted without role-specific validation | Add changeset rules for role and required fields per role | Add role-specific invalid-case tests and fix validation branches |
| Insecure ownership checks on item edit/delete | Filtering by item id only, not seller ownership | Ensure updates/deletes use owner-scoped queries | Reject unauthorized mutations and log attempts in tests |
| Checkout snapshot gaps | Order created without copying price/discount fields | Verify order and order_items persist money snapshots on checkout | Add migration fields and enforce required snapshot data in changesets |
| Fragile LiveView selectors in tests | Tests assert text only or unstable HTML details | Use stable element ids and selector-based assertions | Refactor templates to include deterministic ids and update tests |

### Weekly Health Checks
- Run: mix test
- Run: mix test --failed
- Run: mix precommit
- Review routes for accidental exposure: mix phx.routes

### Pre-PR Safety Checklist
- Authorization checks verified on all seller and buyer mutations.
- Transaction boundaries audited for checkout-related writes.
- DB constraints and indexes exist for ownership and uniqueness assumptions.
- Error states are user-safe (no crash, clear message, no partial commit).
