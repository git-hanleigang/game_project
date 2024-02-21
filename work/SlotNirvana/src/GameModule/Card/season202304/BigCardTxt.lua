local BigCardTxt201903 = util_require("GameModule.Card.season201903.BigCardTxt")
local BigCardTxt = class("BigCardTxt", BigCardTxt201903)

function BigCardTxt:getCsbName()
    return string.format(CardResConfig.seasonRes.BigCardTxtRes, "season202304")
end

return BigCardTxt
