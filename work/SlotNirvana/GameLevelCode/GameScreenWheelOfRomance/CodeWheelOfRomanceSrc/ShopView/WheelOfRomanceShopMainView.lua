-- 需求：
-- 1 页数随便翻，收尾不相连
-- 2 解锁条件是上一页都兑换完全才解锁
-- 3 数量不足需要置黑

local WheelOfRomanceShopMainView = class("WheelOfRomanceShopMainView", util_require("base.BaseView"))


WheelOfRomanceShopMainView.PAGENAME_NAME  = {"Puppy","Bunny","King","Beer"}

WheelOfRomanceShopMainView.SHOP_EFFECT_ITEM_OPEN = 1
WheelOfRomanceShopMainView.SHOP_EFFECT_TOY_LEVEUP = 2
WheelOfRomanceShopMainView.SHOP_EFFECT_ITEM_TRIGGER_WHEEL = 3
WheelOfRomanceShopMainView.SHOP_EFFECT_ITEM_UPDATE = 4

WheelOfRomanceShopMainView.m_LevelUp = false

function WheelOfRomanceShopMainView:initUI()
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self.b_showTips = false 
    local resourceFilename="WheelOfRomance/WheelOfRomanceShop.csb"
    self:createCsbNode(resourceFilename, isAutoScale)

    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

    self.m_countLabel = self:findChild("m_lb_coins")
    self.m_pageNode = self:findChild("Node_Page")
    self.btn_left = self:findChild("Btn_L")
    self.btn_right = self:findChild("Btn_R")
    self.m_pageTouch = self:findChild("Touch")
    self.m_levelLable = self:findChild("m_lb_level") 
    self.m_clippingNode = self:findChild("PageLayer")
    self.m_clippingNode:setClippingEnabled(false)

    self:addClick(self.m_pageTouch)
    self.m_pageTouch:setSwallowTouches(false)


    

    self.m_shop_Tip = util_createView("CodeWheelOfRomanceSrc/WheelOfRomanceTipView","WheelOfRomance_shop_Tip.csb")  
    self:findChild("Node_Tip"):addChild(self.m_shop_Tip)
    self:findChild("Node_Tip"):setLocalZOrder(1000)
    self.m_shop_Tip:setVisible(false)


    self.m_shop_Item_Tip = util_createView("CodeWheelOfRomanceSrc/WheelOfRomanceTipView","WheelOfRomance_shop_item_dark_Tip.csb")  
    self:addChild(self.m_shop_Item_Tip)
    self:setLocalZOrder(10000)
    self.m_shop_Item_Tip:setVisible(false)

    self.m_pageCells = {}
    self.m_isMoved = false
    self.m_curPageIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getDefaultPageIndex() -- 定位页数
    self.m_pageNum = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getShopPageNum() -- 页数

    globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:setEnterFlag(false)

    self:initTagTip()
    self:updateUI()

end

function WheelOfRomanceShopMainView:setMachine(machine)
    self.m_machine = machine
end

function WheelOfRomanceShopMainView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:setEnterShopView(true)

    gLobalNoticManager:addObserver(self,function(self,params)

        local clickNode = params[1]
        if clickNode then

            gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_page.mp3")
            
            local Node_Tip = clickNode:findChild("Node_Tip")
            local pos = util_getConvertNodePos(Node_Tip,self.m_shop_Item_Tip)
            self.m_shop_Item_Tip:setPosition(pos)
            self.m_shop_Item_Tip:setVisible(true)
            self.m_shop_Item_Tip:showView()
            
        end

    end,"WheelOfRomance_LockItem_Click")


    gLobalNoticManager:addObserver(self,function(self,params)

        if params[1] == true then
          -- 接受消息监听
            local spinData = params[2]
            if spinData.action == "SPECIAL" then
                release_print("消息返回胡来了")
                print(cjson.encode(spinData)) 

                self.m_machine:SpinResultParseResultData( spinData)

                self:recvBaseAnim()
            end
        else
            -- 处理消息请求错误情况
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
    
        end

        

    end,ViewEventType.NOTIFY_GET_SPINRESULT)
end

function WheelOfRomanceShopMainView:onExit()
    local eventDispatcher = self.m_pageTouch:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self.m_pageTouch, true)
    gLobalNoticManager:removeAllObservers(self)

    self:clearBuyMusic()
end

function WheelOfRomanceShopMainView:closeUI()
    if self.isClose then
        return
    end
    self:findChild("Btn_Close"):setTouchEnabled(false)

    self.isClose = true
    self.isOpen = false
    self:runCsbAction("over", false, function()
        globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:setEnterShopView(false)
        globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:setNetState(false) 
        if self.m_func then
            self.m_func()
        end
        self:removeFromParent()
    end)

