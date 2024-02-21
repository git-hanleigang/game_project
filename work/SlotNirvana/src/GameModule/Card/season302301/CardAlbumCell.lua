local CardAlbumCell201903 = util_require("GameModule.Card.season201903.CardAlbumCell")
local CardAlbumCell = class("CardAlbumCell", CardAlbumCell201903)

function CardAlbumCell:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumCellRes, "season302301")
end

function CardAlbumCell:getGuideNode()
    return self.m_nodeBase
end

return CardAlbumCell
