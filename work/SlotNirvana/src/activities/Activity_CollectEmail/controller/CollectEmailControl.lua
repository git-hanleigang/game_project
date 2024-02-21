--[[
    邮箱收集
]]

local CollectEmailNet = require("activities.Activity_CollectEmail.net.CollectEmailNet")
local CollectEmailControl = class("CollectEmailControl", BaseActivityControl)

function CollectEmailControl:ctor()
    CollectEmailControl.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.collectEmail)

    self.m_netModel = CollectEmailNet:getInstance()   -- 网络模块
end

function CollectEmailControl:saveEmail(_email, _openPos)
    self.m_netModel:saveEmail(_email, _openPos)
end

return CollectEmailControl
