---
--xcyy
--2018年5月23日
--WarriorAliceItemJackPotBarView.lua
local PublicConfig = require "WarriorAlicePublicConfig"
local WarriorAliceItemJackPotBarView = class("WarriorAliceItemJackPotBarView",util_require("Levels.BaseLevelDialog"))

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

function WarriorAliceItemJackPotBarView:initUI(jackpotType)

    self:createCsbNode("WarriorAlice_jackpot.csb")

    self.jackpotType = jackpotType
    self:showJackpotType(jackpotType)
    self:showJackpotIdle(jackpotType)
    self:hideJackpotLizi()
end

function WarriorAliceItemJackPotBarView:showJackpotIdle(jackpotType)
    self.idleAct = util_createAnimation("WarriorAlice_jackpot_idle.csb")
    for i,v in ipairs(jackpotName) do
        if i == jackpotType then
            self.idleAct:findChild(jackpotName[i]):setVisible(true)
        else
            self.idleAct:findChild(jackpotName[i]):setVisible(false)
        end
        
    end
    self:findChild(jackpotName[jackpotType].."_idle"):addChild(self.idleAct)
    self.idleAct:setVisible(false)
    
end

function WarriorAliceItemJackPotBarView:isShowJackpotIdle(isShow)
    if isShow then
        self.idleAct:setVisible(isShow)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WarriorAlice_show_jackpot_light)
        self:runCsbAction("actionframe1", false, function()
            self:runCsbAction("start", false, function()
                self:runCsbAction("idle2", true)
            end)
        end)
        self.idleAct:runCsbAction("idle", true)
    else
        self.idleAct:stopAllActions()
        self.idleAct:setVisible(isShow)
    end
    
end

function WarriorAliceItemJackPotBarView:showJackpotType(jackpotType)
    if jackpotType == 2 then
        self:findChild("grand"):setVisible(false)
        self:findChild("major"):setVisible(true)
        self:findChild("minor"):setVisible(false)
        self:findChild("mini"):setVisible(false)
    elseif jackpotType == 3 then
        self:findChild("grand"):setVisible(false)
        self:findChild("major"):setVisible(false)
        self:findChild("minor"):setVisible(true)
        self:findChild("mini"):setVisible(false)
    elseif jackpotType == 4 then
        self:findChild("grand"):setVisible(false)
        self:findChild("major"):setVisible(false)
        self:findChild("minor"):setVisible(false)
        self:findChild("mini"):setVisible(true)
    end
end

function WarriorAliceItemJackPotBarView:hideJackpotLizi()
    self:findChild("grand_lizi"):setVisible(false)
    self:findChild("major_lizi"):setVisible(false)
    self:findChild("minor_lizi"):setVisible(false)
end

function WarriorAliceItemJackPotBarView:showJackpotLizi(jackpotType)
    if jackpotType == 2 then
        self:findChild("major_lizi"):setVisible(true)
        for i=1,2 do
            self:findChild("Particle_2_"..i):resetSystem()
        end
        self:delayCallBack(2,function ()
            for i=1,2 do
                self:findChild("Particle_2_"..i):stopSystem()
            end
            self:findChild("major_lizi"):setVisible(false)
        end)
    elseif jackpotType == 3 or jackpotType == 4 then
        self:findChild("minor_lizi"):setVisible(true)
        for i=1,2 do
            self:findChild("Particle_3_"..i):resetSystem()
        end
        self:delayCallBack(2,function ()
            for i=1,2 do
                self:findChild("Particle_3_"..i):stopSystem()
            end
            self:findChild("minor_lizi"):setVisible(false)
        end)
    end
end

function WarriorAliceItemJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WarriorAliceItemJackPotBarView:onEnter()

    WarriorAliceItemJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function WarriorAliceItemJackPotBarView:onExit()
    WarriorAliceItemJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function WarriorAliceItemJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner
    if self.jackpotType == 2 then
        self:changeNode(self:findChild(MajorName),2,false)
    elseif self.jackpotType == 3 then
        self:changeNode(self:findChild(MinorName),3,false)
    elseif self.jackpotType == 4 then
        self:changeNode(self:findChild(MiniName),4,false)
    end

    self:updateSize()
end

function WarriorAliceItemJackPotBarView:updateSize()
    if self.jackpotType == 2 then
        local label2=self.m_csbOwner[MajorName]
        local info2={label=label2,sx=0.67,sy=0.67}
        self:updateLabelSize(info2,204)
    elseif self.jackpotType == 3 then
        local label3=self.m_csbOwner[MinorName]
        local info3={label=label3,sx=0.6,sy=0.6}
        self:updateLabelSize(info3,172)
    elseif self.jackpotType == 4 then
        local label4=self.m_csbOwner[MiniName]
        local info4={label=label4,sx=0.6,sy=0.6}
        self:updateLabelSize(info4,172)
    end

end

function WarriorAliceItemJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,4,nil,nil,isJump))
end

function WarriorAliceItemJackPotBarView:showCoinsForLabel(winCoin)
    local label = nil
    if self.jackpotType == 2 then
        label = self:findChild(MajorName)
    elseif self.jackpotType == 3 then
        label = self:findChild(MinorName)
    elseif self.jackpotType == 4 then
        label = self:findChild(MiniName)
    end
    if label then
        label:setString(util_formatCoins(winCoin,4))
    end
    
end

--[[
    延迟回调
]]
function WarriorAliceItemJackPotBarView:delayCallBack(time, func)
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

return WarriorAliceItemJackPotBarView