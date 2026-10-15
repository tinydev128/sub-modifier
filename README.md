# ⚡ 3x-ui Custom Sub Modifier & Smart Router

A highly optimized, multi-threaded subscription management middleware designed specifically for **3x-ui** panels. It acts as an intelligent proxy, modifying subscription configurations on-the-fly to bypass DPI, inject fragments, and enforce cipher suites based on specific keywords, all while dynamically adapting to the user's client app.

## ✨ Key Features

* **🧠 True Smart Router:** Share just one link with your users! The built-in dispatcher detects the client (`v2rayN`, `V2box`, `happ`, `PattNG`, `PattN`, `Flclash`, `NPV`, etc.) and automatically serves the correct format (**JSON, Base64, or YAML**) with optimal routing rules.
* **⚡ Zero-Latency Architecture:** Say goodbye to nested routing deadlocks! Powered by a multi-threaded Gunicorn backend, a single unified master service handles all traffic natively, dropping RAM usage to under 80MB while delivering sub-50ms response times.
* **🛡️ Custom Security Paths:** Protect your server from active probing! Define custom paths for both your 3x-ui panel and the router app, breaking away from standard, easily scannable `/sub/` or `/json/` endpoints.
* **🧱 DPI Bypass Engine (Finalmask):** Automatically injects advanced fragment rules to evade Deep Packet Inspection. Includes Standard schemas for Xray, Hybrid schemas for strict Sing-box cores, and native `fragment` objects for Mihomo/Clash.
* **🌐 Minimalist Web Dashboard:** If a user opens the link in a browser, they are greeted with an ultra-fast, beautifully designed 1-Click App Installer. It features auto Dark/Light mode and dynamically fetches your live **3x-ui Announcements** in real-time.
* **🔄 Built-in Version Manager:** Easily update to the latest GitHub release or rollback to stable tags using the built-in CLI tool.

---

## 🚀 Installation

Run the following command as `root` on your Ubuntu server:

```bash
sudo bash <(curl -Ls https://raw.githubusercontent.com/tinydev128/sub-modifier/main/install.sh)

```

During the initial installation, you will be prompted to choose between the **Latest Version (Main Branch)** or a **Specific Stable Release (Tags)**.

---

## ⚙️ Architecture & How It Works

The system deploys a single, highly efficient Flask application managed by Gunicorn (`app_master.py`). This Master Service acts as an intelligent reverse proxy, parsing the `User-Agent` and the `Accept` headers to dynamically modify and return configurations:

1. **PattN / PattNG Clients:** Isolated through strict regex matching. Receives **Base64 + Standard Fragment** configs to maintain compatibility.
2. **Clash / Flclash / Mihomo:** Automatically detected and served native **YAML** configurations with injected `fragment` objects and `client-fingerprint: chrome`.
3. **v2rayN, Happ, V2box, NPV, Incy:** Routed to the universal **JSON + Hybrid Fragment** schema, preventing parsing crashes in strict cores.
4. **Browsers:** Blocked from raw config access and seamlessly served the Zero-Latency HTML Dashboard.

*Note: The master service can natively bind to legacy ports (`5000`, `5800`, `5801`, `5802`, `5803`) alongside the main port (`8000`), ensuring that upgrading will not break existing user subscriptions.*

---

## 💻 CLI Usage & Management

After installation, simply type the following command in your terminal at any time to access the interactive management menu:

```bash
sub-modifier

```

**From the interactive menu, you can:**

* Modify your panel's base URL, target keywords, custom security paths, and internal ports instantly.
* Switch between different Finalmask profiles (New/Old).
* Change or update the script version directly from GitHub releases.
* Check the live status of the Python service and monitor RAM usage.
* View client recommendations and usage guides.
* Completely uninstall the tool and clean up your server.

---

## ⚠️ Prerequisites

1. **JSON Subscription** must be enabled in your 3x-ui panel settings.
2. You need a valid SSL certificate (Fullchain and Privkey) for the HTTPS-enabled Smart Router.
