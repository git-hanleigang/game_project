
local NewDiamondChallenge_LoadingMgr = class("NewDiamondChallenge_LoadingMgr", BaseActivityControl)

function NewDiamondChallenge_LoadingMgr:ctor()
    NewDiamondChallenge_LoadingMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewDiamondChallenge_Loading)
end

function NewDiamondChallenge_LoadingMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. hallName .."HallNode"
end

function NewDiamondChallenge_LoadingMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName  .. "/" .. slideName .."SlideNode"
end

function NewDiamondChallenge_LoadingMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

-- function NewDiamondChallenge_LoadingMgr:showPopLayer(popInfo, callback)
--     if not self:isCanShowPop() then
--         return nil
--     end

--     if popInfo and popInfo.clickFlag then
--         G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):showMainLayer()
--     end
--     return nil
-- end

return NewDiamondChallenge_LoadingMgr
