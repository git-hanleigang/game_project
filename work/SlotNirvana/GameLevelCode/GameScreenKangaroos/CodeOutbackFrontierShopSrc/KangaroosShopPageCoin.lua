--[[
    翻牌后是金币的界面
]]

local KangaroosShopData = util_require("CodeOutbackFrontierShopSrc.KangaroosShopData")
local KangaroosShopPageCoin = class("KangaroosShopPageCoin", util_require("base.BaseView"))

function KangaroosShopPageCoin:initUI(pageIndex, pageCellIndex)
    local resourceFilename = "OutbackFrontierShop/Socre_Kangaroos_fanzhuan.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

    self.m_coinLabel = self:findChild("BitmapFontLabel_1")
    self:initData(pageIndex, pageCellIndex)
    -- self:runCsbAction('idle', true)
end

function KangaroosShopPageCoin:initData(pageIndex, pageCellIndex)
    self.m_pageIndex    = pageIndex
    self.m_pageCellIndex= pageCellIndex
    local mores         = KangaroosShopData:getShopFreeMore()
    self.m_more         = mores[self.m_pageIndex]    
end

function KangaroosShopPageCoin:updateUI(noPlayStart, free, half, callBack)
    if noPlayStart then
        if callBack then
            callBack()
        end        
        self:runCsbAction("idle", true)
    else
        self:runCsbAction("start", false, function( )
            if callBack then
                callBack()
            end
            self:runCsbAction("idle", true)
        end)
    end

    local items         = KangaroosShopData:getShopPageInfo()
    local coin          = items[self.m_pageIndex][self.m_pageCellIndex]
    if free then
        local sData = KangaroosShopData:getShopData()
        coin = sData.selectResult
    end
    if half then
        coin = coin*0.5
    end
    self.m_coinLabel:setString(util_formatCoins(tonumber(coin), 3, nil, nil, true))
end

function KangaroosShopPageCoin:changeDouble()
    local items         = KangaroosShopData:getShopPageInfo()
    local coin          = items[self.m_pageIndex][self.m_pageCellIndex]    
    self.m_coinLabel:setString(util_formatCoins(tonumber(coin), 3))
end

function KangaroosShopPageCoin:onEnter()

end

function KangaroosShopPageCoin:onExit()

end


return KangaroosShopPageCoin
