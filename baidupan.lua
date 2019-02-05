baidupan = {}
baidupan.version = "0.1"

local print_r = require("baidupan.utils.print_r")
local https = require("baidupan.utils.https")

return {
    load = https.update_cookies,
    cookies = https.join_cookies,
    load_file = https.load_cookie_file,
    save_file = https.save_cookie_file
}