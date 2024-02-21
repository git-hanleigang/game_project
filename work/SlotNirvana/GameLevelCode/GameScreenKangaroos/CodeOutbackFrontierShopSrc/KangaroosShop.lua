--
-- 袋鼠商店
-- 需求：
-- 1 页数随便翻，收尾不相连
-- 2 解锁条件是上一页都兑换完全才解锁
-- 3 袋鼠标记数量不足需要置黑

local KangaroosShopData = util_require("CodeOutbackFrontierShopSrc.KangaroosShopData")
local KangaroosShop = class("KangaroosShop", util_require("base.BaseView"))

local KANGAROOS_SHOP_BG_MUSIC = "KangaroosSounds/sound_Kangaroos_shop_bgm.mp3" -- 袋鼠商店中背景音乐
KangaroosShop.m_buyClickMusicId = nil
KangaroosShop.m_buyLoopMusicId = nil -- 点击购买时请求数据播放的循环音乐
KangaroosShop.m_buyOverMusicId = nil


function KangaroosShop:initUI()
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename="OutbackFrontierShop/OutbackFrontierShop.csb"
    self:createCsbNode(resourceFilename, isAutoScale)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

    self.m_countLabel   = self:findChild("BitmapFontLabel_2")
    self.m_pageNode     = self:findChild("Node_page")
    self.m_titleIcon    = self:findChild("title_icon")
    self.btn_left       = self:findChild("Button_left")
    self.btn_right      = self:findChild("Button_right")
    self.m_pageTouch    = self:findChild("pageTouch")
    self:addClick(self.m_pageTouch)
    self.m_pageTouch:setSwallowTouches(false)

    self:runCsbAction("start")

    self.m_pageCells    = {}
    self.m_isMoved      = false
    self.m_curPageIndex = KangaroosShopData:getDefaultPageIndex() -- 定位页数

    self.m_pageNum      = KangaroosShopData:getShopPageNum() -- 页数

    KangaroosShopData:setEnterFlag(false)
    self:initTag()
    self:updateUI(true)
end

function KangaroosShop:getUIScalePro()

    -- local ratio = display.width / display.height
    -- if ratio <= 0.68 then
    --     return 0.9
    -- elseif ratio <= 0.75 then
    --     return 0.7
    -- elseif ratio <= 1.34 then
    --     return 1
    -- end
    if globalData.slotRunData.isPortrait == true then
        local ratio = display.height/display.width
        
        if ratio <= 1.5 then -- iPhone 4 (960x640)
            return 0.8
        elseif ratio <= 1.8 then -- iPhone 5 (1136x640)
            return 0.9
        else
            return 1
        end
    end

    local x=display.width/DESIGN_SIZE.width
    local y=display.height/DESIGN_SIZE.height
    local pro=x/y
    return pro
end

function KangaroosShop:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:updateCount()
        local afterUpdate = false
        if params.exchange then
            afterUpdate = true
        end
        self:updateCurPageInfo(true, afterUpdate)
    end,ViewEventType.NOTIFY_KANGAROOS_SHOP_PAGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:playBuySound()
    end,ViewEventType.NOTIFY_KANGAROOS_SHOP_PAGE_BUY_CLICK)

    gLobalNoticManager:addObserver(self,function(self,params)
        -- 购买请求数据返回后处理声音
        self:palyBuySuccessSound()
    end,ViewEventType.NOTIFY_KANGAROOS_SHOP_PAGE_BUY_SUCCESS)

    gLobalNoticManager:addObserver(self,function(self,params)
        if params == "start" then
            self:closeUI()
        elseif params == "over" then
            if self.isClose then
                local view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShop")
                if globalData.slotRunData.machineData.p_portraitFlag then
                    view.getRotateBackScaleFlag = function(  ) return false end
                end
                gLobalViewManager:showUI(view)
            end
        end
    end,ViewEventType.NOTIFY_KANGAROOS_SHOP_FREE_SPIN)

    gLobalSoundManager:setBackgroundMusicVolume(0)
    KangaroosShopData:setEnterShopView(true)
    self.m_musicId = gLobalSoundManager:playSound(KANGAROOS_SHOP_BG_MUSIC, true)
end

function KangaroosShop:onExit()
    local eventDispatcher = self.m_pageTouch:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self.m_pageTouch, true)
    gLobalNoticManager:removeAllObservers(self)

    gLobalSoundManager:setBackgroundMusicVolume(0)
    
    self:clearBuyMusic()
end

function KangaroosShop:closeUI()
    if self.isClose then
        return
    end

    KangaroosShopData:setExCloseState(true)

    self:findChild("Button_back"):setTouchEnabled(false)
    if self.m_musicId then
        gLobalSoundManager:stopAudio(self.m_musicId)
    end
    -- -- 刷新一下兑换币
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_KANGAROOS_SHOP_ENTER_UPDATE, {})
    self.isClose = true
    self.isOpen = false
    self:runCsbAction("over", false, function()
        KangaroosShopData:setExCloseState(false)
        KangaroosShopData:setEnterShopView(false)
        self:removeFromParent()
    end)
