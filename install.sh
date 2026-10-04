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
PORT5="5803"
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
    echo -e "\e[36m   Port: ${MASTER_PORT} (HTTPS Secure - Direct Fetch)\e[0m"
    echo -e "   Just give this ONE link to your users:"
    echo -e "   \e[33mhttps://YOUR_SERVER_IP:${MASTER_PORT}/sub/YOUR_PATH\e[0m"
    echo -e "   \e[90m↳ Auto-routes PattN / PattNG -> Base64 + Standard FM\e[0m"
    echo -e "   \e[90m↳ Auto-routes Flclash / Clash -> YAML + Mihomo Fragment\e[0m"
    echo -e "   \e[90m↳ Auto-routes v2rayN, Happ, V2box, NPV, Incy & ALL OTHERS -> JSON + Hybrid FM\e[0m"
    echo -e "   \e[90m↳ Serves a Minimalist 1-Click App Installer with Live Announcement.\e[0m"
    
    echo -e "\n\e[33m💡 LEGACY PORTS SUPPORT:\e[0m"
    echo -e "   Ports \e[33m${PORT1}, ${PORT2}, ${PORT3}, ${PORT4}, ${PORT5}\e[0m are natively bound to the Smart Router."
    echo -e "   Existing users will continue to update their subs flawlessly with the new logic!"
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
        if ! python3 -c "import flask, requests, urllib3, yaml" &>/dev/null; then
            missing_deps=1
        fi
    fi

    if [ $missing_deps -eq 1 ]; then
        echo -e "\n\e[33m[+] Missing dependencies detected. Installing required packages...\e[0m"
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y python3 python3-pip iptables-persistent netfilter-persistent python3-flask python3-requests python3-urllib3 python3-yaml gunicorn curl jq
        python3 -m pip install Flask requests gunicorn urllib3 PyYAML --break-system-packages 2>/dev/null || python3 -m pip install Flask requests gunicorn urllib3 PyYAML 2>/dev/null
        echo -e "\e[32m[✔] All dependencies are verified and ready.\e[0m"
    else
        echo -e "\n\e[32m[✔] All system & Python dependencies are already installed.\e[0m"
    fi
}

