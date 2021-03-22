FROM nginx:1.18

mkdir /etc/letsencrypt/

ADD conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/
COPY letsencrypt/ /etc/letsencrypt/

RUN usermod -u 1000 www-data

CMD ["nginx"]

EXPOSE 80 443
