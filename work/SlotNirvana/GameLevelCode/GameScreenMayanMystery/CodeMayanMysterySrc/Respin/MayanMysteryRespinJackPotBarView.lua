---
--xcyy
--2018年5月23日
--MayanMysteryRespinJackPotBarView.lua
local MayanMysteryPublicConfig = require "MayanMysteryPublicConfig"
local MayanMysteryRespinJackPotBarView = class("MayanMysteryRespinJackPotBarView", util_require("base.BaseView"))

local EpicName = "m_lb_epic"

function MayanMysteryRespinJackPotBarView:initUI()
    self:createCsbNode("MayanMystery_respin_epic.csb")

    self:runCsbAction("idleframe", true)
end

function MayanMysteryRespinJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MayanMysteryRespinJackPotBarView:onEnter()
    MayanMysteryRespinJackPotBarView.super.onEnter(self)
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
function MayanMysteryRespinJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(EpicName), 1, true)

    self:updateSize()
end

function MayanMysteryRespinJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[EpicName]

    local info1 = {label = label1, sx = 1, sy = 1}

    self:updateLabelSize(info1, 295)
end

function MayanMysteryRespinJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

function MayanMysteryRespinJackPotBarView:playJackpotEffect( )
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idleframe", true)
    end)
end

return MayanMysteryRespinJackPotBarView
