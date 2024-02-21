--[[
    钻石挑战通关挑战
]]

local DiamondManiaConfig = require("activities.Activity_DiamondMania.config.DiamondManiaConfig")
local DiamondManiaNet = require("activities.Activity_DiamondMania.net.DiamondManiaNet")
local DiamondManiaMgr = class("DiamondManiaMgr", BaseActivityControl)

function DiamondManiaMgr:ctor()
    DiamondManiaMgr.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.DiamondMania)

    self.m_netModel = DiamondManiaNet:getInstance()   -- 网络模块
end

function DiamondManiaMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity_DiamondMania.Activity.Activity_DiamondMania")
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function DiamondManiaMgr:sendCollect()
    self.m_netModel:sendCollect()
end

function DiamondManiaMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function DiamondManiaMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function DiamondManiaMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function DiamondManiaMgr:getConfig()
    return DiamondManiaConfig
end

function DiamondManiaMgr:checkStageComplete()
    local data = self:getRunningData()
    if data then
        local list = data:getCanCollectReward()
        if #list > 0 then
            self:showMainLayer()
        end
    end
end

-- function DiamondManiaMgr:getLevelLogoCodePath()
--     if not self:isCanShowLayer() then
--         return
--     end

--     return "Activity_DiamondMania.Activity.Activity_DiamondManiaLogo"
-- end

function DiamondManiaMgr:getEntryPath(entryName)
    return "Activity_DiamondMania/Activity/Activity_DiamondManiaLogo"
end

return DiamondManiaMgr
