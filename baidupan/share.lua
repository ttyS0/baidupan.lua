local apis = require("baidupan.apis")
local node = require("baidupan.node")
local verify = require("baidupan.verify")
local split = require("baidupan.utils.split")
local trim = require("baidupan.utils.trim")
local print_r = require("baidupan.utils.print_r")
local https = require("baidupan.utils.https")
local base64 = require("baidupan.utils.base64")
local baidu_sign = require("baidupan.utils.baidu_sign")
local http_util = require("http.util")
local json = require("json")

local instance_children = {
    
}

local instance_metatable = {
    __index = instance_children
}

local function new(url, password)
    local s = setmetatable({
        url = url,
        password = password,
        update_time = 0
    }, instance_metatable)
    return s, s:update()
end

function instance_children:pcs_download()
    return nil
end

function instance_children:download(id, path, verify)
    assert(type(path) == "string", "Invalid path")
    if path == "/" then return self:root() end
    self:update()
    local query = {
        ["channel"] = "chunlei",
        ["web"] = "1",
        ["app_id"] = "250528",
        ["clienttype"] = "0",
        ["bdstoken"] = self.bdstoken,
        ["sign"] = self.sign,
        ["timestamp"] = self.timestamp
    }
    local form = {
        ["encrypt"] = "0",
        ["product"] = "share",
        ["uk"] = self.uk,
        ["primaryid"] = self.id,
        ["fid_list"] = "[" .. id .. "]",
        ["extra"] = '{"sekey":"' .. http_util.decodeURIComponent(https.get_cookie("BDCLND")) .. '"}'
    }
    if verify ~= nil and verify.answer ~= nil then
        form["vcode_str"] = verify.id
        form["vcode_input"] = verify.answer
    end
    local response = (https.post(apis.SHARE_DOWNLOAD .. "?" .. http_util.dict_to_query(query), http_util.dict_to_query(form), {
        ["accept"] = "*/*",
        ["accept-language"] = "zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
        ["accept-encoding"] = "deflate, br",
        ["content-type"] = "application/x-www-form-urlencoded; charset=UTF-8",
        ["connection"] = "keep-alive",
        ["referer"] = self.dest,
        ["x-requested-with"] = "XMLHttpRequest"
    }))
    response = assert(json.decode(response))
    local link = response.list and response.list[1] and response.list[1].dlink
    return link, response.errno
end

function instance_children:list(path, parent)
    path = path or "/"
    self:update()
    if path == "/" then
        local r = {}
        for k, v in ipairs(self.context.file_list.list) do
            table.insert(r, node.new(v.server_filename, v.path, v.fs_id, v.isdir == 1, nil, self))
        end
        return r
    else
        local query = {
            ["channel"] = "chunlei",
            ["web"] = "1",
            ["app_id"] = "250528",
            ["clienttype"] = "0",
            ["bdstoken"] = self.bdstoken,
            ["uk"] = self.uk,
            ["shareid"] = self.id,
            ["dir"] = path,
            ["t"] = tostring(os.time() * 1000)
        }
        local response = (https.get(apis.SHARE_LIST .. "?" .. http_util.dict_to_query(query), {
            ["accept"] = "*/*",
            ["accept-language"] = "zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
            ["accept-encoding"] = "deflate, br",
            ["connection"] = "keep-alive",
            ["referer"] = self.dest,
            ["x-requested-with"] = "XMLHttpRequest"
        }))
        response = assert(json.decode(response))
        local l = {}
        for k, v in ipairs(response.list) do
            table.insert(l, node.new(v.server_filename, v.path, v.fs_id, v.isdir == 1, parent, self))
        end
        return l
    end
end

function instance_children:node(path)
    local root = true
    local r
    local segs = split(path, "/")
    for i = 1, #segs do
        if trim(segs[i]) ~= "" then
            root = false
            local flag = false
            local t = r and r:children() or self:list()
            if t == nil then return nil end
            for k, n in ipairs(t) do
                if n.name == segs[i] then
                    flag = true
                    r = n
                    break
                end
            end
            if flag == false then return nil end
        end
    end
    if root then return node.new("(root)", "/", nil, true, nil, self) end
    return r
end

function instance_children:transfer(id, path, node)
    if path == "/" then return self:root() end
    self:update()
    local query = {
        ["channel"] = "chunlei",
        ["web"] = "1",
        ["app_id"] = "250528",
        ["clienttype"] = "0",
        ["bdstoken"] = self.bdstoken,
        ["from"] = self.uk,
        ["shareid"] = self.id
    }
    local form = {
        ["fsidlist"] = "[" .. id .. "]",
        ["path"] = node.path
    }
    local response = (https.post(apis.SHARE_TRANSFER .. "?" .. http_util.dict_to_query(query), http_util.dict_to_query(form), {
        ["accept"] = "*/*",
        ["accept-language"] = "zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
        ["accept-encoding"] = "deflate, br",
        ["content-type"] = "application/x-www-form-urlencoded; charset=UTF-8",
        ["connection"] = "keep-alive",
        ["referer"] = self.dest,
        ["x-requested-with"] = "XMLHttpRequest"
    }))
    response = assert(json.decode(response))
    return response.errno
end

function instance_children:verify()
    return verify.new(self.bdstoken)
end

function instance_children:update(verify)
    if ((os.time() - self.update_time) > 60) or verify then
        self.update_time = os.time()
    else
        return
    end
    local response
    local html, dest = https.get(self.url)
    local surl = dest:match("surl=([^&=]*)")
    self.bdstoken = assert(html:match([["bdstoken"..-([^",%s]+)]]), "Page error!")
    if surl then
        assert(string.len(self.password) == 4, "Invalid password for the share!")
        local query = {
            ["channel"] = "chunlei",
            ["web"] = "1",
            ["app_id"] = "250528",
            ["clienttype"] = "0",
            ["bdstoken"] = self.bdstoken,
            ["surl"] = surl,
            ["t"] = tostring(os.time() * 1000)
        }
        local form = {
            ["pwd"] = self.password,
            ["vcode"] = "",
            ["vcode_str"] = ""
        }
        if verify ~= nil and verify.answer ~= nil then
            form["vcode_str"] = verify.id
            form["vcode"] = verify.answer
        end
        response = (https.post(apis.SHARE_VERIFY .. "?" .. http_util.dict_to_query(query), http_util.dict_to_query(form), {
            ["accept"] = "*/*",
            ["accept-language"] = "zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
            ["accept-encoding"] = "deflate, br",
            ["content-type"] = "application/x-www-form-urlencoded; charset=UTF-8",
            ["connection"] = "keep-alive",
            ["referer"] = dest,
            ["x-requested-with"] = "XMLHttpRequest"
        }))
        response = json.decode(response)
        if response.errno ~= 0 then return response.errno end
        html = https.get(self.url)
    end
    self.dest = dest
    self.sign = assert(html:match([["sign"..-([^",%s]+)]]) or html:match([[yunData.sign =..-([^",%s]+)]]), "Page error!")
    self.timestamp = assert(html:match([["timestamp"..-([^",%s]+)]]), "Page error!")
    self.id = assert(html:match([["shareid"..-([^",%s]+)]]), "Page error!")
    self.uk = assert(html:match([["uk"..-([^",%s]+)]]), "Page error!")
    self.context = assert(json.decode(html:match("yunData%.setData%(([^\n]*)%)")), "Page error!")
    return 0
end

return {
    new = new
}