end

function WheelOfRomanceShopMainView:initTagTip()
    
    self.m_points = {}
    for i=1,self.m_pageNum do
        local csb = util_createAnimation("WheelOfRomance_shop_PageNum.csb")
        csb:playAction("idle1", false)
        local point = self:findChild("Node_Page_" .. i)
        point:addChild(csb)
        self.m_points[#self.m_points+1] = csb
    end
end

function WheelOfRomanceShopMainView:updateUI()
    
    self:updatePageName( )
    self:updateLevel( )
    self:updatePoint()
    self:updateTag()
    self:updateBtn()

    self:updateCurPageInfo()
end

function WheelOfRomanceShopMainView:updatePoint()
    local points = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getShopCollectCoins()
    self.m_countLabel:setString(util_formatCoins(points, 50))
    self:updateLabelSize({label = self.m_countLabel, sx = 1, sy = 1}, 136)
end

function WheelOfRomanceShopMainView:updateLevel( )
    
    local leve = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getCellPageLevel( self.m_curPageIndex )
    self.m_levelLable:setString(util_formatCoins(leve, 50))
end

function WheelOfRomanceShopMainView:updatePageName( )
    
    for i=1,4 do
        self:findChild("Name_"..self.PAGENAME_NAME[i]):setVisible(false)
        if i == self.m_curPageIndex then
            self:findChild("Name_"..self.PAGENAME_NAME[i]):setVisible(true)
        end
    end 
end

function WheelOfRomanceShopMainView:updateTag()
    for i=1,#self.m_points do
        if i == self.m_curPageIndex then
            self.m_points[i]:playAction("idle2", false)
        else
            self.m_points[i]:playAction("idle", false)
        end 
    end
end

function WheelOfRomanceShopMainView:updateBtn()
    self.btn_left:setVisible(self.m_curPageIndex>1)
    self.btn_right:setVisible(self.m_curPageIndex<self.m_pageNum)
end


function WheelOfRomanceShopMainView:updateCurPageInfo()
    if self.m_pageCells[self.m_curPageIndex] == nil then
        self.m_pageCells[self.m_curPageIndex] = self:initPageView()
    end
    self.m_pageCells[self.m_curPageIndex]:updateLockUI( )
    self.m_pageCells[self.m_curPageIndex]:initToyUi()
    self.m_pageCells[self.m_curPageIndex]:initPageCellView()
    

end

function WheelOfRomanceShopMainView:initPageView()
    local view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPage", self.m_curPageIndex)
    self.m_pageNode:addChild(view, -1)
    return view
end

-- 翻页 --
function WheelOfRomanceShopMainView:moveNodeCells(direction)
    self.m_isMoved = true

    self.m_clippingNode:setClippingEnabled(true)

    self:updateCurPageInfo()
    self.m_pageCells[self.m_curPageIndex]:setPosition(display.width * direction, 0)

    local moveTo1 = cc.MoveTo:create(0.4,cc.p(display.width * -direction, 0))
    local callfunc = cc.CallFunc:create(function()
        self.m_isMoved = false
        self.m_prePageCell:setVisible(false)

        self.m_clippingNode:setClippingEnabled(false)

    end)

    local seq = cc.Sequence:create(moveTo1, callfunc)
    self.m_prePageCell:runAction(seq)

    self.m_pageCells[self.m_curPageIndex]:setVisible(true)

    local moveTo2 = cc.MoveTo:create(0.4,cc.p(0, 0))
    self.m_pageCells[self.m_curPageIndex]:runAction(moveTo2)
end


function WheelOfRomanceShopMainView:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "Btn_Close" then
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_page.mp3")
        self:closeUI()
    elseif name == "Btn_L" then
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_page.mp3")
        self:clickLast()

    elseif name == "Btn_R" then
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_page.mp3")
        self:clickNext()

    elseif name == "BtnTip" then 
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_page.mp3")
        self.m_shop_Tip:showView( )
    end
end

function WheelOfRomanceShopMainView:canClick()

    if globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getExchangeEffectState() == true then
        return false, "isPlayingAction"
    end

    if globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getNetState() == true then
        return false, "net"
    end

    if globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getEnterFlag() == false then
        return false, "startAni"
    end

    

    if self.m_isMoved == true then
        return false, "pageMoving"
    end
    if self.isClose then
        return false, "isClosed"
    end    
    return true
end

function WheelOfRomanceShopMainView:clickLast()
    if not self:canClick() then
        return
    end
    if self.m_curPageIndex <= 1 then
        return
    end
    self.m_prePageCell = self.m_pageCells[self.m_curPageIndex]
    self.m_curPageIndex = self.m_curPageIndex - 1

    self:updatePageName( )
    self:updateLevel( )
    self:updateTag()
    self:updateBtn()    
    self:moveNodeCells(-1)
end

function WheelOfRomanceShopMainView:clickNext()
    if not self:canClick() then
        return
    end
    if self.m_curPageIndex >= self.m_pageNum then
        return
    end
    self.m_prePageCell = self.m_pageCells[self.m_curPageIndex]
    self.m_curPageIndex = self.m_curPageIndex + 1

    self:updatePageName( )
    self:updateLevel( )
    self:updateTag()
    self:updateBtn()    
    self:moveNodeCells(1)
end

function WheelOfRomanceShopMainView:baseTouchEvent(sender, eventType)
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

    end
end


-- 关闭界面时关闭所有声音
function WheelOfRomanceShopMainView:clearBuyMusic()
  
end


function WheelOfRomanceShopMainView:setCloseShopCallFun(fun)
    self.m_func = function (  )
        if fun then
            fun()
        end
    end
end

--[[
    *********
    处理动画    
--]]

function WheelOfRomanceShopMainView:recvBaseAnim()
   
    self:addShopGameEffect( )

    self:playShopGameEffect( )
    
end

function WheelOfRomanceShopMainView:addShopGameEffect( )
    
    self.m_LevelUp = false 

    self.m_shopGameEffect = {}
    self.m_shopGameEffectIndex = 0

    local gameEffect = {}
    gameEffect.Order = self.SHOP_EFFECT_ITEM_OPEN
    gameEffect.Type = self.SHOP_EFFECT_ITEM_OPEN
    table.insert(self.m_shopGameEffect,gameEffect)

    local requestPageIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageIndex()
    local requestPageCellIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageCellIndex()
    local oldLevel = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageLevel(requestPageIndex)
    local newLeve = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getCellPageLevel( requestPageIndex )
    if oldLevel ~= newLeve then

        self.m_LevelUp = true 

        local gameEffect = {}
        gameEffect.Order = self.SHOP_EFFECT_TOY_LEVEUP
        gameEffect.Type = self.SHOP_EFFECT_TOY_LEVEUP
        table.insert(self.m_shopGameEffect,gameEffect)
    end
    

    local gameEffect = {}
    gameEffect.Order = self.SHOP_EFFECT_ITEM_TRIGGER_WHEEL
    gameEffect.Type = self.SHOP_EFFECT_ITEM_TRIGGER_WHEEL
    table.insert(self.m_shopGameEffect,gameEffect)

    local gameEffect = {}
    gameEffect.Order = self.SHOP_EFFECT_ITEM_UPDATE
    gameEffect.Type = self.SHOP_EFFECT_ITEM_UPDATE
    table.insert(self.m_shopGameEffect,gameEffect)

    -- 调整gameEffectOrder
    table.sort(self.m_shopGameEffect,function( a , b)
        return a.Order < b.Order
    end)

end


function WheelOfRomanceShopMainView:shopGameEffectOver( )
    
    globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:setNetState(false) 

end



function WheelOfRomanceShopMainView:playShopGameEffect( )

    self.m_shopGameEffectIndex = self.m_shopGameEffectIndex + 1

    if self.m_shopGameEffectIndex > #self.m_shopGameEffect then

        self:shopGameEffectOver( )

        return
    end

    local gameEffectData = self.m_shopGameEffect[self.m_shopGameEffectIndex]


    if gameEffectData.Type == self.SHOP_EFFECT_ITEM_OPEN then
        self:playItemOpen( )
    elseif gameEffectData.Type == self.SHOP_EFFECT_TOY_LEVEUP then
        self:playToyLeveUp( )
    elseif gameEffectData.Type == self.SHOP_EFFECT_ITEM_TRIGGER_WHEEL then
        self:playTriggerBonus( )
    elseif gameEffectData.Type == self.SHOP_EFFECT_ITEM_UPDATE then
        self:playItemUpdate( )
    end

end



function WheelOfRomanceShopMainView:playItemOpen( )

    gLobalNoticManager:postNotification("WHEELOFROMANCE_SHOP_ITEM_CLICK")

    self:updatePoint()

    local requestPageIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageIndex()
    local requestPageCellIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageCellIndex()
   
    local pageView = self.m_pageCells[requestPageIndex]

    local clickPageCellStatus = self.m_machine:getClickPageCellStatus()


    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local awardType = selfdata.awardType or ""
    local winCoins = selfdata.winCoins

    if  awardType == self.m_machine.SHOP_TYPE_COINS then
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_Coins.mp3")
    elseif awardType == self.m_machine.BONUS_TYPE_WHEEL then
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_luckyWheel.mp3")
    elseif awardType == self.m_machine.BONUS_TYPE_JACKPOT then
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_click_grandWheel.mp3")
    end


    local cellView = pageView:createOldPageCell(requestPageCellIndex,clickPageCellStatus)

    local animCellView = pageView:createOldAniItem( requestPageCellIndex )

    animCellView:runCsbAction("click_enough1",false,function(  )
        animCellView:removeFromParent()
    end,60)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        
        if  awardType == self.m_machine.SHOP_TYPE_COINS then

            cellView:runCsbAction("actionframe")

            self:ActivityFlyCoins(cellView,winCoins,function(  )
                self:playShopGameEffect( )
            end)

        else

            cellView:runCsbAction("actionframe",false,function(  )
                self:playShopGameEffect( )
            end,60)
        end


        waitNode:removeFromParent()
    end,15/60)
    


