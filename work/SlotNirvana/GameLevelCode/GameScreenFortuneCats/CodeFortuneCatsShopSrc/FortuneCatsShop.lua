-- 需求：
-- 1 页数随便翻，收尾不相连
-- 2 解锁条件是上一页都兑换完全才解锁
-- 3 数量不足需要置黑

local FortuneCatsShopData = util_require("CodeFortuneCatsShopSrc.FortuneCatsShopData")
local FortuneCatsShop = class("FortuneCatsShop", util_require("base.BaseView"))

local FortuneCats_SHOP_BG_MUSIC = "FortuneCatsSounds/sound_FortuneCats_shop_bgm.mp3" -- 袋鼠商店中背景音乐
FortuneCatsShop.m_buyClickMusicId = nil
FortuneCatsShop.m_buyLoopMusicId = nil -- 点击购买时请求数据播放的循环音乐
FortuneCatsShop.m_buyOverMusicId = nil


function FortuneCatsShop:initUI()
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self.b_showTips = false 
    local resourceFilename="FortuneCats/FortuneCatsShop.csb"
    self:createCsbNode(resourceFilename, isAutoScale)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

    self.m_isCanClose = true

    self.m_countLabel   = self:findChild("m_lb_coins")
    self.m_pageNode     = self:findChild("Node_page")
    self.btn_left       = self:findChild("Button_zuo")
    self.btn_right      = self:findChild("Button_you")
    self.m_pageTouch    = self:findChild("pageTouch")
    self:addClick(self.m_pageTouch)
    self.m_pageTouch:setSwallowTouches(false)
    local catNode  = self:findChild("FortuneCats_mao")
    self.m_cat = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShopCat")
    
    catNode:addChild(self.m_cat)
    
    self:runCsbAction("start")

    self.m_pageCells    = {}
    self.m_isMoved      = false
    self.m_curPageIndex = FortuneCatsShopData:getDefaultPageIndex() -- 定位页数
    self.m_cat:changeCatByIndex(self.m_curPageIndex)
    self.m_pageNum      = FortuneCatsShopData:getShopPageNum() -- 页数

    FortuneCatsShopData:setEnterFlag(false)
    self:initTag()
    self:updateUI(true,true)
    self:showPageTitle(self.m_curPageIndex)
end

function FortuneCatsShop:setMachine(machine)
    self.m_Machine = machine
end

function FortuneCatsShop:showPageTitle(Index)
    self:findChild("zi_1"):setVisible(false)
    self:findChild("zi_2"):setVisible(false)
    self:findChild("zi_3"):setVisible(false)
    self:findChild("zi_4"):setVisible(false)
    if Index == 4 then
        self:findChild("zi_1"):setVisible(true)
    elseif Index == 3 then
        self:findChild("zi_2"):setVisible(true)
    elseif Index == 2 then
        self:findChild("zi_3"):setVisible(true)
    elseif Index == 1 then
        self:findChild("zi_4"):setVisible(true)
    end
end

function FortuneCatsShop:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateCount()
        local afterUpdate = false
        if params.exchange then
            afterUpdate = true
        end
        self:updateCurPageInfo(true, afterUpdate)
    end,"NOTIFY_SHOP_PAGE")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:playBuySound()
        self:removeTips()
    end,"NOTIFY_SHOP_PAGE_BUY_CLICK")

    gLobalNoticManager:addObserver(self,function(self,params)
        -- 购买请求数据返回后处理声音
        self:palyBuySuccessSound()
    end,"NOTIFY_SHOP_PAGE_BUY_SUCCESS")

    gLobalNoticManager:addObserver(self,function(self,params)
        if params == "start" then
            self:closeUI(true)
        elseif params == "over" then
            if self.isClose then
                local view = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShop")
                if globalData.slotRunData.machineData.p_portraitFlag then
                    view.getRotateBackScaleFlag = function(  ) return false end
                end
                gLobalViewManager:showUI(view)
            end
        end
    end,"NOTIFY_SHOP_FREE_SPIN")

    gLobalNoticManager:addObserver(self,function(self,params)
        self.m_cat:playOpenCatEffect(function ()
            gLobalNoticManager:postNotification("NOTIFY_SHOP_FREE_SPIN", "start")
        end)
    end,"NOTIFY_OPEN_SHOP_CAT")

    FortuneCatsShopData:setEnterShopView(true)
    self.m_musicId = gLobalSoundManager:playSound(FortuneCats_SHOP_BG_MUSIC, true)
end

