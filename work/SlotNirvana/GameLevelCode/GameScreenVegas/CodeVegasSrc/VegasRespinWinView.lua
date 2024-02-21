---
--xcyy
--2018年5月23日
--VegasRespinWinView.lua

local VegasRespinWinView = class("VegasRespinWinView", util_require("base.BaseView"))

function VegasRespinWinView:initUI()
    self:createCsbNode("Vegas_rswinner.csb")
    local node = self:findChild("effectNode")
    self.m_effect = util_createView("CodeVegasSrc.VegasWinEffect")
    node:addChild(self.m_effect)
    self:runCsbAction("idle",true)
end

function VegasRespinWinView:onEnter()
end

function VegasRespinWinView:onExit()
end
-- 更新赢钱数
function VegasRespinWinView:updateRespinWinCoins(_coins)
    local lab = self:findChild("m_lb_coins")
    lab:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label = lab, sx = 0.6, sy = 0.6}, 854)
end

function VegasRespinWinView:playWinEffect()
    if self.m_effect then
        self.m_effect:playEffect()
    end
end

return VegasRespinWinView
