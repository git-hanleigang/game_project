--
-- 九宫格 未打开
--

local WheelOfRomanceShopPageItemDark = class("WheelOfRomanceShopPageItemDark", util_require("base.BaseView"))

function WheelOfRomanceShopPageItemDark:initUI(pageIndex, pageCellIndex,pageCellStatus)
    local resourceFilename = "WheelOfRomance_shop_item_dark.csb"
    self:createCsbNode(resourceFilename)

    self:initData(pageIndex, pageCellIndex,pageCellStatus)
    
    self:runCsbAction("idle")
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

    
    self:addClick(self:findChild("click"))

end


function WheelOfRomanceShopPageItemDark:initData(pageIndex, pageCellIndex,pageCellStatus)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
    self.m_pageCellStatus = pageCellStatus
end


function WheelOfRomanceShopPageItemDark:updateUI(callBack)

    local needPoins = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getPageNeedPoints( self.m_pageIndex )

    local label = self:findChild("m_lb_coins")
    if label then
        label:setString(util_formatCoins(needPoins,4) )
    end

    if callBack then
        callBack()
    end

end


function WheelOfRomanceShopPageItemDark:canClick()
    if globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getExchangeEffectState() == true then
        return false, "isPlayingAction"
    end

    if globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getNetState() == true then
        return false, "net"
    end

    if globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getEnterFlag() == false then
        return false, "startAni"
    end
    
    return true
end

function WheelOfRomanceShopPageItemDark:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then

        if self:canClick() then
            gLobalNoticManager:postNotification("WheelOfRomance_LockItem_Click", {self})
        end 
        
    end
end

return WheelOfRomanceShopPageItemDark
