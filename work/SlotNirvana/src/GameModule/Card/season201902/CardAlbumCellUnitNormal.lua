--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local CardAlbumCellUnitBase = util_require("GameModule.Card.baseViews.CardAlbumCellUnitBase")
local CardAlbumCellUnitNormal = class("CardAlbumCellUnitNormal", CardAlbumCellUnitBase)

-- 初始化UI --
function CardAlbumCellUnitNormal:initUI()
    CardAlbumCellUnitBase.initUI(self)
end

function CardAlbumCellUnitNormal:initNode()
    CardAlbumCellUnitBase.initNode(self)
    self.m_link          = self:findChild("link")
    self.m_cardWild      = self:findChild("card_wild")

    --link卡 abtest
    if self.m_link then
        --util_changeTexture(self.m_link,CardResConfig.getLinkCardTarget())
        util_linkTipAction(self.m_link)
    end
end

-- 子类重写
function CardAlbumCellUnitNormal:getAlbumCellUnitRes()
    return CardResConfig.CardAlbumCell2020NormalUnitRes
end

function CardAlbumCellUnitNormal:updateCell(clanIndex, cellData)
    CardAlbumCellUnitBase.updateCell(self, clanIndex, cellData)

    local count = CardSysRuntimeMgr:getClanCardTypeCount(self.m_cellData.cards)
    -- 章节卡牌集齐标识，如果本章节的卡牌已经集齐，则需要添加集齐标识
    self.m_cardCompleted:setVisible(count >= #self.m_cellData.cards)
    -- ACE标识，有未使用的ACE卡时，需要在章节logo上添加ACE标识
    local unUse = CardSysRuntimeMgr:haveUnuseLinkCard(self.m_cellData.cards)
    self.m_link:setVisible(unUse)

    -- wild标识，如果本章节会产出wild卡，则需要在此章节logo上添加WILD标识
    -- self.m_cardWild:setVisible(self.m_cellData.wild)
    self.m_cardWild:setVisible(false)
end

return CardAlbumCellUnitNormal