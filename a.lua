local cookie = ngx.var.cookie_portier_nginx_email
ngx.req.clear_header("Remote-User")

if ngx.var.http_cookie then
	local cookies = {}
	for cname in (ngx.var.http_cookie .. ";"):gmatch("([^=]+)[^;]*; *$") do
		if cname ~= "portier_nginx_email" then
			cookies.insert(cname .. "=" .. ngx.var["cookie_" .. cname])
		end
	end
	ngx.req.set_header("Cookie", table.concat(cookies, "; "))
end

if cookie then
	local hmac_t, hmac_v, email = cookie:match("^(%w+):(%w+):(.*)$")
	if email ~= nil then
		local hmac_i = hmac.new(secret, hmac_t)
		local hmac_vc = str.to_hex(hmac_i:final(email)):sub(1, 20)

		if hmac_vc == hmac_v then
			ngx.req.set_header("Remote-User", email)
			return
		end
	end
end

if not ngx.var.request_uri:find("/%.portier/") then
	if cookie then
		ngx.header["Set-Cookie"] = "portier_nginx_email=; Expires=Fri, 01 Jan 2010 00:00:00 GMT"
	end
	ngx.redirect("/.portier/login", ngx.HTTP_MOVED_TEMPORARILY)
end
