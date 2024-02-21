--
-- 九宫格 未打开
--

local WheelOfRomanceShopPageItemIdle = class("WheelOfRomanceShopPageItemIdle", util_require("base.BaseView"))

function WheelOfRomanceShopPageItemIdle:initUI(pageIndex, pageCellIndex,pageCellStatus)
    local resourceFilename = "WheelOfRomance_shop_item_idle.csb"
    self:createCsbNode(resourceFilename)

    self.m_touch = self:findChild("touchPanel")
    self:addClick(self.m_touch)

    self:initData(pageIndex, pageCellIndex,pageCellStatus)
    
    self:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
    

end


function WheelOfRomanceShopPageItemIdle:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "touchPanel" then
        -- 请求数据
        -- 数据请求回来后进行翻页动作奖励
        if self:canClick() then
            globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:request_open(self.m_pageIndex , self.m_pageCellIndex )
        end 
        
    end
end

function WheelOfRomanceShopPageItemIdle:initData(pageIndex, pageCellIndex,pageCellStatus)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
    self.m_pageCellStatus = pageCellStatus
end

function WheelOfRomanceShopPageItemIdle:canClick()
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

function WheelOfRomanceShopPageItemIdle:updateUI(_needPoins)

    local label = self:findChild("m_lb_coins")
    if label then
        label:setString(util_formatCoins(_needPoins,4) )
    end

end



function WheelOfRomanceShopPageItemIdle:newLayer(closeFunc)
    local layer = cc.Layer:create()
    layer:setContentSize(cc.size(display.width, display.height))
    layer:setOpacity(0)
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(cc.p(display.width * 0.5, display.height * 0.5))
    layer:setTouchEnabled(true)
    local isCloseTips = false
    layer:onTouch(
        function(event)
            if isCloseTips then
                return true
            end
            if event.name ~= "ended" then
                return true
            end
            isCloseTips = true
            if layer then
                layer:removeFromParent()
                layer = nil
            end
            if closeFunc then
                closeFunc()
                closeFunc = nil
            end
            return true
        end,
        false,
        true
    )
    gLobalViewManager.p_ViewLayer:addChild(layer, ViewZorder.ZORDER_SPECIAL)
end

function WheelOfRomanceShopPageItemIdle:playSuccessBuyAction(callFunc)
    self:runCsbAction(
        "animation2over",
        false,
        function()
            if callFunc then
                callFunc()
            end
        end
    )
end

return WheelOfRomanceShopPageItemIdle
