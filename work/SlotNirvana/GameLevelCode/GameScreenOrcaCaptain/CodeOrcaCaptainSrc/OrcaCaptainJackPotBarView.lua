---
--xcyy
--2018年5月23日
--OrcaCaptainJackPotBarView.lua
local OrcaCaptainPublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainJackPotBarView = class("OrcaCaptainJackPotBarView", util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_1"
local MegaName = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5"

function OrcaCaptainJackPotBarView:initUI()
    self:createCsbNode("OrcaCaptain_jackpot.csb")

    self.sgList = {}
    self:createAllSg()
end

function OrcaCaptainJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function OrcaCaptainJackPotBarView:onEnter()
    OrcaCaptainJackPotBarView.super.onEnter(self)
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
function OrcaCaptainJackPotBarView:updateJackpotInfo()
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

function OrcaCaptainJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 1.01, sy = 1}
    local info2 = {label = label2, sx = 0.84, sy = 0.82}
    local info3 = {label = label3, sx = 0.84, sy = 0.82}
    local info4 = {label = label4, sx = 0.78, sy = 0.78}
    local info5 = {label = label5, sx = 0.78, sy = 0.78}

    self:updateLabelSize(info1, 365)
    self:updateLabelSize(info2, 356)
    self:updateLabelSize(info3, 356)
    self:updateLabelSize(info4, 331)
    self:updateLabelSize(info5, 331)
end

function OrcaCaptainJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

--sg
function OrcaCaptainJackPotBarView:createAllSg()
    for i=1,5 do
        local sg = util_spineCreate("OrcaCaptain_jackpot_sg", true, true)
        local name = self:getIdleName(i)
        util_spinePlay(sg,name,true)
        self:findChild("Node_sg"..i):addChild(sg)
        self.sgList[#self.sgList + 1] = sg
    end
end

function OrcaCaptainJackPotBarView:getIdleName(index)
    if index == 1 then
        return "idle1"
    elseif index == 2 then
        return "idle2"
    elseif index == 3 then
        return "idle3"
    elseif index == 4 then
        return "idle4"
    elseif index == 5 then
        return "idle5"
    end
end

return OrcaCaptainJackPotBarView
