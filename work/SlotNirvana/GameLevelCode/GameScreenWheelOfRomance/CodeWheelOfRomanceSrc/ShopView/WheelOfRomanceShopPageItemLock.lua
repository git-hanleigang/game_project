--
-- 九宫格 未打开
--

local WheelOfRomanceShopPageItemLock = class("WheelOfRomanceShopPageItemLock", util_require("base.BaseView"))

function WheelOfRomanceShopPageItemLock:initUI(pageIndex, pageCellIndex,pageCellStatus)
    local resourceFilename = "WheelOfRomance_shop_item_lock.csb"
    self:createCsbNode(resourceFilename)

    self:initData(pageIndex, pageCellIndex,pageCellStatus)

    self:runCsbAction("idle")
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

end


function WheelOfRomanceShopPageItemLock:initData(pageIndex, pageCellIndex,pageCellStatus)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
    self.m_pageCellStatus = pageCellStatus
end


function WheelOfRomanceShopPageItemLock:updateUI(callBack)

    local needPoins = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getPageNeedPoints( self.m_pageIndex )

    local label = self:findChild("m_lb_coins")
    if label then
        label:setString(util_formatCoins(needPoins,4) )
    end

    if callBack then
        callBack()
    end

end



return WheelOfRomanceShopPageItemLock
