---
--xcyy
--2018年5月23日
--FishManiaShopListView.lua

local SendDataManager = require "network.SendDataManager"
local FishManiaShopListView = class("FishManiaShopListView",util_require("base.BaseGame"))

FishManiaShopListView.m_states = 0
FishManiaShopListView.m_idleStates = 0
FishManiaShopListView.m_startstates = 2
FishManiaShopListView.m_overStates = 3

FishManiaShopListView.m_closeOrOpen = false

function FishManiaShopListView:initUI(_machine)

    self.m_closeOrOpen = false
    self.m_machine = _machine  

    self:createCsbNode("FishMania_shangdian.csb")

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)

    self.m_buyBtnCallBackList = {} --购买按钮回调
    self.m_isCanTouch = true   --界面按钮是否可点击
    self.m_finishOpen = false  --界面已完成打开动画
    local p_shopData = globalMachineController.p_fishManiaShopData
    local shopPageData = p_shopData:getshopPageData( )
    local shopShowIndex = p_shopData:getShowIndex( )
    --总页数
    self.m_totalPageNum = p_shopData:getShopPageCount() 

    self.m_currPageIdex = shopShowIndex  --当前显示的页数
    self.m_houseGoodsNumTab = {}         --各个页面的商品数量
    for _shopIndex = 1,self.m_totalPageNum do
        local shopData = shopPageData[_shopIndex]
        -- 每一页的道具个数
        local goodsNum = shopData and #shopData or 0
        table.insert(self.m_houseGoodsNumTab,goodsNum)
    end
    self.m_sliderBgFileHeight = 0--滑动条背景高
    self.m_sliderThumbFileHeight = 0--滑动条滑条高
    self.m_sliderCanEvent = true --滑动条事件回调是否生效

    self.m_diandianTab = {}
    for i = 1,self.m_totalPageNum do

        --加页数小点
        local parentNode = self:findChild("dian_"..i)
        if parentNode then
            local diandian = util_createAnimation("FishMania_shangdian_dian.csb")
            parentNode:addChild(diandian)
            table.insert(self.m_diandianTab,diandian)
        end
        
    end
    self:setDiandian()

    --创建翻页容器
    self.m_pageView = ccui.PageView:create()
    self.m_pageView:setContentSize(646,421)
    self.m_scrollviewTab = {}--滑动页面对象存储
    self.m_allGoodsTab = {}--所有商品对象存储
    -- self.m_shouTab = {}--手对象存储
    -- self.m_lockTab = {}--锁定对象存储
    for i = 1,self.m_totalPageNum do
        local goodsTab = {}
        local layout = ccui.Layout:create()
        self.m_pageView:addPage(layout)

        --创建商品列表
        local scrollview = ccui.ScrollView:create()
        scrollview:setDirection(ccui.ScrollViewDir.vertical)
        scrollview:setBounceEnabled(false)
        scrollview:setScrollBarEnabled(false)
        scrollview:setContentSize(self.m_pageView:getContentSize())

        --添加商品
        local perRowGoodsNum = 2 --一行放的商品数量
        local leftReservedSpace = 10 --左边预留间隙
        self.m_topReservedSpace = 10--上边预留间隙
        local bottomReservedSpace = 10--下边预留间隙
        local rowSpace = 10 --行之间的间隙
        local colSpace = 10 --列之间的间隙
        self.m_goodsSize = nil --每个商品的尺寸
        local cerPageHight = nil --本页页面的高

        local pageData = shopPageData[i] 
        local totalRows = math.ceil(self.m_houseGoodsNumTab[i]/perRowGoodsNum)--本页商品总行数
        for j = 1,self.m_houseGoodsNumTab[i] do
            local goods = util_createAnimation("FishMania_shangdian_item.csb")
            local id = tonumber(pageData[j].type) + 1
            local price = tonumber(pageData[j].price) 
            local buy = pageData[j].buy
            --初始化一下这个商品的数据
            goods.m_initData = {
                commodityId = id,
            }
            --初始化logo的缩放
            local picName = p_shopData:getShopIconPath(id) 
            local goodsPic = goods:findChild("goodsPic")
            util_changeTexture(goodsPic,picName) --设置商品图片
            local scale = globalMachineController.p_fishManiaShopData:getCommodityShopScale(id)
            goodsPic:setScale(scale)
            --初始化名称
            local commodityName = globalMachineController.p_fishManiaShopData:getCommodityName(id) 
            local goodsName = goods:findChild("goodsName")
            goodsName:setString(commodityName)

            local btn_Buy = goods:findChild("btn_Buy")
            if btn_Buy then
                btn_Buy:setVisible(false)
                btn_Buy:setTag(j)
            end
            local btn_set = goods:findChild("btn_set")
            if btn_set then
                btn_set:setVisible(false)
                btn_set:setTag(j)
            end
            local scoreLab = goods:findChild("goodsPrice") 
            if scoreLab then
                scoreLab:setString(util_formatCoins(price,6))
            end

            if buy then
                if btn_set then
                    btn_set:setVisible(true)
                end
            else
                if btn_Buy then
                    btn_Buy:setVisible(true)
                end
            end

            if j == 1 then
                self.m_goodsSize = goods:findChild("bg"):getContentSize()
                cerPageHight = totalRows * self.m_goodsSize.height + (totalRows - 1) * rowSpace + self.m_topReservedSpace + bottomReservedSpace
                if cerPageHight < scrollview:getContentSize().height then
                    cerPageHight = scrollview:getContentSize().height
                end
            end
            goods.clickFunc = function (target,sender)
                self:clickFunc(sender)
            end

            scrollview:addChild(goods)

            local posx = ((j-1) % perRowGoodsNum) * (self.m_goodsSize.width + colSpace) + leftReservedSpace
            local posy = cerPageHight - self.m_topReservedSpace - (math.ceil(j/perRowGoodsNum) * self.m_goodsSize.height + (math.ceil(j/perRowGoodsNum)-1) * rowSpace)
            goods:setPosition(cc.p(posx,posy))

            table.insert(goodsTab,goods)
        end
        scrollview:setInnerContainerSize(cc.size(scrollview:getContentSize().width,cerPageHight))
        layout:addChild(scrollview)

        table.insert(self.m_scrollviewTab,scrollview)
        --bugly报错: (cerPageHight is nil) 或者 (scrollview:getContentSize().height is nil) 
        -- 看日志发现进入关卡时的商品列表没传，后端先查一下
        local scrollviewSize = scrollview:getContentSize()
        local value1 = cerPageHight or -1
        local value2 = scrollviewSize.height or -1
        local msg = string.format("cerPageHight=(%d) scrollviewSize.height=(%d)", value1, value2)
        release_print(msg)
        local userCoin = globalData.userRunData.coinNum or -1
        msg = string.format("userCoin=(%s)", "" .. userCoin)
        release_print(msg)

        if cerPageHight > scrollview:getContentSize().height then
            -- 添加进度条
            local bgFile        = util_createSprite("common/FishMania_shop_tiaodi.png")
            local progressFile  = util_createSprite("common/FishMania_shop_tiaodi.png")
            local thumbFile     = util_createSprite("common/FishMania_shop_tiaodi2.png")

            self.m_sliderBgFileHeight = bgFile:getContentSize().width - 60
            self.m_sliderThumbFileHeight = thumbFile:getContentSize().width * 0.8
            thumbFile:setScale(0.8)
            progressFile:setVisible(false)
            local slider = cc.ControlSlider:create(bgFile,progressFile,thumbFile)
            slider:setPosition( scrollview:getContentSize().width - 8  , scrollview:getContentSize().height / 2 )
            slider:setAnchorPoint( cc.p(0.5,0.5) )
            slider:setRotation(90)
            slider:setEnabled( true )
            slider:registerControlEventHandler( handler(self,self.sliderMoveEvent) , cc.CONTROL_EVENTTYPE_VALUE_CHANGED )
            slider:setMinimumValue(0)
            slider:setMaximumValue(1)
            slider:setValue(self:scrolledPercentChangeToSliderPercent(0))
            layout:addChild(slider,1,i)

            scrollview:onScroll(function(data)
                if  data.name == "CONTAINER_MOVED" then
                    self.m_moveSlider = false
                    if self.m_moveTable == true then
                        local percent = scrollview:getScrolledPercentVertical()
                        if slider ~= nil then
                            slider:setValue(self:scrolledPercentChangeToSliderPercent(percent))
                        end
                    end
                    self.m_moveSlider = true
                end
            end)
        end
        table.insert(self.m_allGoodsTab ,goodsTab)
    end

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider= true

    local pageNode = self:findChild("pageNode")
    pageNode:addChild(self.m_pageView)
    --锁定遮罩
    local maskParent = self:findChild("suodingNode")
    self.m_lockMask = util_createAnimation("FishMania_shangdian_suoding.csb") 
    maskParent:addChild(self.m_lockMask)
    self.m_lockMask:setVisible(false)

    self.m_pageView:setTouchEnabled(true)
    self.m_pageView:setAnchorPoint(cc.p(0.5,0.5))

    util_setCascadeOpacityEnabledRescursion(self,true)
