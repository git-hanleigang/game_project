---
--xcyy
--2018年5月23日
--CashRushJackpotsBaseBarView.lua

local CashRushJackpotsBaseBarView = class("CashRushJackpotsBaseBarView",util_require("Levels.BaseLevelDialog"))

CashRushJackpotsBaseBarView.m_freespinCurrtTimes = 0


function CashRushJackpotsBaseBarView:initUI()

    self:createCsbNode("CashRushJackpots_baseBar.csb")
end

function CashRushJackpotsBaseBarView:onEnter()
    CashRushJackpotsBaseBarView.super.onEnter(self)
end

function CashRushJackpotsBaseBarView:onExit()
    CashRushJackpotsBaseBarView.super.onExit(self)
end

return CashRushJackpotsBaseBarView