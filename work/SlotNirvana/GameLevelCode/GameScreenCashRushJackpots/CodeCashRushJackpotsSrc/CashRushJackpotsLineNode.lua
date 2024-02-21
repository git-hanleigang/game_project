---
--xcyy
--2018年5月23日
--CashRushJackpotsLineNode.lua

local CashRushJackpotsLineNode = class("CashRushJackpotsLineNode",util_require("Levels.BaseLevelDialog"))
local lineCount = 30

function CashRushJackpotsLineNode:initUI()

    self:createCsbNode("CashRushJackpots_Paylines.csb")

    self.m_lineTbl = {}
    for i=1, lineCount do
        self.m_lineTbl[i] = self:findChild("nodeLine_"..i)
    end
end

function CashRushJackpotsLineNode:showNodeLine(_lineId)
    self:setVisible(true)
    local lineId = _lineId
    for index, lineNode in pairs(self.m_lineTbl) do
        if index == lineId then
            lineNode:setVisible(true)
            break
        end
    end
end

function CashRushJackpotsLineNode:hideNodeLine()
    self:setVisible(false)
    for index, lineNode in pairs(self.m_lineTbl) do
        lineNode:setVisible(false)
    end
end

return CashRushJackpotsLineNode
