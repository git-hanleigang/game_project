--[[
    以往赛季
]]
local CardCollectionUI201903 = util_require("GameModule.Card.season201903.CardCollectionUI")
local CardCollectionUI = class("CardCollectionUI", CardCollectionUI201903)

function CardCollectionUI:initDatas()
    CardCollectionUI.super.initDatas(self)
    self.m_colNum = 3
    self.m_seasonSizeW, self.m_seasonSizeH = 266, 181
    self.m_cellSizeW, self.m_cellSizeH = 900, 240
    self.m_cellCount = math.ceil(#self.m_data / self.m_colNum)
    self.m_space = 25
    self.m_cellLua = "GameModule.Card.season202204.CardCollectionCell"
    self.m_bgCellLua = "GameModule.Card.season202204.CardCollectionBgCell"
end

function CardCollectionUI:initBgNode(_cell)
    local bgNode = util_createView(self.m_bgCellLua)
    _cell:addChild(bgNode)
    bgNode:setPosition(cc.p(self.m_cellSizeW / 2, self.m_cellSizeH / 2))
end

return CardCollectionUI
