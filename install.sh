#!/bin/bash

CONFIG_DIR="/opt/sub_server"
CONFIG_FILE="${CONFIG_DIR}/config.env"
REPO_NAME="tinydev128/sub-modifier"

SUB_BASE_URL="https://127.0.0.1:2020"
KEYWORDS="CFCDN,CFXCDN,CDN Best"
SPOOF_IP="104.19.230.21"
CERT_PATH="/root/cert/ip/fullchain.pem"
KEY_PATH="/root/cert/ip/privkey.pem"
MASTER_PORT="8000"
PORT1="5000"
PORT2="5800"
PORT3="5801"
PORT4="5802"
WORKERS="1"
FM_VERSION="new"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

function show_recommendations() {
    echo -e "\n\e[32m=================================================\e[0m"
    echo -e "\e[32m             CLIENT USAGE GUIDE                  \e[0m"
    echo -e "\e[32m=================================================\e[0m"
    echo -e "\n\e[32m🌟 SMART ALL-IN-ONE PORT (Highly Recommended)\e[0m"
    echo -e "\e[36m   Port: ${MASTER_PORT} (HTTPS Secure)\e[0m"
    echo -e "   Just give this ONE link to your users:"
    echo -e "   \e[33mhttps://YOUR_SERVER_IP:${MASTER_PORT}/sub/YOUR_PATH\e[0m"
    echo -e "   \e[90m↳ Auto-routes happ, V2box, NPV -> Port ${PORT4} (Universal Fallback)\e[0m"
    echo -e "   \e[90m↳ Auto-routes PattN / PattNG -> Port ${PORT1} (Path: /sub/)\e[0m"
    echo -e "   \e[90m↳ Auto-routes v2rayN / v2rayNG -> Port ${PORT1} (Path: /json/)\e[0m"
    echo -e "   \e[90m↳ Auto-redirects Chrome/Safari to original panel with a warning page.\e[0m"
    
    echo -e "\n\e[31m-------------------------------------------------\e[0m"
    echo -e "\e[31m⚠️ MANUAL DIRECT PORTS (If needed):\e[0m"
    echo -e "   \e[33mPort ${PORT1}\e[0m -> Primary Service (PattNG / v2rayN)"
    echo -e "   \e[33mPort ${PORT2}\e[0m -> SniSpoof Isolated (V2box specific)"
    echo -e "   \e[33mPort ${PORT3}\e[0m -> Strict Fallback (Strict Xray schema)"
    echo -e "   \e[33mPort ${PORT4}\e[0m -> Universal Fallback (Hybrid Engine)"
    echo -e "\e[32m=================================================\e[0m\n"
}

function ensure_dependencies() {
    local missing_deps=0
    for cmd in python3 curl iptables netfilter-persistent gunicorn jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps=1
            break
        fi
    done

    if [ $missing_deps -eq 0 ]; then
        if ! python3 -c "import flask, requests, urllib3" &>/dev/null; then
            missing_deps=1
        fi
    fi

    if [ $missing_deps -eq 1 ]; then
        echo -e "\n\e[33m[+] Missing dependencies detected. Installing required packages...\e[0m"
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y python3 python3-pip iptables-persistent netfilter-persistent python3-flask python3-requests python3-urllib3 gunicorn curl jq
        python3 -m pip install Flask requests gunicorn urllib3 --break-system-packages 2>/dev/null || python3 -m pip install Flask requests gunicorn urllib3 2>/dev/null
        echo -e "\e[32m[✔] All dependencies are verified and ready.\e[0m"
    else
        echo -e "\n\e[32m[✔] All system & Python dependencies are already installed.\e[0m"
    fi
}

