--[[
]]
local CardClanCellGuide = class("CardClanCellGuide", BaseView)

function CardClanCellGuide:getCsbName()
    return "CardRes/season202303/cash_album_guide_2.csb"
end

function CardClanCellGuide:initCsbNodes()
    self.m_nodeGuideLeft = self:findChild("node_guide_left")
    self.m_nodeGuideRight = self:findChild("node_guide_right")
end

function CardClanCellGuide:updateGuidePosition(_isShowRight)
    if _isShowRight == true then
        self.m_nodeGuideRight:setVisible(true)
        self.m_nodeGuideLeft:setVisible(false)
    else
        self.m_nodeGuideLeft:setVisible(true)
        self.m_nodeGuideRight:setVisible(false)
    end
end

return CardClanCellGuide