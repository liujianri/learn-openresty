
local redis = require "lib.redis_iresty"

local _M = {}
local mt 	= { __index = _M }

function _M:new(ip,port)
	local opts ={}
	opts['host'] = ip
	opts['port'] = port
	local red = redis:new(opts)
	return setmetatable({red=red}, mt);
end

function _M:sub(key)
	local func  = self.red:subscribe(key)
	if not func then
	  return nil
	end

	while true do
	    local res, err = func()
	    if err then
	        func(false)
	    end
	    if res ~= nil then 
	    	ngx.say('dd')
	    end
	end
end

function _M:pub(key)
	local param ,err= self.red:publish(key,'333')
	return param
end

function _M:incrK(key)
	local param ,err= self.red:incr(key)
	if err ~= nil then 
		ngx.say(err)
		return
	end
	local js = {}
	js[key] = param
	return js
end

function _M:hgetV(arg,key)
	local param ,err= self.red:hget(arg,key)
	if err ~= nil then 
		ngx.say(err)
		return
	end
	local temp,js = {},{}
	temp[key] = param
	js[arg] = temp 
	return js
end

function _M:getV(arg)
	local param ,err= self.red:get(arg)
	if err ~= nil then 
		ngx.say(err)
		return
	end
	local js = {}
	js[arg] = param
	return js
end

function _M:mgetV(arg)
	local params = split(arg,",")
	local js ,js_= {},{}
	
	for i, v in ipairs(params) do
        js[i] = v
    end 

	local succ,res,err = self.red:mget(unpack(js))
	for i,v in ipairs(params) do
		js_[v] = succ[i]
	end
	return js_
end

function _M:hgetallV(arg)
	local param ,err= self.red:hgetall(arg)
	if err ~= nil then 
		ngx.say(err)
		return
	end
	local js = {}
	for i=1,#param,2 do  
	    js[param[i]]=param[i+1]
	end
	return js
end
return _M;
