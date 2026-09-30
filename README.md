# ⚡ 3x-ui Custom Sub Modifier & Smart Router

A highly optimized, cross-platform subscription management system designed specifically for **3x-ui** panels. It acts as an intelligent middleware, modifying subscription configurations on-the-fly to bypass DPI, inject fragments, and enforce cipher suites based on specific keywords, all while dynamically adapting to the user's client app.

## ✨ Key Features

* **🧠 Smart Router (All-in-One Link):** Share just one link with your users! The built-in dispatcher detects the client (`v2rayN`, `V2box`, `happ`, `PattN`, `NPV`, etc.) and automatically serves the correct format (JSON or Base64) with the optimal routing rules.
* **🛡️ DPI Bypass Engine (Finalmask):** Automatically injects advanced fragment rules into your outbound proxy connections to evade Deep Packet Inspection. Includes both **Standard** and **Hybrid** schemas to support strict Sing-box cores.
* **🔒 Cipher Suites Override:** Enforces secure and specific TLS cipher suites to mask traffic fingerprints.
* **🌐 Browser Protection:** Displays a modern, beautifully designed Persian warning page if a user attempts to open the sub link in a web browser, preventing configuration loops.
* **🔄 Built-in Version Manager:** Easily update to the latest GitHub release or fallback to stable tags using the built-in CLI tool.

---

## 🚀 Installation

Run the following command as `root` on your Ubuntu server:
```bash
bash <(curl -Ls https://raw.githubusercontent.com/tinydev128/sub-modifier/main/install.sh)
```

During the initial installation, you will be prompted to choose between the **Latest Version (Main Branch)** or a **Specific Stable Release (Tags)**.

---

## ⚙️ Architecture & How It Works

The system deploys multiple lightweight Flask applications managed by Gunicorn. The Master Port acts as a reverse proxy, parsing the `User-Agent` and routing the request to the appropriate backend service:

1. **Master Port (Default: 8000):** The smart, HTTPS-enabled dispatcher.
2. **Port 5000 (Service 1):** Primary service serving Standard JSON for `v2rayN` and raw Base64 for `PattNG`.
3. **Port 5800 (Service 2):** Dedicated SniSpoof profile tailored specifically for `V2box`.
4. **Port 5801 (Service 3):** Strict fallback with the Xray `vnext` schema.
5. **Port 5802 (Service 4):** Universal Fallback with a **Hybrid Fragment Engine** to prevent parsing crashes in strict cores like `NPV` and `happ`.

*Note: Unmodified configurations (without your specified keywords) remain completely intact, ensuring that custom setups like Reality or specific Tunnels are never disrupted.*

---

## 💻 CLI Usage & Management

After installation, simply type the following command in your terminal at any time to access the interactive management menu:

sub-modifier

**From the interactive menu, you can:**
* Modify your panel's base URL, target keywords, spoof IP, and internal ports instantly.
* Switch between different Finalmask profiles (New/Old).
* Change or update the script version directly from GitHub releases.
* Check the live status of all Python services and monitor RAM usage.
* Completely uninstall the tool and clean up your server.

---

## ⚠️ Prerequisites
1. **JSON Subscription** must be enabled in your 3x-ui panel settings.
2. You need a valid SSL certificate (Fullchain and Privkey) for the HTTPS-enabled Smart Router.
