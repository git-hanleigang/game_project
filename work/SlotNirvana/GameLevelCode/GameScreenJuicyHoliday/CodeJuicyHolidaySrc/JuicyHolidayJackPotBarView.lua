---
--xcyy
--2018年5月23日
--JuicyHolidayJackPotBarView.lua
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayJackPotBarView = class("JuicyHolidayJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

local JACKPOT_TYPE = {
    "grand",
    "major",
    "minor",
    "mini"
}
function JuicyHolidayJackPotBarView:initUI()
    self:createCsbNode("JuicyHoliday_jackpotkuang_base.csb")

    for index = 1,#JACKPOT_TYPE do
        local jackpotType = JACKPOT_TYPE[index]
        
        local parent = self:findChild("Node_idle_"..string.upper(jackpotType))
        if not tolua.isnull(parent) then
            local light = util_spineCreate("JuicyHoliday_jackpot",true,true)
            parent:addChild(light)
            util_spinePlay(light,"idle_"..string.upper(jackpotType),true)
        end
        

    end
end

function JuicyHolidayJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function JuicyHolidayJackPotBarView:onEnter()
    JuicyHolidayJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

-- 更新jackpot 数值信息
--
function JuicyHolidayJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)
    self:changeNode(self:findChild(MiniName), 4)

    self:updateSize()
end

function JuicyHolidayJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MinorName]
    local label4 = self.m_csbOwner[MiniName]
    
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local info3 = {label = label3, sx = 1, sy = 1}
    local info4 = {label = label4, sx = 1, sy = 1}
    self:updateLabelSize(info1, 305)
    self:updateLabelSize(info2, 305)
    self:updateLabelSize(info3, 255)
    self:updateLabelSize(info4, 255)
end

function JuicyHolidayJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return JuicyHolidayJackPotBarView
