nginx [Portier](https://portier.github.io/) Authentication.

Project supported by [NetworkRADIUS](https://networkradius.com/).

# Pre-flight

You will require:

 * nginx with Lua support, and your application running on it
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

# Deploy

The install process is pretty awful, mostly as everyones application environment is a bit bespoke, but these guidelines below should get you moving:

 1. create a directory `/opt/portier/nginx`
 1. copy all the `*.lua` files from this project into it
 1. inspect the sample `ngnix` configuration in the project
     * the portier-nginx parts are top-and-tailed with `####`
     * extract the `http { ... }` and `server { ... }` sections and graft them into your own nginx configuration
 1. restart nginx

When you start `nginx` you will see a warning in your error log similar to:

    2018/08/03 14:46:58 [warn] 8659#8659: [lua] i.lua:51: using runtime secret

This is harmless, but will mean every time you reload nginx any currently authenticated users will be logged out.  To prevent this you can set the secret to a static value with:

    dd if=/dev/random of=/opt/portier/nginx/secret bs=1 count=16
    chmod 640 /opt/portier/nginx/secret
    chown root:www-data /opt/portier/nginx/secret

# Development

Almost the easiest thing here is to slum it with a Docker container (sorry, it is awful) where you can run:

    docker build -t portier-nginx .
    docker run -it --rm -p 1080:80 portier-nginx

Now from within the container run:

    /etc/init.d/nginx start
    sudo apt-get update && sudo apt-get -y install --no-install-recommends php-cgi
    mkdir webroot
    printf "<?php\nphpinfo();\n?>" > webroot/index.php
    php -S 127.0.0.1:8000 -t webroot

On your workstation, point your browser at http://localhost:1080 and type in your email address to start off the authentication.  If it is successful, you should see the [`phpinfo()`](https://secure.php.net/manual/en/function.phpinfo.php) splash screen and if you scroll down you should find `$_SERVER['HTTP_REMOTE_USER']` is set to your email address.

## Functional Description

After a successful authentication, portier-nginx sets the session cookie `portier-nginx-email` and then uses that going forward.  The cookie is made up of the tuple:

    [hmac type]:[hmac truncated to 80bits]:[created time]:[email]

Currently [`md5`](https://tools.ietf.org/html/rfc6151#section-2.3) is used as the HMAC and these cookies expire after 18 hours of inactivity (renewing on each request during their validity).
