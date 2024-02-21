--[[
    author:{author}
    time:2019-07-16 14:35:39
]]
local BigCardLayer201903 = util_require("GameModule.Card.season201903.BigCardLayer")
local BigCardLayer = class("BigCardLayer", BigCardLayer201903)

function BigCardLayer:getCsbName()
    return string.format(CardResConfig.seasonRes.BigCardLayerRes, "season202203")
end

function BigCardLayer:getMiniChipLua()
    return "GameModule.Card.season201903.MiniChipUnit"
end

function BigCardLayer:getBigCardTextLua()
    return "GameModule.Card.season202203.BigCardTxt"
end

return BigCardLayer
