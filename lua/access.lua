
require "common"

local cjson = require "cjson"
local uri = ngx.var.uri 
local mt = split(uri,"/")
local controller = mt[3]
local action = mt[4]

local request_method = ngx.var.request_method
local args = nil


if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    -- ngx.req.read_body()
    -- args = ngx.req.get_post_args()
end

if "redis" == controller then
	local task1 = require "services.taskm"
	task1:new(action, args)
elseif "show_html" == controller then
	local task2 = require "services.tasktem"
	task2:new(action, args)
elseif "upload" == controller then
	local task3 = require "lib.uploads"
	local ne = task3:new('/home/maple')
	task3:handle_uploading(ne)
else
	ngx.say('error')
end