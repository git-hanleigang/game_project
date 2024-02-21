
local NewDiamondChallenge_RuleMgr = class("NewDiamondChallenge_RuleMgr", BaseActivityControl)

function NewDiamondChallenge_RuleMgr:ctor()
    NewDiamondChallenge_RuleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewDiamondChallenge_Rule)
end

function NewDiamondChallenge_RuleMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. hallName .."HallNode"
end

function NewDiamondChallenge_RuleMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. slideName .."SlideNode"
end

function NewDiamondChallenge_RuleMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

-- function NewDiamondChallenge_RuleMgr:showPopLayer(popInfo, callback)
--     if not self:isCanShowPop() then
--         return nil
--     end

--     if popInfo and popInfo.clickFlag then
--         G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):showMainLayer()
--     end
--     return nil
-- end

return NewDiamondChallenge_RuleMgr
