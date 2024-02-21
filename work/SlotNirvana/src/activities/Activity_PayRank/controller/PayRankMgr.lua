--[[
    付费排行榜
]]

local PayRankNet = require("activities.Activity_PayRank.net.PayRankNet")
local PayRankMgr = class("PayRankMgr", BaseActivityControl)

function PayRankMgr:ctor()
    PayRankMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.PayRank)
    self.m_netModel = PayRankNet:getInstance()   -- 网络模块
end

function PayRankMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    local data = self:getRunningData()
    local unlock = data:getUnlock()
    if unlock then
        view = util_createView("Activity_PayRank.Activity.PayRankMainLayer")
    else
        view = util_createView("Activity_PayRank.Activity.Activity_PayRank")
    end

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function PayRankMgr:showInfoLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity_PayRank.Activity.PayRankInfo", _data)
    gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    return view
end

function PayRankMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function PayRankMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function PayRankMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    local data = self:getRunningData()
    if data and data:getUnlock() then
        return themeName .. "/Activity/" .. "PayRankMainLayer"
    else
        return themeName .. "/Activity/" .. popName
    end
end

function PayRankMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName.. "/Activity/" .. entryName .. "EntryNode" 
 end

function PayRankMgr:sendRefreshData()
    self.m_netModel:sendRefreshData()
end

return PayRankMgr
