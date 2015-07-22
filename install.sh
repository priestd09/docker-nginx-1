#!/bin/bash
set -e

# build apt cache
apt-get update

# install build dependencies
apt-get install -y gcc g++ make libc6-dev libpcre++-dev libssl-dev libxslt-dev libgd2-xpm-dev libgeoip-dev

# use maximum available processor cores for the build
alias make="make -j$(nproc)"

# download nginx-rtmp-module
mkdir /tmp/nginx-rtmp-module
wget https://github.com/arut/nginx-rtmp-module/archive/v${RTMP_VERSION}.tar.gz -O - | tar -zxf - --strip=1 -C /tmp/nginx-rtmp-module

# download ngx_pagespeed
mkdir /tmp/ngx_pagespeed
if [ -f /tmp/ngx_pagespeed-${NPS_VERSION}-beta.tar.gz ]; then
  tar -zxf /tmp/ngx_pagespeed-${NPS_VERSION}-beta.tar.gz --strip=1 -C /tmp/ngx_pagespeed
else
  wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.tar.gz -O - | tar -zxf - --strip=1 -C /tmp/ngx_pagespeed
fi

if [ -f /tmp/psol-${NPS_VERSION}.tar.gz ]; then
  tar -zxf /tmp/psol-${NPS_VERSION}.tar.gz -C /tmp/ngx_pagespeed
else
  wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz -O - | tar -zxf - -C /tmp/ngx_pagespeed
fi

# compile nginx with the nginx-rtmp-module
mkdir -p /tmp/nginx
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -O - | tar -zxf - -C /tmp/nginx --strip=1
cd /tmp/nginx

./configure --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin \
  --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log \
  --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --with-pcre-jit --with-ipv6 --with-http_ssl_module \
  --with-http_stub_status_module --with-http_realip_module \
  --with-http_addition_module --with-http_dav_module --with-http_geoip_module \
  --with-http_gzip_static_module --with-http_image_filter_module \
  --with-http_spdy_module --with-http_sub_module --with-http_xslt_module \
  --with-mail --with-mail_ssl_module \
  --add-module=/tmp/nginx-rtmp-module \
  --add-module=/tmp/ngx_pagespeed
make && make install
cp /tmp/nginx-rtmp-module/stat.xsl /usr/share/nginx/html/

# purge build dependencies
apt-get purge -y --auto-remove gcc g++ make libc6-dev libpcre++-dev libssl-dev libxslt-dev libgd2-xpm-dev libgeoip-dev

# cleanup
rm -rf /tmp/nginx /tmp/nginx-rtmp-module /tmp/ngx_pagespeed
rm -rf /var/lib/apt/lists/*
