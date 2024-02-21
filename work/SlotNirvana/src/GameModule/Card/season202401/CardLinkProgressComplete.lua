--[[
    -- link卡集齐进度面板
]]
local CardLinkProgressComplete201903 = util_require("GameModule.Card.season201903.CardLinkProgressComplete")
local CardLinkProgressComplete = class("CardLinkProgressComplete", CardLinkProgressComplete201903)

function CardLinkProgressComplete:getTotal()
    return 22
end

function CardLinkProgressComplete:getProgressMarkLua()
    return "GameModule.Card.season202401.CardLinkProgressMark"
end

function CardLinkProgressComplete:getProgressNodeLua()
    return "GameModule.Card.season202401.CardLinkProgressNode"
end

return CardLinkProgressComplete
