local baidupan = require("baidupan")
local home = require("baidupan.home")
local share = require("baidupan.share")

-- Load cookies
-- baidupan.load(io.open("cookies"):read("*a"))
baidupan.load_file("cookies")

print(baidupan.cookies())

-- Print the (PCS) link of each file (not directory) in home path /Books
local n = home:node("/Books")
for k, v in ipairs(n:children()) do
    if not v.is_dir then
        -- local l = v:pcs_download()
        local l = v:download()
        print(l)
    end
end

-- Try to download a share and request verify code if necessary
-- Actually, loops are more common when it comes to verify.
-- Recognizing one captcha after another is more comfortable. :P
local s, err = share.new("https://pan.baidu.com/s/1hrSe4Ji", "086u")
print("Open share: " .. tostring(err))
if err == -62 then
    local v = s:verify()
    io.open("image.jpg", "w"):write(v.image):close()
    io.write("Verify code: "); v:answer(io.read())
    s:update(v)
end
local link, err = s:node("/book/重构-改善既有代码的设计.pdf"):download()
print("Download: " .. tostring(err))
if err == -20 then
    local v = s:verify()
    io.open("image.jpg", "w"):write(v.image):close()
    io.write("Verify code: "); v:answer(io.read())
    link = s:node("/book/重构-改善既有代码的设计.pdf"):download(v)
end
print(link)

-- Tranfer a share node to home path /Books
local book_share = share.new("https://dwz.cn/BJQjFzP9", "a7uj")
book_share:node("/HBR 201901-02"):children()[1]:transfer(home:node("/Books"))

-- Save cookies
baidupan.save_file("cookies")