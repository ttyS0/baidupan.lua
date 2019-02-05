local apis = require("baidupan.apis")
local trim = require("baidupan.utils.trim")
local https = require("baidupan.utils.https")
local http_util = require("http.util")
local json = require("json")

local instance_children = {
    
}

local instance_metatable = {
    __index = instance_children
}

local function new(bdstoken)
    local query = {
        ["channel"] = "chunlei",
        ["web"] = "1",
        ["app_id"] = "250528",
        ["clienttype"] = "0",
        ["bdstoken"] = bdstoken,
        ["prod"] = "pan"
    }
    local response = assert(https.get(apis.VERIFY_CODE .. "?" .. http_util.dict_to_query(query), {
        ["accept"] = "*/*",
        ["accept-language"] = "zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
        ["accept-encoding"] = "deflate, br",
        ["connection"] = "keep-alive",
        ["x-requested-with"] = "XMLHttpRequest"
    }))
    response = assert(json.decode(response))
    local s = setmetatable({
        id = response.vcode,
        url = response.img,
        image = https.get(response.img)
    }, instance_metatable)
    return s
end

function instance_children:answer(ans)
    self.answer = ans
end

return {
    new = new
}
