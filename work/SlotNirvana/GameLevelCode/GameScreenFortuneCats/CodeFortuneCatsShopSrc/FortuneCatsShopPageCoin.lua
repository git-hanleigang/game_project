--[[
    翻牌后是金币的界面
]]
local FortuneCatsShopData = util_require("CodeFortuneCatsShopSrc.FortuneCatsShopData")
local FortuneCatsShopPageCoin = class("FortuneCatsShopPageCoin", util_require("base.BaseView"))

function FortuneCatsShopPageCoin:initUI(pageIndex, pageCellIndex)
    local resourceFilename = "FortuneCats_shop_item_2.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

    self.m_coinLabel = self:findChild("BitmapFontLabel_1")
    self:initData(pageIndex, pageCellIndex)
end

function FortuneCatsShopPageCoin:initData(pageIndex, pageCellIndex)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
end

function FortuneCatsShopPageCoin:updateUI(noPlayStart, callBack, firstOpen)
    local items = FortuneCatsShopData:getShopPageInfo()
    local coin = items[self.m_pageIndex][self.m_pageCellIndex][2]
    if noPlayStart == false then
        if FortuneCatsShopData:IsClickPick2() then
            coin = coin / 2
        end
    end
    local _type = items[self.m_pageIndex][self.m_pageCellIndex][3]
    if _type == 0 then
        self:findChild("2x"):setVisible(false)
        self.m_coinLabel:setString(util_formatCoins(tonumber(coin), 3, nil, nil, true))
    else
        self:findChild("shuzi"):setVisible(false)
    end
    if noPlayStart then
        if callBack then
            callBack()
        end
        if firstOpen then
            self:runCsbAction(
                "animationStart",
                false,
                function()
                    self:runCsbAction("idle", true)
                end
            )
        else
            self:runCsbAction("idle", true)
        end
    else
        local openName = "animation1"
        if FortuneCatsShopData:IsClickPick2() then
            openName = "animation0"
        end
        self:runCsbAction(
            openName,
            false,
            function()
                if callBack then
                    callBack()
                end
                if FortuneCatsShopData:IsClickPick2() then
                    local coin = items[self.m_pageIndex][self.m_pageCellIndex][2]
                    self.m_coinLabel:setString(util_formatCoins(tonumber(coin), 3, nil, nil, true))
                end
                self:runCsbAction("idle", true)
            end
        )
    end


   
end

function FortuneCatsShopPageCoin:changeDouble()
    local items = FortuneCatsShopData:getShopPageInfo()
    local coin = items[self.m_pageIndex][self.m_pageCellIndex]
    self.m_coinLabel:setString(util_formatCoins(tonumber(coin), 3))
end

function FortuneCatsShopPageCoin:onEnter()
end

function FortuneCatsShopPageCoin:onExit()
end

return FortuneCatsShopPageCoin