end



function FishManiaShopListView:onEnter()
    FishManiaShopListView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,
        function(self,params) 
            if self.m_closeOrOpen then
                self:HideShopListView( )
            else
                self:showShopListView( )
            end
        end,
        globalMachineController.p_fishManiaPlayConfig.EventName.SHOPLISTVIEW_SHOW_HIDE)

 
end



function FishManiaShopListView:onExit()
    gLobalNoticManager:removeAllObservers(self)
    FishManiaShopListView.super.onExit(self)
end


function FishManiaShopListView:showShopListView( )

    if not self:checkShowStates( ) then
        return
    end
    


    local p_shopData = globalMachineController.p_fishManiaShopData
    local shopIndex = p_shopData:getShowIndex()
    
    self.m_states = self.m_startstates
    self.m_closeOrOpen = true
    self.m_finishOpen = false
    
    self:setVisible(true)
    self:runCsbAction("show")
    self.m_waitNode:stopAllActions()
    --打开时直接切换到当前收集的商店
    self:setPageIndex(shopIndex)

    performWithDelay(self.m_waitNode,function(  )
        self.m_states = self.m_idleStates
        self.m_finishOpen = true
        self:runCsbAction("idle",true)

        if self.m_machine then
            self.m_machine:setMainUiViwible(false)
        end

    end,0.5)

    -- 打点
    local pginfo = {level = shopIndex ,Points = p_shopData:getPickScore()}
    globalMachineController.p_LogFishManiaShop:sendGameUILog("Shop", "Open", pginfo)
