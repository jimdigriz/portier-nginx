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
digest = require "openssl.digest"
pkey = require "openssl.pkey"
hmac = require "openssl.hmac"

broker = assert(os.getenv("PORTIER_BROKER"))

nameservers_str = assert(os.getenv("PORTIER_NAMESERVERS"))
nameservers = {}
for nameserver in nameservers_str:gmatch("%S+") do
	table.insert(nameservers, nameserver)
end

-- see the README for a description of what to do here
authorize = os.genenv("PORTIER_AUTHORIZE")
if authorize then
	authorize = require authorize
end

local file_secret = io.open("/opt/portier/nginx/secret", "r")
if file_secret then
	secret = file_secret:read("*all")
	file_secret:close()
end
if not secret then
	ngx.log(ngx.WARN, "using runtime secret")
	secret = random.bytes(16)
end
