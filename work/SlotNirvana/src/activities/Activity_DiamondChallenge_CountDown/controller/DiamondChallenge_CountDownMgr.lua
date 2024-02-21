
local DiamondChallenge_CountDownMgr = class("DiamondChallenge_CountDownMgr", BaseActivityControl)

function DiamondChallenge_CountDownMgr:ctor()
    DiamondChallenge_CountDownMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiamondChallenge_CountDown)
end

function DiamondChallenge_CountDownMgr:getHallPath(hallName)
    --Activity_DiamondChallenge_CountDown/Activity_DiamondChallenge_CountDown HallNode.lua
    local themeName = self:getThemeName()
    return themeName  .. "/" .. hallName .."HallNode"
end

function DiamondChallenge_CountDownMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. slideName .."SlideNode"
end

function DiamondChallenge_CountDownMgr:showPopLayer(popInfo, callback)
    if not self:isCanShowPop() then
        return nil
    end

    if popInfo and popInfo.clickFlag then
        G_GetMgr(ACTIVITY_REF.LuckyChallenge):showMainLayer()
    end
    return nil
end

return DiamondChallenge_CountDownMgr
