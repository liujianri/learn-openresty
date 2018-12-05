local conf = require "config.maple_config"
local cjson = require "cjson"
local template = require "resty.template"

local _M = {}

function _M:new(action, arg)
	local  str = action..'.html'
	template.render(str, { message = "Hello, World!",pamas = arg})
end

return _M;