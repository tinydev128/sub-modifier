#!/bin/bash

CONFIG_DIR="/opt/sub_server"
CONFIG_FILE="${CONFIG_DIR}/config.env"

SUB_BASE_URL="https://127.0.0.1:2020"
KEYWORDS="CFCDN,CFXCDN,CDN Best"
SPOOF_IP="104.19.230.21"
CERT_PATH="/root/cert/ip/fullchain.pem"
KEY_PATH="/root/cert/ip/privkey.pem"
PORT1="5000"
PORT2="5800"
PORT3="5801"
PORT4="5802"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

function show_recommendations() {
    echo -e "\n\e[32m=================================================\e[0m"
    echo -e "\e[32m             CLIENT USAGE GUIDE                  \e[0m"
    echo -e "\e[32m=================================================\e[0m"
    echo -e "\n\e[31m⚠️ IMPORTANT USAGE NOTE:\e[0m"
    echo -e "To use these links, replace your original subscription port with the ones below."
    echo -e "Example: If your original JSON sub is '8.8.8.8:2020/json/...',"
    echo -e "it should become '8.8.8.8:${PORT1}/json/...' (for Service 1)."
    echo -e "Alternatively, you can set these as a reverse proxy in your panel."
    
    echo -e "\n\e[33m📌 Port ${PORT1} (Path: /sub/...)\e[0m"
    echo -e "   ↳ \e[36mRecommended for: PattNG\e[0m"
    echo -e "\n\e[33m📌 Port ${PORT1} (Path: /json/...)\e[0m"
    echo -e "   ↳ \e[36mRecommended for: v2rayN / v2rayNG\e[0m"
    echo -e "\n\e[33m📌 Port ${PORT2} (Path: /json/...)\e[0m"
    echo -e "   ↳ \e[36mSniSpoof ONLY - Recommended for V2box\e[0m"
    echo -e "\n\e[33m📌 Port ${PORT3} (Path: /json/...)\e[0m"
    echo -e "   ↳ \e[36mFallback (Strict Xray Structure + FM/CS) for clients failing on Port ${PORT1}\e[0m"
    echo -e "\n\e[33m📌 Port ${PORT4} (Path: /json/... ONLY)\e[0m"
    echo -e "   ↳ \e[36mNPV Tunnel Optimized (Hybrid Finalmask + CipherSuites)\e[0m"
    echo -e "\n\e[32m=================================================\e[0m\n"
}

function install_update() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "\e[36m              SUB SERVER CONFIGURATION             \e[0m"
    echo -e "\e[36m=================================================\e[0m\n"
    
    echo -e "\e[31m⚠️ PREREQUISITES:\e[0m"
    echo -e "1. 'JSON Subscription' MUST be enabled in your 3x-ui panel settings."
    echo -e "2. If you set Sub Base URL to 127.0.0.1, ensure your panel listens on that IP.\n"

    echo -e "\e[33m[ Hint: Press Enter to keep the default value in brackets ]\e[0m\n"
    
    read -p "Enter Sub Base URL [$SUB_BASE_URL]: " input </dev/tty; SUB_BASE_URL=${input:-$SUB_BASE_URL}
    read -p "Enter Target Keywords [$KEYWORDS]: " input </dev/tty; KEYWORDS=${input:-$KEYWORDS}
    read -p "Enter Spoof IP [$SPOOF_IP]: " input </dev/tty; SPOOF_IP=${input:-$SPOOF_IP}
    read -p "Enter SSL Fullchain Path [$CERT_PATH]: " input </dev/tty; CERT_PATH=${input:-$CERT_PATH}
    read -p "Enter SSL Privkey Path [$KEY_PATH]: " input </dev/tty; KEY_PATH=${input:-$KEY_PATH}

    echo -e "\n\e[36m================ PORT CONFIGURATION ================\e[0m"
    
    echo -e "\n\e[32mService 1:\e[0m Minimal DNS/Routing + Finalmask + CipherSuites"
    echo -e " 💡 \e[90m(Path /sub/ recommended for PattNG, /json/ for v2rayN/v2rayNG)\e[0m"
    read -p "🔗 Enter port for Service 1 [$PORT1]: " input </dev/tty; PORT1=${input:-$PORT1}

    echo -e "\n\e[32mService 2:\e[0m Minimal DNS/Routing + SniSpoof ONLY (No fragment/ciphers)"
    echo -e " 💡 \e[90m(Path /json/ recommended for V2box)\e[0m"
    read -p "🔗 Enter port for Service 2 [$PORT2]: " input </dev/tty; PORT2=${input:-$PORT2}

    echo -e "\n\e[32mService 3:\e[0m Minimal DNS/Routing + Strict Xray Format + Finalmask + CipherSuites (NO SniSpoof)"
    echo -e " 💡 \e[90m(Fallback option for strict clients that fail on Service 1)\e[0m"
    read -p "🔗 Enter port for Service 3 [$PORT3]: " input </dev/tty; PORT3=${input:-$PORT3}

    echo -e "\n\e[32mService 4:\e[0m NPV Tunnel Optimized (Hybrid Finalmask + CipherSuites)"
    echo -e " 💡 \e[90m(Specifically designed to bypass the 'LengthMin can't be 0' error in NPV Tunnel)\e[0m"
    read -p "🔗 Enter port for Service 4 [$PORT4]: " input </dev/tty; PORT4=${input:-$PORT4}

    mkdir -p "$CONFIG_DIR"
    cat <<EOF > "$CONFIG_FILE"
