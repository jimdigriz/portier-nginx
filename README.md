nginx [Portier](https://portier.github.io/) Authentication.

Handles all the Portier Relying Party (aka client side) work inside `nginx` and the result is an nginx variable set to the users email address that can be added to an HTTP header or FCGI variable to the application being served for use as an external authenticator.  Once authenticated, the user receives a session cookie that expires after 18 hours of inactivity.

Project sponsored by [NetworkRADIUS](https://networkradius.com/).

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

The install process is pretty awful, mostly as everyone's application environment is a bit bespoke, but these guidelines below should get you moving:

 1. create a directory `/opt/portier/nginx`
 1. copy all the `*.lua` files from this project into it
 1. copy [`webroot`](webroot) from this project into it
 1. inspect the sample [`ngnix`](nginx) configuration in the project
     * the portier-nginx parts are top-and-tailed with `####`
     * extract the `http { ... }` and `server { ... }` sections and graft them into your own nginx configuration
     * in the example `location / { ... }` shows how to use `a.lua` with HTTP (setting `X-Portier-Nginx-Email`) and FCGI (setting `REMOTE_USER`) backends
 1. restart nginx

Hopefully everything starts up okay, and depending on how you reconciled the [sample `nginx` configuration](nginx) with your existing one, when you open your application you should be directed to a login screen.

Type in your email address, walk through the authentication flow and you then should be able to access your application.

To logout, send the user to `/.portier/logout` which will delete the cookie and redirect the user to `/`.

## Configuration

### Login Page

Edit [`webroot/index.html`](webroot/index.html) to suit your cosmetic needs.

### Broker

By default, the broker used is `https://broker.portier.io` but this is can be overridden by setting the environment variable `PORTIER_BROKER` to another URL.

### Nameservers

By default, the nameservers used to assist in email address validation are [Google's resolvers](https://developers.google.com/speed/public-dns/), but this can be overridden by setting the environment variable `PORTIER_NAMESERVERS` to a whitespace seperated list of nameservers to use.

**N.B.** if you change this, you should also change [`resolver`](http://nginx.org/en/docs/http/ngx_http_core_module.html#resolver) in the `nginx` configuration too

### Runtime Secret

When you start `nginx` you will see a warning in your error log similar to:

    2018/08/03 14:46:58 [warn] 8659#8659: [lua] i.lua:51: using runtime secret

This is harmless, but will mean every time you reload nginx any currently authenticated users will be logged out.  To prevent this you can set the secret to a static value with:

    dd if=/dev/urandom of=/opt/portier/nginx/secret bs=1 count=16
    chmod 640 /opt/portier/nginx/secret
    chown root:www-data /opt/portier/nginx/secret

### Authorization

You may wish to test externally the email address if it is authorized to connect.

To do this edit `i.lua` and inspect the `authorize` variable and how to use it with the provided [examples (`authz*.lua`)](examples).

# Development

Almost the easiest thing here is to slum it with a Docker container (sorry, it is awful) where you can run:

    docker build -t portier-nginx .
    docker run -it --rm -p 1080:80 portier-nginx

Now from within the container run:

    /etc/init.d/nginx start
    php -S 127.0.0.1:8000 -t /opt/portier/nginx/webroot

On your workstation, point your browser at http://localhost:1080 and type in your email address to start off the authentication.  If it is successful, you should see the [`phpinfo()`](https://secure.php.net/manual/en/function.phpinfo.php) splash screen and if you scroll down you should find `$_SERVER['HTTP_X_PORTIER_NGINX_EMAIL']` is set to your email address.

## Functional Description

After a successful authentication, portier-nginx sets the session cookie `portier-nginx-email` and then uses that going forward.  The cookie is made up of the tuple:

    [hmac type]:[hmac truncated to 80bits]:[created time]:[email]

Currently [`md5`](https://tools.ietf.org/html/rfc6151#section-2.3) is used as the HMAC hash function, the HMAC is [truncated to 80bits](https://tools.ietf.org/html/rfc2104#section-5), and these cookies expire after 18 hours of inactivity (renewing on each request during their validity).

Each lua file servers a particular purpose:

 * **[`i.lua`](i.lua):** sets the global variables that will be used by all the workers; including the secret
 * **[`a.lua`](a.lua):** tests if the user has a valid `portier-nginx-email` cookie, if not it redirects them to login
 * **[`l.lua`](l.lua):** handles the email login flow
 * **[`v.lua`](v.lua):** validates the post back from the portier broker
