FROM ubuntu:22.04

LABEL Maintainer="build docker images by @feilongproject"
LABEL Description="blessing-skin-server container with Nginx 1.18.0 & PHP 8.1.2 based on Ubuntu 22.04"

# 设置时区
ENV TZ=Asia/Shanghai
RUN echo "${TZ}" > /etc/timezone && \
  ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime

# 尽早安装依赖，以便利用 Docker 缓存
COPY ./config/sources.list /etc/apt/sources.list
RUN apt-get update -y && apt-get install supervisor systemctl curl lsof vim git zip wget nginx php8.1 redis php8.1-redis php8.1-mysql php8.1-sqlite php8.1-fpm php8.1-gd php8.1-mbstring php8.1-xml php8.1-zip php8.1-pgsql -y

WORKDIR /var/www/blessing-skin/

COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/50x.html /var/www/html/50x.html
COPY ./config/fpm-pool.conf /etc/php/8.1/fpm/php-fpm.conf
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY ./src /var/www/blessing-skin

# 处理 .env
RUN mkdir -p storage && \
  mv .env.example storage/.env && \
  ln -s storage/.env .env

# 设置插件目录
RUN mkdir storage/plugins && \
  sed 's/PLUGINS_DIR=null/PLUGINS_DIR=\/var\/www\/blessing-skin\/storage\/plugins/' -i storage/.env

RUN chown -R www-data:www-data /var/www/blessing-skin && \
  ls -alh /var/www/ /var/www/blessing-skin

RUN php -v
RUN php artisan key:generate

EXPOSE 80

VOLUME [ "/var/www/blessing-skin/storage" ]

CMD ["/usr/bin/python3.10","/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]
