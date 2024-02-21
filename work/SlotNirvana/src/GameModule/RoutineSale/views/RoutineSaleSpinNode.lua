--[[
    
]]

local RoutineSaleSpinNode = class("RoutineSaleSpinNode", BaseView)

function RoutineSaleSpinNode:getCsbName()
    return "Sale_New/csb/main/SaleMain_spin.csb"
end

function RoutineSaleSpinNode:initUI(_maxUsd, _mainLayer)
    RoutineSaleSpinNode.super.initUI(self)

    self.m_mainLayer = _mainLayer
    self.m_data = G_GetMgr(G_REF.RoutineSale):getRunningData()
    local hasWheelRward = self.m_data:hasWheelRward()
    local spin = self:findChild("spin")
    spin:setEnabled(hasWheelRward)

    local lb_buy = self:findChild("lb_buy")
    lb_buy:setString("$" .. _maxUsd)

    self:runCsbAction("idle1", true)
end

function RoutineSaleSpinNode:clickFunc(_sender)
    if self.m_mainLayer:getTouch() then
        return
    end

    local name = _sender:getName()
    if name == "btn_spin" then
        local params = {}
        params.baseCoins = self.m_data:getWheelBaseCoins()
        params.maxUsd = self.m_data:getWheelMaxUsd()
        params.wheelChunk = self.m_data:getWheelChunk()
        params.count = self.m_data:getWheelAllPro()
        params.isReward = false
        G_GetMgr(G_REF.RoutineSale):showTurntableLayer(params)
    end
end

function RoutineSaleSpinNode:playIdle()
    self:runCsbAction("idle", true)
end

return RoutineSaleSpinNode