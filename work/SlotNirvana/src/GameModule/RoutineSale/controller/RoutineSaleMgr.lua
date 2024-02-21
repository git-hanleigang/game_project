--[[
    新版常规促销
--]]

local RoutineSaleConfig = util_require("GameModule.RoutineSale.config.RoutineSaleConfig")
local RoutineSaleNet = util_require("GameModule.RoutineSale.net.RoutineSaleNet")
local RoutineSaleMgr = class("RoutineSaleMgr", BaseGameControl)

function RoutineSaleMgr:ctor()
    RoutineSaleMgr.super.ctor(self)

    self:setRefName(G_REF.RoutineSale)
    self:setResInApp(true)
    self:setDataModule("GameModule.RoutineSale.model.RoutineSaleData")

    self.m_net = RoutineSaleNet:getInstance()
    self.m_openTime = 1
end

-- 显示主界面
function RoutineSaleMgr:showMainLayer(_params)
	if gLobalViewManager:getViewByExtendData("RoutineSaleMainLayer") then
        return
    end

    local view = util_createView("GameModule.RoutineSale.views.RoutineSaleMainLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function RoutineSaleMgr:showTurntableLayer(_params)
	if gLobalViewManager:getViewByExtendData("RoutineSaleTurntableLayer") then
        return
    end

    local view = util_createView("GameModule.RoutineSale.views.RoutineSaleTurntableLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function RoutineSaleMgr:showRewardLayer(_params, _baseCoins)
	if gLobalViewManager:getViewByExtendData("RoutineSaleRewardLayer") then
        return
    end

    local view = util_createView("GameModule.RoutineSale.views.RoutineSaleRewardLayer", _params, _baseCoins)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function RoutineSaleMgr:showInfoLayer(_params)
	if gLobalViewManager:getViewByExtendData("RoutineSaleInfoLayer") then
        return
    end

    local view = util_createView("GameModule.RoutineSale.views.RoutineSaleInfoLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function RoutineSaleMgr:canShowMainLayer()
    local data = self:getRunningData()
    if data and data:hasBuyTimes() then
        return true
    end

    return false
end

function RoutineSaleMgr:checkOpenMainLayer()
    local data = self:getRunningData()
    if data and data:hasBuyTimes() and self.m_openTime > 0 then
        self.m_openTime = self.m_openTime - 1
        return true
    end

    return false
end

function RoutineSaleMgr:buySale(_data, _index)
    self.m_net:buySale(_data, _index)
end

function RoutineSaleMgr:sendWheelReward()
    self.m_net:sendWheelReward()
end

return RoutineSaleMgr