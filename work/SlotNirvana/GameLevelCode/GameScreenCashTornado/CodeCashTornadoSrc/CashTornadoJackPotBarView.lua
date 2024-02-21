---
--xcyy
--2018年5月23日
--CashTornadoJackPotBarView.lua
local PublicConfig = require "CashTornadoPublicConfig"
local CashTornadoJackPotBarView = class("CashTornadoJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_1"
local MegaName = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5"

function CashTornadoJackPotBarView:initUI()
    self:createCsbNode("CashTornado_Jackpot.csb")
    self:addEveryJackpot()
    self:showIdleActForAllNode()
end

function CashTornadoJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CashTornadoJackPotBarView:onEnter()
    CashTornadoJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

function CashTornadoJackPotBarView:addEveryJackpot()
    self.m_grandNode = util_createAnimation("CashTornado_Jackpot_grand.csb")
    self:findChild("grand"):addChild(self.m_grandNode)

    self.m_megaNode = util_createAnimation("CashTornado_Jackpot_mega.csb")
    self:findChild("mega"):addChild(self.m_megaNode)

    self.m_majorNode = util_createAnimation("CashTornado_Jackpot_major.csb")
    self:findChild("major"):addChild(self.m_majorNode)

    self.m_minorNode = util_createAnimation("CashTornado_Jackpot_minor.csb")
    self:findChild("minor"):addChild(self.m_minorNode)

    self.m_miniNode = util_createAnimation("CashTornado_Jackpot_mini.csb")
    self:findChild("mini"):addChild(self.m_miniNode)
end

-- 更新jackpot 数值信息
--
function CashTornadoJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self.m_grandNode:findChild(GrandName), 1, true)
    self:changeNode(self.m_megaNode:findChild(MegaName), 2, true)
    self:changeNode(self.m_majorNode:findChild(MajorName), 3, true)
    self:changeNode(self.m_minorNode:findChild(MinorName), 4)
    self:changeNode(self.m_miniNode:findChild(MiniName), 5)

    self:updateSize()
end

function CashTornadoJackPotBarView:updateSize()
    local label1 = self.m_grandNode:findChild(GrandName)
    local label2 = self.m_megaNode:findChild(MegaName)
    local label3 = self.m_majorNode:findChild(MajorName)
    local label4 = self.m_minorNode:findChild(MinorName)
    local label5 = self.m_miniNode:findChild(MiniName)
    local info1 = {label = label1, sx = 0.9, sy = 1}
    local info2 = {label = label2, sx = 0.59, sy = 0.65}
    local info3 = {label = label3, sx = 0.59, sy = 0.65}
    local info4 = {label = label4, sx = 0.59, sy = 0.65}
    local info5 = {label = label5, sx = 0.59, sy = 0.65}
    self:updateLabelSize(info1, 394)
    self:updateLabelSize(info2, 394)
    self:updateLabelSize(info3, 394)
    self:updateLabelSize(info4, 294)
    self:updateLabelSize(info5, 294)
end

function CashTornadoJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value, 12, nil, nil, true))
end

function CashTornadoJackPotBarView:hideShowNode(isShow)
    self:findChild("Node_2"):setVisible(isShow)
end

function CashTornadoJackPotBarView:showRewardAct(jackpotType)
    local node = self:getJackpotNodeForType(jackpotType)
    if not tolua.isnull(node) then
        node:runCsbAction("actionframe",true)
    end
end

function CashTornadoJackPotBarView:showFanKuiAct(jackpotType)
    local node = self:getJackpotNodeForType(jackpotType)
    if not tolua.isnull(node) then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_jackpot_fankui)
        node:runCsbAction("actionframe_fankui_"..jackpotType,false,function ()
            self:showIdle2Act(jackpotType)
        end)
    end
    
end

function CashTornadoJackPotBarView:showIdleAct(jackpotType)
    local node = self:getJackpotNodeForType(jackpotType)
    if not tolua.isnull(node) then
        node:runCsbAction("idleframe",true)
    end
end

function CashTornadoJackPotBarView:showIdleActForAllNode()
    self.m_grandNode:runCsbAction("idleframe",true)
    self.m_megaNode:runCsbAction("idleframe",true)
    self.m_majorNode:runCsbAction("idleframe",true)
    self.m_minorNode:runCsbAction("idleframe",true)
    self.m_miniNode:runCsbAction("idleframe",true)
end

function CashTornadoJackPotBarView:showIdle2Act(jackpotType)
    local node = self:getJackpotNodeForType(jackpotType)
    if not tolua.isnull(node) then
        node:runCsbAction("idleframe2_"..jackpotType,true)
    end
    
end

function CashTornadoJackPotBarView:getJackpotNodeForType(jackpotType)
    if jackpotType ==  "grand"then
        return self.m_grandNode
    elseif jackpotType ==  "mega"then
        return self.m_megaNode
    elseif jackpotType ==  "major"then
        return self.m_majorNode
    elseif jackpotType ==  "minor"then
        return self.m_minorNode
    elseif jackpotType ==  "mini"then
        return self.m_miniNode
    end
end

function CashTornadoJackPotBarView:getJackpotDoePick(jackpotType)
    local jackpotNode = self:getJackpotNodeForType(jackpotType)
    if jackpotNode:findChild("Node_pick_"..jackpotType) then
        return jackpotNode:findChild("Node_pick_"..jackpotType)
    else
        return self:findChild("Node_1")
    end
end

return CashTornadoJackPotBarView
