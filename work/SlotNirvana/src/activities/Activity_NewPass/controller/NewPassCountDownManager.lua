--[[
    
    author: 徐袁
    time: 2021-09-18 11:39:10
]]
local NewPassCountDownManager = class("NewPassCountDownManager", BaseActivityControl)

function NewPassCountDownManager:ctor()
    NewPassCountDownManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewPassCountDown)
    self:addPreRef(ACTIVITY_REF.NewPass)
end

function NewPassCountDownManager:showMainLayer()
    return self:showPopLayer()
end

return NewPassCountDownManager
