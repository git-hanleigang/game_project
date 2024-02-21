--[[
    充值抽奖池
]]

local PrizeGameNet = require("activities.Activity_PrizeGame.net.PrizeGameNet")
local PrizeGameMgr = class("PrizeGameMgr", BaseActivityControl)

function PrizeGameMgr:ctor()
    PrizeGameMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.PrizeGame)
    self.m_net = PrizeGameNet:getInstance()
end

function PrizeGameMgr:showMainLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity_PrizeGame.Activity.Activity_PrizeGame", _data)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function PrizeGameMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("PrizeGameInfo") == nil then
        local view = util_createView("Activity_PrizeGame.Activity.PrizeGameInfo")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function PrizeGameMgr:showCollectLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("PrizeGameCollect") == nil then
        local view = util_createView("Activity_PrizeGame.Activity.PrizeGameCollect", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

function PrizeGameMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function PrizeGameMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function PrizeGameMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

-- 付费
function PrizeGameMgr:buySale(_data)
    self.m_net:buySale(_data)
end

function PrizeGameMgr:sendCollect()
    self.m_net:sendCollect()
end

function PrizeGameMgr:refreshData()
    self.m_net:refreshData()
end

function PrizeGameMgr:checkReconnect()
    local data = self:getRunningData()
    if data and data:getRemainingTimes() > 0 then
        local view = self:showMainLayer({reconnect = true})
        return view
    else
        return false
    end
end

return PrizeGameMgr
