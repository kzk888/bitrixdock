FROM nginx:1.18

ADD conf/nginx.conf /etc/nginx/
COPY conf/conf.d/ /etc/nginx/conf.d/

RUN apt-get update -y && apt install python-certbot-nginx -y
RUN usermod -u 1000 www-data

CMD ["nginx"]

EXPOSE 80 443
