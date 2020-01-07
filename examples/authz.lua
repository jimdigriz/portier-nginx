local m = {}

local whitelist = {}
whitelist["bob@example.com"] = true

local function normalize(str)
	local lastAt = str:find("[^%@]+$")
	local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
	local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
	return localPart .. "@" .. domainPart:lower()
end

function m.query(email0)
	errorstr = ""
	bool = false
	local email = normalize(email0)
	if whitelist[email] then
		bool = true
	end
	return bool,errorstr
end

return m
