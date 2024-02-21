
local NewDiamondChallenge_EndMgr = class("NewDiamondChallenge_EndMgr", BaseActivityControl)

function NewDiamondChallenge_EndMgr:ctor()
    NewDiamondChallenge_EndMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewDiamondChallenge_End)
end

function NewDiamondChallenge_EndMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. hallName .."HallNode"
end

function NewDiamondChallenge_EndMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. slideName .."SlideNode"
end

function NewDiamondChallenge_EndMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

-- function NewDiamondChallenge_EndMgr:showPopLayer(popInfo, callback)
--     if not self:isCanShowPop() then
--         return nil
--     end

--     if popInfo and popInfo.clickFlag then
--         G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):showMainLayer()
--     end
--     return nil
-- end

return NewDiamondChallenge_EndMgr
