local apis = require("baidupan.apis")
local node = require("baidupan.node")
local split = require("baidupan.utils.split")
local trim = require("baidupan.utils.trim")
local print_r = require("baidupan.utils.print_r")
local https = require("baidupan.utils.https")
local base64 = require("baidupan.utils.base64")
local baidu_sign = require("baidupan.utils.baidu_sign")
local http_util = require("http.util")
local json = require("json")


local home = { update_time = 0 }

function home:update()
    if (os.time() - home.update_time) > 60 then
        home.update_time = os.time()
    else
        return
    end
    local html = https.get("https://pan.baidu.com/disk/home")
    self.bdstoken = assert(html:match([["bdstoken"..-([^",%s]+)]]), "Page error!")
    self.timestamp = assert(html:match([["timestamp"..-([^",%s]+)]]), "Page error!")
    self.sign1 = assert(html:match([["sign1"..-([^",%s]+)]]), "Page error!")
    self.sign3 = assert(html:match([["sign3"..-([^",%s]+)]]), "Page error!")
    self.sign = base64.encode(baidu_sign.sign2(self.sign3, self.sign1))
end

function home:list(path, parent)
    home:update()
    path = path or "/"
    assert(type(path) == "string", "Invalid path")
    local query = {
        ["channel"] = "chunlei",
        ["web"] = "1",
        ["clienttype"] = "0",
        ["dir"] = path
    }
    local response = (https.get(apis.HOME_LIST .. "?" .. http_util.dict_to_query(query), {
        ["accept"] = "*/*",
        ["accept-language"] = "zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
        ["accept-encoding"] = "deflate, br",
        ["connection"] = "keep-alive",
        ["referer"] = "https://pan.baidu.com",
        ["x-requested-with"] = "XMLHttpRequest"
    }))
    response = assert(json.decode(response))
    local l = {}
    for k, v in ipairs(response.list) do
        table.insert(l, node.new(v.server_filename, v.path, v.fs_id, v.isdir == 1, parent, home))
    end
    return l
end

function home:node(path)
    local root = true
    local r
    local segs = split(path, "/")
    for i = 1, #segs do
        if trim(segs[i]) ~= "" then
            root = false
            local flag = false
            local t = r and r:children() or home:list()
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
    if root then return node.new("(root)", "/", nil, true, nil, home) end
    return r
end

function home:download(id, path)
    home:update()
    local query = {
        ["channel"] = "chunlei",
        ["web"] = "1",
        ["app_id"] = "250528",
        ["clienttype"] = "0",
        ["bdstoken"] = self.bdstoken,
        ["sign"] = self.sign,
        ["timestamp"] = self.timestamp,
        ["fidlist"] = "[" .. id .. "]",
        ["type"] = "dlink"
    }
    local response = (https.get(apis.HOME_DOWNLOAD .. "?" .. http_util.dict_to_query(query), {
        ["accept"] = "*/*",
        ["accept-language"] = "zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
        ["accept-encoding"] = "deflate, br",
        ["connection"] = "keep-alive",
        ["referer"] = "https://pan.baidu.com/disk/home",
        ["x-requested-with"] = "XMLHttpRequest"
    }))
    response = assert(json.decode(response))
    local link = response.dlink and response.dlink[1] and response.dlink[1].dlink
    return link, response.errno
end

function home:pcs_download(id, path)
    home:update()
    local query = {
        ["method"] = "download",
        ["app_id"] = "250528",
        ["path"] = path
    }
    return apis.PCS .. "?" .. http_util.dict_to_query(query)
end

function home:transfer()
    return nil
end

return home
