---
--xcyy
--2018年5月23日
--LuxuryDiamondJackPotBarView.lua

local LuxuryDiamondJackPotBarView = class("LuxuryDiamondJackPotBarView",util_require("Levels.BaseLevelDialog"))
-- local LuxuryDiamondJackPotBarView = class("LuxuryDiamondJackPotBarView", cc.Node)

local SuperName = "m_lb_coin_super"
local GrandName = "m_lb_coin_grand"
local MajorName = "m_lb_coin_major"
local MinorName = "m_lb_coin_minor"
local MiniName = "m_lb_coin_mini" 

-- LuxuryDiamondJackPotBarView.JACKPOT_NAME_LIST = {"yaan_minor", "yaan_major", "yaan_grand","yaan_super" }
LuxuryDiamondJackPotBarView.JACKPOT_NAME_LIST = {"mini","yaan_minor", "yaan_major", "yaan_grand","yaan_super" }

function LuxuryDiamondJackPotBarView:initUI()

    self:createCsbNode("LuxuryDiamond_Jackpot.csb")

    -- self:runCsbAction("idleframe",true)

    -- self.m_effect = util_createAnimation("LuxuryDiamond_gualan.csb")
    -- self:findChild("Node_1"):addChild(self.m_effect, 2)
    -- self.m_effect:setVisible(false)

    self.m_lockNode = {}
    for index,value in ipairs(self.JACKPOT_NAME_LIST) do
        local locakNode = util_createView("CodeLuxuryDiamondSrc.LuxuryDiamondJackPotLock", index)
        self:findChild(value):addChild(locakNode)
        self.m_lockNode[index] = locakNode
    end
end


function LuxuryDiamondJackPotBarView:onExit()
    LuxuryDiamondJackPotBarView.super.onExit(self)
end

function LuxuryDiamondJackPotBarView:initMachine(machine)
    self.m_machine = machine

end


function LuxuryDiamondJackPotBarView:onEnter()
    LuxuryDiamondJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function LuxuryDiamondJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self:findChild(SuperName),1,true)
    self:changeNode(self:findChild(GrandName),2,true)
    self:changeNode(self:findChild(MajorName),3)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)
    self:updateSize()
end

function LuxuryDiamondJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=0.95,sy=1}
    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=0.95,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.95,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.95,sy=1}
    local label5=self.m_csbOwner[SuperName]
    local info5={label=label5,sx=0.95,sy=1}
    self:updateLabelSize(info1,183)
    self:updateLabelSize(info2,183)
    self:updateLabelSize(info3,183)
    self:updateLabelSize(info4,183)
    self:updateLabelSize(info5,183)
end

function LuxuryDiamondJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function LuxuryDiamondJackPotBarView:toAction(actionName)
    -- self:runCsbAction(actionName)
end

function LuxuryDiamondJackPotBarView:updateUI(betID, isInit)

    for index,value in ipairs(self.JACKPOT_NAME_LIST) do
        local locakNode = self.m_lockNode[index]
        if isInit then
            locakNode:initCurLevel(betID)
        else
            locakNode:changeCurbetLevel(betID)
        end
    end
end

function LuxuryDiamondJackPotBarView:showEffect(index)
    local target_name = nil
    if index == 1 then
        target_name = SuperName
    elseif index == 2 then
        target_name = GrandName
    elseif index == 3 then
        target_name = MajorName
    elseif index == 4 then
        target_name = MinorName
    elseif index == 5 then
        target_name = MiniName
    end

    if target_name then
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_jackpot_effect.mp3")
        -- self.m_effect:setPosition(cc.p(self:findChild(target_name):getPosition()))
        -- self.m_effect:setVisible(true)
        -- self.m_effect:playAction("start", false, function()
        --     self.m_effect:setVisible(false)
        -- end)
    end
end

return LuxuryDiamondJackPotBarView