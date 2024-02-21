-- CardResConfig.CardAlbumLinkUpRes
-- CardResConfig.CardAlbumLinkDownRes
local CardAlbumSliderLinkTip = class(CardAlbumSliderLink, util_require("base.BaseView"))
function CardAlbumSliderLinkTip:initUI(csbType)
    local csbRes = nil
    if csbType == "up" then
        csbRes = CardResConfig.CardAlbumLinkUpRes
    elseif csbType == "down" then
        csbRes = CardResConfig.CardAlbumLinkDownRes
    end
    if csbRes == nil then
        return
    end

    self:createCsbNode(csbRes)

    self:playIdle()
end
function CardAlbumSliderLinkTip:playIdle()
    self:runCsbAction("idle", true)
end
return CardAlbumSliderLinkTip