end

function FishManiaShopListView:HideShopListView( )
    
    if not self:checkShowStates( ) then
        return
    end

    if self.m_machine then
        self.m_machine:setMainUiViwible(true)
    end
    -- 触发superFree 解开过早导致一次spin没计算进 free内
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})

    self.m_finishOpen = false
    self.m_waitNode:stopAllActions()
    self.m_states = self.m_overStates
    self:runCsbAction("over")

    self.m_waitNode:stopAllActions()
    performWithDelay(self.m_waitNode,function(  )
        self.m_states = self.m_idleStates
        self.m_closeOrOpen = false
        self:setVisible(false)
    end,0.5)

end

function FishManiaShopListView:quickHideShopListView( )
    
    self.m_waitNode:stopAllActions()
    self.m_states = self.m_overStates
    self:runCsbAction("over")

    if self.m_machine then
        self.m_machine:setMainUiViwible(true)
    end

    self.m_waitNode:stopAllActions()
    performWithDelay(self.m_waitNode,function(  )
        self.m_states = self.m_idleStates
        self.m_closeOrOpen = false
        self:setVisible(false)
    end,0.5)

end
function FishManiaShopListView:checkShowStates( )
    if self.m_states ~= self.m_idleStates then
        return false
    end
    return true
end

--设置点点的显示
function FishManiaShopListView:setDiandian()
    for i,diandian in ipairs(self.m_diandianTab) do
        if i == self.m_currPageIdex then
            diandian:findChild("dian"):setVisible(true)
        else
            diandian:findChild("dian"):setVisible(false)
        end
    end
end

--去下一页
function FishManiaShopListView:toNextPage()
    if self.m_machine:getGameBgMoveState() then
        return
    end
    local nextPageIdex = self.m_currPageIdex + 1
    if nextPageIdex > self.m_totalPageNum then
        return
    end
    self:setPageIndex(nextPageIdex,true)

end
--去上一页
function FishManiaShopListView:toPreviousPage()
    if self.m_machine:getGameBgMoveState() then
        return
    end
    local previousPageIdex = self.m_currPageIdex - 1
    if previousPageIdex < 1 then
        return
    end
    self:setPageIndex(previousPageIdex,true)

end