end

function KangaroosShop:initTag()
    
    self.m_points = {}
    for i=1,self.m_pageNum do
        local point = self:findChild("pagePoint_"..i.."_2")
        self.m_points[#self.m_points+1] = point
    end
end

function KangaroosShop:updateUI(isInit)
    self:updateCount()
    self:updateTitle(isInit)
    self:updateTag()
    self:updateBtn()
    self:updateCurPageInfo(isInit)
end

function KangaroosShop:updateCount()
    local m_num = KangaroosShopData:getShopCollectCoins()
    self.m_countLabel:setString(tostring(m_num))
end

function KangaroosShop:updateTag()
    for i=1,#self.m_points do
        self.m_points[i]:setVisible(i == self.m_curPageIndex)
    end
end

function KangaroosShop:updateBtn()
    self.btn_left:setVisible(self.m_curPageIndex>1)
    self.btn_right:setVisible(self.m_curPageIndex<self.m_pageNum)
end

-- 顶部UI切换 -- 
function KangaroosShop:updateTitle(isInit)
    if isInit then
        util_changeTexture(self.m_titleIcon, KangaroosShopData.shopTitle[self.m_curPageIndex])
    else
        self:runCsbAction("todark", false, function()
            util_changeTexture(self.m_titleIcon, KangaroosShopData.shopTitle[self.m_curPageIndex])
            self:runCsbAction("tolight")
        end)
    end
end

-- noPlayStart:是否播放start动画的标记
-- afterUpdateUI:兑换请求后要先播放动作再刷新UI
function KangaroosShop:updateCurPageInfo(noPlayStart, afterUpdateUI)
    if self.m_pageCells[self.m_curPageIndex] == nil then
        self.m_pageCells[self.m_curPageIndex] = self:initCell()
    end
    
    local callF = false
    if afterUpdateUI then
        callF = true
    end

    -- 上一次是2x，本次需要做粒子飞行和飞行结束变2倍动作
    
    -- 需要先播放UI动效，然后再整体刷新UI
    if callF then
        local callFunc = function()
            if not tolua.isnull(self) then
                self.m_pageCells[self.m_curPageIndex]:updateUI(noPlayStart)
            end
        end
        local frees = KangaroosShopData:getPagesFree()
        self.m_pageCells[self.m_curPageIndex]:playPageUIAction(frees[self.m_curPageIndex][1], noPlayStart, callFunc)
    else 
        self.m_pageCells[self.m_curPageIndex]:updateUI(noPlayStart)
    end
end

function KangaroosShop:initCell()
    local view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShopPage", self.m_curPageIndex)
    self.m_pageNode:addChild(view, -1)
    return view
end

-- 翻页 --
function KangaroosShop:moveNodeCells(direction)
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

function KangaroosShop:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_back" then
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_btnclose.mp3")
        self:closeUI()
    elseif name == "Button_left" then
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_btnnextpage.mp3")
        self:clickLast()
    elseif name == "Button_right" then
        gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_btnnextpage.mp3")
        self:clickNext()
    end
end


function KangaroosShop:canClick()
    if KangaroosShopData:getFlyData() == true then
        return false, "isFreeFlying"
    end
        
    if KangaroosShopData:getFreeSpinState() == true then
        return false, "isFreeSpining"
    end 

    if KangaroosShopData:getExchangeEffectState() == true then
        return false, "isPlayingAction"
    end

    if KangaroosShopData:getNetState() == true then
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

function KangaroosShop:clickLast()
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

function KangaroosShop:clickNext()
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

function KangaroosShop:baseTouchEvent(sender, eventType)
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
function KangaroosShop:palyBuySuccessSound()
    if self.m_buyClickMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_buyClickMusicId)
        self.m_buyClickMusicId = nil
    end
    if self.m_buyLoopMusicId ~= nil then
        gLobalSoundManager:stopAudio(self.m_buyLoopMusicId)
        self.m_buyLoopMusicId = nil
    end    
    self.m_buyOverMusicId = gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_buy_over.mp3")    
end

-- 购买点击时处理声音
function KangaroosShop:playBuySound()    
    self.m_buyClickMusicId = gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_buy_start.mp3", false)
    performWithDelay(self, function()
        self.m_buyLoopMusicId = gLobalSoundManager:playSound("KangaroosSounds/sound_Kangaroos_shop_buy_loop.mp3", true)
    end, 0.5)
end

-- 关闭界面时关闭所有声音
function KangaroosShop:clearBuyMusic()
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

return KangaroosShop