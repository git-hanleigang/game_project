--[[
    
    author: 徐袁
    time: 2021-09-18 11:39:10
]]
local NewPassThreeLineLoadingManager = class("NewPassThreeLineLoadingManager", BaseActivityControl)

function NewPassThreeLineLoadingManager:ctor()
    NewPassThreeLineLoadingManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewPassThreeLineLoading)
    self:addPreRef(ACTIVITY_REF.NewPass)
end

function NewPassThreeLineLoadingManager:getPopName()
    return "Activity_NewPassNewSendLayer"
end

function NewPassThreeLineLoadingManager:getRunningData(refName)
    local data = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not data or not data:isRunning() or not data:isThreeLinePass()  then
        return nil
    end
    return NewPassThreeLineLoadingManager.super.getRunningData(self, refName)
end

return NewPassThreeLineLoadingManager
