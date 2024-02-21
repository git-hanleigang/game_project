local BaseView = util_require("base.BaseView")
local CardClanTitleLight = class("CardClanTitleLight", BaseView)

function CardClanTitleLight:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanTitleLightRes, "season201903")
end

function CardClanTitleLight:initUI()
    self:createCsbNode(self:getCsbName())

    self:runCsbAction("animation0", true)
end
return CardClanTitleLight