function deploy_services() {
    echo -e "\n\e[33m[+] Generating Python Scripts & Services...\e[0m"
    mkdir -p "$CONFIG_DIR"
    
    TARGET_PY=$(python3 -c "import sys, json; print(json.dumps([k.strip() for k in sys.argv[1].split(',') if k.strip()]))" "$KEYWORDS")

    if [ "$FM_VERSION" == "old" ]; then
        FINALMASK_TCP='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355"}}]'
        FINALMASK_TCP_HYBRID='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0", "length": "100-200", "interval": "10-20"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355", "length": "10-20", "interval": "10-20"}}]'
    else
        FINALMASK_TCP='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["0", "104", "1"], "delays": ["0"], "maxSplit": "0"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["114", "1"], "delays": ["1"], "maxSplit": "11"}}]'
        FINALMASK_TCP_HYBRID='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["0", "104", "1"], "delays": ["0"], "maxSplit": "0", "length": "100-200", "interval": "10-20"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["114", "1"], "delays": ["1"], "maxSplit": "11", "length": "10-20", "interval": "10-20"}}]'
    fi

    # ================== APP MASTER (Smart Router) ==================
    cat << EOF > /opt/sub_server/app_master.py
from flask import Flask, request, Response, make_response, jsonify
import requests
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

app = Flask(__name__)
SUB_BASE_URL = "${SUB_BASE_URL}"
PORT1 = ${PORT1}
PORT4 = ${PORT4}

HOP_BY_HOP = {'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'content-length', 'server'}

def copy_headers(upstream_headers, flask_resp):
    for k, v in upstream_headers.items():
        if k.lower() not in HOP_BY_HOP and k.lower() != 'content-type':
            try:
                v.encode('latin-1')
                flask_resp.headers[k] = v
            except UnicodeEncodeError:
                flask_resp.headers[k] = v.encode('utf-8').decode('latin-1')

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def smart_router(path):
    user_agent = request.headers.get('User-Agent', '').lower()
    target_port = PORT1
    target_path = "/" + path
    
    if 'happ' in user_agent or 'v2box' in user_agent or 'npv' in user_agent:
        target_port = PORT4
    elif 'pattn' in user_agent:
        target_port = PORT1
        target_path = target_path.replace('/json/', '/sub/')
        if not target_path.startswith('/sub/'):
            target_path = '/sub/' + path
    elif 'v2ray' in user_agent:
        target_port = PORT1
        target_path = target_path.replace('/sub/', '/json/')
        if not target_path.startswith('/json/'):
            target_path = '/json/' + path
    elif any(b in user_agent for b in ['mozilla', 'chrome', 'safari', 'edge', 'opera', 'applewebkit']):
        qs = request.query_string.decode('utf-8')
        redirect_url = f"{SUB_BASE_URL}/{path}" + (f"?{qs}" if qs else "")
        html_warning = f"""
        <html dir="rtl" lang="fa"><head><meta charset="utf-8"><title>هشدار</title><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="refresh" content="7;url={redirect_url}" /><style>body {{ font-family: Tahoma; text-align: center; padding: 50px 20px; }} .box {{ max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; border-top: 5px solid #dc3545; }}</style></head><body><div class="box"><h2>⚠️ توجه: این لینک مخصوص مرورگر نیست!</h2><p>شما باید این لینک را در نرم‌افزارهای VPN وارد کنید.</p><p style="color: #6c757d; font-size: 14px;">در حال انتقال خودکار به پورت اصلی پنل تا ۷ ثانیه دیگر...</p></div></body></html>
        """
        return Response(html_warning, content_type='text/html; charset=utf-8')
        
    qs = request.query_string.decode('utf-8')
    # Use HTTPS for internal routing since local apps run on SSL
    internal_url = f"https://127.0.0.1:{target_port}{target_path}" + (f"?{qs}" if qs else "")
    try:
        client_headers = {k: v for k, v in request.headers if k.lower() != 'host'}
        resp = requests.get(internal_url, headers=client_headers, timeout=10, verify=False)
        flask_resp = make_response(resp.content)
        flask_resp.status_code = resp.status_code
        flask_resp.headers['Content-Type'] = resp.headers.get('Content-Type', 'text/plain; charset=utf-8')
        copy_headers(resp.headers, flask_resp)
        return flask_resp
    except Exception as e:
        return jsonify({"error": f"Internal routing error: {str(e)}"}), 500
EOF

    # ================== APP 1 (Port 5000) ==================
    cat << EOF > /opt/sub_server/app_1.py
from flask import Flask, jsonify, request, make_response
import requests, copy, urllib3, base64, urllib.parse, json

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "${SUB_BASE_URL}"
TARGET_KEYWORDS = ${TARGET_PY}
CIPHER_SUITES = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
FINALMASK_TCP = ${FINALMASK_TCP}
HOP_BY_HOP = {'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'content-length', 'server'}

def copy_headers(upstream_headers, flask_resp):
    for k, v in upstream_headers.items():
        if k.lower() not in HOP_BY_HOP and k.lower() != 'content-type':
            try: flask_resp.headers[k] = v.encode('latin-1').decode('latin-1')
            except: flask_resp.headers[k] = v.encode('utf-8').decode('latin-1')

def get_client_headers():
    h = {k: v for k, v in request.headers if k.lower() not in {'host', 'content-length'}}
    if 'User-Agent' not in h and 'user-agent' not in h: h['User-Agent'] = 'v2rayN/6.42'
    return h

MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}

def process_json_config(config):
    if not any(k in config.get("remarks", "") for k in TARGET_KEYWORDS): return config
    config["dns"] = copy.deepcopy(MINIMAL_DNS); config["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
    if "balancers" not in config.get("routing", {}): config["routing"] = copy.deepcopy(MINIMAL_ROUTING_PROXY)
    for out in config.get("outbounds", []):
        if out.get("protocol") == "vless":
            st = out.get("streamSettings", {})
            st["finalmask"] = {"tcp": FINALMASK_TCP}
            if "tlsSettings" in st: st["tlsSettings"].update({"cipherSuites": CIPHER_SUITES, "fingerprint": "unsafe"})
            out["streamSettings"] = st
    return config

@app.route('/json/<path:sub_path>')
def dynamic_json_sub(sub_path):
    try:
        qs = request.query_string.decode('utf-8'); sep = "&" if qs else "?"
        url = f"{SUB_BASE_URL}/json/{sub_path}?{qs}" if "view=raw" in qs else f"{SUB_BASE_URL}/json/{sub_path}?{qs}{sep}view=raw" if qs else f"{SUB_BASE_URL}/json/{sub_path}?view=raw"
        resp = requests.get(url, headers=get_client_headers(), verify=False, timeout=10)
        data = resp.json()
        mod_data = [process_json_config(cfg) for cfg in data] if isinstance(data, list) else process_json_config(data) if isinstance(data, dict) else data
        flask_resp = jsonify(mod_data); copy_headers(resp.headers, flask_resp)
        return flask_resp
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
        qs = request.query_string.decode('utf-8')
        url = f"{SUB_BASE_URL}/sub/{sub_path}" + (f"?{qs}" if qs else "")
        resp = requests.get(url, headers=get_client_headers(), verify=False, timeout=10)
        raw = resp.text.strip(); raw += '=' * (-len(raw) % 4)
        try: dec = base64.b64decode(raw).decode('utf-8')
        except: dec = resp.text
        mod = [process_uri_config(l.strip()) for l in dec.split('\n') if l.strip()]
        res = make_response(base64.b64encode('\n'.join(mod).encode('utf-8')).decode('utf-8'))
        res.headers['Content-Type'] = 'text/plain; charset=utf-8'; copy_headers(resp.headers, res)
        return res
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # ================== APP 2 (Port 5800) ==================
    cat << EOF > /opt/sub_server/app_2.py
from flask import Flask, jsonify, request, make_response
import requests, copy, urllib3, base64, urllib.parse
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "${SUB_BASE_URL}"
TARGET_KEYWORDS = ${TARGET_PY}
SPOOF_IP = "${SPOOF_IP}"
HOP_BY_HOP = {'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'content-length', 'server'}

def copy_headers(upstream_headers, flask_resp):
    for k, v in upstream_headers.items():
        if k.lower() not in HOP_BY_HOP and k.lower() != 'content-type':
            try: flask_resp.headers[k] = v.encode('latin-1').decode('latin-1')
            except: flask_resp.headers[k] = v.encode('utf-8').decode('latin-1')

def get_client_headers():
    h = {k: v for k, v in request.headers if k.lower() not in {'host', 'content-length'}}
    if 'User-Agent' not in h and 'user-agent' not in h: h['User-Agent'] = 'v2rayN/6.42'
    return h

MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}

def process_cfg(cfg):
    if not any(k in cfg.get("remarks", "") for k in TARGET_KEYWORDS): return cfg
    cfg["dns"] = copy.deepcopy(MINIMAL_DNS); cfg["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
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
        qs = request.query_string.decode('utf-8'); sep = "&" if qs else "?"
        url = f"{SUB_BASE_URL}/json/{sub_path}?{qs}" if "view=raw" in qs else f"{SUB_BASE_URL}/json/{sub_path}?{qs}{sep}view=raw" if qs else f"{SUB_BASE_URL}/json/{sub_path}?view=raw"
        resp = requests.get(url, headers=get_client_headers(), verify=False, timeout=10)
        data = resp.json()
        mod = [process_cfg(c) for c in data] if isinstance(data, list) else process_cfg(data) if isinstance(data, dict) else data
        flask_resp = jsonify(mod); copy_headers(resp.headers, flask_resp)
        return flask_resp
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # ================== APP 3 (Port 5801) ==================
    cat << EOF > /opt/sub_server/app_3.py
from flask import Flask, jsonify, request, make_response
import requests, copy, urllib3, base64, urllib.parse, json
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "${SUB_BASE_URL}"
TARGET_KEYWORDS = ${TARGET_PY}
CIPHER_SUITES = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
FINALMASK_TCP = ${FINALMASK_TCP}
HOP_BY_HOP = {'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'content-length', 'server'}

def copy_headers(upstream_headers, flask_resp):
    for k, v in upstream_headers.items():
        if k.lower() not in HOP_BY_HOP and k.lower() != 'content-type':
            try: flask_resp.headers[k] = v.encode('latin-1').decode('latin-1')
            except: flask_resp.headers[k] = v.encode('utf-8').decode('latin-1')

def get_client_headers():
    h = {k: v for k, v in request.headers if k.lower() not in {'host', 'content-length'}}
    if 'User-Agent' not in h and 'user-agent' not in h: h['User-Agent'] = 'v2rayN/6.42'
    return h

MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}

def process_cfg(cfg):
    if not any(k in cfg.get("remarks", "") for k in TARGET_KEYWORDS): return cfg
    cfg["dns"] = copy.deepcopy(MINIMAL_DNS); cfg["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
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
        qs = request.query_string.decode('utf-8'); sep = "&" if qs else "?"
        url = f"{SUB_BASE_URL}/json/{sub_path}?{qs}" if "view=raw" in qs else f"{SUB_BASE_URL}/json/{sub_path}?{qs}{sep}view=raw" if qs else f"{SUB_BASE_URL}/json/{sub_path}?view=raw"
        resp = requests.get(url, headers=get_client_headers(), verify=False, timeout=10)
        data = resp.json()
        mod = [process_cfg(c) for c in data] if isinstance(data, list) else process_cfg(data) if isinstance(data, dict) else data
        flask_resp = jsonify(mod); copy_headers(resp.headers, flask_resp)
        return flask_resp
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # ================== APP 4 (Port 5802) ==================
    cat << EOF > /opt/sub_server/app_4.py
from flask import Flask, jsonify, request, make_response
import requests, copy, urllib3, base64, urllib.parse, json
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
app = Flask(__name__)
SUB_BASE_URL = "${SUB_BASE_URL}"
TARGET_KEYWORDS = ${TARGET_PY}
CIPHER_SUITES = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
FINALMASK_TCP_HYBRID = ${FINALMASK_TCP_HYBRID}
HOP_BY_HOP = {'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'content-length', 'server'}

def copy_headers(upstream_headers, flask_resp):
    for k, v in upstream_headers.items():
        if k.lower() not in HOP_BY_HOP and k.lower() != 'content-type':
            try: flask_resp.headers[k] = v.encode('latin-1').decode('latin-1')
            except: flask_resp.headers[k] = v.encode('utf-8').decode('latin-1')

def get_client_headers():
    h = {k: v for k, v in request.headers if k.lower() not in {'host', 'content-length'}}
    if 'User-Agent' not in h and 'user-agent' not in h: h['User-Agent'] = 'v2rayN/6.42'
    return h

MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}

def process_cfg(cfg):
    if not any(k in cfg.get("remarks", "") for k in TARGET_KEYWORDS): return cfg
    cfg["dns"] = copy.deepcopy(MINIMAL_DNS); cfg["inbounds"] = copy.deepcopy(MINIMAL_INBOUNDS)
    if "balancers" not in cfg.get("routing", {}): cfg["routing"] = copy.deepcopy(MINIMAL_ROUTING_PROXY)
    for out in cfg.get("outbounds", []):
        tag = out.get("tag", "")
        if tag == "proxy" or tag.startswith("bal-"):
            out["mux"] = {"concurrency": -1, "enabled": False}
            old = out.get("settings", {})
            if "address" in old: out["settings"] = {"vnext": [{"address": old.get("address"), "port": old.get("port"), "users": [{"encryption": old.get("encryption", "none"), "flow": old.get("flow", ""), "id": old.get("id"), "level": old.get("level", 8)}]}]}
            out.pop("sniSpoof", None)
            st = out.get("streamSettings", {})
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
def dyn_json(sub_path):
    try:
        qs = request.query_string.decode('utf-8'); sep = "&" if qs else "?"
        url = f"{SUB_BASE_URL}/json/{sub_path}?{qs}" if "view=raw" in qs else f"{SUB_BASE_URL}/json/{sub_path}?{qs}{sep}view=raw" if qs else f"{SUB_BASE_URL}/json/{sub_path}?view=raw"
        resp = requests.get(url, headers=get_client_headers(), verify=False, timeout=10)
        data = resp.json()
        mod = [process_cfg(c) for c in data] if isinstance(data, list) else process_cfg(data) if isinstance(data, dict) else data
        flask_resp = jsonify(mod); copy_headers(resp.headers, flask_resp)
        return flask_resp
    except Exception as e: return jsonify({"error": str(e)}), 500

def process_uri_config(uri):
    if not uri.startswith("vless://"): return uri
    try:
        b_url, rem = uri.split("#", 1)
        if not any(k in urllib.parse.unquote(rem) for k in TARGET_KEYWORDS): return uri
        hp, qp = b_url.split("?", 1) if "?" in b_url else (b_url, "")
        params = dict(urllib.parse.parse_qsl(qp))
        params.update({"fp": "unsafe", "cs": CIPHER_SUITES, "fm": json.dumps({"tcp": FINALMASK_TCP_HYBRID}), "allowInsecure": "0", "insecure": "0"})
        new_q = urllib.parse.urlencode(params, quote_via=urllib.parse.quote)
        return f"{hp}?{new_q}#{rem}"
    except: return uri

@app.route('/sub/<path:sub_path>')
def dyn_sub(sub_path):
    try:
        qs = request.query_string.decode('utf-8')
        url = f"{SUB_BASE_URL}/sub/{sub_path}" + (f"?{qs}" if qs else "")
        resp = requests.get(url, headers=get_client_headers(), verify=False, timeout=10)
        raw = resp.text.strip(); raw += '=' * (-len(raw) % 4)
        try: dec = base64.b64decode(raw).decode('utf-8')
        except: dec = resp.text
        mod = [process_uri_config(l.strip()) for l in dec.split('\n') if l.strip()]
        res = make_response(base64.b64encode('\n'.join(mod).encode('utf-8')).decode('utf-8'))
        res.headers['Content-Type'] = 'text/plain; charset=utf-8'; copy_headers(resp.headers, res)
        return res
    except Exception as e: return jsonify({"error": str(e)}), 500
EOF

    # ساخت سرویس‌های اصلی (با SSL)
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
ExecStart=/usr/bin/python3 -m gunicorn --workers ${WORKERS} --bind 0.0.0.0:${PORT} --certfile ${CERT_PATH} --keyfile ${KEY_PATH} --timeout 60 ${APP_NAME}:app
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
        iptables -I INPUT -p tcp --dport ${PORT} -j ACCEPT 2>/dev/null
    done

    # ساخت سرویس Master Router (پورت هوشمند هم اکنون با SSL است)
    cat << EOF > /etc/systemd/system/subserver_master.service
[Unit]
Description=Smart Router Sub Server (Master Port ${MASTER_PORT})
Wants=network-online.target
After=network-online.target
[Service]
User=root
WorkingDirectory=/opt/sub_server
ExecStart=/usr/bin/python3 -m gunicorn --workers ${WORKERS} --bind 0.0.0.0:${MASTER_PORT} --certfile ${CERT_PATH} --keyfile ${KEY_PATH} --timeout 60 app_master:app
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
    iptables -I INPUT -p tcp --dport ${MASTER_PORT} -j ACCEPT 2>/dev/null

    netfilter-persistent save >/dev/null 2>&1

    echo -e "\e[33m[+] Reloading & Restarting Services...\e[0m"
    systemctl daemon-reload
    systemctl enable --now subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} subserver_master >/dev/null 2>&1
    systemctl restart subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} subserver_master >/dev/null 2>&1
}

function update_version_manager() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "\e[36m             GITHUB VERSION MANAGER              \e[0m"
    echo -e "\e[36m=================================================\e[0m\n"
    
    echo -e "\n\e[33m[+] Fetching available releases from GitHub...\e[0m"
    tags=$(curl -s https://api.github.com/repos/${REPO_NAME}/releases | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$tags" ]; then
        echo -e "\e[31m[✖] No releases found or API rate limit exceeded. Proceeding with Main branch...\e[0m"
        sleep 2
        if [ -f "$CONFIG_FILE" ]; then
            main_menu
        else
            configure_and_install
        fi
        return
    fi
    
    echo -e "\n\e[36mAvailable Releases:\e[0m"
    declare -a tag_array
    i=1
    for tag in $tags; do
        echo "  $i) $tag"
        tag_array[$i]=$tag
        ((i++))
    done
    
    read -p "Select a version [1-$((i-1))]: " tag_choice </dev/tty
    if [[ ! "$tag_choice" =~ ^[0-9]+$ ]] || [ "$tag_choice" -lt 1 ] || [ "$tag_choice" -ge "$i" ]; then
        echo -e "\e[31m[✖] Invalid selection.\e[0m"
        sleep 1
        update_version_manager
        return
    fi
    
    SELECTED_TAG=${tag_array[$tag_choice]}
    DOWNLOAD_URL="https://raw.githubusercontent.com/${REPO_NAME}/refs/tags/${SELECTED_TAG}/install.sh"
    
    echo -e "\n\e[33m[+] Downloading script (Tag: ${SELECTED_TAG}) from GitHub...\e[0m"
    TMP_SCRIPT="/tmp/sub_modifier_update.sh"
    curl -Ls "${DOWNLOAD_URL}?$(date +%s)" -o "$TMP_SCRIPT"
    
    if [ $? -ne 0 ] || [ ! -s "$TMP_SCRIPT" ]; then
        echo -e "\e[31m[✖] Download failed! Please check your server's connection to GitHub.\e[0m\n"
        rm -f "$TMP_SCRIPT"
        read -p "Press Enter to return..." </dev/tty
        main_menu
        return
    fi

    cp "$TMP_SCRIPT" /usr/local/bin/sub-modifier
    chmod +x /usr/local/bin/sub-modifier
    rm -f "$TMP_SCRIPT"
    echo -e "\e[32m[✔] CLI tool (/usr/local/bin/sub-modifier) updated successfully!\e[0m"

    if [ -f "$CONFIG_FILE" ]; then
        echo -e "\e[33m[+] Handing over to the NEW script version to rebuild services...\e[0m"
        exec /usr/local/bin/sub-modifier --rebuild
    else
        echo -e "\n\e[33m[!] Initializing setup for the selected version...\e[0m"
        exec /usr/local/bin/sub-modifier --force-install
    fi
}

function first_run_menu() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "\e[36m        SUB MODIFIER INITIAL INSTALLATION        \e[0m"
    echo -e "\e[36m=================================================\e[0m\n"
    echo "Which version do you want to install?"
    echo "  1) 🚀 Latest Version (Main Branch - Bleeding Edge)"
    echo "  2) 📦 Select a specific Release / Pre-release tag"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [1-2, default: 1]: " first_opt </dev/tty
    
    if [ "$first_opt" == "2" ]; then
        update_version_manager
    else
        configure_and_install
    fi
}

function configure_and_install() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "\e[36m              SUB SERVER CONFIGURATION           \e[0m"
    echo -e "\e[36m=================================================\e[0m\n"
    
    echo -e "\e[31m⚠️ PREREQUISITES:\e[0m"
    echo -e "1. 'JSON Subscription' MUST be enabled in your 3x-ui panel settings."
    echo -e "2. If you set Sub Base URL to 127.0.0.1, ensure your panel listens on that IP.\n"

    echo -e "\e[33m[ Hint: Press Enter to keep the current value in brackets ]\e[0m\n"
    
    read -p "Enter Sub Base URL [$SUB_BASE_URL]: " input </dev/tty; SUB_BASE_URL=${input:-$SUB_BASE_URL}
    read -p "Enter Target Keywords [$KEYWORDS]: " input </dev/tty; KEYWORDS=${input:-$KEYWORDS}
    read -p "Enter Spoof IP [$SPOOF_IP]: " input </dev/tty; SPOOF_IP=${input:-$SPOOF_IP}
    read -p "Enter SSL Fullchain Path [$CERT_PATH]: " input </dev/tty; CERT_PATH=${input:-$CERT_PATH}
    read -p "Enter SSL Privkey Path [$KEY_PATH]: " input </dev/tty; KEY_PATH=${input:-$KEY_PATH}

    echo -e "\n\e[36m================ PORT CONFIGURATION ================\e[0m"
    echo -e "\e[32m🌟 Master Port:\e[0m Smart Auto-Router (Highly Recommended, HTTPS)"
    read -p "🔗 Enter port for Smart Router [$MASTER_PORT]: " input </dev/tty; MASTER_PORT=${input:-$MASTER_PORT}

    echo -e "\n\e[32mService 1:\e[0m Primary Dual Service (URI /sub/ for PattNG, JSON /json/ for v2rayN/v2rayNG)"
    read -p "🔗 Enter port for Service 1 [$PORT1]: " input </dev/tty; PORT1=${input:-$PORT1}

    echo -e "\n\e[32mService 2:\e[0m Dedicated SniSpoof Profile (JSON only, tailored for V2box)"
    read -p "🔗 Enter port for Service 2 [$PORT2]: " input </dev/tty; PORT2=${input:-$PORT2}

    echo -e "\n\e[32mService 3:\e[0m Strict Fallback (Strict Xray vnext schema + FM/CS)"
    read -p "🔗 Enter port for Service 3 [$PORT3]: " input </dev/tty; PORT3=${input:-$PORT3}

    echo -e "\n\e[32mService 4:\e[0m 🛡️ Universal Fallback (Hybrid Fragment + CipherSuites)"
    read -p "🔗 Enter port for Service 4 [$PORT4]: " input </dev/tty; PORT4=${input:-$PORT4}

    echo -e "\n\e[36m============= PERFORMANCE CONFIGURATION =============\e[0m"
    echo -e " 💡 \e[90mWorker Guidelines per service:\e[0m"
    echo -e "    \e[33m1 Worker\e[0m  -> ~150MB Total RAM (Best for 1GB RAM)"
    echo -e "    \e[33m2 Workers\e[0m -> ~350MB Total RAM (Best for 2GB RAM)"
    echo -e "    \e[33m4 Workers\e[0m -> ~700MB Total RAM (Best for 4GB+ RAM)"
    read -p "⚡ Enter Gunicorn workers per service [$WORKERS]: " input </dev/tty; WORKERS=${input:-$WORKERS}

    echo -e "\n\e[36m================ FINALMASK PROFILE ================\e[0m"
    echo -e "  1) NEW Profile (0,104,1 / 114,1 - maxSplit: 11) [\e[32mRecommended\e[0m]"
    echo -e "  2) OLD Profile (5,94,1 / 109,1 - maxSplit: 355)"
    read -p "Select Finalmask profile [1 or 2, default: 1]: " fm_in </dev/tty
    if [[ "$fm_in" == "2" ]]; then
        FM_VERSION="old"
    else
        FM_VERSION="new"
    fi

    mkdir -p "$CONFIG_DIR"
    cat <<EOF > "$CONFIG_FILE"
SUB_BASE_URL="$SUB_BASE_URL"
KEYWORDS="$KEYWORDS"
SPOOF_IP="$SPOOF_IP"
CERT_PATH="$CERT_PATH"
KEY_PATH="$KEY_PATH"
MASTER_PORT="$MASTER_PORT"
PORT1="$PORT1"
PORT2="$PORT2"
PORT3="$PORT3"
PORT4="$PORT4"
WORKERS="$WORKERS"
FM_VERSION="$FM_VERSION"
EOF

    ensure_dependencies
    deploy_services

    echo -e "\n\e[32m[✔] Settings saved and services deployed successfully!\e[0m"
    show_recommendations
    read -p "Press Enter to return to menu..." </dev/tty
    main_menu
}