--将页面设置到某一页
function FishManiaShopListView:setPageIndex(index,isPlayAction,isCallMachine)
    self.m_currPageIdex = index
    if isCallMachine == nil then
        isCallMachine = true
    end
    self:setDiandian()
    self:setLeftRightButton()
    --
    local postEvent = function()
        if isCallMachine == true then
            local eventName = globalMachineController.p_fishManiaPlayConfig.EventName.UPDATE_MACHINE_FISH_TANK
            local data = {self.m_currPageIdex}
            gLobalNoticManager:postNotification(eventName, data)
        end
    end
    
    if isPlayAction then
        self.m_pageView:scrollToItem(self.m_currPageIdex - 1, self.m_machine.m_moveBgTime)
        self.m_machine:slideSwitchShopBg(self.m_currPageIdex, function()
            postEvent()
        end)
    else
        self.m_pageView:setCurrentPageIndex(self.m_currPageIdex - 1)
        postEvent()
    end

    

    self:updateGoodsAtPageIndex(self.m_currPageIdex)
    self:upDateLockMaskShow()
end

function FishManiaShopListView:upDateLockMaskShow()
    local shopIndex = globalMachineController.p_fishManiaShopData:getShowIndex()
    local isUnLock = self.m_currPageIdex <= shopIndex
    self.m_lockMask:setVisible(not isUnLock)
end

--设置按钮的显示
function FishManiaShopListView:setLeftRightButton()
    self:findChild("btn_left"):setVisible(true)
    self:findChild("btn_right"):setVisible(true)
    if self.m_currPageIdex >= self.m_totalPageNum then
        self:findChild("btn_right"):setVisible(false)
    end
    if self.m_currPageIdex <= 1 then
        self:findChild("btn_left"):setVisible(false)
    end
end

--刷新某一页商品图标
function FishManiaShopListView:updateGoodsAtPageIndex(pageIndex)
    if not self:isVisible() then
        return
    end
    
    local goodsTab = self.m_allGoodsTab[pageIndex]
    if goodsTab then

        for _index,_goods in ipairs(goodsTab) do
            self:updateOneGood(pageIndex, _index)
        end

    end

end
function FishManiaShopListView:updateOneGood(pageIndex, index)
    local goodsTab = self.m_allGoodsTab[pageIndex]
    if not goodsTab or not goodsTab[index] then
        return
    end
    local goods = goodsTab[index]

    local p_shopData = globalMachineController.p_fishManiaShopData
    local pickScore  = p_shopData:getPickScore()
    local price      = p_shopData:getCommodityPrice(pageIndex, goods.m_initData.commodityId)
    local state = p_shopData:getCommodityState(pageIndex, goods.m_initData.commodityId)

    
    local btn_Buy = goods:findChild("btn_Buy")
    local btn_set = goods:findChild("btn_set")

    local shopIndex = p_shopData:getShowIndex()
    local isCurShopIndex = shopIndex==pageIndex
    local isBuy = state~=p_shopData.COMMODITYSTATE.NORMAL
    local isCanBuy = isCurShopIndex and pickScore >= price
    btn_Buy:setVisible(not isBuy)
    btn_Buy:setBright(isCanBuy)
    btn_Buy:setTouchEnabled(isCanBuy)

    local isNotSet = state==p_shopData.COMMODITYSTATE.NOTSET
    btn_set:setVisible(isBuy)
    btn_set:setBright(isNotSet)
    btn_set:setTouchEnabled(isNotSet)
end

--将滚动容器的进度转换为滑动条的进度
function FishManiaShopListView:scrolledPercentChangeToSliderPercent(percent)
    return ((self.m_sliderBgFileHeight - self.m_sliderThumbFileHeight) * percent/100 + self.m_sliderThumbFileHeight/2)/self.m_sliderBgFileHeight
end

--将滑动条的进度转换为滚动容器的进度
function FishManiaShopListView:sliderPercentChangeToScrolledPercent(percent)
    return (self.m_sliderBgFileHeight * percent - self.m_sliderThumbFileHeight/2)/(self.m_sliderBgFileHeight - self.m_sliderThumbFileHeight) * 100
end

