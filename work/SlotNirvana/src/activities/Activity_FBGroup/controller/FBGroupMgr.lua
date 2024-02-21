--[[
    author:{author}
    time:2021-09-28 14:22:08
]]
local FBGroupMgr = class("FBGroupMgr", BaseActivityControl)

-- 需要随机的 主题后缀 index 对应工程里面
local randomIndexGroupVec = {
    1,
    2
}

function FBGroupMgr:ctor()
    FBGroupMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FBGroup)
end

-- 三个路径是 2023 版本 取消 随机显示广告位功能，只显示最新的
function FBGroupMgr:getPopPath()
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName
end

function FBGroupMgr:getHallPath()
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function FBGroupMgr:getSlidePath()
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "SlideNode"
end

-- 下面是老版的

-- function FBGroupMgr:showMainLayer(data)
--     if not self:isCanShowLayer() then
--         return nil
--     end
--     local uiView = util_createFindView("Activity/Activity_FBGroup", data)
--     gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
--     return uiView
-- end
-- function FBGroupMgr:getShowLayerCsbName()
--     local weelType = self:getShowDataWeekType()
--     local basePath = "Activity/Activity_FBGroup/csb/Activity_Group"
--     local csbPath =  basePath ..randomIndexGroupVec[1] ..".csb"
--     if weelType < #randomIndexGroupVec then
--         csbPath =  basePath ..randomIndexGroupVec[weelType + 1] ..".csb"
--     end
--     return csbPath
-- end
-- function FBGroupMgr:randomShowHall(data)
--     local refName = self:getRefName()
--     local themeName = self:getThemeName()
--     if refName ~= themeName then 
--         return data
--     end

--     local result_data = data
--     local weelType = self:getShowDataWeekType()
--     local basePath = "Icons/Activity_Group"
--     if weelType < #randomIndexGroupVec then
--         result_data.p_slideImage =  basePath ..randomIndexGroupVec[weelType + 1] .."Slide.csb" 
--         result_data.p_hallImages =  {basePath ..randomIndexGroupVec[weelType + 1] .."Hall.csb"}
--     end
--     return result_data
-- end
-- function FBGroupMgr:getShowDataWeekType()
--     if self.m_weelType then
--         return  self.m_weelType
--     end
--     local nowTime = tonumber(globalData.userRunData.p_serverTime / 1000)
--     local serverTM = util_UTC2TZ(nowTime, -8)
--     local b = serverTM.yday%7
--     local WeekBegan = 0
--     if serverTM.wday > b then
--         WeekBegan = 7 - serverTM.wday + b
--     else
--         WeekBegan = b - serverTM.wday 
--     end
--     local week = 0
--     if serverTM.yday - WeekBegan > 0 then
--         if (serverTM.yday - WeekBegan)%7 > 0 then
--             week = math.floor((serverTM.yday - WeekBegan)/7) + 1
--         else
--             week = (serverTM.yday - WeekBegan)/7
--         end
--     end
    
--     self.m_weelType = week% #randomIndexGroupVec
--     return  self.m_weelType
-- end
return FBGroupMgr