function deploy_services() {
    echo -e "\n\e[33m[+] Generating Unified Python Script & Service...\e[0m"
    mkdir -p "$CONFIG_DIR"
    
    TARGET_PY=$(python3 -c "import sys, json; print(json.dumps([k.strip() for k in sys.argv[1].split(',') if k.strip()]))" "$KEYWORDS")

    if [ "$FM_VERSION" == "old" ]; then
        FINALMASK_TCP='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355"}}]'
        FINALMASK_TCP_HYBRID='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["5", "94", "1"], "delays": ["0"], "maxSplit": "0", "length": "100-200", "interval": "10-20"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["109", "1"], "delays": ["1"], "maxSplit": "355", "length": "10-20", "interval": "10-20"}}]'
    else
        FINALMASK_TCP='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["0", "104", "1"], "delays": ["0"], "maxSplit": "0"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["114", "1"], "delays": ["1"], "maxSplit": "11"}}]'
        FINALMASK_TCP_HYBRID='[{"type": "fragment", "settings": {"packets": "tlshello", "lengths": ["0", "104", "1"], "delays": ["0"], "maxSplit": "0", "length": "100-200", "interval": "10-20"}}, {"type": "fragment", "settings": {"packets": "1-1", "lengths": ["114", "1"], "delays": ["1"], "maxSplit": "11", "length": "10-20", "interval": "10-20"}}]'
    fi

# ================== UNIFIED MASTER APP (Minimalist 1-Click Installer) ==================
    cat << EOF > /opt/sub_server/app_master.py
from flask import Flask, request, Response, make_response, jsonify
import requests
import urllib3
import urllib.parse
import base64
import time
import copy
import json
import re

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

app = Flask(__name__)
SUB_BASE_URL = "${SUB_BASE_URL}"
TARGET_KEYWORDS = ${TARGET_PY}
CIPHER_SUITES = "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA:TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256:TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"
FINALMASK_TCP = ${FINALMASK_TCP}
FINALMASK_TCP_HYBRID = ${FINALMASK_TCP_HYBRID}

PORT1 = ${PORT1}

HOP_BY_HOP = {'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade', 'content-encoding', 'content-length', 'server'}

MINIMAL_DNS = {"queryStrategy": "UseIP", "servers": [{"address": "8.8.8.8", "skipFallback": False}], "tag": "dns_out"}
MINIMAL_INBOUNDS = [{"port": 10808, "protocol": "mixed", "settings": {"auth": "noauth", "udp": True, "userLevel": 8}, "sniffing": {"destOverride": ["http", "tls", "quic", "fakedns"], "enabled": True}, "tag": "mixed"}, {"port": 10809, "protocol": "http", "settings": {"userLevel": 8}, "tag": "http"}]
MINIMAL_ROUTING_PROXY = {"domainStrategy": "AsIs", "rules": [{"network": "tcp,udp", "outboundTag": "proxy", "type": "field"}]}

IMG_V2BOX = "data:image/webp;base64,UklGRq4EAABXRUJQVlA4IKIEAABQGgCdASpgAGAAPkkijUUioiERzAb8KASEtIALZ7aafouh58jerHJ7ZefgPyV/LvUVf3b8hPzA5TrkX9G/un5l/3rWOv8b+Wmv6/4fpxfRHoY/K/7//0fcH/jn89/1v5yccB+xBq/+u4VGCCApRi/kh0UOtBeheVDbkae/vwehM0xE2nN9zxpT5EjDkAaHYVZwwYl0UoclA7PIzfMlchPY8aXYMuDvOEYYcsQHNqnLtxtb/KreGbVNajxK+2Uo6DvNSXjQHyVlvAqvxoDpw7KeYTkKxOGdau4YXQAA/v/iYxVbmNpeb9D2wZARRyc09bxGKq+TzVMQttgJlJv7v+rNNjPOtQpcmPfzjtFM5sZ/WE5vIZm1nPrIg4LI79GOGG4E8b75J/rAHgSkRpcFwV5rMOWBJprzzOKMHzqIvipffZBj8t5SDg2NuWUEB8x0h22h3KR6yk/ia2jbIV6mEY+ToZuWPjzcKUMd/5l6GyU+gh55FlF/gKU3bUdcA2RD8dTD3h80LOgLUq7iPujZn0o1ZvCT9V1QjliPrExc8Rto05ujiHbQgF2m8welwK5b5KNE861+iBao9GhziBe1Eww5QGhpolBqfmPqkuGuX+oMukf6uphzzyx+6yZ4EbEb4hyPiEfMnIsED9c7e+OUEMVGlbX5bJEWmqI5dWE3yGqZFU+hG1SxGi/06ch7LQoqVfs0UU83XuU8Y03x2WEa9CDCErzxU/aRNfAYv+1g5P5ORew8rnnyLQ3TavzJrb6TvEehWIn76QxCUJY9nbNsf/IQpA2uvDS3zg2u7ARfTa/+KzjvbZT4J347904OSMtduZaJzZcAMzJO4OworFZx32LSt7jb9lc8Nvu4cgmcq3oT5VIol1el4MUpWad8qlM/gNgj3u+oqvHxOcUlrvBVg7QCteFz4lmvjwN+ok19RKkk7aCAo/a5gDq9Iz9Tr/IUhsanu+FpLrivxM4g54S0fL3BWwAKGRL2wDfIPYb8gZ7IcOnjC0sa0EPVVRwFrXdFxqNCOV7PAVKeo2HINIz45yQKQOCllYJzEOt24nq/ReL5+Mbw//zPVcYwBdWcLLTtvpjyyJLCPH0hJPnQTQxQB4YJXLw/Y/vK9ei/v/Nycp+UIr/2MXJZEgWg6yGsfJWvM/ExIqtT7FWPB0vzbsGHaQIv/DO/m82m/zf8wWH95X9XUH5TqqDZXw6eX//dp+7IlD//JakMjS+vnXCzsiLF7ykxdHQ3f6+bIdRyV39665k+ohbXUVBfmJKJqdlofjjQQ1JQmFFNI0S1vFwOAJ3iVrn1cCzA6N/H4bZ4nthHatWCeuNzJlAfgy2ovCCaZm/eaExpPYAuYQfmyGiEyIWDuvefcJF/7x1hl03FSKb5HQ0x87KrHo3K1iBQNMQsADSxp1AHX7pNQHx7xx780TkXHeXiy3mWPHCzY89OQ6UsXfSWnCwCl0bU9yg1mHvdmNQhN2oyp/eIFsWSFa07EfTLcL0X3xaxBAlGAJKARlXFW+MSrABA0Ptqf0b5/6ehEfeXZ6cqLMpYzIkrjCvQ3lRZBchRAMQBcWkjGWi10yHNWF99AAAA"
IMG_INCY = "data:image/webp;base64,UklGRrwGAABXRUJQVlA4ILAGAACwHACdASpgAGAAPkkejEOioaGWrVZ4KASEsgBnGAdo1kx2fuRxoe0Cc5+fN5R5gP4d/g/2q91X8ZvdN/evUA/tf9c60P0DvLX9lD9zvSyuhVeZ/nvB08WZYZdbnR3Og0APzd56H/J5jPoP2Cf5f/X/9+HHvnqt086DVsmNXKalaS/+bPh+Mp0kA85jXjVn8/VifydEHiBJEvC9KrLpP70Fc32ZP14LVDrakfQ6cjmAOoTLWBsj+rfyQFjgwDPZ0ltIkZ9sF3VAZagYj/Gm0bXi/4pKY+B8Ab3xWVAAHqyggxydXIziWuMiELcqiKPQAP7/OjGNYKmo9sLb/y/lkviOlPNfWzTmjtOSLgq73A+ujPx/0y3J9IiI34pacgKrA4ym9/nAqFPccrntb9/u1QWdPIV/YbzBV2fQdeuzHfxkQTjnyxE//FvmzEYVhbl1QFFYI/gGVa3EFbXg2v0wWF7e6XeRPkz7LDHT1TTvG0w58PtSXR3yCrYZQF4LZfexzXVSFE5711Cx+56oCtIpASQ4WvmX8Th2tbd5IaiBGFbMJ9B0PKE1I4dj/APT+8KsP0PQZv7qQ+6hE69GfDe4dty7HL9ifUfCiwBUHJp45HNGtFz4NsfvLS9FzaPrU136LfOWjnWZcCWX4DF/jtVQ2AOeaVovIkfYkHS3mqD9qA//GKHpEmFLLYt1854Rjq0dQ30GVXKnDA6uvSugPs90TzlPXsX3kwIpnbxFPYCGjNtAAKa6Rz6NuLDQI6P5R/i3Jn2JtVNZWQS1LNbXxy3rZnYl8ur7wHefu/BUOUxPeur9WZKf2jrwprLfgNqV2z6pJoI17+DN/GYZOnWBx1/NEH7kEtz+NUYZPf9XR22ZTb+j0PnHZed/1HA/qvodA/9dq23acA60mLROQ6LIq+ojNsEZ3pptFLYXVvuolWOEZteY3WnLeSmyVkDvfNjAuYi/2ZCBRo3jZqIOEVlReTmNGMVj/Vaa5imuPyUpe68pTu/MbYkaUA93M9VXQ8RoH0SGSkm9nWFAG+jsHM6b2W2XAyXJOZ5laXamDyX3q0sHA8sKLK69R6BoZPMw994ORUjlq+H7LzUXpUpGxA8SKs5TSFY0UwjxTfBTm3vYUkPuzq6/ngljqr0uZXA3I23Kh+9qscaTG2tueHHeoe2KqPVYu2bGrStgP0z+P85ueEQUuHk3fw+mILFJdPIbx4356RmMbZnGrzkNqqbrkO/1jitS0xpEhxbEs1/mRk5ajv3KcDPWcsZ4k+/ioax2Ih47/HasaNXNI2bZL227tjbh201yemr7uZoI2DdU9lXymGA0eajX5lpkMlJaYXsJUQBvDErRNe64tyE4ixQIMjSxyiakswA/0PsbUq+8HZAku9A7oh2scrCvtPi8b/r0OiBvU/1RL+7SsBLZQIuxBQOPgfrZvoy9yL6dpQWS+Kq5RF+/0fhgv7JKGo6dAjVJ1ffuq4GGI0ZhFUnmsPaajHC+wki3a7NxeO2eL4CghF64X91Rx86DkmQ9uxlAjMHJE+j50RcrsQsCR5I18lLoVsMGsP989o8fFuHZl71636p195kuw3Ct2lhbm+u2u0x5MIZGgnRvsrhwHOxuaKuSmKwGcxHel5v7Lu2IaAMPHb9lXOvztgiNbMc4Iz+mQXS9/TMHbyEa6xc7pQx11flUT+En2MWJ2ZNeX10PeK2mO+o3mfsDC0q4YcG1KqJmPZAKqNLSi/0AaxlTJx31QTuv3tWn9uEtVhO2bM/4+VlgO2SdH9xuqMOmYuLhppY6FUMhSMr4kS2IzUCtfTIHP5yY43m7RP9Cg0B7GbCpuUf0Ar23B+ZjGQwlp7V0NMP72taP0IfW5P4AGTvE0tbDtcigFySAABrQO1lGkfBm6C6m/6LQySQnwov3/1T/+jP7DvcUGXkSaIRpQENvox/YhCD9/5IQg/dROJWaH7xYP6NY61swltcz91o1iIR8vjWHpgdShTfd4Sxj0KS81kpDKFMGDkkLlQN4NaFayAvQExfL7K6OIw+anag5RF9R5wfeBw0Ru+Tk8Cy9f1ftckaoDLaBB1noMRVNzFFp7x2DtR++0cED2iGian2he4a3eL3ShRk6EcpOBjPGyayRS+peHgd/ZK+muvm4kL4TPn2zgQ+R/7l/8/CprutaCs0q6bs5+s4mSW1PG8iQAN7i8nVgv/nj9w0z2cZbEmH8TCnxXwHLNAl9uggbXAMHnfnCk9tl86evxtmDvAzFH8sgmciFqU3OqAyg11EgOKueU8kicN1oTExZeYQDbAAAAA=="
IMG_SHADOWROCKET = "data:image/webp;base64,UklGRj4EAABXRUJQVlA4IDIEAABwFgCdASpgAGAAPkkijkUioiETKk08KASEoA1iPH/Hcq5wDtd4z8uXlX8T9QDxN+kB5gOgB6AH9V/wHWN+gB+wHpY/uj8Fn7gftd7UurV+ANCdy1GXt8GUnyZ8Cl8AeoGkpxo+hJnj+qSPyOpwM+zSw5Jp6WQHC3D94YW7MS9k3CCiWM8gysReo0fB4wTxBVXBPzPz6tIH7sDaT/cXgt4ytUMfl0TcAsiYw6l6fXVIwx6T90N0NoJxaEDAAAD+/cCWe4WmLhHGgleFZkjqkAvda/k4Lm7f+Ziiypvox/+AN+toyfzCyd0uHO5Lx3h3NHGTpqkihpJcpP2zGhVD7Bbbko+AVKDe64CQOlgDQKvwKkDGtRaxpciVuOcnK9WZbn1aTGeXcrq1cDnox8E9SKqkevYBwVj015ayf7+wubGdxxePmQXHoxap8YiJnD3lT/i89gEhbo5tCyW3N8cP2lI1IDUsDv1EphZrvn4ucc+moDGgpJnYCKxF4aNotzXI5KOntu+23Q6Ctf3zQx2oiQo3l9XOB+9yaeWOSULVCvDT/DzV8fPHiAHdb/GKoDY2eDALT2Jd9UQylyLEqh5XMv1gA3MngprDwDTzOzsultvxlHk3pwho6KPJxT2z9NRxmPCTi5E6Y6TBKEF2Sz9/981ru3ZqJ1H2k+tWRdjfWxrebrYSBCUXWhf3bHK7cmH2qXZuutm8fl0OWilh340vEdP+RvSgndA03DE0472H4ql6Lv6anRvmjt+9vrNm83S3KSAdTrNmHMIxm8pU8hBsdydLHkIA2vbiskLbsSgRi7l+EDWHKm+eTNzj3JzxNQa4OPmscddBVICjpfxDrc9GW6Twh3r16WXhbjxv1LxOOrqRfNo3kN5kFRnxrM9TJKP/WW/c345WIi+mhj/fAfjrDCQq5s4xNWD27r0DLq9EZc0m/j5Bngzqa0ec3Ie4s8PGQY77oU9fkQF7qT27/0QUYIMXV45+Zylqv536+qwdvDAlg+bKkKkuJZQl47f+vPqji+7nX+f0zkr4y5gxi4fY7YhJIWsWLif9XKQCtSTkTdbLVP4JDQ+Krbvy4wRQrbyWs9LfGCqFRc1y10sJ/1U3XxkIBmm/EX/N+Vq3rHjGmEdcfoCUQYj+nQk7u6jXKaZlyzjT+ttFMGDFbJTP+58lNbdEAvXLanzH7bLxOjfCeQEATeo/0bGIUpLIsBbBDjC6j1j6omt/HbX8wZqJ6fw59DTxn4OXyWxH1dl1glNra2Bp+scOq+G9dskeF9BEOEQGS59AnAOJ8XdBvzob6/6MJX2CeSzZhe12ia/Y3Hbuze7oQTELx1rpjSMXO1OFNRNfmu7tNriXnvv65+T95ctItPkiIL4vV3b3YzcDaXmFbI4F6OqD6qXOECtdkEVz7bSarFJAnXB8PxsPSO084YDFtci4AAA="
IMG_STREISAND = "data:image/webp;base64,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"

# Base64 SVGs
SVG_V2RAYNG = """<svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="m9.6185,41.4866V10.6142h-4.1185v-4.0722h10.2641v14.3936c.6957-.6404,1.2872-1.1794,1.8728-1.7248,3.5152-3.2745,7.0291-6.5504,10.5432-9.826.9416-.8777,1.8767-1.7624,2.8301-2.6271.1437-.1303.3712-.2375.5603-.2382,3.5668-.0136,10.9295,0,10.9295,0-10.9555,11.6366-21.8724,23.2736-32.8815,34.9672Z"/></svg>"""
SVG_SINGBOX = """<svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><path d="M40.7241,15.6976l-15.4896-10.8095c-.7416-.5175-1.7273-.5175-2.4689,0L7.2759,15.6976c-.9141.6379-.9141,1.9909,0,2.6288l15.4896,10.8095c.7416.5175,1.7273.5175,2.4689,0l15.4896-10.8095c.9141-.6379.9141-1.9909,0-2.6288Z"/><path d="M41.4096,17.012v13.976c0,.4977-.2285.9954-.6855,1.3144l-15.4896,10.8095c-.7416.5175-1.7273-.5175-2.4689,0l-15.4896-10.8095c-.457-.3189-.6855-.8167-.6855-1.3144h0s0-13.976,0-13.976"/><line x1="24" y1="29.524" x2="24" y2="43.5"/><path d="M11.8734,12.4893l18.3951,13.1335v3.8047c0,.6869.7673,1.0951,1.3369.7111l4.3991-2.9651c.2961-.1996.4735-.5332.4735-.8903v-4.9939l-18.3951-13.1335"/></svg>"""
SVG_V2RAYTUN = """<svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><rect x="5.5" y="5.5" width="37" height="37" rx="4" ry="4"/><polyline points="28.9436 11.2023 20.4652 36.7977 11.9867 11.2023"/><path d="M28.3091,29.0207c0-2.3774,2.1537-4.2518,4.6165-3.7785,1.6155.3105,2.9055,1.7076,3.0663,3.3447.1195,1.2178-.2658,2.4194-1.1069,3.1576-1.5583,1.3675-6.5759,5.053-6.5759,5.053h7.7042"/></svg>"""
SVG_HAPP = """<svg viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2"><polyline points="11.9387 18.636 11.2805 19.2322 13.2164 6.3148 21.6618 6.3148 21.082 10.1846"/><polyline points="20.2585 28.1999 18.113 42.5 9.6674 42.5 10.3198 38.1088"/><polyline points="28.1728 36.5585 27.2773 42.5 35.7228 42.5 37.9603 27.5876 36.0158 29.2999"/><polyline points="21.0144 27.3598 27.8555 27.3598 26.2122 38.3731 36.0158 29.2999 39.1998 8.0038 29.2593 17.99 28.8029 21.0714 27.2773 21.0714 26.4784 21.8658"/><polygon points="26.4784 21.8658 20.2243 28.1543 18.9689 28.1543 18.752 29.6379 8.8002 39.6355 11.9387 18.636 21.7423 9.5743 19.9047 21.8658 26.4784 21.8658"/><polyline points="38.0794 9.1294 38.6261 5.5 30.1808 5.5 28.1701 18.9112 29.2593 17.99"/></svg>"""

def copy_headers(upstream_headers, flask_resp):
    for k, v in upstream_headers.items():
        if k.lower() not in HOP_BY_HOP and k.lower() != 'content-type':
            try: flask_resp.headers[k] = v.encode('latin-1').decode('latin-1')
            except: flask_resp.headers[k] = v.encode('utf-8').decode('latin-1')

def process_cfg(cfg, is_hybrid):
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
            st["finalmask"] = {"tcp": FINALMASK_TCP_HYBRID if is_hybrid else FINALMASK_TCP}
            if "tlsSettings" in st:
                st["tlsSettings"].pop("alpn", None)
                st["tlsSettings"].update({"cipherSuites": CIPHER_SUITES, "allowInsecure": False, "show": False, "fingerprint": "unsafe"})
            if "wsSettings" in st:
                h = st["wsSettings"].pop("host", None); st["wsSettings"].pop("heartbeatPeriod", None)
                st["wsSettings"]["headers"] = {"Host": h} if h else {}
            out["streamSettings"] = st
        elif tag == "direct": out["settings"] = {"domainStrategy": "UseIP"}
    return cfg

def process_uri(uri, is_hybrid):
    if not uri.startswith("vless://"): return uri
    try:
        b_url, rem = uri.split("#", 1)
        if not any(k in urllib.parse.unquote(rem) for k in TARGET_KEYWORDS): return uri
        hp, qp = b_url.split("?", 1) if "?" in b_url else (b_url, "")
        params = dict(urllib.parse.parse_qsl(qp))
        params.update({"fp": "unsafe", "cs": CIPHER_SUITES, "fm": json.dumps({"tcp": FINALMASK_TCP_HYBRID if is_hybrid else FINALMASK_TCP}), "allowInsecure": "0", "insecure": "0"})
        new_q = urllib.parse.urlencode(params, quote_via=urllib.parse.quote)
        return f"{hp}?{new_q}#{rem}"
    except: return uri

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def smart_router(path):
    user_agent = request.headers.get('User-Agent', '').lower()
    qs = request.query_string.decode('utf-8')
    accept_header = request.headers.get('Accept', '').lower()
    host_header = request.headers.get('Host', '')

    # Known VPN Core & Client Tokens
    is_vpn_client = any(k in user_agent for k in [
        'patt', 'patn', 'v2ray', 'v2box', 'shadowrocket', 'happ', 'npv', 'incy',
        'streisand', 'sing-box', 'clash', 'surge', 'loon', 'flclash', 'mihomo', 'meta',
        'okhttp', 'dart', 'go-http-client', 'cfnetwork'
    ])

    # 1. Dashboard Check (Only serve to real web browsers)
    is_browser = False
    if 'text/html' in accept_header and not is_vpn_client:
        is_browser = True

    if is_browser:
        host = host_header
        current_url = "https://" + host + "/" + path + ("?" + qs if qs else "")
        encoded_url = urllib.parse.quote(current_url, safe='')
        b64_url = base64.b64encode((current_url + "?flag=shadowrocket").encode('utf-8')).decode('utf-8')
        
        try:
            panel_port = SUB_BASE_URL.split(':')[-1].split('/')[0]
            if not panel_port.isdigit(): panel_port = "2020"
        except: panel_port = "2020"
        
        panel_scheme = "https" if "https" in SUB_BASE_URL else "http"
        panel_url = panel_scheme + "://" + host.split(':')[0] + ":" + panel_port + "/"
        
        clean_path = path
        if clean_path.startswith('sub/'): clean_path = clean_path[4:]
        elif clean_path.startswith('json/'): clean_path = clean_path[5:]
        
        # Super-Fast Dynamic Info Fetch via single HEAD request!
        sub_title = "CO VPN"
        announce_text = ""
        
        try:
            r_stats = requests.head(f"{SUB_BASE_URL}/sub/{clean_path}", headers={'User-Agent': 'happ'}, timeout=3, verify=False)
            
            # Fetch Title
            title_hdr = r_stats.headers.get('Profile-Title', '')
            if title_hdr.startswith('base64:'):
                try: sub_title = base64.b64decode(title_hdr.split('base64:')[1]).decode('utf-8')
                except: pass
            elif title_hdr:
                sub_title = urllib.parse.unquote(title_hdr)
                
            # Fetch Announce
            ann_hdr = r_stats.headers.get('Announce', '')
            if ann_hdr.startswith('base64:'):
                try: announce_text = base64.b64decode(ann_hdr.split('base64:')[1]).decode('utf-8')
                except: pass
            elif ann_hdr:
                announce_text = urllib.parse.unquote(ann_hdr)
                
        except: pass

        alert_box_html = ""
        if announce_text:
            alert_box_html = f"""
            <div class="alert-box">
                <span style="font-size: 20px;">ℹ</span>
                <div>{announce_text}</div>
            </div>
            """

        html_landing = """
        <!DOCTYPE html>
        <html dir="ltr" lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>__SUB_TITLE__</title>
            <link href="https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css" rel="stylesheet" type="text/css" />
            <script>
                const getTheme = () => localStorage.getItem('theme') || (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
                document.documentElement.className = getTheme();
            </script>
            <style>
                :root { 
                    --bg: #f4f7f6; --card: #fff; --tile: #f8fafc; --border: #e2e8f0; 
                    --text: #0f172a; --muted: #64748b; --accent: #7c3aed; --accent-bg: #7c3aed1a; 
                    --row-hover: #f1f5f9;
                }
                html.dark { 
                    --bg: #101116; --card: #23252b9e; --tile: #2d2f37; --border: #ffffff14; 
                    --text: #fff; --muted: #94a3b8; --accent: #a78bfa; --accent-bg: #a78bfa1a; 
                    --row-hover: #a78bfa1f;
                }
                body { background: var(--bg); color: var(--text); font-family: 'Vazirmatn', -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; min-height: 100vh; transition: background 0.3s, color 0.3s; }
                html.dark body { background: radial-gradient(ellipse 120% 90% at 18% -10%, #1f1740 0%, #16171d 52%, #101116 100%); }
                .sub-content { padding: 32px 16px; max-width: 600px; margin: 0 auto; position: relative; z-index: 1;}
                .sub-card { background: var(--card); border: 1px solid var(--border); box-shadow: 0 4px 24px rgba(0,0,0,0.1); backdrop-filter: blur(24px) saturate(180%); border-radius: 20px; padding: 28px; transition: 0.3s;}
                html.dark .sub-card { box-shadow: 0 1px 3px #0006, 0 24px 64px #6d28d93d; }
                .sub-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); padding-bottom: 20px; margin-bottom: 24px; }
                .sub-brand { display: flex; align-items: center; gap: 12px; }
                .sub-brand-mark { width: 44px; height: 44px; background: linear-gradient(135deg, #a78bfa, #22d3ee); color: #fff; border-radius: 13px; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: bold; }
                .sub-brand-title { font-size: 20px; font-weight: 700; margin: 0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 250px;}
                .theme-toggle { background: var(--tile); border: 1px solid var(--border); color: var(--text); width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; font-size: 18px; transition: 0.3s; }
                .theme-toggle:hover { background: var(--row-hover); color: var(--accent); }
                .alert-box { background: #2c1618; border: 1px solid #5b2526; border-radius: 8px; padding: 12px 16px; display: flex; align-items: center; gap: 12px; margin-bottom: 24px; color: rgba(255,255,255,0.85); text-align: right; direction: rtl;}
                html:not(.dark) .alert-box { background: #e0e7ff; border-color: #c7d2fe; color: #3730a3; }
                .sub-tabs { display: flex; gap: 16px; margin-bottom: 20px; border-bottom: 1px solid var(--border); }
                .tab-btn { background: transparent; color: var(--muted); border: none; font-size: 15px; cursor: pointer; padding: 12px 0; font-weight: 500; position: relative; }
                .tab-btn.active { color: var(--accent); }
                .tab-btn.active::after { content: ""; position: absolute; bottom: -1px; left: 0; right: 0; height: 3px; background: linear-gradient(90deg, #a78bfa, #22d3ee); border-radius: 2px; }
                html:not(.dark) .tab-btn.active::after { background: linear-gradient(90deg, #7c3aed, #06b6d4); }
                .tab-content { display: none; }
                .tab-content.active { display: block; }
                .sub-app-grid { display: grid; grid-template-columns: repeat(2, minmax(0,1fr)); gap: 10px; }
                @media (max-width: 576px) { .sub-app-grid { grid-template-columns: minmax(0,1fr); } }
                .sub-row { background: var(--accent-bg); border: 1px solid var(--border); border-radius: 12px; padding: 10px 12px; display: flex; align-items: center; gap: 10px; text-decoration: none; transition: 0.2s; cursor: pointer; }
                .sub-row:hover { background: var(--row-hover); border-color: var(--accent); transform: translateY(-1px); }
                .sub-app-logo { width: 32px; height: 32px; border-radius: 9px; object-fit: cover; box-shadow: 0 0 0 1px var(--border); flex-shrink: 0; }
                .sub-app-glyph { width: 32px; height: 32px; border-radius: 9px; flex-shrink: 0; display:flex; align-items:center; justify-content:center; background: #292e42; color:#a78bfa;}
                html:not(.dark) .sub-app-glyph { background: #f1f5f9; color: #7c3aed; }
                .sub-app-glyph svg { width: 20px; height: 20px; }
                .sub-app-name { color: var(--text); font-size: 14px; flex: 1; font-weight: 500; }
                .add-btn { background: var(--tile); color: var(--accent); border: 1px solid var(--border); padding: 4px 12px; border-radius: 6px; font-size: 13px; font-weight: 600; pointer-events: none; transition: 0.2s; }
                .copy-section { margin-top: 24px; }
                .copy-box { background: var(--accent-bg); border: 1px dashed var(--border); border-radius: 12px; padding: 12px; display: flex; align-items: center; gap: 10px; }
                .copy-box span { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 13px; color: var(--muted); font-family: monospace; }
                .copy-btn { background: var(--tile); color: var(--text); border: 1px solid var(--border); padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; }
                .footer-link { display: block; text-align: center; margin-top: 24px; color: var(--muted); text-decoration: none; font-size: 13px; }
                .footer-link:hover { color: var(--accent); }
            </style>
        </head>
        <body>
            <div class="sub-content">
                <div class="sub-card">
                    <div class="sub-header">
                        <div class="sub-brand">
                            <div class="sub-brand-mark">C</div>
                            <div class="sub-brand-title">__SUB_TITLE__</div>
                        </div>
                        <button class="theme-toggle" onclick="toggleTheme()">🌙</button>
                    </div>
                    
                    __ALERT_BOX__
                    
                    <div class="sub-tabs">
                        <button class="tab-btn active" onclick="switchTab('android', this)">Android</button>
                        <button class="tab-btn" onclick="switchTab('ios', this)">iOS</button>
                    </div>
                    
                    <div id="android" class="tab-content active">
                        <div class="sub-app-grid">
                            <a href="v2box://install-sub?url=__ENCODED_URL__&name=Premium%20Sub" class="sub-row">
                                <img class="sub-app-logo" src="__IMG_V2BOX__">
                                <span class="sub-app-name">V2Box</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="v2rayng://install-config?url=__ENCODED_URL__" class="sub-row">
                                <span class="sub-app-glyph">__SVG_V2RAYNG__</span>
                                <span class="sub-app-name">v2rayNG</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="sing-box://import-remote-profile?url=__ENCODED_URL__#Premium%20Sub" class="sub-row">
                                <span class="sub-app-glyph">__SVG_SINGBOX__</span>
                                <span class="sub-app-name">Sing-box</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="v2raytun://import/__CURRENT_URL__" class="sub-row">
                                <span class="sub-app-glyph">__SVG_V2RAYTUN__</span>
                                <span class="sub-app-name">V2RayTun</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="happ://add/__CURRENT_URL__" class="sub-row">
                                <span class="sub-app-glyph">__SVG_HAPP__</span>
                                <span class="sub-app-name">Happ</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="incy://add/__CURRENT_URL__" class="sub-row">
                                <img class="sub-app-logo" src="__IMG_INCY__">
                                <span class="sub-app-name">Incy</span>
                                <span class="add-btn">Add</span>
                            </a>
                        </div>
                    </div>
                    
                    <div id="ios" class="tab-content">
                        <div class="sub-app-grid">
                            <a href="shadowrocket://add/sub://__B64_URL__?remark=Premium%20Sub" class="sub-row">
                                <img class="sub-app-logo" src="__IMG_SHADOWROCKET__">
                                <span class="sub-app-name">Shadowrocket</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="v2box://install-sub?url=__ENCODED_URL__&name=Premium%20Sub" class="sub-row">
                                <img class="sub-app-logo" src="__IMG_V2BOX__">
                                <span class="sub-app-name">V2Box</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="streisand://import/__ENCODED_URL__" class="sub-row">
                                <img class="sub-app-logo" src="__IMG_STREISAND__">
                                <span class="sub-app-name">Streisand</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="v2raytun://import/__CURRENT_URL__" class="sub-row">
                                <span class="sub-app-glyph">__SVG_V2RAYTUN__</span>
                                <span class="sub-app-name">V2RayTun</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="happ://add/__CURRENT_URL__" class="sub-row">
                                <span class="sub-app-glyph">__SVG_HAPP__</span>
                                <span class="sub-app-name">Happ</span>
                                <span class="add-btn">Add</span>
                            </a>
                            <a href="foxray://install-sub?url=__ENCODED_URL__&name=Premium%20Sub" class="sub-row">
                                <span class="sub-app-glyph" style="font-size: 16px; background: transparent; box-shadow: 0 0 0 1px var(--border);">🦊</span>
                                <span class="sub-app-name">FoXray</span>
                                <span class="add-btn">Add</span>
                            </a>
                        </div>
                    </div>
                    
                    <div class="copy-section">
                        <div class="copy-box">
                            <span id="subLink">__CURRENT_URL__</span>
                            <button class="copy-btn" onclick="copyText(this)">Copy</button>
                        </div>
                    </div>
                    
                    <a href="__PANEL_URL__" class="footer-link">ورود به پنل کاربری اصلی →</a>
                </div>
            </div>
    
            <script>
                function toggleTheme() {
                    const html = document.documentElement;
                    const btn = document.querySelector('.theme-toggle');
                    if(html.classList.contains('dark')) {
                        html.classList.remove('dark');
                        html.classList.add('light');
                        localStorage.setItem('theme', 'light');
                        btn.innerText = "☀";
                    } else {
                        html.classList.remove('light');
                        html.classList.add('dark');
                        localStorage.setItem('theme', 'dark');
                        btn.innerText = "🌙";
                    }
                }
                document.querySelector('.theme-toggle').innerText = document.documentElement.classList.contains('dark') ? "🌙" : "☀️";
                function switchTab(tabId, btn) {
                    document.querySelectorAll('.tab-content').forEach(e => e.classList.remove('active'));
                    document.querySelectorAll('.tab-btn').forEach(e => e.classList.remove('active'));
                    document.getElementById(tabId).classList.add('active');
                    btn.classList.add('active');
                }
                function copyText(btn) {
                    var txt = document.getElementById("subLink").innerText;
                    navigator.clipboard.writeText(txt);
                    btn.innerText = "Copied!";
                    btn.style.background = "#10b981";
                    btn.style.color = "#fff";
                    setTimeout(() => { 
                        btn.innerText = "Copy"; 
                        btn.style.background = "var(--tile)";
                        btn.style.color = "var(--text)";
                    }, 2000);
                }
            </script>
        </body>
        </html>
        """
        
        html_landing = html_landing.replace("__SUB_TITLE__", sub_title)
        html_landing = html_landing.replace("__ALERT_BOX__", alert_box_html)
        html_landing = html_landing.replace("__CURRENT_URL__", current_url)
        html_landing = html_landing.replace("__ENCODED_URL__", encoded_url)
        html_landing = html_landing.replace("__B64_URL__", b64_url)
        html_landing = html_landing.replace("__PANEL_URL__", panel_url)
        
        html_landing = html_landing.replace("__IMG_V2BOX__", IMG_V2BOX)
        html_landing = html_landing.replace("__IMG_INCY__", IMG_INCY)
        html_landing = html_landing.replace("__IMG_SHADOWROCKET__", IMG_SHADOWROCKET)
        html_landing = html_landing.replace("__IMG_STREISAND__", IMG_STREISAND)
        html_landing = html_landing.replace("__SVG_V2RAYNG__", SVG_V2RAYNG)
        html_landing = html_landing.replace("__SVG_SINGBOX__", SVG_SINGBOX)
        html_landing = html_landing.replace("__SVG_V2RAYTUN__", SVG_V2RAYTUN)
        html_landing = html_landing.replace("__SVG_HAPP__", SVG_HAPP)
        
        return Response(html_landing, content_type='text/html; charset=utf-8')

    # ================== 2. SMART ROUTER LOGIC (CLIENTS) ==================
    target_format = 'json'
    is_hybrid = True

    # Robust detection for PattN & PattNG
    if any(k in user_agent for k in ['patt', 'patn', 'pattn', 'pattng', 'patt-ng', 'patt_ng']):
        target_format = 'base64'
        is_hybrid = False
    elif host_header.endswith(f":{PORT1}") and not ('json' in path):
        target_format = 'base64'
        is_hybrid = False
    elif 'v2ray' in user_agent:
        target_format = 'json'
        is_hybrid = False
    elif any(c in user_agent for c in ['flclash', 'clash', 'mihomo', 'meta']):
        target_format = 'yaml'
        is_hybrid = True

    clean_path = path
    if clean_path.startswith('sub/'): clean_path = clean_path[4:]
    elif clean_path.startswith('json/'): clean_path = clean_path[5:]

    # Log incoming request for live inspection
    try:
        with open('/opt/sub_server/sub_access.log', 'a', encoding='utf-8') as f:
            f.write(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] IP: {request.remote_addr} | Host: {host_header} | Path: {path} | UA: {request.headers.get('User-Agent', '')} | Format: {target_format}\n")
    except Exception: pass

    panel_url = f"{SUB_BASE_URL}/json/{clean_path}" if target_format == 'json' else f"{SUB_BASE_URL}/sub/{clean_path}"
    if qs:
        if target_format == 'json' and 'view=raw' not in qs: panel_url += f"?{qs}&view=raw"
        else: panel_url += f"?{qs}"
    else:
        if target_format == 'json': panel_url += "?view=raw"

    client_headers = {k: v for k, v in request.headers if k.lower() not in ['host', 'accept-encoding']}
    if 'user-agent' not in [k.lower() for k in client_headers]:
        client_headers['User-Agent'] = 'v2rayN/6.42'

    try:
        resp = requests.get(panel_url, headers=client_headers, verify=False, timeout=15)
        
        if target_format == 'yaml':
            try:
                import yaml
                data = yaml.safe_load(resp.text)
                if data and 'proxies' in data:
                    for p in data['proxies']:
                        if any(k in p.get('name', '') for k in TARGET_KEYWORDS):
                            if p.get('type') in ['vless', 'vmess', 'trojan']:
                                p['client-fingerprint'] = 'chrome'
                                if is_hybrid:
                                    p['fragment'] = {"packets": "tlshello", "length": "100-200", "interval": "10-20"}
                                else:
                                    p['fragment'] = {"packets": "1-1", "length": "10-20", "interval": "10-20"}
                    modified_yaml = yaml.dump(data, allow_unicode=True, sort_keys=False)
                    res = make_response(modified_yaml)
                    res.headers['Content-Type'] = resp.headers.get('Content-Type', 'text/yaml; charset=utf-8')
                    copy_headers(resp.headers, res)
                    return res
            except Exception: pass
            res = make_response(resp.text)
            copy_headers(resp.headers, res)
            return res
            
        elif target_format == 'json':
            data = resp.json()
            mod_data = [process_cfg(c, is_hybrid) for c in data] if isinstance(data, list) else process_cfg(data, is_hybrid) if isinstance(data, dict) else data
            flask_resp = jsonify(mod_data)
            copy_headers(resp.headers, flask_resp)
            return flask_resp
            
        else:
            raw = resp.text.strip()
            raw += '=' * (-len(raw) % 4)
            try: dec = base64.b64decode(raw).decode('utf-8')
            except: dec = resp.text
            
            mod_lines = [process_uri(l.strip(), is_hybrid) for l in dec.split('\n') if l.strip()]
            final_b64 = base64.b64encode('\n'.join(mod_lines).encode('utf-8')).decode('utf-8')
            
            res = make_response(final_b64)
            res.headers['Content-Type'] = 'text/plain; charset=utf-8'
            copy_headers(resp.headers, res)
            return res

    except Exception as e:
        return jsonify({"error": f"Upstream fetch error: {str(e)}"}), 500
EOF

    BIND_ARGS="--bind 0.0.0.0:${MASTER_PORT}"
    for p in "$PORT1" "$PORT2" "$PORT3" "$PORT4" "$PORT5"; do
        if [ -n "$p" ]; then
            BIND_ARGS="$BIND_ARGS --bind 0.0.0.0:$p"
            iptables -I INPUT -p tcp --dport $p -j ACCEPT 2>/dev/null
        fi
    done
    iptables -I INPUT -p tcp --dport ${MASTER_PORT} -j ACCEPT 2>/dev/null

    cat << EOF > /etc/systemd/system/subserver_master.service
[Unit]
Description=Smart Router Sub Server (Unified Master)
Wants=network-online.target
After=network-online.target
[Service]
User=root
WorkingDirectory=/opt/sub_server
ExecStart=/usr/bin/python3 -m gunicorn --workers ${WORKERS} --threads 20 ${BIND_ARGS} --certfile ${CERT_PATH} --keyfile ${KEY_PATH} --timeout 60 app_master:app
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

    netfilter-persistent save >/dev/null 2>&1

    echo -e "\e[33m[+] Reloading & Restarting Services...\e[0m"
    systemctl daemon-reload
    
    systemctl stop subserver5000 subserver5800 subserver5801 subserver5802 subserver5803 >/dev/null 2>&1
    systemctl disable subserver5000 subserver5800 subserver5801 subserver5802 subserver5803 >/dev/null 2>&1
    
    systemctl enable --now subserver_master >/dev/null 2>&1
    systemctl restart subserver_master >/dev/null 2>&1
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

    echo -e "\n\e[36m============= PERFORMANCE CONFIGURATION =============\e[0m"
    echo -e " 💡 \e[90mWorker Guidelines per service:\e[0m"
    echo -e "    \e[33m1 Worker\e[0m  -> ~80MB Total RAM (Handles 20 concurrent connections)"
    echo -e "    \e[33m2 Workers\e[0m -> ~150MB Total RAM (Handles 40 concurrent connections)"
    read -p "⚡ Enter Gunicorn workers for Master Port [$WORKERS]: " input </dev/tty; WORKERS=${input:-$WORKERS}

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
PORT5="$PORT5"
WORKERS="$WORKERS"
FM_VERSION="$FM_VERSION"
EOF

    ensure_dependencies
    deploy_services

    echo -e "\n\e[32m[✔] Settings saved and unified service deployed successfully!\e[0m"
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
    
    STATUS=$(systemctl is-active subserver_master 2>/dev/null)
    if [ "$STATUS" == "active" ]; then
        echo -e "  Port \e[36m${MASTER_PORT} (Smart Router - HTTPS)\e[0m: \e[32m● Running (Active)\e[0m"
    else
        echo -e "  Port \e[36m${MASTER_PORT}\e[0m: \e[31m● Stopped or Failed (${STATUS})\e[0m"
    fi
    
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
        systemctl stop subserver_master subserver5000 subserver5800 subserver5801 subserver5802 subserver5803 >/dev/null 2>&1
        systemctl disable subserver_master subserver5000 subserver5800 subserver5801 subserver5802 subserver5803 >/dev/null 2>&1
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
    echo "  5) 📌 Show Client Recommendations"
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

if [ ! -f "$CONFIG_FILE" ]; then
    first_run_menu
else
    main_menu
fi
