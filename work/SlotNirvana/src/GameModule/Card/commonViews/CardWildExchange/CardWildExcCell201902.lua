local BaseCardWildExcCell = util_require("GameModule.Card.baseViews.BaseCardWildExcCell")
local CardWildExcCell201902 = class("CardWildExcCell201902", BaseCardWildExcCell)
function CardWildExcCell201902:getCsbName()
    return string.format(CardResConfig.commonRes.CardWildExcCell201902Res, "common"..CardSysRuntimeMgr:getCurAlbumID())
end

function CardWildExcCell201902:getClanLogoScale(clanType)
    if CardSysManager:getWildExcMgr():getClanTypeIndex(clanType) <= 3 then
        -- puzzle clan
        return 0.3
    else
        return 0.5
    end
end

return CardWildExcCell201902