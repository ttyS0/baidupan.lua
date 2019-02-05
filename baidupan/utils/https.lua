local https = {}

local http_request = require("http.request")
local print_r = require("baidupan.utils.print_r")
local trim = require("baidupan.utils.trim")
local split = require("baidupan.utils.split")
local table_merge = require("baidupan.utils.table_merge")

local cookie_jar = {}

local function query_string(data)
    local t = {}
    for k, v in pairs(data) do
        table.insert(t, urlencode(tostring(k)) .. "=" .. urlencode(tostring(v)))
    end
    return table.concat(t, "&")
end

function https.join_cookies()
    local r = {}
    for i, v in pairs(cookie_jar) do
        table.insert(r, i .. "=" .. v)
    end
    return table.concat(r, "; ")
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

function https.get_cookie(field)
    return cookie_jar[field]
end

function https.load_cookie_file(path)
    local f = io.open(path, "r")
    https.update_cookies(f:read("*a"))
    f:close()
end

function https.save_cookie_file(path)
    local f = io.open(path, "w")
    local c = assert(https.join_cookies())
    f:write(c)
    f:close()
end

function https.get(url, headers)
    assert(trim(url):lower():find("https") == 1, "Protocol is not supported by Baidu Netdisk, try with HTTPS.")
    local destination = url
    local redirects = 0
    local req = http_request.new_from_uri(url)
    req.headers:upsert("user-agent", "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.9 Safari/537.36")
    req.headers:upsert("cookie", https.join_cookies())
    req.follow_redirects = false
    if type(headers) == "table" then
        for k, v in pairs(headers) do
            req.headers:upsert(k:lower(), v)
        end
    end
    local res_headers, res_stream = assert(req:go())
    while res_headers:get("location") do
        redirects = redirects + 1
        if redirects > 5 then break end
        destination = res_headers:get("location")
        res_headers, res_stream = assert(req:handle_redirect(res_headers):go())
    end
    local res_body = assert(res_stream:get_body_as_string())
    if res_headers:has("set-cookie") then
        for i, v in pairs(res_headers:get_as_sequence("set-cookie")) do
	        https.update_cookies(v)
	    end
	end
    return res_body, destination, res_headers
end

function https.post(url, data, headers)
    assert(trim(url):lower():find("https") == 1, "Protocol is not supported by Baidu Netdisk, try again with HTTPS.")
    local req = http_request.new_from_uri(url)
    req.headers:upsert(":method", "POST")
    req.headers:upsert("user-agent", "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.9 Safari/537.36")
    req.headers:upsert("cookie", https.join_cookies())
    req:set_body(data)
    if type(headers) == "table" then
        for k, v in pairs(headers) do
            req.headers:upsert(k:lower(), v)
        end
    end
    local res_headers, res_stream = assert(req:go())
	for i, v in pairs(res_headers) do
		if i:lower() == "set-cookie" then
			https.update_cookies(v)
		end
	end
    return assert(res_stream:get_body_as_string())
end

return https
