# baidupan.lua

Baidu Netdisk API written in Lua.

百度网盘 Lua 版 API

## Dependencies

* [lua-http](https://github.com/daurnimator/lua-http)

* [json.lua](https://github.com/rxi/json.lua)

**lua-http** is available in `luarocks`, while **json.lua** should be installed manually. (**rxi-json-lua** in `luarocks` is an quite old version.)

## Examples

See [example.lua](example.lua).

## Documentation

**Only loading cookies to login Baidu Netdisk is supported.**

You should login Baidu Netdisk through browser and get the raw string of its cookies in corresponding developer tool.

Cookie string or file should keep the form of

```

A=XXXX; B=YYYY; C=ZZZZ

```

### baidupan

Cookies should be loaded before any further operation.

And it's quite recommended to save cookies after the task is finished.

#### baidupan.load(cookies)

Load cookies from a string.

***Parameters***

*string* `cookies`

Load cookies.

#### baidupan.cookies()

***Return*** *string*

cookies string

#### baidupan.load_file(path)

Load cookies from a file.

***Parameters***

*string* `path`

Load cookies from `path`.

#### baidupan.save_file(path)

Save cookies to a file.

***Parameters***

*string* `path`

Save cookies to `path`.

### baidupan.verify

`baidupan.verify` should be created by `baidupan.share` or manually.

However, it seldom needs manual creating in practice.

#### verify.id

*string*

the unique id of the verify code

#### verify.image

*string*

the image url of the verify code

#### verify.new()

***Return*** *baidupan.verify*

a new instance of `baidupan.verify` will be generated from server

#### verify:answer(ans)

Set the answer.

***Parameters***

*string* `ans`

the answer of the verify code


### baidupan.node

`baidupan.node` should be created by methods in `baidupan.share` and `baidupan.home`.

#### node.id

*string*

the unique id of the node

#### node.name

*string*

the name of the node stored on server

#### node.path

*string*

the virtual absolute path of the node on server

#### node.is_dir

*boolean*

indicating whether the node is a directory

#### node:children()

***Return*** *table*

the children of the node

#### node:parent()

***Return*** *baidupan.node*

the parent of the node

#### node:download([verify])

Get the download link of the node.

***Parameters***

*baidupan.verify* `verify` (optional)

pass a `baidupan.verify` instance if necessary according to its error code

***Return***

*string*

the link of the node

*number*

the error code

#### node:pcs_download()

Get the PCS download link of a **home** node.

This is only supported when the node is created by `baidupan.home`.

***Return*** *string*

the PCS link of the node

#### node:transfer(target)

Transfer a **share** node to a specific target path.

This is only supported when the node is created by `baidupan.share`.

***Parameters***

*baidupan.node* `target`

the target which the node will be transferred to

***Return***

*number*

the error code

### baidupan.share

Opeations on others' share.

#### share.new(url [, password])

Create a new share instance.

***Parameters***

*string* `url`

the share page url starting with `https://pan.baidu.com/s/` (however, shortened url is also supported :D)

*string* `password` (optional)

the password for the share

***Return***

*baidupan.share*

a new share instance

*number*

the error code

#### share:node(path)

Create a share node.

***Parameters***

*string* `path`

the path of the node

***Return*** *baidupan.node*

the share node with the specific path.

#### share:verify()

Create a share verify.

***Return*** *baidupan.verify*

a new `baidupan.verify` will be generated which can be passed after the answer is set

#### share:update([verify])

Force to update if verify is necessary.

When `verify` is `nil`, call of the method will be ignored if it's less than 1 minute between two calls.

`share.new` and `share:node` will both call the method automatically.

***Parameters***

*baidupan.verify* `verify` (optional)

pass a `baidupan.verify` instance if necessary according to its error code

### baidupan.home

My own files.

#### home:node(path)

Create a home node.

***Parameters***

*string* `path`

the path of the node

***Return*** *baidupan.node*

the home node with the specific path.

### Error code

|code|description|
|---|---|
|0|success|
|1|server error|
|2|argument error|
|3|lost session|
|4|storage problem|
|12|multiple procedure errors|
|14|network error|
|15|operation failed|
|16|network error|
|105|linking failed|
|106|file read error|
|108|invalid file name|
|110|share limits exceeded|
|111|transfer error|
|112|lost session|
|113|sign error|
|114|invalid task|
|115|invalid share|
|116|invalid share|
|117|invalid share|
|118|invalid key check|
|-1|share is disabled|
|-2|invalid user|
|-4|invalid session|
|-5|invalid session|
|-6|invalid session|
|-7|invalid share|
|-8|invalid share|
|-9|invalid password for share|
|-10|share limits exceeded|
|-11|invalid session|
|-12|invalid |
|-20|require verifying|
|-21|forbidden share|
|-22|invalid operation on shared files|
|-30|file has existed|
|-31|file saving failed|
|-32|no space left|
|-33|operation limits exceeded|
|-40|recommendation failed|
|-60|recommendation failed|
|-62|password try limits exceeded|
|-64|invalid description|
|-70|malware share|