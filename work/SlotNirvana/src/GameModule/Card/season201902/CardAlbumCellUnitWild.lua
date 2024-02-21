--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local CardAlbumCellUnitBase = util_require("GameModule.Card.baseViews.CardAlbumCellUnitBase")
local CardAlbumCellUnitWild = class("CardAlbumCellUnitWild", CardAlbumCellUnitBase)

-- 初始化UI --
function CardAlbumCellUnitWild:initUI()
    CardAlbumCellUnitBase.initUI(self)
end

function CardAlbumCellUnitWild:initNode()
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
function CardAlbumCellUnitWild:getAlbumCellUnitRes()
    return CardResConfig.CardAlbumCell2020WildUnitRes
end

function CardAlbumCellUnitWild:updateCell(clanIndex, cellData)
    CardAlbumCellUnitBase.updateCell(self, clanIndex, cellData)
    self:initIdle()
end

function CardAlbumCellUnitWild:initIdle()
    self:runCsbAction("idle", true)
end

return CardAlbumCellUnitWild