--
-- 袋鼠九宫格 未打开
--
local KangaroosShopData = util_require("CodeOutbackFrontierShopSrc.KangaroosShopData")
local KangaroosShopPageunOpen = class("KangaroosShopPageunOpen", util_require("base.BaseView"))

local TAG_NEED_MORE         =       1001

function KangaroosShopPageunOpen:initUI(pageIndex, pageCellIndex)

    local resourceFilename = "OutbackFrontierShop/Socre_Kangaroos_unopen.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

    self.m_touch = self:findChild("touch")
    self:addClick(self.m_touch)

    self:initData(pageIndex, pageCellIndex)
end


function KangaroosShopPageunOpen:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if KangaroosShopData:getFreeSpinState() == true then
        return
    end
    if name == "touch" then
        -- 请求数据
        -- 数据请求回来后进行翻页动作奖励
        local re, flag = self:canClick()
        if re then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_PAGE_BUY_CLICK)
            self:openAction(function()
                KangaroosShopData:request_open(self.m_pageIndex-1, self.m_pageCellIndex-1)
            end)
        else
            if flag == 'needMore' then
                if self.m_needMoreShowing == true then
                    return
                end
                self.m_needMoreShowing = true
                local needMore = self:getChildByTag(TAG_NEED_MORE)
                if not needMore then
                    needMore = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopNeedMore")
                    self:addChild(needMore)
                    needMore:setPositionY(10)
                    needMore:setTag(TAG_NEED_MORE)
                end
                needMore:showUI()
                
                self:newLayer(function()
                    if not tolua.isnull(needMore) and needMore:isVisible() then
                        needMore:closeUI(function()
                            self.m_needMoreShowing = false
                        end)
                    end
                end)
            end
        end
    end
end

function KangaroosShopPageunOpen:initData(pageIndex, pageCellIndex)
    self.m_pageIndex    = pageIndex
    self.m_pageCellIndex= pageCellIndex
end

function KangaroosShopPageunOpen:canClick( )
    if KangaroosShopData:getExchangeEffectState() == true then
        return false, "isPlayingAction"
    end

    if KangaroosShopData:getNetState() == true then
        return false, "net"
    end

    if not self.m_unlock then
        return false, "unlock"
    end

    if not self.m_more then
        if self.m_collectCoins < self.m_needCoin then
            return false, "needMore"
        end
    end

    if KangaroosShopData:getFlyData() == true then
        return false, "isFreeFlying"
    end

    if KangaroosShopData:getExCloseState() == true then
        return false, "isOverAni"
    end
    
    return true
end

function KangaroosShopPageunOpen:updateUI(noPlayStart)
    self.m_collectCoins = KangaroosShopData:getShopCollectCoins()

    local needCoins     = KangaroosShopData:getShopNeedCoins()
    self.m_needCoin     = needCoins[self.m_pageIndex]

    self.m_unlock       = KangaroosShopData:isPageIndexUnlock(self.m_pageIndex)
    
    local mores         = KangaroosShopData:getShopFreeMore()
    self.m_more         = mores[self.m_pageIndex]
    
    local label = self:findChild("BitmapFontLabel_1")
    label:setString(tostring(self.m_needCoin))

    if self.m_unlock then
        -- 兑换
        if self.m_more then
            if noPlayStart == true then
                self:runCsbAction("toFree", false, function()
                    self:runCsbAction("idle_free")
                end)
            else
                self:runCsbAction("idle_free")
            end        
        else
            if self.m_collectCoins < self.m_needCoin then
                -- 条件不满足 置黑
                self:runCsbAction("idle_noEnough", true)
            else
                self:runCsbAction("idle_enough", true)
            end
        end
    else
        -- 未解锁状态
        self:runCsbAction("idle_unLock", true)
    end
end

-- 先播动作再从父类中移除
function KangaroosShopPageunOpen:openAction(callback)
    KangaroosShopData:setExchangeEffectState(true)
    if self.m_more then
        self:runCsbAction("click_free", false, function()
            self:runCsbAction("click_free2", true)
            if callback then
                callback()
            end
        end)
    else
        self:runCsbAction("click_enough1", false, function()
            self:runCsbAction("click_enough2", false, function()
                self:runCsbAction("click_enough2", true)
                if callback then
                    callback()
                end
            end)
        end)
    end
end

function KangaroosShopPageunOpen:newLayer(closeFunc)
    local layer = cc.Layer:create()
    layer:setContentSize(cc.size(display.width, display.height))
    layer:setOpacity(0)
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(cc.p(display.width * 0.5, display.height * 0.5))
    layer:setTouchEnabled(true)
    -- layer:setSwallowTouches(false)   
    local isCloseTips = false
    layer:onTouch(function(event)
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
            closeFunc= nil 
        end
        return true 
    end, false, true)
    gLobalViewManager.p_ViewLayer:addChild(layer,ViewZorder.ZORDER_SPECIAL)    
end

function KangaroosShopPageunOpen:playSuccessBuyAction(callFunc)
    local act1 = cc.EaseIn:create(cc.ScaleTo:create(1.2, 0.2), 0.2)
    local act2 = cc.ScaleTo:create(0.01, 0.4)
    -- local act3 = cc.CallFunc:create(callFunc)
    -- local act2 = cc.Spawn:create(cc.CallFunc:create(callFunc), small)
    local seq = cc.Sequence:create(act1, act2)
    self:runAction(seq)
    performWithDelay(self, function()
        if callFunc then
            callFunc()
        end
    end, 0.4)
end

return KangaroosShopPageunOpen