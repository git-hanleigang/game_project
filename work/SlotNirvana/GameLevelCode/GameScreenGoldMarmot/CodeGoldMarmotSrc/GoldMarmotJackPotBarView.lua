---
--xcyy
--2018年5月23日
--GoldMarmotJackPotBarView.lua
local PublicConfig = require "levelsGoldMarmotPublicConfig"
local GoldMarmotJackPotBarView = class("GoldMarmotJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function GoldMarmotJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("GoldMarmot_jackpot.csb")
    self:runIdleAni()
    self.m_sounds = {}

    --中奖光效
    self.m_lightAni = {}
    for index = 1,4 do
        local light = util_createAnimation("GoldMarmot_jackpot_1.csb")
        for iLight = 1,4 do
            light:findChild("light_"..iLight):setVisible(index == iLight)
        end

        self:findChild("light_"..index):addChild(light)
        light:runCsbAction("zhongjiang",true)
        light:setVisible(false)
        self.m_lightAni[index] = light
    end
end

function GoldMarmotJackPotBarView:runIdleAni()
    self:runCsbAction("idle",true)
end

function GoldMarmotJackPotBarView:onEnter()

    GoldMarmotJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function GoldMarmotJackPotBarView:onExit()
    GoldMarmotJackPotBarView.super.onExit(self)
end

function GoldMarmotJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function GoldMarmotJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function GoldMarmotJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.71,sy=0.71}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.66,sy=0.66}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.56,sy=0.56}
    self:updateLabelSize(info1,355)
    self:updateLabelSize(info2,300)
    self:updateLabelSize(info3,300)
    self:updateLabelSize(info4,300)
end

function GoldMarmotJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end


function GoldMarmotJackPotBarView:showHitJackpot(jackpots)
    local isPlaySound = false
    for k,jackpotIndex in pairs(jackpots) do
        if not self.m_lightAni[jackpotIndex]:isVisible() then
            self.m_lightAni[jackpotIndex]:setVisible(true)
            isPlaySound = true
        end
    end

    if isPlaySound then
        local randIndex = math.random(1,#self.m_sounds)
        local soundPath = self.m_sounds[randIndex]
        table.remove(self.m_sounds,randIndex,1)
        gLobalSoundManager:playSound(soundPath)
    end
end

function GoldMarmotJackPotBarView:hideAllLight()
    for k,light in pairs(self.m_lightAni) do
        light:setVisible(false)
    end

    self.m_sounds = {
        PublicConfig.SoundConfig.sound_GoldMarmot_yeah,
        PublicConfig.SoundConfig.sound_GoldMarmot_heihei,
        PublicConfig.SoundConfig.sound_GoldMarmot_more_gold,
        PublicConfig.SoundConfig.sound_GoldMarmot_nice,
    }
end

return GoldMarmotJackPotBarView