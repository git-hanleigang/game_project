--[[--
]]
local CardSeasonBottom201903 = require("GameModule.Card.season201903.CardSeasonBottom")
local CardSeasonBottom = class("CardSeasonBottom", CardSeasonBottom201903)

function CardSeasonBottom:getCsbName()
    return string.format(CardResConfig.seasonRes.CardBottomNodeRes, "season202102")
end

function CardSeasonBottom:getMenuNodeLua()
    return "GameModule.Card.season202102.CardMenuNode"    
end

function CardSeasonBottom:getMenuWheelLua()
    return "GameModule.Card.season202102.CardMenuWheel"    
end

function CardSeasonBottom:getSeasonNadoWheelLua()
    return "GameModule.Card.season202102.CardSeasonNadoWheel"    
end

--[[-- 神像入口]]
function CardSeasonBottom:getStatueLua()
    return "GameModule.Card.season202102.CardSeasonStatue"
end

function CardSeasonBottom:initNode()
    CardSeasonBottom201903.initNode(self)
    self.m_bottomStatue = self:findChild("Node_GodStatue")
end

function CardSeasonBottom:initBottomNode()
    CardSeasonBottom201903.initBottomNode(self)
    self:initStatue()
end

function CardSeasonBottom:initStatue()
    if not self.m_statueUI then
        self.m_statueUI = util_createView(self:getStatueLua())
        self.m_bottomStatue:addChild(self.m_statueUI)
    end
    self.m_statueUI:updateUI()
end

return CardSeasonBottom