end

function WheelOfRomanceShopMainView:ActivityFlyCoins( currNode,winCoins,func )
    local endPos = globalData.flyCoinsEndPos
    local startPos = currNode:getParent():convertToWorldSpace(cc.p(currNode:getPosition()))
    local baseCoins = globalData.topUICoinCount

    if self.m_LevelUp then
        gLobalViewManager:getFlyCoinsView():pubShowSelfCoins(true) 
        self.m_LevelUp = false
    end
    
    local view = gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,winCoins,function()
        gLobalViewManager:getFlyCoinsView():pubShowSelfCoins(false)
        if func then
            func()
        end
    end )
end

function WheelOfRomanceShopMainView:playToyLeveUp( )

    
    gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_levelUp.mp3")

    local requestPageIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageIndex()
    local requestPageCellIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageCellIndex()
    local oldLevel = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageLevel(requestPageIndex)
    local newLeve = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getCellPageLevel( requestPageIndex )
    local pageView = self.m_pageCells[requestPageIndex]
    local toy = pageView.m_Toy
    pageView:showAllToyUi( )


    local aniName = "change".. oldLevel .. "_" .. newLeve
    toy:runCsbAction(aniName,false,function(  )

        pageView:updateLockUI( )
        self:updateLevel( )



        pageView:hideAllToyUi( )
        toy:findChild("Wheel_of_Romance_Toy_"..newLeve):setVisible(true)

        toy:runCsbAction("idleframe",true)

        
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_shop_levelUp_WinVIew.mp3")

        self.m_machine:showShopLevelUpView(function(  )
            self.m_machine.m_bottomUI:notifyTopWinCoin()
            self:playShopGameEffect( )
        end)

        

    end,60)
