ngx.req.read_body()

local args = ngx.req.get_post_args()
if not args then
        ngx.log(ngx.WARN, "no post args")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

if args.error then
        ngx.log(ngx.WARN, "error: " .. args.error)
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local id_token = args.id_token
if not id_token then
        ngx.log(ngx.WARN, "missing id_token")
        return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

ngx.log(ngx.ERR, id_token)

local conf_res = ngx.location.capture(proxy_url(broker .. "/.well-known/openid-configuration"))
if conf_res.status >= 400 or conf_res.truncated then
	ngx.log(ngx.ERR, "failed to get /.well-known/openid-configuration")
	return ngx.exit(ngx.HTTP_BAD_GATEWAY)
end
local openid_configuration = json.decode(conf_res.body)
local jwks_res = ngx.location.capture(proxy_url(openid_configuration.jwks_uri))
if jwks_res.status >= 400 or jwks_res.truncated then
	ngx.log(ngx.ERR, "failed to get " .. openid_configuration.jwks_uri)
	return ngx.exit(ngx.HTTP_BAD_GATEWAY)
end
local jwks = json.decode(jwks_res.body)
ngx.log(ngx.ERR, jwks_res.body)

