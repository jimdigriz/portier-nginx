if ngx.var.cookie_portier_nginx_email then
	ngx.log(ngx.ERR, ngx.var.cookie_portier_nginx_email);
else
	if not ngx.var.request_uri:find("/%.portier/") then
		ngx.redirect("/.portier/login", ngx.HTTP_MOVED_TEMPORARILY)
	end
end
