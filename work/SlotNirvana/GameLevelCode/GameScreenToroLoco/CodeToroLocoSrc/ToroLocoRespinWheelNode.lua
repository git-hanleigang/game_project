---
--xcyy
--2018年5月23日
--ToroLocoRespinWheelNode.lua
local ToroLocoPublicConfig = require "ToroLocoPublicConfig"
local ToroLocoRespinWheelNode = class("ToroLocoRespinWheelNode", util_require("base.BaseView"))

function ToroLocoRespinWheelNode:initUI()
    self:createCsbNode("Socre_ToroLoco_Respin_Zi.csb")
end

function ToroLocoRespinWheelNode:updateData(indexType, coins, machine)
    self:findChild("Node_jackpot_respin"):setVisible(false)
    self:findChild("Node_mul"):setVisible(false)
    self:findChild("Node_respin"):setVisible(false)

    if indexType == 1 then --jackpot
        self:findChild("Node_jackpot_respin"):setVisible(true)
        self:findChild("respin_grand"):setVisible(coins == "Grand")
        self:findChild("respin_major"):setVisible(coins == "Major")
        self:findChild("respin_minor"):setVisible(coins == "Minor")
        self:findChild("respin_mini"):setVisible(coins == "Mini")
    elseif indexType == 2 then --乘倍
        self:findChild("Node_mul"):setVisible(true)
        self:findChild("m_lb_coins_mul"):setString("X"..coins)
    else --金币
        self:findChild("Node_respin"):setVisible(true)
        self:findChild("m_lb_coins"):setString(util_formatCoins(coins, 3, false, true, true))
    end
end

return ToroLocoRespinWheelNode
