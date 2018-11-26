local cjson = require "cjson"
local str = {}
str['new'] = 'lua';
str[1] = 1;
str = cjson.encode(str)
ngx.say(str);