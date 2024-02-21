--[[
    新版常规促销
--]]

local RoutineSaleTurntableLayer = class("RoutineSaleTurntableLayer", BaseLayer)

function RoutineSaleTurntableLayer:initDatas(_params)
    self.m_params = _params
    self.m_maxUsd = _params.maxUsd
    self.m_baseCoins = _params.baseCoins
    self.m_wheelChunk = _params.wheelChunk
    self.m_wheelReward = _params.wheelReward
    self.m_count = _params.count
    self.m_overcall = _params.overcall

    self:setPortraitCsbName("Sale_New/csb/turntable/SaleTurntable_shu.csb")
    self:setLandscapeCsbName("Sale_New/csb/turntable/SaleTurntable.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("RoutineSaleTurntableLayer")
end

function RoutineSaleTurntableLayer:initCsbNodes()
    self.m_Node_spine = self:findChild("Node_spine")
    self.m_node_tip = self:findChild("node_tip")
    self.m_node_turntable = self:findChild("node_turntable")
    self.m_node_ef = self:findChild("node_xuanzhuangguang")
    self.m_lb_buy = self:findChild("lb_buy")
    self.m_lb_coins = self:findChild("lb_coins")
    self.m_sp_coins = self:findChild("sp_coins")
    self.m_btn_close = self:findChild("btn_close")
    self.m_btn_close:setVisible(not self.m_params.isReward)
end

function RoutineSaleTurntableLayer:initView()
    self:initTip()
    self:setCoins()
    self:initWheel()
    self:initSpine()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function RoutineSaleTurntableLayer:initTip()
    if self.m_params.isReward then
        self.m_tip = util_createView("GameModule.RoutineSale.views.RoutineSaleTurntableTip")
        self.m_node_tip:addChild(self.m_tip)
    end
end

function RoutineSaleTurntableLayer:setCoins()
    self.m_lb_buy:setString("$" .. self.m_maxUsd)
    self:updateLabelSize({label = self.m_lb_buy}, 280)

    local coins = self.m_baseCoins
    self.m_lb_coins:setString(util_formatCoins(coins, 6))

    local uiList = {
        {node = self.m_sp_coins},
        {node = self.m_lb_coins, alignX = 3}
    }
    util_alignCenter(uiList)
end

function RoutineSaleTurntableLayer:initWheel()
    self.m_wheel = util_createView("GameModule.RoutineSale.views.RoutineSaleWheel", self.m_params, self)
    self.m_node_turntable:addChild(self.m_wheel)
end

function RoutineSaleTurntableLayer:initSpine()
    if self.m_Node_spine then
        self.m_npc = util_spineCreate("Sale_New/spine/npc", true, true, 1)
        self.m_Node_spine:addChild(self.m_npc)
    end
end

function RoutineSaleTurntableLayer:getTouch()
    return self.m_isTouch
end

function RoutineSaleTurntableLayer:setTouch(_flag)
    self.m_isTouch = _flag
end

function RoutineSaleTurntableLayer:clickFunc(_sender)
    if self:getTouch() then
        return
    end

    local name = _sender:getName()
    if name == "btn_close" then
        self:hideEf()
        self:closeUI(function ()
            if self.m_params.pop then
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
            if self.m_overcall then
                self.m_overcall()
            end
        end)
    elseif name == "btn_rule" then
        G_GetMgr(G_REF.RoutineSale):showInfoLayer()
    end
end

function RoutineSaleTurntableLayer:addSpinEf()
    self.m_efNode = util_createView("GameModule.RoutineSale.views.RoutineSaleEfNode")
    self.m_node_ef:addChild(self.m_efNode)
end

function RoutineSaleTurntableLayer:hideEf()
    if self.m_efNode then
        self.m_efNode:setVisible(false)
    end

    local Particle_1 = self:findChild("Particle_1")
    local Particle_2 = self:findChild("Particle_2")
    local Particle_3 = self:findChild("Particle_3")
    if Particle_1 then
        Particle_1:setVisible(false)
    end
    if Particle_2 then
        Particle_2:setVisible(false)
    end
    if Particle_3 then
        Particle_3:setVisible(false)
    end
end

function RoutineSaleTurntableLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)

    if self.m_tip then
        self.m_tip:playStart()
    end
end

function RoutineSaleTurntableLayer:onEnter()
    RoutineSaleTurntableLayer.super.onEnter(self)
    
    if self.m_npc then
        util_spinePlay(self.m_npc, "idle", true)
    end
end

function RoutineSaleTurntableLayer:registerListener()
    RoutineSaleTurntableLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(
        self,
        function()
            self:hideEf()
            self:closeUI(function ()
                if self.m_params.pop then
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
                if self.m_overcall then
                    self.m_overcall()
                end
            end)
        end,
        ViewEventType.NOTIFY_ROUTINE_SALE_WHEEL_REWARD_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            if not self.m_params.isReward then
                self:hideEf()
                self:closeUI(function ()
                    if self.m_overcall then
                        self.m_overcall()
                    end
                end)
            end
        end,
        ViewEventType.NOTIFY_ROUTINE_SALE_TIME_OUT
    )
end

return RoutineSaleTurntableLayer