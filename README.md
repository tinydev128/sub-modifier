# Sub-Modifier
An automated tool to dynamically modify 3x-ui subscriptions. Injects custom Fragments, CipherSuites, and SniSpoof configurations for advanced Xray clients.

# 3x-ui Custom Sub Server Manager

An automated bash script that sets up an advanced subscription modification server for 3x-ui panels. This tool deploys three robust Python-based services (running via Gunicorn) that dynamically modify your 3x-ui subscription configs by applying custom Fragments (Finalmask), CipherSuites, and SniSpoof configurations based on specific keywords.

## 🚀 Features

- **Automated Deployment:** Installs all dependencies (Python3, Flask, Gunicorn, iptables-persistent) and configures systemd services automatically.
- **Interactive CLI:** Accessible via the `sub-modifier` command on your terminal for easy setup, updates, and uninstallation.
- **Dynamic Configuration Injection:** Applies modifications only to configs whose remarks contain your predefined keywords.
- **Load Balancer Support:** Correctly processes nested load balancer configurations (e.g., tags starting with `bal-`).
- **Gunicorn Integration:** Ensures high availability and prevents server freezes from malicious scanners.

## 📦 Services Deployed

The script runs three separate services on different ports to accommodate various client applications:

1. **Service 1 (Default Port: 5000): Minimal Structure + Finalmask + CipherSuites**
   - **Path `/sub/...`:** Recommended for **PattNG**.
   - **Path `/json/...`:** Recommended for **v2rayN / v2rayNG**.
2. **Service 2 (Default Port: 5800): SniSpoof ONLY**
   - Strips finalmask and custom ciphers, applies a standard Xray structure.
   - **Path `/json/...`:** Recommended for **V2box**.
3. **Service 3 (Default Port: 5801): Standard Structure + Finalmask + CipherSuites (NO SniSpoof)**
   - Acts as a reliable fallback alternative for clients that fail on Service 1's minimal structure.

## 🛠 Installation

Run the following command on your server:

```bash
sudo curl -Ls https://raw.githubusercontent.com/tinydev128/sub-modifier/main/install.sh | sudo bash
```

### During installation, you will be prompted to provide:

🌐Your 3x-ui Panel URL (e.g., https://127.0.0.1:2020).

➿Comma-separated keywords (e.g., CFCDN,CFXCDN,CDN Best).

〰️The SniSpoof IP (e.g., 104.19.230.21).

🌐Paths to your SSL certificate (fullchain.pem) and private key (privkey.pem).

🌐Preferred ports for the three services.

## ⚙️ Management
Once installed, you can launch the interactive management menu at any time by simply typing:

```bash
sudo sub-modifier
```

### The menu allows you to:

🔘Update your configurations (Panel URL, keywords, ports, etc.).

🔘View the client usage guide.

❌Completely uninstall the tool from your server.

## 📜 License
This project is licensed under the MIT License. See the LICENSE file for details.
