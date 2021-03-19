FROM nginx:1.18

RUN apt-get update && apt-get install -y apt-transport-https
RUN apt install python3 python3-dev py3-pip build-base libressl-dev musl-dev libffi-dev
RUN pip3 install pip --upgrade
RUN pip3 install certbot-nginx
RUN mkdir /etc/letsencrypt

ADD conf/nginx.conf /etc/nginx/
ADD conf/upstream.conf /etc/nginx/conf.d/
ADD conf/sites/*.conf /etc/nginx/conf.d/

RUN usermod -u 1000 www-data

CMD ["nginx"]

EXPOSE 80 443