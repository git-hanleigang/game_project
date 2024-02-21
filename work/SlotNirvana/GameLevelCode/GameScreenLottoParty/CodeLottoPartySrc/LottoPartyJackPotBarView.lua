---
--xcyy
--2018年5月23日
--LottoPartyJackPotBarView.lua

local LottoPartyJackPotBarView = class("LottoPartyJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"

function LottoPartyJackPotBarView:initUI()
    self:createCsbNode("LottoParty_jackpot.csb")

    -- self:runCsbAction("idleframe",true)
end

function LottoPartyJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

function LottoPartyJackPotBarView:onExit()
end

function LottoPartyJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function LottoPartyJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)

    self:updateSize()
end

function LottoPartyJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local info1 = {label = label1, sx = 0.42, sy = 0.42}
    self:updateLabelSize(info1, 734)

    local label2 = self.m_csbOwner[MajorName]
    local info2 = {label = label2, sx = 0.3, sy = 0.3}
    self:updateLabelSize(info2, 624)

    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.3, sy = 0.3}
    self:updateLabelSize(info3, 545)
end

function LottoPartyJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

return LottoPartyJackPotBarView
