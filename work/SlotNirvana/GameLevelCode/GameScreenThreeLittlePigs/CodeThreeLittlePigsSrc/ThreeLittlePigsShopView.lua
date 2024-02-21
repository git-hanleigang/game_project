local SendDataManager = require "network.SendDataManager"
local ThreeLittlePigsShopView = class("ThreeLittlePigsShopView", util_require("base.BaseGame"))
function ThreeLittlePigsShopView:initUI(machine)
    self:createCsbNode("ThreeLittlePigs_shangdian.csb")
    self.m_machine = machine
    self.m_isCloseing = false
    --是否正在关闭

    self.m_goodsNameTab = {
        --商品名称
        {"ROOF", "ROOF", "TOP ROOF", "DECOR", "LOGO"},
        {"WALL", "RAFTER", "WINDOW", "WINDOW", "ROOF", "ATTIC", "SEDUM ROOF", "LOGO"},
        {"DOOR", "WINDOW", "WINDOWS", "LIVING ROOM", "BEDROOM", "BEDROOMS", "BALCONY", "WINDOW", "WINDOWS", "PLANTS", "LOGO"}
    }

    self.m_isCanTouch = false
    --界面按钮是否可点击
    self.m_pigShopData = self.m_machine:getPigShopData()
    dump(self.m_pigShopData)
    self.m_totalPageNum = #self.m_pigShopData.levels
    --总页数
    self.m_currPageIdex = 1
    --当前显示的页数
    self.m_houseGoodsNumTab = {}
    --各个页面的商品数量
    for i = 1, self.m_totalPageNum do
        local goodsNum = #self.m_pigShopData.levels[i].cards
        table.insert(self.m_houseGoodsNumTab, goodsNum)
    end
    self.m_sliderBgFileHeight = 0
    --滑动条背景高
    self.m_sliderThumbFileHeight = 0
    --滑动条滑条高
    self.m_sliderCanEvent = true --滑动条事件回调是否生效

    self.m_diandianTab = {}
    for i = 1, self.m_totalPageNum do
        --加页数小点
        local diandian = util_createAnimation("ThreeLittlePigs_shangdian_dian.csb")
        self:findChild("dian_" .. i):addChild(diandian)
        table.insert(self.m_diandianTab, diandian)
    end
    self:setDiandian()

    --创建翻页容器
    self.m_pageView = ccui.PageView:create()
    self.m_pageView:setContentSize(645, 316)
    self.m_scrollviewTab = {}
    --滑动页面对象存储
    self.m_allGoodsTab = {}
    --所有商品对象存储
    self.m_shouTab = {}
    --手对象存储
    self.m_lockTab = {}
    --锁定对象存储
    for i = 1, self.m_totalPageNum do
        local goodsTab = {}
        local layout = ccui.Layout:create()
        self.m_pageView:addPage(layout)

        --创建商品列表
        local scrollview = ccui.ScrollView:create()
        scrollview:setDirection(ccui.ScrollViewDir.vertical)
        scrollview:setBounceEnabled(false)
        scrollview:setScrollBarEnabled(false)
        scrollview:setContentSize(self.m_pageView:getContentSize())

        local goodsPrice = self.m_pigShopData.scoreLimit[i]
        -- local firstGoodPrice = self.m_pigShopData.firstCard
        local goodsData = self.m_pigShopData.levels[i].cards

        --添加商品
        local perRowGoodsNum = 2 --一行放的商品数量
        local leftReservedSpace = 10 --左边预留间隙
        self.m_topReservedSpace = 10
        --上边预留间隙
        local bottomReservedSpace = 10
        --下边预留间隙
        local rowSpace = 10 --行之间的间隙
        local colSpace = 10 --列之间的间隙
        self.m_goodsSize = nil --每个商品的尺寸
        local cerPageHight = nil --本页页面的高

        local totalRows = math.ceil(self.m_houseGoodsNumTab[i] / perRowGoodsNum)
        --本页商品总行数
        for j = 1, self.m_houseGoodsNumTab[i] do
            local goods = util_createAnimation("ThreeLittlePigs_shangdian_item.csb")
            local picName = "common/ThreeLittlePigs_shop_ui_wu" .. i .. "_" .. j .. ".png"
            if j == self.m_houseGoodsNumTab[i] then
                picName = "common/ThreeLittlePigs_shop_ui_wulogo.png"
            end
            util_changeTexture(goods:findChild("goodsPic"), picName) --设置商品图片
            local goodsName = ""
            if self.m_goodsNameTab[i] and self.m_goodsNameTab[i][j] then
                goodsName = self.m_goodsNameTab[i][j]
            end
            goods:findChild("goodsName"):setString(goodsName) --设置商品名称
            goods:findChild("goodsPrice"):setString(goodsPrice)
            --设置商品价格
            -- if j == 1 and i == 1 then
            --     goods:findChild("goodsPrice"):setString(firstGoodPrice)
            -- end
            goods:findChild("btn_2"):setTag(j)
            if j == 1 then
                self.m_goodsSize = goods:findChild("bg"):getContentSize()
                cerPageHight = totalRows * self.m_goodsSize.height + (totalRows - 1) * rowSpace + self.m_topReservedSpace + bottomReservedSpace
                if cerPageHight < scrollview:getContentSize().height then
                    cerPageHight = scrollview:getContentSize().height
                end
            end
            goods.clickFunc = function(target, sender)
                local name = sender:getName()
                local tag = sender:getTag()
                self:clickFunc(sender)
            end

            scrollview:addChild(goods)

            local posx = ((j - 1) % perRowGoodsNum) * (self.m_goodsSize.width + colSpace) + leftReservedSpace
            local posy = cerPageHight - self.m_topReservedSpace - (math.ceil(j / perRowGoodsNum) * self.m_goodsSize.height + (math.ceil(j / perRowGoodsNum) - 1) * rowSpace)
            goods:setPosition(cc.p(posx, posy))

            table.insert(goodsTab, goods)
        end
        scrollview:setInnerContainerSize(cc.size(scrollview:getContentSize().width, cerPageHight))
        layout:addChild(scrollview)

        table.insert(self.m_scrollviewTab, scrollview)

        if cerPageHight > scrollview:getContentSize().height then
            -- 添加进度条
            local bgFile = util_createSprite("common/ThreeLittlePigs_shop_huadongdi.png")
            local progressFile = util_createSprite("common/ThreeLittlePigs_shop_huadongdi.png")
            local thumbFile = util_createSprite("common/ThreeLittlePigs_shop_huadongtiao.png")

            self.m_sliderBgFileHeight = bgFile:getContentSize().width - 60
            self.m_sliderThumbFileHeight = thumbFile:getContentSize().width * 0.8
            thumbFile:setScale(0.8)
            progressFile:setVisible(false)
            local slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
            slider:setPosition(scrollview:getContentSize().width - 20, scrollview:getContentSize().height / 2)
            slider:setAnchorPoint(cc.p(0.5, 0.5))
            slider:setRotation(90)
            slider:setEnabled(true)
            slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
            slider:setMinimumValue(0)
            slider:setMaximumValue(1)
            slider:setValue(self:scrolledPercentChangeToSliderPercent(0))
            layout:addChild(slider, 1, i)

            scrollview:onScroll(
                function(data)
                    if data.name == "CONTAINER_MOVED" then
                        self.m_moveSlider = false
                        if self.m_moveTable == true then
                            local percent = scrollview:getScrolledPercentVertical()
                            if slider ~= nil then
                                slider:setValue(self:scrolledPercentChangeToSliderPercent(percent))
                            end
                        end
                        self.m_moveSlider = true
                    end
                end
            )
        end
        table.insert(self.m_allGoodsTab, goodsTab)

        --添加手
        local shou = util_createAnimation("ThreeLittlePigs_shangdian_shou.csb")
        scrollview:addChild(shou)
        shou:playAction("actionframe", true)
        table.insert(self.m_shouTab, shou)
        shou:setVisible(false)

        --添加锁定界面
        local lock = util_createAnimation("ThreeLittlePigs_shangdian_suoding.csb")
        layout:addChild(lock)
        lock:setPosition(cc.p(layout:getContentSize().width / 2, layout:getContentSize().height / 2 - self:findChild("pageNode"):getPositionY()))
        lock:setVisible(false)
        table.insert(self.m_lockTab, lock)

        self:updateGoodsAtPageIndex(i)

        if self.m_pigShopData.levels[i].unlock == true then
            for j, data in ipairs(goodsData) do
                if data.unlock == true and data.purchase == false then
                    local posY = scrollview:getContentSize().height - (self.m_allGoodsTab[i][j]:getPositionY() + self.m_goodsSize.height + self.m_topReservedSpace)
                    if posY > 0 then
                        posY = 0
                    end
                    scrollview:setInnerContainerPosition(cc.p(0, posY))
                    self.m_moveSlider = nil
                    break
                end
            end
        end
    end

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true

    self:findChild("pageNode"):addChild(self.m_pageView)

    self.m_pageView:setTouchEnabled(true)
    self.m_pageView:setAnchorPoint(cc.p(0.5, 0.5))

    util_setCascadeOpacityEnabledRescursion(self, true)
    self:runCsbAction(
        "show",
        false,
        function()
            self.m_isCanTouch = true
        end
    )

    local currChooseHouseIdx = gLobalDataManager:getNumberByField("ThreeLittlePigs_chooseHouseIdx", 1)
    self:setPageIndex(currChooseHouseIdx, false)
