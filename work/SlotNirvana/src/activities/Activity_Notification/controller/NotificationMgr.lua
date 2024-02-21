--[[
    打开推送通知送奖
]]

local NotificationConfig = require("activities.Activity_Notification.config.NotificationConfig")
local NotificationNet = require("activities.Activity_Notification.net.NotificationNet")
local NotificationMgr = class("NotificationMgr", BaseActivityControl)

function NotificationMgr:ctor()
    NotificationMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.Notification)
    self.m_net = NotificationNet:getInstance()
end

function NotificationMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function NotificationMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function NotificationMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function NotificationMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function NotificationMgr:sendCollect()
    self.m_net:sendCollect()
end

function NotificationMgr:hasReward()
    local flag = false
    local data = self:getRunningData()
    if data then
        local cdExpireAt = data:getCdExpired()
        if cdExpireAt <= util_getCurrnetTime() then
            flag = true
        end
    end

    return flag
end

return NotificationMgr
