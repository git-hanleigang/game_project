---
--xhkj
--2018年6月11日
--FrogPrinceBonusRoundView.lua

local FrogPrinceBonusRoundView = class("FrogPrinceBonusRoundView", util_require("base.BaseView"))

function FrogPrinceBonusRoundView:initUI(data)
    self:createCsbNode("FrogPrince_BonusGame3.csb")
    local round = data.round
    local num = data.num
    self:findChild("BitmapFontLabel_1"):setString(round)
    self:findChild("BitmapFontLabel_2"):setString(num)
    -- self:runCsbAction("start")
end

function FrogPrinceBonusRoundView:onEnter()

end

function FrogPrinceBonusRoundView:setParent(parent)
    self.m_parent = parent
end

function FrogPrinceBonusRoundView:onExit()
end

return FrogPrinceBonusRoundView
