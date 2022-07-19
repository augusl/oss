#!/bin/bash
#修改时区为东八区
timedatectl set-timezone Asia/Shanghai
#安装依赖包&&nginx certbot
apt update
apt install gcc make libsqlite3-dev nginx certbot -y

#安装vnstat
wget https://humdi.net/vnstat/vnstat-latest.tar.gz
tar zxvf vnstat-latest.tar.gz
# shellcheck disable=SC2164
cd vnstat-2.9
./configure --prefix=/usr --sysconfdir=/etc --disable-dependency-tracking && make && make install
cp -v examples/systemd/vnstat.service /etc/systemd/system/
systemctl enable vnstat
systemctl start vnstat
cp -v examples/init.d/ubuntu/vnstat /etc/init.d/
update-rc.d vnstat defaults
service vnstat start

#网络连接数统计
cat >~/connectstat.sh <<EOF
#!/bin/bash
connectstat_num=\$(netstat -na | awk '/^tcp/ {++S[\$NF]} END {for(a in S) print a, S[a]}' | grep ESTABLISHED | awk '{print \$2}')
cmd=\$(curl -X "POST" "https://api.prod.ibestproxy.com/api/connectstat?key=hetsbKKR" \
    -H 'Content-Type: application/json; charset=utf-8' \
    -d '{"num":'\$connectstat_num'}')
echo \${cmd}
EOF
chmod +x ~/connectstat.sh
crontab -l | {
    cat
    echo "*/10 * * * * ~/connectstat.sh >/dev/null 2>&1"
} | crontab -

#流量统计
cat >~/traffic.sh <<EOF
#!/bin/bash
vnstat_json=\$(/usr/bin/vnstat --json m 10)
cmd=\$(curl -X "POST" "https://api.prod.ibestproxy.com/api/traffic?key=hetsbKKR" \
    -H 'Content-Type: application/json; charset=utf-8' \
    -d \${vnstat_json})
echo \${cmd}
EOF
chmod +x ~/traffic.sh
crontab -l | {
    cat
    echo "59 * * * * ~/traffic.sh >/dev/null 2>&1"
} | crontab -

#每月带宽统计
cat >~/bandwidth.sh <<EOF
#!/bin/bash
vnstat_json=\$(/usr/bin/vnstat --json d 30)
cmd=\$(curl -X "POST" "https://api.prod.ibestproxy.com/api/bandwidth?key=hetsbKKR" \
    -H 'Content-Type: application/json; charset=utf-8' \
    -d \${vnstat_json})
echo \${cmd}
EOF
chmod +x ~/bandwidth.sh
crontab -l | {
    cat
    echo "0 * * * * ~/bandwidth.sh >/dev/null 2>&1"
} | crontab -

#https证书自动签发
service nginx stop
echo "Enter your domain name:"
# shellcheck disable=SC2162
read domain
certbot certonly --standalone -d "$domain" --email support@ibestproxy.com -n --agree-tos

#配置nginx 站点
cat >/etc/nginx/conf.d/ibestproxy.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name *.ibestproxy.com;
    root /usr/share/nginx/html;
    location / {
        proxy_ssl_server_name on;
        proxy_pass https://www.duckduckgo.com;
        proxy_set_header Accept-Encoding '';
        sub_filter_once off;
        }

    location = /robots.txt {
    }
}
EOF

#安装trojan
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
echo "" >/usr/local/etc/trojan/config.json
cat >/usr/local/etc/trojan/config.json <<EOF
{
  "run_type": "server",
  "aes_key": "RENGRTUyMTQ3NkI5ODNBIw==",
  "local_addr": "::",
  "local_port": 443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": [],
  "log_level": 1,
  "ssl": {
    "cert": "/usr/local/etc/trojan/fullchain1.pem",
    "key": "/usr/local/etc/trojan/privkey1.pem",
    "key_password": "",
    "sni": "",
    "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
    "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
    "prefer_server_cipher": true,
    "alpn": [
      "http/1.1"
    ],
    "alpn_port_override": {
      "h2": 81
    },
    "reuse_session": true,
    "session_ticket": false,
    "session_timeout": 600,
    "plain_http_response": "",
    "curves": "",
    "dhparam": ""
  },
  "tcp": {
    "prefer_ipv4": false,
    "no_delay": true,
    "keep_alive": true,
    "reuse_port": false,
    "fast_open": false,
    "fast_open_qlen": 20
  }
}
EOF

# shellcheck disable=SC2164
cd ~/
wget https://raw.githubusercontent.com/augusl/oss/main/uPic/trojan
rm -rf /usr/local/bin/trojan
mv trojan /usr/local/bin/
chmod +x /usr/local/bin/trojan
systemctl enable trojan
ln -sf /etc/letsencrypt/live/"$domain"/fullchain.pem /usr/local/etc/trojan/fullchain1.pem
ln -sf /etc/letsencrypt/live/"$domain"/privkey.pem /usr/local/etc/trojan/privkey1.pem
ll /usr/local/etc/trojan/
crontab -l | {
    cat
    echo "0 0 * * * systemctl stop nginx; certbot renew; systemctl start nginx; service trojan restart"
} | crontab -
systemctl restart nginx
systemctl restart trojan
systemctl status trojan
echo "Trojan is installed and running."