end
--刷新某一页商品图标
function ThreeLittlePigsShopView:updateGoodsAtPageIndex(pageIndex)
    local goodsData = self.m_pigShopData.levels[pageIndex].cards
    self.m_shouTab[pageIndex]:setVisible(false)
    if self.m_pigShopData.levels[pageIndex].unlock == false then
        self.m_lockTab[pageIndex]:setVisible(true)
    else
        self.m_lockTab[pageIndex]:setVisible(false)
    end
    for i, data in ipairs(goodsData) do
        if data.unlock == false then --是否解锁
            self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setTouchEnabled(false)
            self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setBright(false)
            util_setChildNodeOpacity(self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):getRendererDisabled(), 100)
            self.m_allGoodsTab[pageIndex][i]:playAction("idle1")
        else
            if data.purchase == false then --是否已购买
                local limitMoney = self.m_pigShopData.scoreLimit[pageIndex]
                -- if #goodsData == 5 and i==1 and not self.m_finshFirstPurchase then
                --     limitMoney = self.m_pigShopData.firstCard
                -- end

                if self.m_pigShopData.scoreTotal >= limitMoney then
                    self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setTouchEnabled(true)
                    self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setBright(true)
                    util_setChildNodeOpacity(self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):getRendererDisabled(), 255)
                    self.m_allGoodsTab[pageIndex][i]:playAction("idle1")
                    self.m_shouTab[pageIndex]:setVisible(true)
                    local worldPos = self.m_allGoodsTab[pageIndex][i]:findChild("shou"):getParent():convertToWorldSpace(cc.p(self.m_allGoodsTab[pageIndex][i]:findChild("shou"):getPosition()))
                    local pos = self.m_shouTab[pageIndex]:getParent():convertToNodeSpace(worldPos)
                    self.m_shouTab[pageIndex]:setPosition(pos)
                else
                    --钱不够
                    self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setTouchEnabled(false)
                    self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setBright(false)
                    util_setChildNodeOpacity(self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):getRendererDisabled(), 100)
                    self.m_allGoodsTab[pageIndex][i]:playAction("idle1")
                end
            else
                self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setTouchEnabled(false)
                self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):setBright(false)
                util_setChildNodeOpacity(self.m_allGoodsTab[pageIndex][i]:findChild("btn_2"):getRendererDisabled(), 100)
                self.m_allGoodsTab[pageIndex][i]:playAction("idle2")
            end
        end
    end
