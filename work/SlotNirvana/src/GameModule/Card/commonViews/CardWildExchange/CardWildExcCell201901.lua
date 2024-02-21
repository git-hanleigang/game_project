local BaseCardWildExcCell = util_require("GameModule.Card.baseViews.BaseCardWildExcCell")
local CardWildExcCell201901 = class("CardWildExcCell201901", BaseCardWildExcCell)
function CardWildExcCell201901:getCsbName()
    return string.format(CardResConfig.commonRes.CardWildExcCell201902Res, "common"..CardSysRuntimeMgr:getCurAlbumID())
end

function CardWildExcCell201901:getClanLogoScale()
    return 0.3
end

return CardWildExcCell201901