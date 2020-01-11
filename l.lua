local args = ngx.req.get_uri_args()
if not args.email then
	return
end

local url = ngx.var.scheme .. "://" .. ngx.var.http_host
local url_login = url .. "/.portier/login"

local function error (error)
	local url = url_login .. "#" .. ngx.encode_args({
		email = args.email,
		error = error
	})
	return ngx.redirect(url, ngx.HTTP_MOVED_TEMPORARILY)
end

if args.email:len() == 0 or args.email:match("%c") then
	ngx.log(ngx.WARN, "invalid value: '" .. args.email .. "'")
	error("email has no valid characters")
end

local valid, domain = validemail.validemail(args.email)
if not valid then
	ngx.log(ngx.WARN, "invalid value: '" .. args.email .. "'")
	error("email is invalid")
end

local r, err = resolver:new{
	nameservers = nameservers
}
if not r then
	ngx.log(ngx.ERR, "no resolver (" .. err .. "): '" .. args.email .. "'")
	error("server DNS resolver problem, please contact support")
end
local ans, err = r:query(domain, { qtype = r.TYPE_MX })
if not ans then
	ngx.log(ngx.WARN, "no ans: '" .. args.email .. "'")
	error("server DNS timeout problem, please contact support")
end
if #ans == 0 then
	ngx.log(ngx.WARN, "no mx: '" .. args.email .. "'")
	error("domain does not accept mail")
end

if authorize then
	local success, authorized = pcall(authorize.query, args.email)
	if not success or not authorized == true then
		ngx.log(ngx.WARN, "not authorized: '" .. args.email .. "', reason: " .. tostring(authorized))
		if type(authorized) ~= 'string' then
			authorized = "not authorized, please contact support"
		end
		error(authorized)
	end
end

local res = ngx.location.capture(proxy_url(broker .. "/.well-known/openid-configuration"))
if res.status >= 400 or res.truncated then
	ngx.log(ngx.ERR, "failed to get /.well-known/openid-configuration")
	error("email authentication failed, please contact support")
end
local openid_configuration = json.decode(res.body)

local args = {
	client_id = url,
	nonce = str.to_hex(random.bytes(16)),
	response_type = "id_token",
	redirect_uri = url .. "/.portier/verify",
	scope = "openid email",
	login_hint = args.email,
	response_mode = "form_post"
}

ngx.redirect(openid_configuration.authorization_endpoint .. "?" .. ngx.encode_args(args), ngx.HTTP_MOVED_TEMPORARILY)