end
--将滚动容器的进度转换为滑动条的进度
function ThreeLittlePigsShopView:scrolledPercentChangeToSliderPercent(percent)
    return ((self.m_sliderBgFileHeight - self.m_sliderThumbFileHeight) * percent / 100 + self.m_sliderThumbFileHeight / 2) / self.m_sliderBgFileHeight
end
--将滑动条的进度转换为滚动容器的进度
function ThreeLittlePigsShopView:sliderPercentChangeToScrolledPercent(percent)
    return (self.m_sliderBgFileHeight * percent - self.m_sliderThumbFileHeight / 2) / (self.m_sliderBgFileHeight - self.m_sliderThumbFileHeight) * 100
end
function ThreeLittlePigsShopView:clickFunc(sender)
    if self.m_machine.m_hummerAnimationOver == false then
        return
    end

    if self.m_isCanTouch then
        local name = sender:getName()
        local tag = sender:getTag()
        if name == "btn_left" then
            self:toPreviousPage()
        elseif name == "btn_right" then
            self:toNextPage()
        else
            --点击的购买按钮
            gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_shopClicked.mp3")
            sender:setTouchEnabled(false)

            if self.m_pigShopData.scoreTotal >= self.m_pigShopData.scoreLimit[self.m_currPageIdex] then
                self:sendData(tag)
                self.m_shouTab[self.m_currPageIdex]:setVisible(false)
            end
        end
    end