function FortuneCatsShop:onExit()
    local eventDispatcher = self.m_pageTouch:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self.m_pageTouch, true)
    gLobalNoticManager:removeAllObservers(self)

    self:clearBuyMusic()
end

function FortuneCatsShop:closeUI(_bfree)
    if self.isClose then
        return
    end
    self:findChild("Button_guanbi"):setTouchEnabled(false)
    if self.m_musicId then
        gLobalSoundManager:stopAudio(self.m_musicId)
    end
    -- -- 刷新一下兑换币
    gLobalNoticManager:postNotification("NOTIFY_SHOP_UPDATE_COINS", {})
    self.isClose = true
    self.isOpen = false
    self:runCsbAction("over", false, function()
        FortuneCatsShopData:setEnterShopView(false)
        if self.m_func then
            self.m_func()
        end
        if _bfree == false then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
        self:removeFromParent()
    end)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
end

function FortuneCatsShop:initTag()
    
    self.m_points = {}
    for i=1,self.m_pageNum do
        local csb = util_createAnimation("FortuneCats_shop_yema.csb")
        csb:playAction("idle1", false)
        local point = self:findChild("fanye_" .. i)
        point:addChild(csb)
        self.m_points[#self.m_points+1] = csb
    end
end

function FortuneCatsShop:updateUI(isInit,firstOpen)
    self:updateCount()
    self:updateTitle()
    self:updateTag()
    self:updateBtn()
    self:updateCurPageInfo(isInit,false,firstOpen)
end

function FortuneCatsShop:updateCount()
    local m_num = FortuneCatsShopData:getShopCollectCoins()
    self.m_countLabel:setString(util_formatCoins(m_num, 50))
    self:updateLabelSize({label = self.m_countLabel, sx = 0.39, sy = 0.39}, 420)
end

function FortuneCatsShop:updateTag()
    for i=1,#self.m_points do
        if i == self.m_curPageIndex then
            self.m_points[i]:playAction("idle2", false)
        else
            self.m_points[i]:playAction("idle", false)
        end 
    end
end

function FortuneCatsShop:updateBtn()
    self.btn_left:setVisible(self.m_curPageIndex>1)
    self.btn_right:setVisible(self.m_curPageIndex<self.m_pageNum)
end

-- 顶部UI切换 -- 
function FortuneCatsShop:updateTitle(isInit)
    self:showPageTitle(self.m_curPageIndex)
    self.m_cat:changeCatByIndex(self.m_curPageIndex)
end

-- noPlayStart:是否播放start动画的标记
-- afterUpdateUI:兑换请求后要先播放动作再刷新UI
function FortuneCatsShop:updateCurPageInfo(noPlayStart, afterUpdateUI,firstOpen)
    if self.m_pageCells[self.m_curPageIndex] == nil then
        self.m_pageCells[self.m_curPageIndex] = self:initCell()
    end
    
    local callF = false
    if afterUpdateUI then
        callF = true
    end
    
    -- 需要先播放UI动效，然后再整体刷新UI
    if callF then
        local callFunc = function()
            self.m_pageCells[self.m_curPageIndex]:updateUI(noPlayStart)
        end
        self.m_pageCells[self.m_curPageIndex]:playPageUIAction(noPlayStart, callFunc)
    else 
        self.m_pageCells[self.m_curPageIndex]:updateUI(noPlayStart,firstOpen)
    end
end

function FortuneCatsShop:initCell()
    local view = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShopPage", {rootView = self,pageIndex = self.m_curPageIndex} )
    self.m_pageNode:addChild(view, -1)
    return view
end

-- 翻页 --
function FortuneCatsShop:moveNodeCells(direction)
    self.m_isMoved = true

    self:updateCurPageInfo(true)
    self.m_pageCells[self.m_curPageIndex]:setPosition(display.width * direction, 0)

    local moveTo1 = cc.MoveTo:create(0.4,cc.p(display.width * -direction, 0))
    local callfunc = cc.CallFunc:create(function()
        self.m_isMoved = false
        self.m_prePageCell:setVisible(false)
    end)

    local seq = cc.Sequence:create(moveTo1, callfunc)
    self.m_prePageCell:runAction(seq)

    self.m_pageCells[self.m_curPageIndex]:setVisible(true)

    local moveTo2 = cc.MoveTo:create(0.4,cc.p(0, 0))
    self.m_pageCells[self.m_curPageIndex]:runAction(moveTo2)
end

function FortuneCatsShop:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "Button_guanbi" then
        if not self.m_isCanClose then
            return
        end
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_close.mp3")
        self:closeUI(false)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    elseif name == "Button_zuo" then
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_click_page.mp3")
        self:clickLast()
        self:removeTips()
    elseif name == "Button_you" then
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_click_page.mp3")
        self:clickNext()
        self:removeTips()
    elseif name == "Button_5" then
        if self.m_tips then
            self:removeTips()
        else
            self:initTips()
            self.b_showTips = true
        end
        
    end
end

function FortuneCatsShop:canClick()
    if FortuneCatsShopData:getFlyData() == true then
        return false, "isFreeFlying"
    end
        
    if FortuneCatsShopData:getFreeSpinState() == true then
        return false, "isFreeSpining"
    end 

    if FortuneCatsShopData:getExchangeEffectState() == true then
        return false, "isPlayingAction"
    end

    if FortuneCatsShopData:getNetState() == true then
        return false, "net"
    end
    if self.m_isMoved == true then
        return false, "pageMoving"
    end
    if self.isClose then
        return false, "isClosed"
    end    
    return true
end

function FortuneCatsShop:clickLast()
    if not self:canClick() then
        return
    end
    if self.m_curPageIndex <= 1 then
        return
    end
    self.m_prePageCell = self.m_pageCells[self.m_curPageIndex]
    self.m_curPageIndex = self.m_curPageIndex - 1
    self:updateTitle()
    self:updateTag()
    self:updateBtn()    
    self:moveNodeCells(-1)
end

function FortuneCatsShop:clickNext()
    if not self:canClick() then
        return
    end
    if self.m_curPageIndex >= self.m_pageNum then
        return
    end
    self.m_prePageCell = self.m_pageCells[self.m_curPageIndex]
    self.m_curPageIndex = self.m_curPageIndex + 1
    self:updateTitle()
    self:updateTag()
    self:updateBtn()    
    self:moveNodeCells(1)
end

function FortuneCatsShop:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if self.m_isMoved == true then
            return
        end
    elseif eventType == ccui.TouchEventType.moved then
        -- self.m_isMoved = true
    elseif eventType == ccui.TouchEventType.ended then
        -- self.m_isMoved = false
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = endPos.x-beginPos.x
        if math.abs(offx)<50 then
            self:clickFunc(sender)
        else
            if offx < 0 then
                self:clickNext()
            else
                self:clickLast()
            end
        end
    -- elseif eventType == ccui.TouchEventType.canceled then
    --     -- self.m_isMoved = false
    end
end

-- 购买请求接受后，播放声音
function FortuneCatsShop:palyBuySuccessSound()
    if self.m_buyClickMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_buyClickMusicId)
        self.m_buyClickMusicId = nil
    end
    if self.m_buyLoopMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_buyLoopMusicId)
        self.m_buyLoopMusicId = nil
    end    
    -- self.m_buyOverMusicId = gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_buy_over.mp3")    
