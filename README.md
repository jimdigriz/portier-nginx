nginx [Portier](https://portier.github.io/) Authentication.

Project supported by [NetworkRADIUS](https://networkradius.com/).

# Pre-flight

You will require:

 * nginx with Lua support
     * [`lua-json`](https://github.com/harningt/luajson)
     * [`lua-luaossl`](http://25thandclement.com/~william/projects/luaossl.html)
     * [`lua-nginx-dns`](https://github.com/openresty/lua-resty-dns)
     * [`lua-nginx-string`](https://github.com/openresty/lua-resty-string)

## Debian

    apt-get -yy install --no-install-recommends \
    	ca-certificates \
    	libnginx-mod-http-lua \
    	lua-json \
    	lua-luaossl \
    	lua-nginx-dns \
    	lua-nginx-string \
    	nginx-full

# Usage

This is still a Work-in-Progress so unfortunately you will have to slum it with a Docker container whilst I experiment and tidy things up...sorry, it is awful.

    docker build -t portier-nginx .
    docker run -it --rm -p 1080:80 portier-nginx

In the container run:

    /etc/init.d/nginx start

On your workstation in a browser go to: http://localhost:1080
