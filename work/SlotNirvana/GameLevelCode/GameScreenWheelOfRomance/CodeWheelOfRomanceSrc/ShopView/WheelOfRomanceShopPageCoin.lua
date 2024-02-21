--[[
    翻牌后是金币的界面
]]

local WheelOfRomanceShopPageCoin = class("WheelOfRomanceShopPageCoin", util_require("base.BaseView"))

function WheelOfRomanceShopPageCoin:initUI(pageIndex, pageCellIndex,pageCellStatus)
    local resourceFilename = "WheelOfRomance_shop_item_coins.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
    self:runCsbAction("idle")
    
    self.m_coinLabel = self:findChild("m_lb_coins")
    self:initData(pageIndex, pageCellIndex,pageCellStatus)
end

function WheelOfRomanceShopPageCoin:initData(pageIndex, pageCellIndex,pageCellStatus)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
    self.m_pageCellStatus = pageCellStatus -- 实际上是钱数
end

function WheelOfRomanceShopPageCoin:updateUI(callBack)

    local coin = self.m_pageCellStatus
    self.m_coinLabel:setString(util_formatCoins(tonumber(coin), 3, nil, nil, true))

    if callBack then
        callBack()
    end     

end

function WheelOfRomanceShopPageCoin:onEnter()
end

function WheelOfRomanceShopPageCoin:onExit()
end

return WheelOfRomanceShopPageCoin
