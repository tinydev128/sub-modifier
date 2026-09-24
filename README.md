# 3x-ui Custom Sub Server Manager

An automated bash script that sets up an advanced subscription modification server for 3x-ui panels. This tool deploys three robust Python-based services (running via Gunicorn) that dynamically modify your 3x-ui subscription configs by applying custom Fragments (Finalmask), CipherSuites, and SniSpoof configurations based on specific keywords.

## ⚠️ Prerequisites & Usage Notes

Before using this tool, please keep the following rules in mind to ensure everything works correctly:

1. **JSON Subscription Must Be Enabled:** Ensure you have navigated to your 3x-ui panel settings and enabled the **JSON Subscription** feature. The `/json/` paths will not work without it.
2. **Sub Base URL Binding:** If you input `127.0.0.1` (e.g., `https://127.0.0.1:2020`) as your Sub Base URL during setup, your 3x-ui panel's subscription service must be configured to listen on that exact IP address.
3. **How to Use the Links:** To provide the modified subscription to your clients, take your original subscription link and replace the port with the modified ones, OR map them as a reverse proxy directly in the panel.
   - *Example:* If your original JSON sub is `https://8.8.8.8:2020/json/MyKey`, it should become `https://8.8.8.8:5000/json/MyKey` (for Port 5000 JSON).

## 🚀 Features

- **Automated Deployment:** Installs all dependencies (Python3, Flask, Gunicorn, iptables-persistent) and configures systemd services automatically.
- **Interactive CLI:** Accessible via the `sub-modifier` command on your terminal for easy setup, updates, and uninstallation.
- **Dynamic Configuration Injection:** Applies modifications only to configs whose remarks contain your predefined keywords.
- **Load Balancer Support:** Correctly processes nested load balancer configurations (e.g., tags starting with `bal-`).
- **Gunicorn Integration:** Ensures high availability and prevents server freezes from malicious scanners.

## 📌 Architecture & Client Routing

| Port | Path | Profile Type | Target Client(s) | Description |
| :---: | :---: | :--- | :--- | :--- |
| **5000** | `/sub/...` | Base64 URI | **PattNG / PattN** | Direct base64 URI sub with injected `fm` and `cs` query parameters. |
| **5000** | `/json/...` | Standard JSON | **v2rayN / v2rayNG** | Streamlined JSON config stripped of regional bloatware. |
| **5800** | `/json/...` | SniSpoof Profile | **V2box** | Isolates SNI spoofing; eliminates fragment/cipher conflicts. |
| **5801** | `/json/...` | Strict Fallback | **Strict Xray Clients** | Strict standard Xray schema (`vnext` array formatting). |
| **5802** | `/json/...` | **🛡️ Universal Fallback** | **All Incompatible Clients / NPV Tunnel** | **Universal hybrid fallback.** Resolves core parsing failures and parser rejections. |

## 🛠 Installation

Run the following command on your server:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/tinydev128/sub-modifier/main/install.sh)
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

## 📬 Contact

If you have any questions, suggestions, or need support regarding this project, feel free to reach out:

- **Email:** [omartinydev128@atomicmail.io](mailto:omartinydev128@atomicmail.io)
- **GitHub:** [@tinydev128](https://github.com/tinydev128)

## 📜 License
This project is licensed under the MIT License. See the LICENSE file for details.