-- slider 滑动事件 --
function FishManiaShopListView:sliderMoveEvent(slider)
    self.m_moveTable = false
    if self.m_moveSlider == true and self.m_sliderCanEvent == true then
        local sliderOff = slider:getValue()
        if sliderOff < self:scrolledPercentChangeToSliderPercent(0) then
            sliderOff = self:scrolledPercentChangeToSliderPercent(0)
            self.m_sliderCanEvent = false
            slider:setValue(sliderOff)
            self.m_sliderCanEvent = true
        elseif sliderOff > self:scrolledPercentChangeToSliderPercent(100) then
            sliderOff = self:scrolledPercentChangeToSliderPercent(100)
            self.m_sliderCanEvent = false
            slider:setValue(sliderOff)
            self.m_sliderCanEvent = true
        end
        local tag = slider:getTag()
        self.m_scrollviewTab[slider:getTag()]:scrollToPercentVertical(self:sliderPercentChangeToScrolledPercent(sliderOff),0.2,false)
    end
    self.m_moveTable = true
end

--设置界面按钮是否可点击
function FishManiaShopListView:setIsCanTouch(isCan)
    self.m_isCanTouch = isCan
end
function FishManiaShopListView:getIsCanTouch(sender)
    if not self.m_isCanTouch or not  self.m_finishOpen then
        return false
    end

    local p_shopData = globalMachineController.p_fishManiaShopData
    local isGuide = p_shopData:getGuideState()
    if isGuide then
        --引导状态只能购买第一个商品
        local name = sender:getName()
        if name ~= "btn_Buy" then
            return false
        end
        local tag = sender:getTag()
        if 1 ~= tag then
            return false
        end

    end

    return true
end
function FishManiaShopListView:clickFunc(sender)

    if self:getIsCanTouch(sender) then
        local name = sender:getName()
        local tag = sender:getTag()
        if name == "btn_left" then
            self:toPreviousPage()
        elseif name == "btn_right" then
            self:toNextPage()
        elseif name == "btn_Buy" then
            self:sendBuyData(tag)
            self:triggerBuyBtnCallBack(self.m_currPageIdex, tag)
        elseif name == "btn_set" then
            local p_shopData = globalMachineController.p_fishManiaShopData
            local item = self:getOneCommodityItem(self.m_currPageIdex, tag)
            local data = {
                shopIndex   = self.m_currPageIdex,
                commodityId = item.m_initData.commodityId,
                state = p_shopData.COMMODITYSTATE.SET,
            }
            p_shopData:upDateCommodityCash(data)
            self:updateOneGood(self.m_currPageIdex, tag)
            -- self.m_machine:setLayer_switchSetLayerShow(self.m_currPageIdex, nil, tag)
            self.m_machine:fishToy_playShowAnim(self.m_currPageIdex, nil, tag)

            
            -- 打点
            local commodityData = p_shopData:getCommodityData(self.m_currPageIdex, tag)
            local commodityType = commodityData.type
            local pginfo = {level = self.m_currPageIdex ,Points = p_shopData:getPickScore()}
            local iInfo = {name = commodityType,level = self.m_currPageIdex }
            globalMachineController.p_LogFishManiaShop:sendGameUILog("Shop", "Get", pginfo,nil,iInfo)
        end
    end
end

