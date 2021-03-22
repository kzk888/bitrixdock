FROM nginx:1.18

ADD conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/
COPY letsencrypt/ /etc/letsencrypt/

RUN usermod -u 1000 www-data && apt-get update -y && apt install python-certbot-nginx -y

CMD ["nginx"]

EXPOSE 80 443
