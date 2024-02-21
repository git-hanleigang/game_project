--[[
    
    author: 徐袁
    time: 2021-08-18 15:40:18
]]
local QuestShowTopManager = class("QuestShowTopManager", BaseActivityControl)

function QuestShowTopManager:ctor()
    QuestShowTopManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.QuestShowTop)
end

return QuestShowTopManager