end
--设置界面按钮是否可点击
function ThreeLittlePigsShopView:setIsCanTouch(isCan)
    self.m_isCanTouch = isCan
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, self.m_isCanTouch})
    gLobalNoticManager:postNotification("CodeGameScreenThreeLittlePigsMachine_setShangdianTouchEnabled", {self.m_isCanTouch})
end
--设置是否可购买
function ThreeLittlePigsShopView:setIsCanBuy(isCan)
    if self.m_isCloseing then
        return
    end
    self.m_isCanTouch = isCan
end
--去下一页
function ThreeLittlePigsShopView:toNextPage()
    local nextPageIdex = self.m_currPageIdex + 1
    if nextPageIdex > self.m_totalPageNum then
        return
    end
    self:setPageIndex(nextPageIdex, true)

    self.m_machine:updateHummerStatus(nextPageIdex)
end
--去上一页
function ThreeLittlePigsShopView:toPreviousPage()
    local previousPageIdex = self.m_currPageIdex - 1
    if previousPageIdex < 1 then
        return
    end
    self:setPageIndex(previousPageIdex, true)
    self.m_machine:updateHummerStatus(previousPageIdex)
end
--设置点点的显示
function ThreeLittlePigsShopView:setDiandian()
    for i, diandian in ipairs(self.m_diandianTab) do
        if i == self.m_currPageIdex then
            diandian:findChild("dian"):setVisible(true)
        else
            diandian:findChild("dian"):setVisible(false)
        end
    end
end
--设置按钮的显示
function ThreeLittlePigsShopView:setLeftRightButton()
    self:findChild("btn_left"):setVisible(true)
    self:findChild("btn_right"):setVisible(true)
    if self.m_currPageIdex >= self.m_totalPageNum then
        self:findChild("btn_right"):setVisible(false)
    end
    if self.m_currPageIdex <= 1 then
        self:findChild("btn_left"):setVisible(false)
    end
end
--将页面设置到某一页
function ThreeLittlePigsShopView:setPageIndex(index, isPlayAction, isCallMachine)
    self.m_currPageIdex = index
    if isCallMachine == nil then
        isCallMachine = true
    end
    self:setDiandian()
    self:setLeftRightButton()
    if isPlayAction then
        gLobalSoundManager:playSound("ThreeLittlePigsSounds/music_ThreeLittlePigs_chooseHouse.mp3")
        gLobalDataManager:setNumberByField("ThreeLittlePigs_chooseHouseIdx", self.m_currPageIdex, true)
        self.m_pageView:scrollToItem(self.m_currPageIdex - 1)
    else
        self.m_pageView:setCurrentPageIndex(self.m_currPageIdex - 1)
    end
    if isCallMachine == true then
        gLobalNoticManager:postNotification("CodeGameScreenThreeLittlePigsMachine_chooseHouse", {self.m_currPageIdex})
    end
