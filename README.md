# TON Shop Bot

A standalone Telegram ecommerce bot for physical products, built with Python and aiogram 3. It is a chat bot only; it does not use a Telegram Mini App.

## Configure from an iPhone

The project reads these values at runtime and never writes them to source files:

- `TELEGRAM_BOT_TOKEN`: the token from BotFather for your existing bot.
- `ADMIN_TELEGRAM_ID`: your numeric Telegram user ID. This is not a username.
- `TON_WALLET_ADDRESS`: merchant TON wallet.
- `BTC_WALLET_ADDRESS`: merchant Bitcoin wallet.
- `LTC_WALLET_ADDRESS`: merchant Litecoin wallet.
- `TONCENTER_API_KEY`: optional TON Center API key for higher TON API limits.

The BTC and LTC wallets are now stored in the secure project configuration flow. If either wallet is missing, that payment method is hidden from checkout. Never paste wallet values, tokens, or API keys into Telegram, GitHub, `config.py`, Dockerfile, `.env.example`, or this README.

For local development, copy `.env.example` to `.env`, fill in the same variable names, and keep the file uncommitted. For cloud deployment, use the target host's secret/environment-variable settings.

## Market verification phrase

Each customer can create a personal phrase with `/setphrase`. The bot stores a salted verification hash plus an encrypted copy needed to display the phrase later; the phrase is not logged or stored as plaintext. Use `/verify_market` in this bot to display it and compare it with the phrase you created. If a different bot, website, or “support agent” asks you for the phrase, do not provide it.

This is an anti-clone signal, not a replacement for checking identity. Before trusting the phrase, verify that the chat is with the exact official Telegram bot username/profile you originally opened through BotFather. A scam bot cannot know a phrase that you never disclose, but anyone who sees the phrase can copy it. Do not reuse the phrase as a password, wallet seed, recovery phrase, or payment reference. If the protected BotFather token is rotated, existing encrypted phrases cannot be decrypted; users should create new phrases with `/setphrase`.

## BotFather setup

1. Open Telegram and open the existing BotFather bot.
2. Use `/setcommands` and enter:

```text
start - Open the shop
shop - Browse products
cart - View your cart
orders - Order history
help - Help
setphrase - Set your market security phrase
verify_market - Show your market security phrase
cancel - Cancel the current action
admin - Admin panel
```

The application also sets the command menu on startup. BotFather is only needed if you want the menu visible before the first successful deployment.

## Telegram Mini App and admin dashboard

The project now includes a customer Mini App at `/miniapp` and a protected administrator dashboard at `/admin-dashboard`. Both use the same SQLite database and the same verified payment service as the Telegram bot. The Mini App validates Telegram `initData` server-side using the bot token; the admin API additionally requires the configured `ADMIN_TELEGRAM_ID`. Frontend permissions are never trusted.

After the container has a public HTTPS URL, set `MINI_APP_URL=https://YOUR-DOMAIN/miniapp` and `ADMIN_APP_URL=https://YOUR-DOMAIN/admin-dashboard` in the deployment secret/environment settings, then restart the bot. `/start` shows the customer launch button and `/admin` shows the administrator launch button. The dashboard supports product edits, inventory, active/featured flags, category creation/renaming, and image upload; CSV remains available for bulk operations.

The customer Mini App includes dedicated Featured Products and New Arrivals sections, product-detail panels with image, description, price, stock, quantity selection, basket actions, and persistent per-user wishlists. Wishlist state is authenticated through Telegram initData and stored in SQLite rather than browser-only storage.

## Editing the bot from the admin dashboard

Open `/admin-dashboard` from the configured administrator Telegram account and choose **Bot content & menu**. You can edit the `/start` welcome copy, `/help` copy, customer shop launch-button label, administrator dashboard-button label, and every visible Telegram command description. Saving applies the copy immediately and updates Telegram’s command menu through the live bot session. The editor deliberately cannot change the bot token, admin ID, payment wallets, blockchain API settings, or payment-verification rules; those remain protected environment configuration.

## Product administration

