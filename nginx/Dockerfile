FROM nginx:1.18

ADD conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/

RUN apt-get update -y && apt install python-certbot-nginx -y
COPY letsencrypt/ /etc/letsencrypt/

RUN usermod -u 1000 www-data

CMD ["nginx", "certbot"]

EXPOSE 80 443
