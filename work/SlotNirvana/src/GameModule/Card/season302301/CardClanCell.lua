local CardClanCell201903 = util_require("GameModule.Card.season201903.CardClanCell")
local CardClanCell = class("CardClanCell", CardClanCell201903)

function CardClanCell:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanCellRes, "season302301")
end

function CardClanCell:getMiniChipLua()
    return "GameModule.Card.season201903.MiniChipUnit"
end

-- 重写父类
function CardClanCell:getClanData()   
    local clansData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return clansData and clansData[self.m_index]
end

return CardClanCell
