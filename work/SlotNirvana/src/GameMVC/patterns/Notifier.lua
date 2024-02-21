--[[
    
    author: 徐袁
    time: 2021-09-01 11:31:52
]]
local Facade = require("GameMVC.core.Facade")

local Notifier = class("Notifier")

function Notifier:ctor()
    -- self._facade = Facade:getInstance()
end

function Notifier:getMgr(refName)
    return Facade:getInstance():getCtrl(refName)
end

function Notifier:registerCtrl(ctrl)
    Facade:getInstance():registerCtrl(ctrl)
end

-- 获得数据
function Notifier:getData(refName)
    return Facade:getInstance():getModel(refName)
end

-- 获得数据
function Notifier:registerData(model)
    return Facade:getInstance():registerModel(model)
end

-- function Notifier:sendNotification(notificationName, body, type)
--     self._facade:sendNotification(notificationName, body, type)
-- end

return Notifier
