function base64url_encode (s)
	local s64 = ngx.encode_base64(s)
	return s64:gsub("+", "-"):gsub("/", "_"):gsub("=", "")
end

function base64url_decode (s64url)
	local s64 = s64url:gsub("-", "+"):gsub("_", "/")
	local pad = s64:len() % 4
        if pad > 0 then
		s64 = s64 .. string.rep("=", 4 - pad)
	end
	return ngx.decode_base64(s64)
end

function proxy_url (url)
	local scheme, rest = url:match("^(%w+)://(.*)$")
	return "/.portier/proxy/" .. scheme .. "/" .. rest
end

validemail = require "valid-email"
resolver = require "nginx.dns.resolver"
random = require "nginx.random"
str = require "nginx.string"
json = require "json"
x509 = require "openssl.x509"
digest = require "openssl.digest"
pkey = require "openssl.pkey"

-- broker = os.getenv("BROKER")
broker = "https://broker.portier.io"
if not broker then
	assert("missing env BROKER")
end

-- nameservers_str = os.getenv("NAMESERVERS")
nameservers_str = "8.8.8.8 8.8.4.4"
if not nameservers_str then
	assert("missing env NAMESERVERS")
end
nameservers = {}
for nameserver in nameservers_str:gmatch("%S+") do
	table.insert(nameservers, nameserver)
end

local file_secret = io.open("/opt/portier/nginx/secret", "r")
if file_secret then
	secret = file_email_html:read("*all")
	file_email_html:close()
end
if not secret then
	ngx.log(ngx.WARN, "using runtime secret")
	while not secret == nil do
		secret = random.bytes(16, true)
	end
end
