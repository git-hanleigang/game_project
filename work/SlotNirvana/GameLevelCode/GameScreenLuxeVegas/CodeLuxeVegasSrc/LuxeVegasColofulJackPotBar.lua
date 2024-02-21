---
--xcyy
--2018年5月23日
--LuxeVegasColofulJackPotBar.lua
local PublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasColofulJackPotBar = class("LuxeVegasColofulJackPotBar",util_require("base.BaseView"))

local GrandName = "m_lb_coins_GRAND"
local MegaName = "m_lb_coins_MEGA"
local MajorName = "m_lb_coins_MAJOR"
local MinorName = "m_lb_coins_MINOR"
local MiniName = "m_lb_coins_MINI" 

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5,
}

function LuxeVegasColofulJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("LuxeVegas_Jackpot_dfdc.csb")
    self:runIdleAni()

    self.m_collectItems = {}    --所有的收集点
    self.m_topBarJackpotBar = {} --jackpot触发动画
    self.m_topBarCollectLight = {} --差一个集满
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_collectItems[jackpotType] = {}
        local itemParent = nil
        if jackpotIndex == 1 then
            itemParent = util_createAnimation("LuxeVegas_Jackpot_dfdcGrand.csb")
        else
            itemParent = util_createAnimation("LuxeVegas_Jackpot_dfdcOther.csb")
            itemParent:findChild("Node_mega"):setVisible(jackpotType=="mega")
            itemParent:findChild("Node_major"):setVisible(jackpotType=="major")
            itemParent:findChild("Node_minor"):setVisible(jackpotType=="minor")
            itemParent:findChild("Node_mini"):setVisible(jackpotType=="mini")
        end
        self:findChild("Node_Jackpot_"..jackpotIndex):addChild(itemParent)
        for index = 1,3 do
            local item = itemParent:findChild(jackpotType.."_"..index)
            self.m_collectItems[jackpotType][index] = item
        end
        self.m_topBarCollectLight[jackpotIndex] = itemParent
        self.m_topBarJackpotBar[jackpotIndex] = util_createAnimation("LuxeVegas_Jackpot_win.csb")
        self:findChild("Node_win"..jackpotIndex):addChild(self.m_topBarJackpotBar[jackpotIndex])
        self.m_topBarJackpotBar[jackpotIndex]:setVisible(false)
    end
end

function LuxeVegasColofulJackPotBar:onEnter()

    LuxeVegasColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function LuxeVegasColofulJackPotBar:onExit()
    LuxeVegasColofulJackPotBar.super.onExit(self)
end

function LuxeVegasColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function LuxeVegasColofulJackPotBar:resetActData()
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_topBarJackpotBar[jackpotIndex]:setVisible(false)
        self.m_topBarCollectLight[jackpotIndex]:runCsbAction("idle", true)
    end
end

-- 差一个集满动效
function LuxeVegasColofulJackPotBar:collectBarLight(jackpotIndex)
    self.m_topBarCollectLight[jackpotIndex]:runCsbAction("idle2", true)
end

--[[
    收集反馈动效
]]
function LuxeVegasColofulJackPotBar:collectFeedBackAni(jackpotIndex)
    self.m_topBarJackpotBar[jackpotIndex]:setVisible(true)
    util_resetCsbAction(self.m_topBarJackpotBar[jackpotIndex].m_csbAct)
    local particle = self.m_topBarJackpotBar[jackpotIndex]:findChild("Particle_2")
    particle:setPositionType(0)
    particle:setDuration(-1)
    particle:resetSystem()
    self.m_topBarJackpotBar[jackpotIndex]:runCsbAction("actionframe2", false, function()
        particle:stopSystem()
        self.m_topBarJackpotBar[jackpotIndex]:setVisible(false)
    end)
end

--[[
    显示中奖光效
]]
function LuxeVegasColofulJackPotBar:showHitLight(jackpotIndex)
    self:resetActData()
    self.m_topBarJackpotBar[jackpotIndex]:setVisible(true)
    util_resetCsbAction(self.m_topBarJackpotBar[jackpotIndex].m_csbAct)
    self.m_topBarJackpotBar[jackpotIndex]:runCsbAction("actionframe", true)
end

--[[
    idle
]]
function LuxeVegasColofulJackPotBar:runIdleAni()
    self:runCsbAction("idle",true)
end

function LuxeVegasColofulJackPotBar:getAllNode()
    return self.m_collectItems
end

-- 更新jackpot 数值信息
--
function LuxeVegasColofulJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MegaName), 2, true)
    self:changeNode(self:findChild(MajorName), 3, true)
    self:changeNode(self:findChild(MinorName), 4)
    self:changeNode(self:findChild(MiniName), 5)

    self:updateSize()
end

function LuxeVegasColofulJackPotBar:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.93, sy = 1.0}
    local info2 = {label = label2, sx = 0.73, sy = 0.75}
    local info3 = {label = label3, sx = 0.73, sy = 0.75}
    local info4 = {label = label4, sx = 0.63, sy = 0.68}
    local info5 = {label = label5, sx = 0.63, sy = 0.68}
    
    self:updateLabelSize(info1, 378)
    self:updateLabelSize(info2, 378)
    self:updateLabelSize(info3, 378)
    self:updateLabelSize(info4, 378)
    self:updateLabelSize(info5, 378)
end

function LuxeVegasColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return LuxeVegasColofulJackPotBar
