--[[
    翻牌后是金币的界面
]]

local WheelOfRomanceShopPageCircularWheel = class("WheelOfRomanceShopPageCircularWheel", util_require("base.BaseView"))

function WheelOfRomanceShopPageCircularWheel:initUI(pageIndex, pageCellIndex,pageCellStatus)
    local resourceFilename = "WheelOfRomance_shop_item_Circular.csb"
    self:createCsbNode(resourceFilename)
    
    self:initData(pageIndex, pageCellIndex,pageCellStatus)

    
    self:runCsbAction("idle")
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end

function WheelOfRomanceShopPageCircularWheel:initData(pageIndex, pageCellIndex,pageCellStatus)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
    self.m_pageCellStatus = pageCellStatus
end

function WheelOfRomanceShopPageCircularWheel:updateUI(callBack)
   
    if callBack then
        callBack()
    end

   
end


function WheelOfRomanceShopPageCircularWheel:onEnter()
    
end

function WheelOfRomanceShopPageCircularWheel:onExit()
end

return WheelOfRomanceShopPageCircularWheel
