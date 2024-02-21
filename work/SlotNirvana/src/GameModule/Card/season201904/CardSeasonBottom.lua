--[[--
]]
local CardSeasonBottom201903 = require("GameModule.Card.season201903.CardSeasonBottom")
local CardSeasonBottom = class("CardSeasonBottom", CardSeasonBottom201903)

function CardSeasonBottom:getCsbName()
    return string.format(CardResConfig.seasonRes.CardBottomNodeRes, "season201904")
end

function CardSeasonBottom:getMenuNodeLua()
    return "GameModule.Card.season201904.CardMenuNode"    
end

function CardSeasonBottom:getMenuWheelLua()
    return "GameModule.Card.season201904.CardMenuWheel"    
end

function CardSeasonBottom:getSeasonNadoWheelLua()
    return "GameModule.Card.season201904.CardSeasonNadoWheel"    
end

function CardSeasonBottom:getPuzzleLua()
    return "GameModule.Card.season201904.CardSeasonPuzzle"
end

function CardSeasonBottom:initNode()
    CardSeasonBottom201903.initNode(self)
    self.m_bottomPuzzle = self:findChild("Cash_puzzle")
end

function CardSeasonBottom:initBottomNode()
    CardSeasonBottom201903.initBottomNode(self)
    self:initPuzzle()
end

function CardSeasonBottom:initPuzzle()
    if not self.m_puzzleUI then
        self.m_puzzleUI = util_createView(self:getPuzzleLua())
        self.m_bottomPuzzle:addChild(self.m_puzzleUI)
    end
    self.m_puzzleUI:updateUI()
end

return CardSeasonBottom
