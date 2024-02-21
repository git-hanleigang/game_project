--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-05-17 10:59:40
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-09 16:34:43
FilePath: /SlotNirvana/src/activities/Activity_FBCommunity/controller/FBCommunityMgr.lua
Description: FB 社区FanPage manager
--]]
local FBCommunityMgr = class("FBCommunityMgr", BaseActivityControl)

-- 需要随机的 主题后缀 index 对应工程里面
local randomIndexCommunityVec = {
    1,
    2
}

function FBCommunityMgr:ctor()
    FBCommunityMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FBCommunity)
   
end

-- 三个路径是 2023 版本 取消 随机显示广告位功能，只显示最新的
function FBCommunityMgr:getPopPath()
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName
end

function FBCommunityMgr:getHallPath()
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "HallNode"
end

function FBCommunityMgr:getSlidePath()
    local themeName = self:getThemeName()
    return themeName .. "/" .. themeName .. "SlideNode"
end

-- 下面是老版的
-- function FBCommunityMgr:showMainLayer(data)
--     if not self:isCanShowLayer() then
--         return nil
--     end
    
--     local uiView = util_createFindView("Activity/Activity_FBGroup", data)
--     gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
--     return uiView
-- end

-- function FBCommunityMgr:getShowLayerCsbName()
--     local weelType = self:getShowDataWeekType()
--     local basePath = "Activity/Activity_FBCommunity/csb/Activity_FBCommunity"
--     local csbPath =  basePath ..randomIndexCommunityVec[1] ..".csb"
--     if weelType < #randomIndexCommunityVec then
--         csbPath =  basePath ..randomIndexCommunityVec[weelType + 1] ..".csb"
--     end
--     return csbPath
-- end
-- function FBCommunityMgr:randomShowHall(data)
--     local refName = self:getRefName()
--     local themeName = self:getThemeName()
--     if refName ~= themeName then 
--         return data
--     end
    
--     local result_data = data
--     local weelType = self:getShowDataWeekType()
--     local basePath = "Icons/Activity_FBCommunity"
--     if weelType < #randomIndexCommunityVec then
--         result_data.p_slideImage =  basePath ..randomIndexCommunityVec[weelType + 1] .."Slide.csb" 
--         result_data.p_hallImages =  {basePath ..randomIndexCommunityVec[weelType + 1] .."Hall.csb"}
--     end
--     return result_data
-- end
-- function FBCommunityMgr:getShowDataWeekType()
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
--     self.m_weelType = week% #randomIndexCommunityVec
--     return  self.m_weelType
-- end

return FBCommunityMgr
