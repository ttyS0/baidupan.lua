local https = {}

local ssl_https = require("ssl.https")
local print_r = require("baidupan.utils.print_r")
local trim = require("baidupan.utils.trim")
local split = require("baidupan.utils.split")
local table_merge = require("baidupan.utils.table_merge")

local cookie_jar = {}

local function join_cookies()
    local r = {}
    for i, v in pairs(cookie_jar) do
        table.insert(r, i .. "=" .. v)
    end
    return table.concat(r, "; ")
end

local function query_string(data)
    local t = {}
    for k, v in pairs(data) do
        table.insert(t, urlencode(tostring(k)) .. "=" .. urlencode(tostring(v)))
    end
    return table.concat(t, "&")
end

function https.update_cookies(str)
    local segments = split(str, ";")
    for i, v in pairs(segments) do
        if v:find(",") then
            for i, w in pairs(split(v, ",")) do
                if w:find("=") then
                    local kv = split(w, "=")
                    local ck = trim(kv[1])
                    local cv = trim(kv[2])
                    if ck:lower() ~= "path" and ck:lower() ~= "expires" and ck:lower() ~= "max-age" and ck:lower() ~= "domain" then
                        cookie_jar[ck] = cv
                    end
                end
            end
        else
            if v:find("=") then
                local kv = split(v, "=")
                local ck = trim(kv[1])
                local cv = trim(kv[2])
                if ck:lower() ~= "path" and ck:lower() ~= "expires" and ck:lower() ~= "max-age" and ck:lower() ~= "domain" then
                    cookie_jar[ck] = cv
                end
            end
        end
    end
end

function https.get(url, headers)
	local res = {}
	
	if type(headers) == "table" then
	    headers = table_merge(headers, { ["Cookie"] = join_cookies() })
	else
	    headers = {}
	end
	
	local req = {
		method = "GET",
		url = url,
		protocol = "any",
		verify = "none",
		sink = ltn12.sink.table(res),
		headers = headers
	}
	
	local ok, res_code, res_headers, res_status = ssl_https.request(req);
    print(res_code)
	print_r(res_headers)
	
	for i, v in pairs(res_headers) do
		if i:lower() == "set-cookie" then
			https.update_cookies(v)
		end
	end
	
	return table.concat(res)
end

function https.post(url, data, headers)
	local res = {}
	
	if type(headers) == "table" then
	    headers = table_merge(headers, { ["Content-Length"] = string.len(data), ["Cookie"] = join_cookies() })
	else
	    headers = {}
	end
	
	local req = {
		method = "POST",
		url = url,
		protocol = "any",
		verify = "none",
		source = ltn12.source.string(data),
		sink = ltn12.sink.table(res),
		headers = headers
	}
	
	local ok, res_code, res_headers, res_status = ssl_https.request(req);
	
	print_r(res_headers)
	
	for i, v in pairs(res_headers) do
		if i:lower() == "set-cookie" then
			https.update_cookies(v)
		end
	end
	
	return table.concat(res)
end

return https