function switch_finalmask() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "\e[36m             SWITCH FINALMASK PROFILE            \e[0m"
    echo -e "\e[36m=================================================\e[0m\n"
    
    if [ "$FM_VERSION" == "old" ]; then
        echo -e "Current Active Profile: \e[33mOLD\e[0m (5,94,1 / 109,1 - maxSplit: 355)\n"
    else
        echo -e "Current Active Profile: \e[32mNEW\e[0m (0,104,1 / 114,1 - maxSplit: 11)\n"
    fi
    
    echo "  1) Set NEW Profile (0,104,1 / 114,1 - maxSplit: 11) [Recommended]"
    echo "  2) Set OLD Profile (5,94,1 / 109,1 - maxSplit: 355)"
    echo "  0) Back to Main Menu"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [0-2]: " choice </dev/tty

    case $choice in
        1) FM_VERSION="new" ;;
        2) FM_VERSION="old" ;;
        0) main_menu; return ;;
        *) echo "Invalid option!"; sleep 1; switch_finalmask; return ;;
    esac

    if grep -q "FM_VERSION=" "$CONFIG_FILE"; then
        sed -i "s/^FM_VERSION=.*/FM_VERSION=\"$FM_VERSION\"/" "$CONFIG_FILE"
    else
        echo "FM_VERSION=\"$FM_VERSION\"" >> "$CONFIG_FILE"
    fi

    deploy_services
    echo -e "\n\e[32m[✔] Switched to ${FM_VERSION^^} Finalmask profile successfully!\e[0m\n"
    read -p "Press Enter to return to menu..." </dev/tty
    main_menu
}

