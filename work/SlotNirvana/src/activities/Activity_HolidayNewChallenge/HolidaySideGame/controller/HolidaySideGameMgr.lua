--[[
    圣诞聚合 -- 小游戏
]]

require("activities.Activity_HolidayNewChallenge.HolidaySideGame.config.HolidaySideGameConfig")
local HolidaySideGameMgr = class("HolidaySideGameMgr", BaseActivityControl)

function HolidaySideGameMgr:ctor()
    HolidaySideGameMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidaySideGame)
end

-- 显示主弹板
function HolidaySideGameMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("Activity_HolidaySideGame") then
        return
    end
    local view = util_createView("Activity_HolidaySideGame.Code.Activity_HolidaySideGame", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function HolidaySideGameMgr:showRewardLayer(_num, _over)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName("HSGameRewardLayer") then
        return
    end
    local view = util_createView("Activity_HolidaySideGame.Code.HSGameRewardLayer", _num, _over)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view    
end

-- function HolidaySideGameMgr:getHallPath(hallName)
--     local themeName = self:getThemeName()
--     return themeName .. "/Icons/" .. hallName .. "HallNode"
-- end

-- function HolidaySideGameMgr:getSlidePath(slideName)
--     local themeName = self:getThemeName()
--     return themeName .. "/Icons/" .. slideName .. "SlideNode"
-- end

-- function HolidaySideGameMgr:getPopPath(popName)
--     local themeName = self:getThemeName()
--     return themeName .. "/Activity/" .. popName
-- end

return HolidaySideGameMgr
