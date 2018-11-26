
local conf = require "config.maple_config"
local redis = require "lib.redism"
local cjson = require "cjson"

local _M = {}

function _M:new(action, arg)
	
	local conf = conf.def_redis
	local red = redis:new(conf.host,conf.port)

	local json = ''
	if action == 'get' then
		json = red:getV(arg['param'])
	elseif action == 'mget' then
		json = red:mgetV(arg['param'])
	elseif action == 'hgetall' then
		json = red:hgetallV(arg['param'])
	elseif action == 'hget' then
		json = red:hgetV(arg['param'],arg['key'])
	elseif action == 'incr' then
		json = red:incrK(arg['param'])
	elseif action == 'pub' then
		json = red:pub(arg['param'])
	elseif action == 'sub' then
		json = red:sub(arg['param'])
	else 
		json = 1
	end
	local str = cjson.encode(json)
	ngx.say(str)
end

return _M;