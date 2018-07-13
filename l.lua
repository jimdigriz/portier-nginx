function login ()
	body = [[
<!DOCTYPE html>
<html lang="en">
<head>
 <title>Login</title>
</head>
<body>
 <h1>Login</h1>
 <form action="/.portier/login" method="GET">
  <input type="email" name="email" required>
  <input type="submit" value="Log In">
 </form>
</body>
</html>
]]

	ngx.header["Content-Type"] = "text/html; charset=utf-8"
	ngx.header["Content-Length"] = body:len()

	ngx.print(body)

	return ngx.exit(ngx.HTTP_OK)
end

function handle (email)
	local url = ngx.var.scheme .. "://" .. ngx.var.http_host
	local url_login = url .. "/.portier/login"

	if not email or email:len() == 0 or email:match("%c") then
		ngx.log(ngx.WARN, "invalid value: '" .. email .. "'")
		return ngx.redirect(url_login, ngx.HTTP_TEMPORARY_REDIRECT)
	end

	local valid, domain = validemail.validemail(email)
	if not valid then
		ngx.log(ngx.WARN, "invalid value: '" .. email .. "'")
		return ngx.redirect(url_login, ngx.HTTP_TEMPORARY_REDIRECT)
	end

	local r, err = resolver:new{
		nameservers = nameservers
	}
	if not r then
		ngx.log(ngx.ERR, "no resolver (" .. err .. "): '" .. email .. "'")
		return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	end
	local ans, err = r:query(domain, { qtype = r.TYPE_MX })
	if not ans then
		ngx.log(ngx.WARN, "no ans: '" .. email .. "'")
		return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
	end
	if #ans == 0 then
		ngx.log(ngx.WARN, "no mx: '" .. email .. "'")
		return ngx.redirect(url_login, ngx.HTTP_TEMPORARY_REDIRECT)
	end

	local res = ngx.location.capture(proxy_url(broker .. "/.well-known/openid-configuration"))
	if res.status >= 400 or res.truncated then
		ngx.log(ngx.ERR, "failed to get /.well-known/openid-configuration")
		return ngx.exit(ngx.HTTP_BAD_GATEWAY)
	end
	local openid_configuration = json.decode(res.body)

	local args = {
		client_id = url,
		nonce = str.to_hex(random.bytes(16)),
		response_type = "id_token",
		redirect_uri = url .. "/.portier/verify",
		scope = "openid email",
		login_hint = email,
		response_mode = "form_post"
	}
	ngx.redirect(openid_configuration.authorization_endpoint .. "?" .. ngx.encode_args(args), ngx.HTTP_TEMPORARY_REDIRECT)
end

local args = ngx.req.get_uri_args()
if not args.email then
	login()
else
	handle(args.email)
end
