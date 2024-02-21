--[[
    
    author: 徐袁
    time: 2021-08-18 15:40:18
]]
local QuestNewShowTopManager = class("QuestNewShowTopManager", BaseActivityControl)

function QuestNewShowTopManager:ctor()
    QuestNewShowTopManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.QuestNewShowTop)
end

return QuestNewShowTopManager
