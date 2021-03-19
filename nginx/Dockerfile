FROM nginx:1.18

RUN apt-get update && apt-get install -y apt-transport-https
RUN add-apt-repository ppa:certbot/certbot
RUN apt install python-certbot-nginx

ADD conf/nginx.conf /etc/nginx/
ADD conf/upstream.conf /etc/nginx/conf.d/
ADD conf/sites/*.conf /etc/nginx/conf.d/

RUN usermod -u 1000 www-data

CMD ["nginx"]

EXPOSE 80 443