--[[
    shopType = 1,        商店索引
    buyType   = 1,       商品类型
    --selectSuperFree = 1,  自定义选择的哪个鱼缸 (购买时不使用)

    服务器返回的数据没有标记购买的id需要前端自己存，且无法进行连续购买，必须等待一次购买数据返回后再进行下一次购买
--]]
--数据发送
function FishManiaShopListView:sendBuyData(_index)
    -- 触发了free模式 
    if self.m_machine.m_bProduceSlots_InFreeSpin then
        return
    end
    --正在展示上一个购买物品 (需要连续播放购买物品时注释该条检测)
    if nil ~= self.m_buyData or self.m_machine:isOpenBonusView() then
        return
    end
    
    local p_shopData = globalMachineController.p_fishManiaShopData
    local commodityData = p_shopData:getCommodityData(self.m_currPageIdex, _index)
    --拿商品数据
    if not commodityData then
        return
    end
    local commodityType = commodityData.type
    --检测积分是否充足
    local price  = tonumber(commodityData.price)
    local pickScore = p_shopData:getPickScore()
    if pickScore < price then
        return
    end
    --检测当前进度
    local progress = p_shopData:getShopProgress(self.m_currPageIdex)
    if progress>=1 then
        return
    end
   

    self:setIsCanTouch(false)
    --本次购买会触发superFree时 提前禁用spin按钮
    -- local curspend,allSpend = p_shopData:getShopSpend(self.m_currPageIdex)
    -- if 0 ~= allSpend and (curspend + price)/allSpend >=1 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        self.m_machine.m_shopBar:setIsCanTouch(false)
    -- end

    --存本次购买的商品
    self.m_buyData = {
        isSendNotice = false,
        --
        shopIndex = self.m_currPageIdex,
        commodityType = commodityType,
        price = price
    }

    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {
        msg = MessageDataType.MSG_BONUS_SPECIAL,
        data = {
            pageIndex = self.m_buyData.shopIndex,
            pageCellIndex  = self.m_buyData.commodityType,
        }
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


--接收返回消息
function FishManiaShopListView:featureResultCallFun(param)
    if not self:isVisible() then
        return
    end

    if  param[1] == true then
        local spinData = param[2]
        local selfData = spinData.result.selfData
        -- 更新商店数据
        if (nil ~= self.m_buyData and not self.m_buyData.isSendNotice) and selfData.pickScore then
            self.m_buyData.isSendNotice = true

            local userMoneyInfo = param[3]
            -- 记录下服务器返回赢钱的结果
            self.m_serverWinCoins = spinData.result.winAmount  

            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

            self:upDateShopBuyData(param)
        end

    else

        gLobalViewManager:showReConnect(true)
    end

    self:setIsCanTouch(true)
end
--商品购买返回
function FishManiaShopListView:upDateShopBuyData(_param)
    local _spinData = _param[2]
    local selfData = _spinData.result.selfData

    if selfData.triggerSuperFree then
        --禁止spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    else
        --解开spin按钮
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})
    end
    

    -- 打点
    local pginfo = {level = self.m_buyData.shopIndex ,Points = globalMachineController.p_fishManiaShopData:getPickScore()}
    local iInfo = {name = self.m_buyData.commodityType,level = self.m_buyData.shopIndex }
    globalMachineController.p_LogFishManiaShop:sendGameUILog("Shop", "Buy", pginfo,self.m_buyData.price,iInfo,self.m_serverWinCoins)


    --刷一下单个商品的状态
    local commodityIndex = globalMachineController.p_fishManiaShopData:getCommodityIndex(self.m_buyData.shopIndex, self.m_buyData.commodityType)
    self:updateOneGood(self.m_buyData.shopIndex, commodityIndex)
    --
    local goodsTab = self.m_allGoodsTab[self.m_buyData.shopIndex]
    local goods = goodsTab[commodityIndex]
    local btn_buy = goods:findChild("btn_Buy") 
    local startPos =  btn_buy:getParent():convertToWorldSpace( cc.p(btn_buy:getPosition()) )
    local data = {
        pickScore = selfData.pickScore,
        avgBet    = selfData.avgBet,
        triggerSuperFree = selfData.triggerSuperFree,
        --
        winCoin = self.m_serverWinCoins,
        shopIndex = self.m_buyData.shopIndex,
        commodityType = self.m_buyData.commodityType,
        startPos = startPos,
    }

    
    
    -- self.m_buyData 在这个接口内会清理
    self.m_machine:shopBar_buyUpDateShow(data, _param)

   
end

function FishManiaShopListView:getOneCommodityItem(_shopIndex, _commodityIndex)
    local goodsTab = self.m_allGoodsTab[_shopIndex]
    if goodsTab then
        for _index,_goods in ipairs(goodsTab) do
            if _index == _commodityIndex then
                return _goods
            end
        end
    end
    return nil
end

--[[
    商店引导
]]
function FishManiaShopListView:registerBuyBtnClickCallBack(_fun)
    local registerId = -1
    if "function" ~= type(_fun)  then
        return registerId
    end

    registerId = 0
    while nil ~= self.m_buyBtnCallBackList[registerId] do
        registerId = registerId + 1
    end
    
    self.m_buyBtnCallBackList[registerId] = _fun

    return registerId
end
function FishManiaShopListView:unRegisterBuyBtnClickCallBack(_registerId)
    if nil ~= self.m_buyBtnCallBackList[_registerId] then
        self.m_buyBtnCallBackList[_registerId] = nil
    end
end

function FishManiaShopListView:triggerBuyBtnCallBack(_shopIndex, _commodityIndex)
    for _registerId,_callback in pairs(self.m_buyBtnCallBackList) do
        _callback(_registerId, {_shopIndex, _commodityIndex})
    end
end

return FishManiaShopListView