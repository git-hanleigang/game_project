--[[--
]]
local CardSeasonBottom201903 = require("GameModule.Card.season201903.CardSeasonBottom")
local CardSeasonBottom = class("CardSeasonBottom", CardSeasonBottom201903)

function CardSeasonBottom:getCsbName()
    return string.format(CardResConfig.seasonRes.CardBottomNodeRes, "season202202")
end

function CardSeasonBottom:getMenuNodeLua()
    return "GameModule.Card.season202202.CardMenuNode"
end

function CardSeasonBottom:getMenuWheelLua()
    return "GameModule.Card.season202202.CardMenuWheel"
end

function CardSeasonBottom:getSeasonNadoWheelLua()
    return "GameModule.Card.season202202.CardSeasonNadoWheel"
end

--[[-- 神像入口]]
function CardSeasonBottom:getStatueLua()
    return "GameModule.Card.season202202.CardSeasonStatue"
end

function CardSeasonBottom:initNode()
    CardSeasonBottom201903.initNode(self)
    self.m_bottomStatue = self:findChild("Node_GodStatue")
    self.m_efNode = self:findChild("ef_node_sg")
end

function CardSeasonBottom:initBottomNode()
    CardSeasonBottom201903.initBottomNode(self)
    self:initStatue()
    -- 特效
    if self.m_efNode then
        local efNode = self.m_efNode:getChildByName("LG")
        if not efNode then
            efNode = util_createAnimation("CardRes/season202202/cash_season_bottom_ef_sg.csb")
            self.m_efNode:addChild(efNode)
            efNode:setName("LG")
        end
        efNode:playAction("idle", true)
    end
end

function CardSeasonBottom:initStatue()
    if not self.m_statueUI then
        self.m_statueUI = util_createView(self:getStatueLua())
        self.m_bottomStatue:addChild(self.m_statueUI)
    end
    self.m_statueUI:updateUI()
end

return CardSeasonBottom