end

function WheelOfRomanceShopMainView:playTriggerBonus( )

    -- 触发了特殊玩法直接进特殊玩法，关闭商店

    local isTrigger =  self.m_machine:checkAddShopFeatures( )

    if isTrigger then

        self.m_machine.m_shopTriggerBonus = true

        self:closeUI()

    else
        self:playShopGameEffect( )
    end

end

function WheelOfRomanceShopMainView:playItemUpdate( )

    local requestPageIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageIndex()
    local requestPageCellIndex = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageCellIndex()
    local pageView = self.m_pageCells[requestPageIndex]

    local oldCellNodeList = pageView:getAllPageCellNdoe(  )
    local oldCellStatusList = {}
    for i=1,pageView.m_cellNum do
        local oldCell = oldCellNodeList[i]
        table.insert( oldCellStatusList, oldCell.m_pageCellStatus )
    end

    self:updateCurPageInfo()

    
    local newCellNodeList = pageView:getAllPageCellNdoe(  )

    local darkStates = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_DARK  -- 不可点击
    local lockStates = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_LOCK  -- 锁住
    local idleStates = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_IDLE  -- 是可点击
    local portraitStates = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_PORTRAIT_WHEEL  -- 多个竖着的轮子
    local circulardarkStates = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_CIRCULAR_WHEEL  -- 是直接进大圆盘 
    local coinsStates = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_CIRCULAR_COINS  -- > 0 金币钱

    local isWait = false
    for i=1,pageView.m_cellNum do
        local newCell = newCellNodeList[i]
        local oldCellStates = oldCellStatusList[i]
        if newCell.m_pageCellStatus ~=  oldCellStates  then
            isWait = true
            newCell:runCsbAction("start",false,function(  )
                newCell:runCsbAction("idle",true)
            end,60) 
        end
    end

    local waitTime = 0
    if isWait then
        waitTime = 45/60
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode) 
    performWithDelay(waitNode,function(  )

        self:playShopGameEffect( )

        waitNode:removeFromParent()
    end,waitTime)
    
end

return WheelOfRomanceShopMainView