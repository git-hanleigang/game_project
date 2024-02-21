--[[--
    wild卡兑换cell 中 章节标题
]]
local CardWildExcCellTitle = class("CardWildExcCellTitle", BaseView)

function CardWildExcCellTitle:getCsbName()
    return "CardRes/common" .. CardSysRuntimeMgr:getCurAlbumID() .. "/cash_wild_cell_title.csb"
end

function CardWildExcCellTitle:initCsbNodes()
    self.m_panelTouch = self:findChild("Panel_touch")
    self.m_nodeCard = self:findChild("Node_card")
end

function CardWildExcCellTitle:getViewSize()
    return self.m_panelTouch:getContentSize()
end

function CardWildExcCellTitle:initUI()
    CardWildExcCellTitle.super.initUI(self)
    self:initCard()
    self:initMask()
    self:initYes()
end

function CardWildExcCellTitle:initCard()
end

function CardWildExcCellTitle:initMask()
end

function CardWildExcCellTitle:initYes()
end

return CardWildExcCellTitle
