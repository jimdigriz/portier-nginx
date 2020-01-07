-- apt-get -yy install --no-install-recommends lua-ldap

local m = {}

require "lualdap"

local function normalize(str)
        local lastAt = str:find("[^%@]+$")
        local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
        local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
        return localPart .. "@" .. domainPart:lower()
end

function m.query(email0)
        local ld = assert(lualdap.open_simple("ldap.example.com"))
		local bool = false
		local errorstr = "" 
        local email = normalize(email0)

        local params = {
                attrs           = "1.1",
                base            = "dc=example,dc=com",
                filter          = "(&(objectClass=inetOrgPerson)(mail=" .. email .. "))",
                scope           = "subtree",
                sizelimit       = 1
        }

        for dn in ld:search(params) do
                bool = true
        end

        ld:close()

        return bool,errorstr
end

return m
