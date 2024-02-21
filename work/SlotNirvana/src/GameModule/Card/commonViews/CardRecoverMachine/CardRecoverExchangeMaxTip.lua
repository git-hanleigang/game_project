
local BaseView = util_require("base.BaseView")
local CardRecoverExchangeMaxTip = class("CardRecoverExchangeMaxTip", BaseView)
function CardRecoverExchangeMaxTip:initUI()
    self:createCsbNode(string.format(CardResConfig.commonRes.CardRecoverMaxTipRes, "common"..CardSysRuntimeMgr:getCurAlbumID()))

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true, nil, 60)
    end, 60)

    self.m_maxStar = self:findChild("max_star")
    self.m_moreStar = self:findChild("more_star")
end

function CardRecoverExchangeMaxTip:reloadUI(max, cur)
    self.m_maxStar:setString(tostring(max))
    local moreStarNum = cur - max
    local endStr = " star "
    if moreStarNum > 1 then
        endStr = " stars "
    end
    self.m_moreStar:setString(moreStarNum..endStr)
end

function CardRecoverExchangeMaxTip:closeUI()
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:runCsbAction("over", false, function()
        self:removeFromParent()
    end, 60)
end


return CardRecoverExchangeMaxTip
