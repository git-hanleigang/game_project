--[[  
    返回持金极大值促销
]]

local TimeBackNet = require("activities.Activity_TimeBack.net.TimeBackNet")
local TimeBackMgr = class("TimeBackMgr", BaseActivityControl)

function TimeBackMgr:ctor()
    TimeBackMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.TimeBack)
    self.m_net = TimeBackNet:getInstance()
end

-- 显示主界面
function TimeBackMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity_TimeBack.Activity.Activity_TimeBack")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function TimeBackMgr:showTipLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity_TimeBack.Activity.Activity_TimeBackTipLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function TimeBackMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function TimeBackMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function TimeBackMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function TimeBackMgr:sendActivityClose()
    self.m_net:ActivityClose()
end

function TimeBackMgr:sendBuySale(_data)
    self.m_net:buySale(_data)
end

function TimeBackMgr:isPopup()
    local data = self:getRunningData()
    if data and data:getPopup() then
        return true
    end
    return false
end

function TimeBackMgr:checkActivityPopup()
    if self:isPopup() then
        return self:showMainLayer()
    end
end

function TimeBackMgr:parseSlotData(_data)
    local gameData = self:getRunningData()
    if gameData then
        gameData:parseData(_data)
    end
end

return TimeBackMgr