SUB_BASE_URL="$SUB_BASE_URL"
KEYWORDS="$KEYWORDS"
SPOOF_IP="$SPOOF_IP"
CERT_PATH="$CERT_PATH"
KEY_PATH="$KEY_PATH"
PORT1="$PORT1"
PORT2="$PORT2"
PORT3="$PORT3"
PORT4="$PORT4"
EOF

    echo -e "\n\e[33m[+] Installing Dependencies...\e[0m"
    apt update -y >/dev/null 2>&1
    apt install -y python3-pip iptables-persistent >/dev/null 2>&1
    pip3 install Flask requests gunicorn urllib3 --break-system-packages >/dev/null 2>&1 || pip3 install Flask requests gunicorn urllib3 >/dev/null 2>&1

    echo -e "\e[33m[+] Generating Python Scripts & Services...\e[0m"
    
    FORMATTED_KEYWORDS=$(echo "$KEYWORDS" | sed 's/,/","/g')
    TARGET_PY="[\"$FORMATTED_KEYWORDS\"]"

    # ================== SERVICE 1 (MINIMAL + FM + CS) ==================
    cat << 'EOF' > /opt/sub_server/app_1.py
from flask import Flask, jsonify, request, make_response
import requests, copy, urllib3, base64, urllib.parse, json
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "__SUB_BASE_URL__"
TARGET_KEYWORDS = __TARGET_KEYWORDS__
CIPHER_SUITES = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
FINALMASK_TCP = [{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355"}}]
MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}
def process_json_config(config):
    if not any(k in config.get("remarks", "") for k in TARGET_KEYWORDS): return config
    config["dns"] = copy.deepcopy(MINIMAL_DNS)
    config["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
    if "balancers" not in config.get("routing", {}): config["routing"] = copy.deepcopy(MINIMAL_ROUTING_PROXY)
    for out in config.get("outbounds", []):
        if out.get("protocol") == "vless":
            stream = out.get("streamSettings", {})
            stream["finalmask"] = {"tcp": FINALMASK_TCP}
            tls = stream.get("tlsSettings", {})
            tls["cipherSuites"] = CIPHER_SUITES
            tls["fingerprint"] = "unsafe"
            stream["tlsSettings"] = tls
            out["streamSettings"] = stream
    return config
@app.route('/json/<path:sub_path>')
def dynamic_json_sub(sub_path):
    try:
        resp = requests.get(f"{SUB_BASE_URL}/json/{sub_path}?view=raw", verify=False, timeout=10)
        data = resp.json()
        mod_data = [process_json_config(cfg) for cfg in data] if isinstance(data, list) else process_json_config(data) if isinstance(data, dict) else data
        return jsonify(mod_data)
    except Exception as e: return jsonify({"error": str(e)}), 500
def process_uri_config(uri):
    if not uri.startswith("vless://"): return uri
    try:
        b_url, rem = uri.split("#", 1)
        if not any(k in urllib.parse.unquote(rem) for k in TARGET_KEYWORDS): return uri
        hp, qp = b_url.split("?", 1) if "?" in b_url else (b_url, "")
        params = dict(urllib.parse.parse_qsl(qp))
        params.update({"fp": "unsafe", "cs": CIPHER_SUITES, "fm": json.dumps({"tcp": FINALMASK_TCP}), "allowInsecure": "0", "insecure": "0"})
        new_q = urllib.parse.urlencode(params, quote_via=urllib.parse.quote)
        return f"{hp}?{new_q}#{rem}"
    except: return uri
@app.route('/sub/<path:sub_path>')
def dynamic_uri_sub(sub_path):
    try:
        resp = requests.get(f"{SUB_BASE_URL}/sub/{sub_path}", headers={"User-Agent": "v2rayN/6.42"}, verify=False, timeout=10)
        raw = resp.text.strip()
        raw += '=' * (-len(raw) % 4)
        try: dec = base64.b64decode(raw).decode('utf-8')
        except: dec = resp.text
        mod = [process_uri_config(l.strip()) for l in dec.split('\n') if l.strip()]
        res = make_response(base64.b64encode('\n'.join(mod).encode('utf-8')).decode('utf-8'))
        res.headers['Content-Type'] = 'text/plain; charset=utf-8'
        return res
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # ================== SERVICE 2 (MINIMAL + SNISPOOF ONLY) ==================
    cat << 'EOF' > /opt/sub_server/app_2.py
from flask import Flask, jsonify, request
import requests, copy, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "__SUB_BASE_URL__"
TARGET_KEYWORDS = __TARGET_KEYWORDS__
SPOOF_IP = "__SPOOF_IP__"
MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}
def process_cfg(cfg):
    if not any(k in cfg.get("remarks", "") for k in TARGET_KEYWORDS): return cfg
    cfg["dns"] = copy.deepcopy(MINIMAL_DNS)
    cfg["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
    if "balancers" not in cfg.get("routing", {}): cfg["routing"] = copy.deepcopy(MINIMAL_ROUTING_PROXY)
    for out in cfg.get("outbounds", []):
        tag = out.get("tag", "")
        if tag == "proxy" or tag.startswith("bal-"):
            out["mux"] = {"concurrency": -1, "enabled": False}
            out.pop("sniSpoof", None)
            old = out.get("settings", {})
            if "address" in old: out["settings"] = {"vnext": [{"address": old.get("address"), "port": old.get("port"), "users": [{"encryption": old.get("encryption", "none"), "flow": old.get("flow", ""), "id": old.get("id"), "level": old.get("level", 8)}]}]}
            out["sniSpoof"] = {"active": True, "fakeSni": "hcaptcha.com", "spoofIp": SPOOF_IP, "targetPort": 443}
            st = out.get("streamSettings", {})
            st.pop("finalmask", None)
            if "tlsSettings" in st:
                st["tlsSettings"].pop("cipherSuites", None); st["tlsSettings"].pop("alpn", None)
                st["tlsSettings"].update({"allowInsecure": False, "show": False, "fingerprint": "chrome"})
            if "wsSettings" in st:
                h = st["wsSettings"].pop("host", None); st["wsSettings"].pop("heartbeatPeriod", None)
                st["wsSettings"]["headers"] = {"Host": h} if h else {}
            out["streamSettings"] = st
        elif tag == "direct": out["settings"] = {"domainStrategy": "UseIP"}
    return cfg
@app.route('/json/<path:sub_path>')
def dyn(sub_path):
    try:
        data = requests.get(f"{SUB_BASE_URL}/json/{sub_path}?view=raw", verify=False, timeout=10).json()
        mod = [process_cfg(c) for c in data] if isinstance(data, list) else process_cfg(data) if isinstance(data, dict) else data
        return jsonify(mod)
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # ================== SERVICE 3 (MINIMAL + STRICT XRAY + FM + CS) ==================
    cat << 'EOF' > /opt/sub_server/app_3.py
from flask import Flask, jsonify, request
import requests, copy, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "__SUB_BASE_URL__"
TARGET_KEYWORDS = __TARGET_KEYWORDS__
CIPHER_SUITES = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
FINALMASK_TCP = [{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355"}}]
MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}
def process_cfg(cfg):
    if not any(k in cfg.get("remarks", "") for k in TARGET_KEYWORDS): return cfg
    cfg["dns"] = copy.deepcopy(MINIMAL_DNS)
    cfg["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
    if "balancers" not in cfg.get("routing", {}): cfg["routing"] = copy.deepcopy(MINIMAL_ROUTING_PROXY)
    for out in cfg.get("outbounds", []):
        tag = out.get("tag", "")
        if tag == "proxy" or tag.startswith("bal-"):
            out["mux"] = {"concurrency": -1, "enabled": False}
            old = out.get("settings", {})
            if "address" in old: out["settings"] = {"vnext": [{"address": old.get("address"), "port": old.get("port"), "users": [{"encryption": old.get("encryption", "none"), "flow": old.get("flow", ""), "id": old.get("id"), "level": old.get("level", 8)}]}]}
            
            out.pop("sniSpoof", None)
            
            st = out.get("streamSettings", {})
            st["finalmask"] = {"tcp": FINALMASK_TCP}
            if "tlsSettings" in st:
                st["tlsSettings"].pop("alpn", None)
                st["tlsSettings"].update({"cipherSuites": CIPHER_SUITES, "allowInsecure": False, "show": False, "fingerprint": "unsafe"})
            if "wsSettings" in st:
                h = st["wsSettings"].pop("host", None); st["wsSettings"].pop("heartbeatPeriod", None)
                st["wsSettings"]["headers"] = {"Host": h} if h else {}
            out["streamSettings"] = st
        elif tag == "direct": out["settings"] = {"domainStrategy": "UseIP"}
    return cfg
@app.route('/json/<path:sub_path>')
def dyn(sub_path):
    try:
        data = requests.get(f"{SUB_BASE_URL}/json/{sub_path}?view=raw", verify=False, timeout=10).json()
        mod = [process_cfg(c) for c in data] if isinstance(data, list) else process_cfg(data) if isinstance(data, dict) else data
        return jsonify(mod)
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # ================== SERVICE 4 (NPV TUNNEL HYBRID FINALMASK) ==================
    cat << 'EOF' > /opt/sub_server/app_4.py
from flask import Flask, jsonify, request
import requests, copy, urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "__SUB_BASE_URL__"
TARGET_KEYWORDS = __TARGET_KEYWORDS__
CIPHER_SUITES = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"

# Hybrid Finalmask: Includes both 'lengths' (arrays) and 'length' (strings) to satisfy strict parsers like NPV Tunnel
FINALMASK_TCP_HYBRID = [
    {"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0", "length": "100-200", "interval": "10-20"}}, 
    {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355", "length": "10-20", "interval": "10-20"}}
]

MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}

def process_cfg(cfg):
    if not any(k in cfg.get("remarks", "") for k in TARGET_KEYWORDS): return cfg
    cfg["dns"] = copy.deepcopy(MINIMAL_DNS)
    cfg["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
    if "balancers" not in cfg.get("routing", {}): cfg["routing"] = copy.deepcopy(MINIMAL_ROUTING_PROXY)
    for out in cfg.get("outbounds", []):
        tag = out.get("tag", "")
        if tag == "proxy" or tag.startswith("bal-"):
            out["mux"] = {"concurrency": -1, "enabled": False}
            old = out.get("settings", {})
            if "address" in old: out["settings"] = {"vnext": [{"address": old.get("address"), "port": old.get("port"), "users": [{"encryption": old.get("encryption", "none"), "flow": old.get("flow", ""), "id": old.get("id"), "level": old.get("level", 8)}]}]}
            
            out.pop("sniSpoof", None)
            
            st = out.get("streamSettings", {})
            # Inject Hybrid Finalmask for NPV Tunnel
            st["finalmask"] = {"tcp": FINALMASK_TCP_HYBRID}
            if "tlsSettings" in st:
                st["tlsSettings"].pop("alpn", None)
                st["tlsSettings"].update({"cipherSuites": CIPHER_SUITES, "allowInsecure": False, "show": False, "fingerprint": "unsafe"})
            if "wsSettings" in st:
                h = st["wsSettings"].pop("host", None); st["wsSettings"].pop("heartbeatPeriod", None)
                st["wsSettings"]["headers"] = {"Host": h} if h else {}
            out["streamSettings"] = st
        elif tag == "direct": out["settings"] = {"domainStrategy": "UseIP"}
    return cfg

@app.route('/json/<path:sub_path>')
def dyn(sub_path):
    try:
        data = requests.get(f"{SUB_BASE_URL}/json/{sub_path}?view=raw", verify=False, timeout=10).json()
        mod = [process_cfg(c) for c in data] if isinstance(data, list) else process_cfg(data) if isinstance(data, dict) else data
        return jsonify(mod)
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # Replace variables in all apps
    for f in app_1.py app_2.py app_3.py app_4.py; do
        sed -i "s|__SUB_BASE_URL__|${SUB_BASE_URL}|g" /opt/sub_server/$f
        sed -i "s|__TARGET_KEYWORDS__|${TARGET_PY}|g" /opt/sub_server/$f
        sed -i "s|__SPOOF_IP__|${SPOOF_IP}|g" /opt/sub_server/$f
    done

    # Create and start services
    for PORT in $PORT1 $PORT2 $PORT3 $PORT4; do
        if [ "$PORT" == "$PORT1" ]; then APP_NAME="app_1"; elif [ "$PORT" == "$PORT2" ]; then APP_NAME="app_2"; elif [ "$PORT" == "$PORT3" ]; then APP_NAME="app_3"; else APP_NAME="app_4"; fi
        cat << EOF > /etc/systemd/system/subserver${PORT}.service
[Unit]
Description=Custom Sub Server (Port ${PORT})
Wants=network-online.target
After=network-online.target
[Service]
User=root
WorkingDirectory=/opt/sub_server
ExecStart=/usr/bin/python3 -m gunicorn --workers 4 --bind 0.0.0.0:${PORT} --certfile ${CERT_PATH} --keyfile ${KEY_PATH} --timeout 60 ${APP_NAME}:app
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
        iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT 2>/dev/null
    done
    netfilter-persistent save >/dev/null 2>&1

    echo -e "\e[33m[+] Starting Services...\e[0m"
    systemctl daemon-reload
    systemctl enable --now subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} >/dev/null 2>&1
    systemctl restart subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} >/dev/null 2>&1

    echo -e "\n\e[32m[✔] Installation / Update Completed Successfully!\e[0m"
    show_recommendations
    read -p "Press Enter to return to menu..." </dev/tty
    main_menu
}

function uninstall() {
    clear
    echo -e "\e[31m=================================================\e[0m"
    echo -e "\e[31m            COMPLETE UNINSTALLATION              \e[0m"
    echo -e "\e[31m=================================================\e[0m"
    read -p "Are you sure you want to completely remove this tool? (y/n): " confirm </dev/tty
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        systemctl stop subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} >/dev/null 2>&1
        systemctl disable subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} >/dev/null 2>&1
        rm -f /etc/systemd/system/subserver*.service
        rm -rf /opt/sub_server
        rm -f /usr/local/bin/sub-modifier
        systemctl daemon-reload
        echo -e "\n\e[32m[✔] Uninstalled successfully. Goodbye!\e[0m"
        exit 0
    else
        main_menu
    fi
}

function main_menu() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "\e[36m       3x-ui Custom Sub Server Manager           \e[0m"
    echo -e "\e[36m=================================================\e[0m"
    echo "  1) ⚙️  Install / Update Configuration"
    echo "  2) 📌 Show Client Recommendations"
    echo "  3) 🗑️  Uninstall Completely"
    echo "  0) ❌ Exit"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [0-3]: " option </dev/tty

    case $option in
        1) install_update ;;
        2) show_recommendations; read -p "Press Enter to return..." </dev/tty ; main_menu ;;
        3) uninstall ;;
        0) exit 0 ;;
        *) echo "Invalid option!"; sleep 1; main_menu ;;
    esac
}

if [ ! -f "$CONFIG_FILE" ]; then
    install_update
else
    main_menu
fi
