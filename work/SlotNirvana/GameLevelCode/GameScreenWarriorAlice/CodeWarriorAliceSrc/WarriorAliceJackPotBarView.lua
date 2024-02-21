---
--xcyy
--2018年5月23日
--WarriorAliceJackPotBarView.lua
local PublicConfig = require "WarriorAlicePublicConfig"
local WarriorAliceJackPotBarView = class("WarriorAliceJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

local jackpotName = {
    "grand",
    "major",
    "minor",
    "mini"
}

function WarriorAliceJackPotBarView:initUI()

    self:createCsbNode("WarriorAlice_jackpot.csb")

    self:showJackpotType()
    self:showJackpotIdle()

    self:hideJackpotLizi()
end

function WarriorAliceJackPotBarView:showJackpotType()
    self:findChild("major"):setVisible(false)
    self:findChild("minor"):setVisible(false)
    self:findChild("mini"):setVisible(false)
    self:findChild("Node_tx"):setVisible(false)
end

function WarriorAliceJackPotBarView:showJackpotIdle()
    self.idleAct = util_createAnimation("WarriorAlice_jackpot_idle.csb")
    for i,v in ipairs(jackpotName) do
        if i == 1 then
            self.idleAct:findChild(jackpotName[i]):setVisible(true)
        else
            self.idleAct:findChild(jackpotName[i]):setVisible(false)
        end
        
    end
    self:findChild("grand_idle"):addChild(self.idleAct)
    self.idleAct:setVisible(false)
    -- self.idleAct:runCsbAction("idle",true)
end

function WarriorAliceJackPotBarView:isShowJackpotIdle(isShow)
    if isShow then
        self.idleAct:setVisible(isShow)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_jackpot_light)
        self.idleAct:runCsbAction("idle",true)
    else
        self.idleAct:stopAllActions()
        self.idleAct:setVisible(isShow)
    end
    
end

function WarriorAliceJackPotBarView:hideJackpotLizi()
    self:findChild("grand_lizi"):setVisible(false)
    self:findChild("major_lizi"):setVisible(false)
    self:findChild("minor_lizi"):setVisible(false)
end

function WarriorAliceJackPotBarView:showJackpotLizi()
    self:runCsbAction("actionframe")

    self:findChild("grand_lizi"):setVisible(true)
    for i=1,4 do
        self:findChild("Particle_1_"..i):resetSystem()
    end
    self:delayCallBack(1/6,function ()
        self:findChild("grand_lizi"):setVisible(false)
    end)
end

function WarriorAliceJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WarriorAliceJackPotBarView:onEnter()

    WarriorAliceJackPotBarView.super.onEnter(self)
    self:stopAllActions()
    util_setCascadeOpacityEnabledRescursion(self,true)
    
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function WarriorAliceJackPotBarView:onExit()
    WarriorAliceJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function WarriorAliceJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    -- self:changeNode(self:findChild(MajorName),2)
    -- self:changeNode(self:findChild(MinorName),3)
    -- self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function WarriorAliceJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    -- local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1.14,sy=1.14}
    -- local info2={label=label2,sx=0.67,sy=0.67}
    -- local label3=self.m_csbOwner[MinorName]
    -- local info3={label=label3,sx=0.6,sy=0.6}
    -- local label4=self.m_csbOwner[MiniName]
    -- local info4={label=label4,sx=0.6,sy=0.6}
    self:updateLabelSize(info1,383)
    -- self:updateLabelSize(info2,204)
    -- self:updateLabelSize(info3,172)
    -- self:updateLabelSize(info4,172)
end

function WarriorAliceJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,isJump))
end

--[[
    延迟回调
]]
function WarriorAliceJackPotBarView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WarriorAliceJackPotBarView