Send `/admin` from the configured admin account. Use **Add product** and enter the requested fields in one message separated by `|`:

```text
Canvas Tote | Heavy cotton tote bag | 24.99 | 12 | https://example.com/tote.jpg
```

The fields are name, description, price in GBP, stock quantity, and image URL. Enter GBP as a normal decimal amount, for example `24.99`. To edit an item, send `/admin_edit PRODUCT_ID` and enter the same five fields. To delete an item, send `/admin_delete PRODUCT_ID`. To set inventory, send `/admin_stock PRODUCT_ID QUANTITY`.

On first startup, the bot seeds a database-backed editable catalogue containing **20 categories, 60 subcategories, and 240 clearly labelled placeholder products**. Placeholder SKUs use the `PLACE-####` format and placeholder images use an emerald-and-gold image URL. Customers browse root categories, then subcategories, then active products. Products are never hardcoded inside Telegram handlers.

Use `/admin_export` to download the current catalogue as CSV, `/admin_template` to download a safe import template, and `/admin_import` followed by a CSV upload to update or add products. Rows are matched by SKU. The CSV columns are `sku`, `name`, `description`, `category`, `subcategory`, `price_gbp`, `stock`, `image_url`, `active`, and `featured`. Set `active` or `featured` to `0` or `1`. Use `/admin_category_add CATEGORY | optional parent category` and `/admin_category_rename CATEGORY_ID New Name` to manage categories. This makes the complete catalogue editable without changing Python code.

## Payment methods and quote behavior

Customers see catalogue, product, and basket prices in GBP. No crypto amount is displayed before checkout. After the customer chooses TON, Bitcoin, or Litecoin and submits the delivery address, the bot obtains a live GBP-to-crypto quote, displays the exact amount for the selected network, adds a small atomic-unit discriminator for BTC/LTC order association, and locks the quote for 15 minutes. The customer must send the exact displayed amount on the matching network.

BTC payments require at least `BTC_REQUIRED_CONFIRMATIONS` confirmations, defaulting to 1. LTC payments require at least `LTC_REQUIRED_CONFIRMATIONS`, defaulting to 6. Adjust these environment values if your risk policy requires more confirmations.

## Payment safety

A submitted transaction ID is only a lookup hint. The bot never trusts it by itself.

For TON, the verifier queries TON Center v3 and checks the configured destination wallet, exact nanoTON amount, successful/non-bounced execution, masterchain finality, and the order reference in the transfer comment.

For Bitcoin and Litecoin, the verifier queries the configured public explorer API and checks the transaction ID, confirmed status, current block height, required confirmation count, and the sum of outputs paid to the configured merchant wallet. It also checks the exact order-specific atomic amount. Standard BTC/LTC payments do not reliably carry a wallet-visible memo, so the unique exact amount is used for order association. The database rejects reuse of a verified transaction ID.

A background monitor checks pending orders automatically. Only after the relevant blockchain checks pass does the bot mark an order paid and deduct stock.

## Run locally

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -e .
cp .env.example .env
# Fill .env locally; never commit it.
python -m app.main
```

The health endpoint listens on `PORT` (default `3000`) and returns `OK` at `/health` while Telegram long polling runs in the same process.

## Deploy

The repository includes `Dockerfile`. Configure the environment values in the target host's secret manager, then build and run the image. For Manus WebDev, the project is prepared for a server/container publish. Choose an always-on/reserved hosting mode for continuous polling if your account supports it; otherwise an on-demand deployment can sleep and is not suitable for reliable polling.

### SQLite durability note

SQLite is implemented because it is a requested requirement. Published container filesystems can be replaced during redeploys or restarts, so a production shop should periodically back up `data/shop.db` or move to a durable mounted volume/managed database before taking significant order volume. Always-on hosting reduces idle stops but is not itself a filesystem durability guarantee.

## Security notes

Logs contain order IDs and statuses, not bot tokens, wallet secrets, API keys, raw payment bodies, or full customer addresses. The admin guard compares Telegram numeric IDs. Payment status transitions are performed only by the verifier after blockchain checks; there is no manual “mark paid” control.
