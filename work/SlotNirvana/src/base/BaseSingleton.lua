--[[
    基础单例类
    author:徐袁
    time:2020-12-19 15:07:10
]]
local BaseSingleton = class("BaseSingleton")

function BaseSingleton:ctor()
    self._instance = nil
end

--[[
    @desc: 获得单例对象
    author:徐袁
    time:2020-12-19 15:16:24
    @return:
]]
function BaseSingleton:getInstance()
    if not self._instance then
        self._instance = self.__index:create()
    end
    return self._instance
end

return BaseSingleton
