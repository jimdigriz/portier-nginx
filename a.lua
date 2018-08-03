ngx.req.clear_header('X-Portier-Email')

if ngx.var.cookie_portier_nginx_email then
	local cookies = {}
	for cname in (ngx.var.http_cookie .. ";"):gmatch('([^=]+)[^;]*; *$') do
		if cname ~= 'portier_nginx_email' then
			cookies.insert(cname .. '=' .. ngx.var['cookie_' .. cname])
		end
	end
	ngx.req.set_header('X-Portier-Nginx-Email', ngx.var.cookie_portier_nginx_email)
	ngx.req.set_header('Cookie', table.concat(cookies, '; '))
else
	if not ngx.var.request_uri:find("/%.portier/") then
		ngx.redirect("/.portier/login", ngx.HTTP_MOVED_TEMPORARILY)
	end
end
