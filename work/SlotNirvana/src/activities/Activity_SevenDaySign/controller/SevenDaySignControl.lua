--[[
    7天签到
]]

local SevenDaySignNet = require("activities.Activity_SevenDaySign.net.SevenDaySignNet")
local SevenDaySignControl = class("SevenDaySignControl", BaseActivityControl)

function SevenDaySignControl:ctor()
    SevenDaySignControl.super.ctor(self)
    -- 新的7天活动签到从2周年签到开始（老版的不知道还要不要，就有点离谱）
    self:setRefName(ACTIVITY_REF.Years2)

    self.m_netModel = SevenDaySignNet:getInstance()   -- 网络模块
end

function SevenDaySignControl:collectReward()
    self.m_netModel:sendCollectReward()
end

function SevenDaySignControl:openRewardUI()
    if not self:isCanShowLayer() then
        return nil
    end

    local themeName = self:getThemeName()
    local path = nil
    if themeName == "Activity_2YearsRegister" then 
        path = "Activity.Activity_2YearsReward"
    end

    if path then 
        local view = util_createView(path)
        if view then 
            gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
        end
    end
end

return SevenDaySignControl