end

-- 购买点击时处理声音
function FortuneCatsShop:playBuySound()    
    self.m_buyClickMusicId = gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_click_open.mp3")
    performWithDelay(self, function()
        -- self.m_buyLoopMusicId = gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_buy_loop.mp3", true)
    end, 0.5)
end

-- 关闭界面时关闭所有声音
function FortuneCatsShop:clearBuyMusic()
    if self.m_buyClickMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_buyClickMusicId)
        self.m_buyClickMusicId = nil
    end
    if self.m_buyLoopMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_buyLoopMusicId)
        self.m_buyLoopMusicId = nil
    end
    if self.m_buyOverMusicId ~= nil     then
        gLobalSoundManager:stopAudio(self.m_buyOverMusicId)
        self.m_buyOverMusicId = nil
    end    
end

function FortuneCatsShop:initTips()
    local node_bar = self:findChild("tipsNode")
    self.m_tips = util_createView("CodeFortuneCatsSrc.FortuneCatsTips", 1)
    node_bar:addChild(self.m_tips)
end

function FortuneCatsShop:removeTips()
    if  self.b_showTips == false then
        return
    end
    self.b_showTips  = false
    if self.m_tips then
        self.m_tips:playOver(
            function()
                self.m_tips:removeFromParent()
                self.m_tips = nil
            end
        )
    end
end

function FortuneCatsShop:setCloseShopCallFun(fun)
    self.m_func = function (  )
        if fun then
            fun()
        end
    end
end

function FortuneCatsShop:changeCloseStatus(canClose)
    self.m_isCanClose = canClose
end
return FortuneCatsShop