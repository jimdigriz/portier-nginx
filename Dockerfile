FROM debian

SHELL ["/bin/sh", "-x", "-c"]

RUN apt-get update \
	&& apt-get -yy --option=Dpkg::options::=--force-unsafe-io upgrade \
	&& apt-get -yy --option=Dpkg::options::=--force-unsafe-io install --no-install-recommends \
		ca-certificates \
		libnginx-mod-http-lua \
                lua-json \
                lua-luaossl \
                lua-nginx-dns \
		lua-nginx-string \
		nginx-full \
	&& apt-get clean \
	&& find /var/lib/apt/lists -type f -delete

COPY nginx *.lua /opt/portier/nginx/

RUN mkdir -p /var/cache/nginx \
        && chown www-data /var/cache/nginx \
        && chmod 750 /var/cache/nginx
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /opt/portier/nginx/nginx /etc/nginx/sites-enabled/portier

ENTRYPOINT ["/bin/bash"]
