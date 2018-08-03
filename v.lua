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
local header_b64url, payload_b64url, signature_b64url = id_token:match("^([^.]+)%.([^.]+)%.([^.]+)$")
if not signature_b64url then
	ngx.log(ngx.WARN, "id_token invalid")
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
header = json.decode(base64url_decode(header_b64url))
if header.alg ~= "RS256" then
	ngx.log(ngx.WARN, "unsupported alg '" .. header.alg .. "'")
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

payload = json.decode(base64url_decode(payload_b64url))
if payload.iss ~= broker then
	ngx.log(ngx.ERR, "payload iss mismatch, got '" .. payload.iss .. "', expected '" .. broker .. "'")
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local url = ngx.var.scheme .. "://" .. ngx.var.http_host
if payload.aud ~= url then
	ngx.log(ngx.WARN, "incorrect aud, got '" .. payload.aud .. "', expected '" .. url .. "'")
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
local now = ngx.time()
if now < payload.iat - 10 or now > payload.exp then
	ngx.log(ngx.WARN, "expired")
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end
-- TODO check nonce matches (requires hmac in the verify postback url)

-- the email to use is .sub
local email = payload.sub
local valid = validemail.validemail(email)
if not valid then
	ngx.log(ngx.WARN, "email not valid: " .. email)
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

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
local key
for i in pairs(jwks.keys) do
	if jwks.keys[i].use == "sig" and jwks.keys[i].alg == "RS256" and jwks.keys[i].kid == header.kid then
		key = jwks.keys[i]
		break
	end
end
if not key then
	ngx.log(ngx.ERR, "no matching kid for " .. header.kid)
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

-- https://stackoverflow.com/a/27570866
local top_header = ngx.decode_base64("MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA")
local mid_header = "\x02\x03"
local n = base64url_decode(key.n)
local e = base64url_decode(key.e)
local pub = pkey.new(top_header .. n .. mid_header .. e, 'DER')
local data = digest.new("sha256")
data:update(header_b64url .. "." .. payload_b64url)
local verified = pub:verify(base64url_decode(signature_b64url), data)
if not verified then
	ngx.log(ngx.WARN, "bad signature")
	return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local hmac_t = 'md5'
local hmac_i = hmac.new(secret, hmac_t)
local hmac_vc = str.to_hex(hmac_i:final(email)):sub(1, 20)
local value = table.concat({ hmac_t, hmac_vc, email }, ':')

ngx.header["Set-Cookie"] = "portier_nginx_email=" .. value .. "; Path=/; HttpOnly"
ngx.redirect(url, ngx.HTTP_MOVED_TEMPORARILY)
