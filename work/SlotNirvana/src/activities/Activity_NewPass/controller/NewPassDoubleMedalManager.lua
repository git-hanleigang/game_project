--[[
    
    author: 徐袁
    time: 2021-09-18 11:19:06
]]
local NewPassDoubleMedalManager = class("NewPassDoubleMedalManager", BaseActivityControl)

function NewPassDoubleMedalManager:ctor()
    NewPassDoubleMedalManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewPassDoubleMedal)
    self:addPreRef(ACTIVITY_REF.NewPass)
end

function NewPassDoubleMedalManager:showMainLayer()
    return self:showPopLayer()
end

return NewPassDoubleMedalManager
