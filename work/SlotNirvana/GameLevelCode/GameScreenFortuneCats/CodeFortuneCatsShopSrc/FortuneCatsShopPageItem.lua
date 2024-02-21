--
-- 九宫格 未打开
--
local FortuneCatsShopData = util_require("CodeFortuneCatsShopSrc.FortuneCatsShopData")
local FortuneCatsShopPageItem = class("FortuneCatsShopPageItem", util_require("base.BaseView"))

local TAG_NEED_MORE         =       1001

function FortuneCatsShopPageItem:initUI(pageIndex, pageCellIndex,rootView)
    local resourceFilename = "FortuneCats_shop_item_1.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
    self:runCsbAction("animationStart1")
    self.m_touch = self:findChild("touchPanel")
    self:addClick(self.m_touch)

    self.m_rootView = rootView
    self:initData(pageIndex, pageCellIndex)
    self:showCat(pageIndex)
end

function FortuneCatsShopPageItem:showCat(pageIndex)
    self:findChild("mao_hong"):setVisible(false)
    self:findChild("mao_lv"):setVisible(false)
    self:findChild("mao_lan"):setVisible(false)
    self:findChild("mao_huang"):setVisible(false)
    if pageIndex == 1 then
        self:findChild("mao_hong"):setVisible(true)
    elseif pageIndex == 2 then
        self:findChild("mao_lv"):setVisible(true)
    elseif pageIndex == 3 then
        self:findChild("mao_lan"):setVisible(true)
    elseif pageIndex == 4 then
        self:findChild("mao_huang"):setVisible(true)
    end
end

function FortuneCatsShopPageItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if FortuneCatsShopData:getFreeSpinState() == true then
        return
    end
    if name == "touchPanel" then
        -- 请求数据
        -- 数据请求回来后进行翻页动作奖励
        local re, flag = self:canClick()
        if re then
            gLobalNoticManager:postNotification("NOTIFY_SHOP_PAGE_BUY_CLICK")
            self:openAction(
                function()
                    FortuneCatsShopData:request_open(self.m_pageIndex - 1, self.m_pageCellIndex - 1)
                end
            )
        else
            if flag == "needMore" then
                if self.m_needMoreShowing == true then
                    return
                end
                self.m_needMoreShowing = true

                local needMore = self:getChildByTag(TAG_NEED_MORE)
                if not needMore then
                    needMore = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShopNeedMore")
                    self:addChild(needMore)
                    needMore:setPositionY(10)
                    needMore:setTag(TAG_NEED_MORE)
                end
                self.m_rootView:changeCloseStatus(false)
                needMore:showUI(function()
                    self:newLayer(function()
                        needMore:closeUI(function()
                            self.m_needMoreShowing = false
                            self.m_rootView:changeCloseStatus(true)
                        end)
                    end)
                end)
            end
        end
    end
end

function FortuneCatsShopPageItem:initData(pageIndex, pageCellIndex)
    self.m_pageIndex = pageIndex
    self.m_pageCellIndex = pageCellIndex
end

function FortuneCatsShopPageItem:canClick()
    if FortuneCatsShopData:getExchangeEffectState() == true then
        return false, "isPlayingAction"
    end

    if FortuneCatsShopData:getNetState() == true then
        return false, "net"
    end

    if not self.m_unlock then
        return false, "unlock"
    end

    if not self.m_more then
        if FortuneCatsShopData:getShopIsTriggerPick() then
            return true
        end
        if self.m_collectCoins < self.m_needCoin then
            return false, "needMore"
        end
    end

    if FortuneCatsShopData:getFlyData() == true then
        return false, "isFreeFlying"
    end

    return true
end

function FortuneCatsShopPageItem:updateUI(noPlayStart, callBack, firstOpen,isTriggerPick)
    self.m_collectCoins = FortuneCatsShopData:getShopCollectCoins()

    local needCoins = FortuneCatsShopData:getShopNeedCoins()
    self.m_needCoin = needCoins[self.m_pageIndex]

    self.m_unlock = FortuneCatsShopData:isPageIndexUnlock(self.m_pageIndex)

    local label = self:findChild("BitmapFontLabel_1")
    if label then
        label:setString(tostring(self.m_needCoin))
    end
    if self.m_unlock then
        if firstOpen == false and isTriggerPick == true then
            self:runCsbAction("animation0")
            return
        end

        if self.m_collectCoins < self.m_needCoin then
            -- 条件不满足 置黑
            if firstOpen then
                if isTriggerPick  then
                    self:runCsbAction("animationStart4")
                else
                    self:runCsbAction(
                        "animationStart3",
                        false,
                        function()
                            self:runCsbAction("idle_noEnough", true)
                        end
                    )
                end
            else
                if isTriggerPick  then
                    self:runCsbAction("pickIdle")
                else
                    self:runCsbAction("idle_noEnough", true)
                end
            end
        else
            if firstOpen then
                if isTriggerPick  then
                    self:runCsbAction("animationStart4")
                else
                    self:runCsbAction(
                        "animationStart1",
                        false,
                        function()
                            self:runCsbAction("idle_enough", true)
                        end
                    )
                end
            else
                if isTriggerPick  then
                    self:runCsbAction("pickIdle", true)
                else
                    self:runCsbAction("idle_enough", true)
                end
            end
        end
    else
        -- 未解锁状态
        if firstOpen then
            self:runCsbAction(
                "animationStart2",
                false,
                function()
                    self:runCsbAction("idle_unLock", true)
                end
            )
        else
            self:runCsbAction("idle_unLock", true)
        end
    end
end

-- 先播动作再从父类中移除
function FortuneCatsShopPageItem:openAction(callback)
    FortuneCatsShopData:setExchangeEffectState(true)
    local clickName = "animation2"
    if FortuneCatsShopData:getShopIsTriggerPick() then
        clickName = "animation3"
    end
    self:runCsbAction(
        clickName,
        false,
        function()
            self:runCsbAction(
                "click_enough2",
                false,
                function()
                    self:runCsbAction("click_enough2", true)
                    if callback then
                        callback()
                    end
                end
            )
        end
    )
end

function FortuneCatsShopPageItem:newLayer(closeFunc)
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

function FortuneCatsShopPageItem:playSuccessBuyAction(callFunc)
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

return FortuneCatsShopPageItem
