local trim = require("baidupan.utils.trim")
local https = require("baidupan.utils.https")
local http_util = require("http.util")
local json = require("json")

local instance_children = {
    
}

local instance_metatable = {
    __index = instance_children
}

local function new_list(raw_list)
    local t = {}
    for k, v in ipairs(raw_list) do
    
    end
end

local function new(name, path, id, is_dir, parent, navigator)
    local s = setmetatable({
        name = name,
        path = path,
        id = id,
        is_dir = is_dir,
        parent = parent,
        navigator = navigator
    }, instance_metatable)
    return s
end

function instance_children:children()
    if self.is_dir == false then return nil
    else return self.navigator:list(self.path, self)
    end
end

function instance_children:parent()
    return self.parent
end

function instance_children:transfer(target)
    return self.navigator:transfer(self.id, self.path, target)
end

function instance_children:download(verify)
    if self.is_dir then return nil
    else return self.navigator:download(self.id, self.path, verify)
    end
end

function instance_children:pcs_download()
    if self.is_dir then return nil
    else return self.navigator:pcs_download(self.id, self.path)
    end
end

function instance_children:mkdir(name)
    if not self.is_dir then return nil
    else return self.navigator:mkdir(self.path, name)
    end
end

return {
    new = new
}