function check_status() {
    clear
    echo -e "\e[36m=================================================\e[0m"
    echo -e "\e[36m             SERVICES STATUS OVERVIEW            \e[0m"
    echo -e "\e[36m=================================================\e[0m\n"
    
    for PORT in $MASTER_PORT $PORT1 $PORT2 $PORT3 $PORT4; do
        if [ "$PORT" == "$MASTER_PORT" ]; then SRV_NAME="subserver_master"; else SRV_NAME="subserver${PORT}"; fi
        STATUS=$(systemctl is-active ${SRV_NAME} 2>/dev/null)
        if [ "$STATUS" == "active" ]; then
            if [ "$PORT" == "$MASTER_PORT" ]; then
                echo -e "  Port \e[36m${PORT} (Smart Router - HTTPS)\e[0m: \e[32m● Running (Active)\e[0m"
            else
                echo -e "  Port \e[33m${PORT}\e[0m: \e[32m● Running (Active)\e[0m"
            fi
        else
            echo -e "  Port \e[33m${PORT}\e[0m: \e[31m● Stopped or Failed (${STATUS})\e[0m"
        fi
    done
    
    echo -e "\n\e[36m-------------------------------------------------\e[0m"
    echo -e "RAM Usage by sub-modifier:"
    ps aux | grep "[g]unicorn" | awk '{sum += $6} END {printf "  Total Memory: %.1f MB\n", sum/1024}'
    echo -e "\e[36m=================================================\e[0m\n"
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
        systemctl stop subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} subserver_master >/dev/null 2>&1
        systemctl disable subserver${PORT1} subserver${PORT2} subserver${PORT3} subserver${PORT4} subserver_master >/dev/null 2>&1
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
    echo "  1) ⚙️  Modify Configuration (Instant Update)"
    echo "  2) 🚀 Change / Update Version (Releases/Tags)"
    echo "  3) 🔄 Switch Finalmask Profile (Current: ${FM_VERSION^^})"
    echo "  4) 📊 Check Service Status & RAM Usage"
    echo "  5) 📌 Show Client Recommendations (Smart Port)"
    echo "  6) 🗑️  Uninstall Completely"
    echo "  0) ❌ Exit"
    echo -e "\e[36m=================================================\e[0m"
    read -p "Select an option [0-6]: " option </dev/tty

    case $option in
        1) configure_and_install ;;
        2) update_version_manager ;;
        3) switch_finalmask ;;
        4) check_status ;;
        5) show_recommendations; read -p "Press Enter to return..." </dev/tty ; main_menu ;;
        6) uninstall ;;
        0) exit 0 ;;
        *) echo "Invalid option!"; sleep 1; main_menu ;;
    esac
}

# Entry Point handles internal rebuild flags to allow version switching
if [ "$1" == "--rebuild" ]; then
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        ensure_dependencies
        deploy_services
        echo -e "\n\e[32m[✔] Update completed! All services are running with the chosen version.\e[0m"
    else
        echo -e "\e[31m[✖] Config file not found. Cannot rebuild.\e[0m"
    fi
    exit 0
elif [ "$1" == "--force-install" ]; then
    configure_and_install
    exit 0
fi

# Initial check for fresh installs
if [ ! -f "$CONFIG_FILE" ]; then
    first_run_menu
else
    main_menu
fi
