ngx.req.clear_header("X-Portier-Email")

if ngx.var.cookie_portier_nginx_email then
	local hmac_t, hmac_v, email = ngx.var.cookie_portier_nginx_email:match("^(%w+):(%w+):(.*)$")

	if email ~= nil then
		local hmac_i = hmac.new(secret, hmac_t)
		local hmac_vc = str.to_hex(hmac_i:final(email)):sub(1, 20)

		if hmac_vc == hmac_v then
			ngx.req.set_header("X-Portier-Nginx-Email", email)

			local cookies = {}
			for cname in (ngx.var.http_cookie .. ";"):gmatch("([^=]+)[^;]*; *$") do
				if cname ~= "portier_nginx_email" then
					cookies.insert(cname .. "=" .. ngx.var["cookie_" .. cname])
				end
			end
			ngx.req.set_header("Cookie", table.concat(cookies, "; "))

			return
		end
	end
end

if not ngx.var.request_uri:find("/%.portier/") then
	ngx.redirect("/.portier/login", ngx.HTTP_MOVED_TEMPORARILY)
end
