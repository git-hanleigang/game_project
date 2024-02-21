--[[
    7天签到
]]

local SevenDaySignNet = require("activities.Activity_NiceDice.net.NiceDiceNet")
local NiceDiceControl = class("NiceDiceControl", BaseActivityControl)

function NiceDiceControl:ctor()
    NiceDiceControl.super.ctor(self)

    self:setRefName(ACTIVITY_REF.NiceDice)
    self.m_netModel = SevenDaySignNet:getInstance()   -- 网络模块
end

function NiceDiceControl:collectReward()
    self.m_netModel:sendCollectReward()
end

function NiceDiceControl:showRewardLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity.Activity_NiceDiceReward", _data)
    gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
end

function NiceDiceControl:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity.Activity_NiceDice", _data)
    gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
end

return NiceDiceControl
