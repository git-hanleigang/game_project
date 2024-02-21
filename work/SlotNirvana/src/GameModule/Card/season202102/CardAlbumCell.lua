local CardAlbumCell201903 = util_require("GameModule.Card.season201903.CardAlbumCell")
local CardAlbumCell = class("CardAlbumCell", CardAlbumCell201903)

function CardAlbumCell:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumCellRes, "season202102")
end

return CardAlbumCell