end
function ThreeLittlePigsShopView:onEnter()
    ThreeLittlePigsShopView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeSelf()
        end,
        "ThreeLittlePigsShopView_closeSelf"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setIsCanTouch(params[1])
        end,
        "ThreeLittlePigsShopView_setIsCanTouch"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:setIsCanBuy(params[1])
        end,
        "ThreeLittlePigsShopView_setIsCanBuy"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateBuyGoods(params[1])
        end,
        "ThreeLittlePigsShopView_updateBuyGoods"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:buySuccess()
        end,
        "ThreeLittlePigsShopView_buySuccess"
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_GET_SPINRESULT)
        end,
        "ThreeLittlePigsShopView_removeGetSpinresult"
    )
end

function ThreeLittlePigsShopView:closeSelf()
    self.m_isCloseing = true
    self.m_isCanTouch = false
    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_GET_SPINRESULT)
    self:runCsbAction(
        "over",
        false,
        function()
            gLobalNoticManager:postNotification("CodeGameScreenThreeLittlePigsMachine_closeShopViewEnd")
        end
    )
end

function ThreeLittlePigsShopView:onExit()
    ThreeLittlePigsShopView.super.onExit(self)
end

-- slider 滑动事件 --
function ThreeLittlePigsShopView:sliderMoveEvent(slider)
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
        self.m_scrollviewTab[slider:getTag()]:scrollToPercentVertical(self:sliderPercentChangeToScrolledPercent(sliderOff), 0.2, false)
    end
    self.m_moveTable = true
end

--数据发送
function ThreeLittlePigsShopView:sendData(cardIdx)
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = {pageIndex = self.m_currPageIdex, pageCellIndex = cardIdx}}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
    self:setIsCanTouch(false)
end
--接收返回消息
function ThreeLittlePigsShopView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果

        self.m_totleWimnCoins = spinData.result.winAmount

        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        self.m_spinDataResult = spinData.result
        if self.m_spinDataResult.selfData and self.m_spinDataResult.selfData.pigShop then
            self.m_pigShopData = self.m_spinDataResult.selfData.pigShop
        end
        self.m_machine:SpinResultParseResultData(spinData)

        self.m_machine:updateHummerStatus(self.m_machine.m_housePageView:getCurrentPageIndex() + 1)
        gLobalNoticManager:postNotification("CodeGameScreenThreeLittlePigsMachine_buySuccessUpdate", {self.m_currPageIdex})
    else
        -- 处理消息请求错误情况
        self:setIsCanTouch(true)
        self:updateGoodsAtPageIndex(self.m_currPageIdex)
    end
end
--更新购买商品的显示状态
function ThreeLittlePigsShopView:updateBuyGoods(goodsIdx)
    if self.m_allGoodsTab[self.m_currPageIdex][goodsIdx] then
        self.m_allGoodsTab[self.m_currPageIdex][goodsIdx]:playAction("dianji")
    end
end
--购买一个商品成功
function ThreeLittlePigsShopView:buySuccess()
    for i = 1, self.m_totalPageNum do
        self:updateGoodsAtPageIndex(i)

        local goodsData = self.m_pigShopData.levels[i].cards
        local scrollview = self.m_scrollviewTab[i]
        if self.m_pigShopData.levels[i].unlock == true then
            for j, data in ipairs(goodsData) do
                if data.unlock == true and data.purchase == false then
                    if self.m_allGoodsTab[i][j]:getPositionY() < math.abs(scrollview:getInnerContainerPosition().y) then
                        local posY = scrollview:getContentSize().height - (self.m_allGoodsTab[i][j]:getPositionY() + self.m_goodsSize.height + self.m_topReservedSpace)
                        if posY > 0 then
                            posY = 0
                        end
                        local minY = scrollview:getContentSize().height - scrollview:getInnerContainerSize().height
                        local percent = (posY - minY) / (-minY) * 100
                        scrollview:scrollToPercentVertical(percent, 0.2, false)
                    end
                    break
                end
            end
        end
    end
    self:setIsCanTouch(true)
end
return ThreeLittlePigsShopView
