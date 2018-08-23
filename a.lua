local cookie_portier_nginx_email = ngx.var.cookie_portier_nginx_email
if ngx.var.http_cookie then
	local cookie = ngx.var.http_cookie:gsub("portier_nginx_email=[^;]+;? *", "")
	ngx.req.set_header("Cookie", cookie)
end

if cookie_portier_nginx_email then
	local hmac_t, hmac_v, created_v, email = cookie_portier_nginx_email:match("^(%w+):([0-9a-f]+):(%d+):(.*)$")
	if email ~= nil then
		local now = ngx.time()
		local created = tonumber(created_v)
		-- 18 hours validity
		if created and created + 64800 > now then
			local hmac_i = hmac.new(secret, hmac_t)
			local hmac_vc = str.to_hex(hmac_i:final(created .. ':' .. email)):sub(1, 20)
			if hmac_vc == hmac_v then
				hmac_i = hmac.new(secret, hmac_t)
				hmac_vc = str.to_hex(hmac_i:final(now .. ':' .. email)):sub(1, 20)
				local value = table.concat({ hmac_t, hmac_vc, now, email }, ":")

				ngx.header["Set-Cookie"] = "portier_nginx_email=" .. value .. "; Path=/; HttpOnly"
				ngx.var.portier_nginx_email = email
				return
			end
		end
	end
end

if not ngx.var.request_uri:find("/%.portier/") then
	if cookie_portier_nginx_email then
		ngx.header["Set-Cookie"] = "portier_nginx_email=; Path=/; HttpOnly; Expires=Mon, 11 Jan 2010 00:00:00 GMT"
	end
	ngx.redirect("/.portier/login/", ngx.HTTP_MOVED_TEMPORARILY)
end

return
