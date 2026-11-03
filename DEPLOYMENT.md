# Deployment contract

The container exposes port `3000` and serves an unauthenticated `GET /health` endpoint. Configure the deployment health path as `/health`. The bot itself uses Telegram long polling, so no public webhook URL is required.

Use the environment variables documented in `README.md`, including `BTC_WALLET_ADDRESS` and `LTC_WALLET_ADDRESS`. Confirmation defaults are one block for BTC and six blocks for LTC. For continuous polling, select an always-on or reserved hosting mode if available. If the platform requires a membership confirmation for that mode, complete the platform confirmation before publishing.

After publication, set `MINI_APP_URL` to the public `/miniapp` URL and `ADMIN_APP_URL` to the public `/admin-dashboard` URL, then restart the container. Telegram WebApp initData is validated server-side; the admin dashboard additionally checks the configured admin Telegram ID. Product uploads are validated as images and limited to 5 MB.
