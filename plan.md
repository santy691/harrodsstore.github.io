# TON Shop Bot implementation plan

## Scope and architecture

This project is a standalone Telegram chat bot, not a Telegram Mini App. It uses Python 3.11+, aiogram 3, aiosqlite, and an SQLite database. Telegram handlers are split into customer and admin routers. The repository layer owns all SQL and transaction boundaries. TON payments use the TON Center v3 indexed API and independently check the submitted transaction against the configured recipient wallet, exact nanoTON amount, successful execution, non-bounced inbound message, and masterchain finality. Bitcoin and Litecoin payments use live TON/BTC/LTC quotes, order-specific atomic amounts, Mempool.space/Litecoin Space transaction output checks, and configurable confirmation thresholds. A submitted transaction ID is never treated as proof on its own.
Catalogue and basket prices are stored as GBP pence. Crypto is not used for product pricing or displayed in the catalogue; only after payment-method selection at checkout does the quote service convert the GBP total into an exact TON, BTC, or LTC atomic amount with an expiry.
The catalogue is database-backed: categories support parent/child subcategories, products carry SKU/category/image/active/featured metadata, and a one-time seed creates 20 categories, 60 subcategories, and 240 editable placeholders. Customer navigation reads categories and products from SQLite. Admin CSV export/import is matched by SKU so the catalogue can be customized without handler changes.
The approved architecture is hybrid: the existing Telegram bot remains the operational backend and notification/payment monitor, while aiohttp serves `/miniapp`, `/admin-dashboard`, and protected JSON APIs from the same process and database. Telegram WebApp initData is HMAC-validated with the bot token, and admin API requests additionally compare the authenticated Telegram ID with `ADMIN_TELEGRAM_ID`.
Each customer can create a personal anti-clone market phrase. The bot stores a salted scrypt verification hash and an encrypted copy keyed from the protected BotFather token, exposes `/setphrase` and `/verify_market`, and explicitly instructs customers to compare the phrase only after checking the exact official Telegram bot identity. The phrase is never logged or requested by support/payment flows.

A small aiohttp health server listens on `PORT` so the container can satisfy the deployment health check while aiogram runs long polling in the same process. `Dockerfile` is the production entrypoint. SQLite is stored at `data/shop.db`; the database is initialized on boot and all order and inventory mutations are serialized with `BEGIN IMMEDIATE` transactions.

Secure runtime values are injected only through environment variables: `TELEGRAM_BOT_TOKEN`, `ADMIN_TELEGRAM_ID`, `TON_WALLET_ADDRESS`, and optional `TONCENTER_API_KEY`. No credentials are placed in source, `.env.example`, Git, or logs.

## Project structure

- `app/main.py`: boot, Telegram command menu, health server, polling, and payment monitor.
- `app/config.py`: validated environment settings.
- `app/db.py`: SQLite schema, catalogue, cart, order, inventory, and admin operations.
- `app/ton.py`: TON Center v3 client and TON verification rules.
- `app/crypto.py`: live crypto quotes, BTC/LTC explorer clients, and multi-chain payment dispatch.
- `app/security.py`: phrase normalization, salted hashing, and encrypted-at-rest market phrase helpers.
- `app/keyboards.py`: concise inline keyboard layouts.
- `app/states.py`: checkout, payment, and admin FSM states.
- `app/handlers/user.py`: catalogue, cart, checkout, payment submission, order history, and tracking.
- `app/handlers/admin.py`: admin-only catalogue, inventory, and order controls.
- `docs/ton-payment-verification.md`: API evidence and verification invariants.
- `Dockerfile`: reproducible cloud container.

## Interface/design direction

Three possible visual directions were considered: Terminal Ledger (0.06), Quiet Commerce (0.04), and Neon Wallet (0.02). The chosen direction is **Quiet Commerce**.

- **Design movement:** quiet luxury retail translated into a compact Telegram conversation.
- **Core principles:** one clear action per message, generous line spacing, terse labels, and no decorative clutter.
- **Color philosophy:** Telegram's native theme does the coloring; text uses restrained symbols and consistent hierarchy so it remains legible in light and dark mode.
- **Layout paradigm:** catalogues are linear, with each product detail as a focused message and inline controls below it rather than dense grids.
- **Signature elements:** short section labels, TON amounts displayed with the TON symbol, and stock/payment status chips.
- **Interaction philosophy:** every state-changing action has a visible result, stock limits are enforced before checkout, and payment status is explicit.
- **Animation:** none is required; the bot should feel immediate and dependable.
- **Typography system:** Telegram's native font, with bold headings and compact secondary text.
- **Brand essence:** a dependable, low-friction way to buy physical goods in Telegram; calm, precise, transparent.
- **Brand voice:** direct and reassuring. Example lines: “Choose an item. We will reserve stock only when checkout is confirmed.” and “Payment is being verified on-chain. We will notify you when it is final.”
- **Wordmark/mark:** the text label `TON SHOP` plus a simple TON diamond symbol in section headings.
- **Signature brand color:** TON blue is referenced only through the currency and wallet context; no custom web palette is required.

## Deployment choice

The project is prepared as a WebDev server container with a health endpoint and a persistent-process-compatible polling entrypoint. Reserved/always-on hosting is the appropriate mode for continuous polling, but it may require the owner's membership confirmation. SQLite satisfies the requested database technology; because published container filesystems are ephemeral, the README calls out the operational risk and recommends a persistent VM or an external durable database before high-volume production use.
