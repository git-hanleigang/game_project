--[[
    翻牌后是金币的界面
]]

local WheelOfRomanceShopPageCoin = class("WheelOfRomanceShopPageCoin", util_require("base.BaseView"))

function WheelOfRomanceShopPageCoin:initUI(pageIndex, pageCellIndex,pageCellStatus)
    local resourceFilename = "WheelOfRomance_shop_item_Portrait.csb"
    self:createCsbNode(resourceFilename)
    
    self:initData(pageIndex, pageCellIndex,pageCellStatus)

    self:runCsbAction("idle")
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end

function WheelOfRomanceShopPageCoin:initData(pageIndex, pageCellIndex,pageCellStatus)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
    self.m_pageCellStatus = pageCellStatus
end

function WheelOfRomanceShopPageCoin:updateUI( callBack)
   
    if callBack then
        callBack()
    end
         
end


function WheelOfRomanceShopPageCoin:onEnter()
end

function WheelOfRomanceShopPageCoin:onExit()
end

return WheelOfRomanceShopPageCoin
