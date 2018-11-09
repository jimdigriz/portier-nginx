-- apt-get -yy install --no-install-recommends lua-ldap

local m = {}

local ldapldap = require "lualdap"

local function normalize(str)
        local lastAt = str:find("[^%@]+$")
        local localPart = str:sub(1, (lastAt - 2)) -- Returns the substring before '@' symbol
        local domainPart = str:sub(lastAt, #str) -- Returns the substring after '@' symbol
        return localPart .. "@" .. domainPart:lower()
end

function m.query(email0)
        local ld = assert(lualdap.open_simple("ldap.example.com"))

        local email = normalize(email0)

        local params = {
                attrs           = "1.1",
                base            = "dc=example,dc=com",
                filter          = "(&(objectClass=inetOrgPerson)(mail=" .. email .. "))",
                scope           = "subtree",
                sizelimit       = 1
        }

        local count = 0
        for dn in ld:search(params) do
                count = count + 1
        end

        ld:close()

        return count > 0
end

return m
