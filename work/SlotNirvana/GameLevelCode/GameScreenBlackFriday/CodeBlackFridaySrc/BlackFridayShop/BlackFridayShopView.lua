---
--xcyy
--2018年5月23日
--BlackFridayShopView.lua
local SendDataManager = require "network.SendDataManager"
local BlackFridayShopView = class("BlackFridayShopView",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_LEFT          = 1001              --左翻页
local BTN_TAG_RIGHT         = 1002              --右翻页
local BTN_TAG_CLOSE         = 9999              --关闭

local SHOP_ITEM_TAG         = 2001

function BlackFridayShopView:initUI(params)
    self.m_machine = params.machine
    self.m_isTriggerSuper = false

    self.m_clickPosAry = {}
    self.m_pageNode = {}
    self.m_pageCells = {}
    self.m_tipsList = {}--存9个金币不足标签

    self:createCsbNode("BlackFriday/ShopBlackFriday.csb")
    self:setVisible(false)

    self:findChild("Button_left"):setTag(BTN_TAG_LEFT)
    self:findChild("Button_right"):setTag(BTN_TAG_RIGHT)
    self:findChild("Button_back"):setTag(BTN_TAG_CLOSE)

    for i=1,5 do
        --下面翻页 的小球
        self.m_pageNode[i] = util_createAnimation("BlackFriday_shop_page.csb")
        self:findChild("Node_page"..i):addChild(self.m_pageNode[i])
        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_page"..i), true)
        util_setCascadeColorEnabledRescursion(self:findChild("Node_page"..i), true)
    end

    for pageIndex = 1, 5 do
        local pageNode = util_createAnimation("BlackFriday_shop_shangpin_page.csb")
        for index = 1,9 do
            local shopItem = util_createView("CodeBlackFridaySrc.BlackFridayShop.BlackFridayShopItem",{parent = self,index = index})
            pageNode:findChild("Node_shangpin"..index):addChild(shopItem)
            shopItem:setTag(SHOP_ITEM_TAG)
        end
        self:findChild("pageNode"):addChild(pageNode)
        self.m_pageCells[pageIndex] = pageNode
    end
    util_setCascadeOpacityEnabledRescursion(self:findChild("pageNode"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("pageNode"), true)
    
    --super free类型
    self.m_superType = util_createAnimation("BlackFriday_shop_xiaoqipan.csb")
    self:findChild("Node_xiaoqipan"):addChild(self.m_superType)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_xiaoqipan"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_xiaoqipan"), true)

    --金币栏
    self.m_coinsBar = util_createAnimation("BlackFriday_shop.csb")
    self:findChild("Node_shop"):addChild(self.m_coinsBar)
    -- 修改透明度 不然不会随着根节点变化
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_shop"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_shop"), true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_shop_0"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_shop_0"), true)

    --折扣标签
    self.m_discountBar = util_createAnimation("BlackFriday_off.csb")
    self:findChild("Node_off"):addChild(self.m_discountBar)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_off"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_off"), true)

    for tipsIndex = 1, 9 do
        --金币不足标签
        local tips = util_createAnimation("BlackFriday_shop_tips.csb")
        self:addChild(tips)
        tips:setVisible(false)
        self.m_tipsList[tipsIndex] = tips
    end

    --隐藏标签用
    -- self:addClick(self:findChild("zhezhao"))

    --点击事件 滑动用
    self:addClick(self:findChild("moveClick"))
end

function BlackFridayShopView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

--[[
    显示金币不足标签
]]
function BlackFridayShopView:showCoinNotEnough(_clickPos,_isHide,_isLocked)
    if self.m_curClickPos and self.m_tipsList[self.m_curClickPos]:isVisible() then
        -- 点击同一个位置
        if self.m_curClickPos == _clickPos then
            return
        end
    end

    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    if self.m_curClickPos and self.m_tipsList[self.m_curClickPos]:isVisible() then
        local lastClickPos = clone(self.m_curClickPos)
        self.m_tipsList[lastClickPos]:runCsbAction("over",false, function()
            self.m_tipsList[lastClickPos]:setVisible(false)
        end)
    end
    if _clickPos == nil then
        return
    end

    self.m_curClickPos = _clickPos
    --设置标签位置
    local shopItem = self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin".._clickPos):getChildByTag(SHOP_ITEM_TAG)    
    if shopItem then
        local pos = util_convertToNodeSpace(shopItem:findChild("Node_tips"),self)
        self.m_tipsList[self.m_curClickPos]:setPosition(pos)
        self.m_tipsList[self.m_curClickPos]:setVisible(true)
        if _isLocked then
            self.m_tipsList[self.m_curClickPos]:findChild("tip"):setVisible(false)
            self.m_tipsList[self.m_curClickPos]:findChild("tip_0"):setVisible(true)
        else
            self.m_tipsList[self.m_curClickPos]:findChild("tip"):setVisible(true)
            self.m_tipsList[self.m_curClickPos]:findChild("tip_0"):setVisible(false)
        end
        self.m_tipsList[self.m_curClickPos]:runCsbAction("start",false, function()
            self.m_tipsList[self.m_curClickPos]:runCsbAction("idle",true)
        end)
        self.m_scheduleId = schedule(self, function(  )

            if self.m_scheduleId then
                self:stopAction(self.m_scheduleId)
                self.m_scheduleId = nil
            end

            self.m_tipsList[self.m_curClickPos]:runCsbAction("over",false, function()
                self.m_tipsList[self.m_curClickPos]:setVisible(false)
            end)
        end, 3)
    end
end

--[[
    点击的时候 检查一下
]]
function BlackFridayShopView:cheakIsCanClick(_func)
    -- 正在移动 不能操作
    if self.m_isMoved then
        return
    end
    self:showCoinNotEnough(nil,true,false)
    --已经触发superfree后不允许点击按钮
    if self.m_isTriggerSuper then
        return
    end

    -- 正在播放关闭动画 不可点击
    if self.m_isPlayCloseView then
        return 
    end

    if self.m_isWaiting then
        return
    end

    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    if self.m_curClickPos and self.m_tipsList[self.m_curClickPos]:isVisible() then
        self.m_tipsList[self.m_curClickPos]:runCsbAction("over",false, function()
            self.m_tipsList[self.m_curClickPos]:setVisible(false)
        end)
    end

    if _func then
        _func()
    end
end
--默认按钮监听回调
function BlackFridayShopView:clickFunc(sender)
    local name = sender:getName()
    local btnTag = sender:getTag()

    self:cheakIsCanClick(function()
        if btnTag == BTN_TAG_LEFT then --左翻页
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)
            self.m_curPageIndex = self.m_curPageIndex - 1
            if self.m_curPageIndex < 1 then
                self.m_curPageIndex = 5
            end
            self:refreshView(nil,-1)
        elseif btnTag == BTN_TAG_RIGHT then --右翻页
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)
            self.m_curPageIndex = self.m_curPageIndex + 1
            if self.m_curPageIndex > 5 then
                self.m_curPageIndex = 1
            end
            self:refreshView(nil,1)
        elseif btnTag == BTN_TAG_CLOSE then --关闭
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)
            self.m_isPlayCloseView = true
            self.m_isWaiting = true
            self.m_machine:checkTriggerOrInSpecialGame(function(  )
                self.m_machine:reelsDownDelaySetMusicBGVolume( ) 
            end)
    
            self:hideView()
        end
    end)
end

--默认按钮监听回调 滑动
function BlackFridayShopView:clickEndFunc(sender)
    
    local name = sender:getName()
    local btnTag = sender:getTag()

    if name == "moveClick" then
        self:onMoveClickCallBack(sender)
    end
end

--[[
    滑动背景
]]
--左右滑动切换背景和商店
function BlackFridayShopView:onMoveClickCallBack(_sender)
    if self.m_isTriggerSuper then
        return
    end

    -- 正在播放关闭动画 不可点击
    if self.m_isPlayCloseView then
        return 
    end

    -- 正在移动 不能操作
    if self.m_isMoved then
        return
    end

    if self.m_isWaiting then
        return
    end

    local beginPos = _sender:getTouchBeganPosition()
    local endPos = _sender:getTouchEndPosition()
    local offPosX = endPos.x - beginPos.x
    if math.abs(offPosX) <= 50 then
        return
    end

    if self.m_scheduleId then
        self:stopAction(self.m_scheduleId)
        self.m_scheduleId = nil
    end

    if self.m_curClickPos and self.m_tipsList[self.m_curClickPos]:isVisible() then
        self.m_tipsList[self.m_curClickPos]:runCsbAction("over",false, function()
            self.m_tipsList[self.m_curClickPos]:setVisible(false)
        end)
    end

    local offsetValue = offPosX > 0 and -1 or 1
    -- 表示往右滑动
    if offsetValue == 1 then
        self.m_curPageIndex = self.m_curPageIndex + 1
        if self.m_curPageIndex > 5 then
            self.m_curPageIndex = 1
        end
        self:refreshView(nil,1)
    -- 表示往左滑动
    else
        self.m_curPageIndex = self.m_curPageIndex - 1
        if self.m_curPageIndex < 1 then
            self.m_curPageIndex = 5
        end
        self:refreshView(nil,-1)
    end
end

--[[
    刷新界面 _isComeIn 打开商店进来的
]]
function BlackFridayShopView:refreshView(_isSuperFreeBack, _direction, _isComeIn)
    self.m_clickPos = nil

    local shopConfig = self.m_machine.m_shopConfig

    --当前页是否锁定
    self.m_isLocked = not shopConfig.finished[self.m_curPageIndex]

    -- 显示商店下方的5个 page 点
    for index = 1,5 do
        self.m_pageNode[index]:findChild("liang"):setVisible(index == self.m_curPageIndex)
        self.m_superType:findChild("Node_"..index):setVisible(index == self.m_curPageIndex)
    end

    -- self:findChild("Button_left"):setVisible(self.m_curPageIndex ~= 1)
    -- self:findChild("Button_right"):setVisible(self.m_curPageIndex ~= 5)

    self:updateCoins(_isComeIn)

    --构造当前页数据
    local curShopPageData = {
        cost = shopConfig.cost[self.m_curPageIndex],
        shop = shopConfig.shop[self.m_curPageIndex],
        shopCoins = shopConfig.shopCoins[self.m_curPageIndex],
        coins = shopConfig.coins,
        isLocked = self.m_isLocked,
        extraPickPos = shopConfig.extraPickPos,
        features = shopConfig.features or 0,
        extraPick = shopConfig.extraPick or false
    }
    --刷新商店道具
    for index = 1,9 do
        local shopItem = self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin"..index):getChildByTag(SHOP_ITEM_TAG)    
        if shopItem then
            shopItem:refreshUI(curShopPageData, _isSuperFreeBack, index == 9)
        end
    end
    if _isSuperFreeBack then
        self.m_machine:waitWithDelay(30/60,function()
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_jiesuo)
        end)
    end

    self:moveNodeCells(_direction)
end

-- 翻页 --
function BlackFridayShopView:moveNodeCells(_direction)
    if not _direction then
        return
    end

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_qiehuan_page)

    self.m_isMoved = true
    local lastPageIndex = self.m_curPageIndex-_direction
    if  _direction == 1 then
        if self.m_curPageIndex == 1 then
            lastPageIndex = 5
        end
    end

    if  _direction == -1 then
        if self.m_curPageIndex == 5 then
            lastPageIndex = 1
        end
    end

    self.m_pageCells[self.m_curPageIndex]:setPosition(display.width * _direction, 0)

    local moveTo1 = cc.MoveTo:create(0.4,cc.p(display.width * -_direction, 0))
    local callfunc = cc.CallFunc:create(function()
        self.m_isMoved = false
        self.m_pageCells[lastPageIndex]:setVisible(false)

    end)

    local seq = cc.Sequence:create(moveTo1, callfunc)
    self.m_pageCells[lastPageIndex]:runAction(seq)

    self.m_pageCells[self.m_curPageIndex]:setVisible(true)

    local moveTo2 = cc.MoveTo:create(0.4,cc.p(0, 0))
    self.m_pageCells[self.m_curPageIndex]:runAction(moveTo2)
end

--[[
    刷新金币
]]
function BlackFridayShopView:updateCoins(_isComeIn)
    local shopConfig = self.m_machine.m_shopConfig
    local coins = shopConfig.coins
    self.m_coinsBar:findChild("m_lb_coins"):setString(util_formatCoins(coins,11))
    self:updateLabelSize({label=self.m_coinsBar:findChild("m_lb_coins"),sx=1,sy=1},150)

    --构造当前页数据
    local curShopPageData = {
        cost = shopConfig.cost[self.m_curPageIndex],
        shop = shopConfig.shop[self.m_curPageIndex],
        shopCoins = shopConfig.shopCoins[self.m_curPageIndex],
        coins = shopConfig.coins,
        isLocked = self.m_isLocked,
        extraPickPos = shopConfig.extraPickPos,
        features = shopConfig.features or 0,
        extraPick = shopConfig.extraPick or false
    }

    --刷新商店道具
    for index = 1,9 do
        local shopItem = self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin"..index):getChildByTag(SHOP_ITEM_TAG)    
        if shopItem then
            if self.m_clickPos and self.m_clickPos == index then
            else
                shopItem:refreshUIPrice(curShopPageData, _isComeIn)
            end
        end
    end
end

--[[
    显示界面
]]
function BlackFridayShopView:showView(_isSuperFreeBack)
    self:setVisible(true)

    self.m_clickPosAry = {}

    self.m_isTriggerSuper = false

    self.m_isPlayCloseView = true

    self.m_isWaiting = false

    self.m_clickPos = nil

    local shopConfig = self.m_machine.m_shopConfig
    
    -- 记录折扣 是否存在
    self.m_isZheKou = self.m_machine.m_shopConfig.discountTime > 0 and true or false
    if not self.m_isZheKou then
        self.m_discountBar:runCsbAction("idle",false)
    else
        self.m_discountBar:runCsbAction("idle1",false)
    end

    self:changeCoinNodeParent()

    if not shopConfig.firstRound then
        if not self.m_curPageIndex then
            --计算当前页
            self.m_curPageIndex = 1
        end
    else
        --计算当前页
        self.m_curPageIndex = 1
        for index , isFinished in ipairs(shopConfig.finished) do
            if isFinished and index > self.m_curPageIndex then
                self.m_curPageIndex = index
            end
        end
    end

    self:showCurPage(self.m_curPageIndex)

    self:refreshView(_isSuperFreeBack, nil, true)

    self.m_machine:removeSoundHandler()
    self.m_machine:resetMusicBg(false,"BlackFridaySounds/music_BlackFriday_shop.mp3")

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_start)

    self:runCsbAction("start",false, function()

        self.m_isPlayCloseView = false

        self:runCsbAction("idle",true)
        self.m_coinsBar:runCsbAction("idle",true)
    end)
end

--[[
    关闭界面
]]
function BlackFridayShopView:hideView(_func)
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_over)

    self:runCsbAction("over",false, function()
        self:setVisible(false)
        self.m_machine:resetMusicBg()

        if _func then
            _func()
        end
    end)
    
end

--[[
    点击商店道具
]]
function BlackFridayShopView:clickItem(_clickPos)
    self:sendData(_clickPos)
end

--[[
    数据发送
]]
function BlackFridayShopView:sendData(_clickPos)
    if self.m_isWaiting then
        return
    end

    if self.m_machine.m_shopConfig.shop[self.m_curPageIndex][_clickPos] == 1 then
        return
    end

    -- 加个判断 未解锁的话 防止报错
    if self.m_machine.m_shopConfig.finished[self.m_curPageIndex] == false then
        return
    end

    --防止连续点击
    self.m_isWaiting = true
    self.m_clickPos = _clickPos
    local data = {self.m_curPageIndex - 1, _clickPos - 1}
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = data, clickPos = _clickPos - 1}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function BlackFridayShopView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        if spinData and spinData.action == "SPECIAL" then
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        
            self:recvBaseData(spinData.result)
        end
    else
        gLobalViewManager:showReConnect()
    end
end


--[[
    接收数据
]]
function BlackFridayShopView:recvBaseData(_featureData)
    if not self:isVisible() then
        return
    end
    
    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.m_machine.m_shopConfig.finished = _featureData.selfData.finished
    self.m_machine.m_shopConfig.shop = _featureData.selfData.shop
    self.m_machine.m_shopConfig.shopCoins = _featureData.selfData.shopCoins
    self.m_machine.m_shopConfig.coins = _featureData.selfData.coins
    self.m_machine.m_shopConfig.firstRound = _featureData.selfData.firstRound
    self.m_machine.m_shopConfig.features = _featureData.features[2] or 0
    self.m_machine.m_runSpinResultData.p_selfMakeData = _featureData.selfData
    self.m_machine:refreshShopScore()
    -- 判断下次 购买 是否免费
    if _featureData.selfData.shopCoins[self.m_curPageIndex][self.m_clickPos] == "extraPick" then
        self.m_machine.m_shopConfig.extraPick[self.m_curPageIndex] = true
        if self.m_machine.m_shopConfig.extraPickPos then
            self.m_machine.m_shopConfig.extraPickPos[self.m_curPageIndex][1] = self.m_curPageIndex - 1
            self.m_machine.m_shopConfig.extraPickPos[self.m_curPageIndex][2] = self.m_clickPos - 1
        else
            self.m_machine.m_shopConfig.extraPickPos = {}
            self.m_machine.m_shopConfig.extraPickPos[self.m_curPageIndex] = {}
            self.m_machine.m_shopConfig.extraPickPos[self.m_curPageIndex][1] = self.m_curPageIndex - 1
            self.m_machine.m_shopConfig.extraPickPos[self.m_curPageIndex][2] = self.m_clickPos - 1
        end
    else
        self.m_machine.m_shopConfig.extraPick[self.m_curPageIndex] = false
    end

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_click_fankui)

    if _featureData.features[2] and _featureData.features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        self.m_isTriggerSuper = true
        local shopConfig = self.m_machine.m_shopConfig
        local coins = shopConfig.coins
        self.m_coinsBar:findChild("m_lb_coins"):setString(util_formatCoins(coins,11))
        self:updateLabelSize({label=self.m_coinsBar:findChild("m_lb_coins"),sx=1,sy=1},150)

    else
        self:updateCoins()
    end 

    local selfData = _featureData.selfData
    if selfData and selfData.pickResult then
        self.m_clickPosAry[#self.m_clickPosAry + 1] = selfData.pickResult[#selfData.pickResult][2] + 1
    end

    self:updateClickPosReward(_featureData.selfData.pickResult, _featureData.selfData, _featureData, function()

        if _featureData.features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
            --触发free时只更新点击位置的奖励
            self.m_isTriggerSuper = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
            
            self:hideView(function()
                self.m_isWaiting = false

                self.m_machine.m_runSpinResultData:parseResultData(_featureData, self.m_machine.m_lineDataPool)
                self.m_machine:triggerSuperFree()
            end)
        end
    end)
end

--[[
    更新点击位置的奖励
]]
function BlackFridayShopView:updateClickPosReward(_rewardData, _selfData, _featureData, _func)
    local featureDataList = clone(_featureData)
    local reward = _rewardData[#_rewardData - 1]
    local clickPos = _rewardData[#_rewardData][2] + 1
    --当前页数不符
    if self.m_curPageIndex ~= _rewardData[#_rewardData][1] + 1 then
        return
    end

    --设置标签位置
    local shopItem = self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin"..clickPos):getChildByTag(SHOP_ITEM_TAG) 
    if #_rewardData > 2 and _rewardData[2] > 1 then
        shopItem:updateReward(_rewardData[1], true, function()
            local startpos = 1
            local shopConfig = self.m_machine.m_shopConfig
            if shopConfig.extraPickPos and shopConfig.extraPickPos[self.m_curPageIndex] and shopConfig.extraPickPos[self.m_curPageIndex][2] then
                startpos = shopConfig.extraPickPos[self.m_curPageIndex][2] + 1
            end

            self:collectChengBeiFly(startpos, clickPos, function()
                if _featureData.features[2] ~= SLOTO_FEATURE.FEATURE_FREESPIN then
                    self.m_isWaiting = false
                end
                shopItem:updateReward(reward, false, function()
                    self:flyCollectWinCois(reward, shopItem, function()
                        if _func then
                            _func()
                        end
                    end)
                end)
            end)
        end)
    else  
        if reward ~= "extraPick" then
            shopItem:updateReward(reward, true, function()
                if _featureData.features[2] ~= SLOTO_FEATURE.FEATURE_FREESPIN then
                    self.m_isWaiting = false
                end
                self:flyCollectWinCois(reward, shopItem, function()
                    if _func then
                        _func()
                    end
                end)
            end)
        else
            shopItem:updateReward(reward, true, function()
                if _featureData.features[2] ~= SLOTO_FEATURE.FEATURE_FREESPIN then
                    self.m_isWaiting = false
                end
                if _func then
                    _func()
                end
            end)
        end
    end
end

--[[
    赢钱飞到 底部赢钱区
]]
function BlackFridayShopView:flyCollectWinCois(_score,_startNode,_func) 
    local flyNode = util_createAnimation("BlackFriday_shop_qian.csb")

    flyNode:findChild("m_lb_num"):setString(util_formatCoins(_score,3))
    self:updateLabelSize({label=flyNode:findChild("m_lb_num"),sx=1,sy=1},125)
    flyNode:findChild("zi"):setVisible(false)

    local startPos = util_convertToNodeSpace(_startNode,self)
    local moveEndPos = cc.p(0,0)
    local endPos = util_convertToNodeSpace(self.m_machine.m_bottomUI.m_normalWinLabel, self)

    self:addChild(flyNode)
    flyNode:setPosition(startPos)
    flyNode:runCsbAction("fly",false)

    -- 第一阶段飞 到底部
    local seq = cc.Sequence:create({
        cc.DelayTime:create(25/60),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_coins_fly)
        end),
        cc.EaseQuarticActionIn:create(cc.MoveTo:create(35/60,endPos)),
        cc.CallFunc:create(function()

            self.m_machine:playhBottomLight(_score, function()
                if type(_func) == "function" then
                    _func()
                end
            end)
            
            flyNode:removeFromParent()
            flyNode = nil
        end),
    })

    flyNode:runAction(seq)
end

-- 成倍飞
function BlackFridayShopView:collectChengBeiFly(_startpos, _endPos, _func)
    local shopItem = self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin".._startpos):getChildByTag(SHOP_ITEM_TAG)
    shopItem.m_winCoinsNode:runCsbAction("idle",false)

    local flyNode = util_createAnimation("BlackFriday_shop_qian.csb")
    self:addChild(flyNode)
    flyNode:findChild("m_lb_num"):setVisible(false)
    flyNode:runCsbAction("idle",false)

    local startWorldPos = self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin".._startpos):getParent():convertToWorldSpace(cc.p(self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin".._startpos):getPosition()))
    local startPos = self:convertToNodeSpace(startWorldPos)
    local endWorldPos = self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin".._endPos):getParent():convertToWorldSpace(cc.p(self.m_pageCells[self.m_curPageIndex]:findChild("Node_shangpin".._endPos):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
    flyNode:setPosition(startPos)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_shop_chengbei_fly) 

    flyNode:runCsbAction("fly", false, function()
        flyNode:runCsbAction("actionframe1", false)
    end)

    local actList = {}
    actList[#actList + 1]  = cc.DelayTime:create(25/60)

    actList[#actList + 1]  = cc.EaseQuarticActionIn:create(cc.MoveTo:create(35/60,endPos))
    
    actList[#actList + 1]  = cc.DelayTime:create(10/60)

    actList[#actList + 1] = cc.CallFunc:create(function (  )

        if _func then
            _func()
        end

    end)
    actList[#actList + 1]  = cc.DelayTime:create(20/60)
    
    actList[#actList + 1] = cc.CallFunc:create(function (  )

        flyNode:removeFromParent()

    end)

    flyNode:runAction(cc.Sequence:create(actList))
    
end

-- 显示当前的页
function BlackFridayShopView:showCurPage(_pageIndex)
    for pageIndex = 1, 5 do
        self.m_pageCells[pageIndex]:setVisible(false)
    end
    
    self.m_pageCells[_pageIndex]:setVisible(true)
    self.m_pageCells[_pageIndex]:setPosition(0, 0)
end

-- 修改金币父节点 没有折扣卷的时候 显示到中间
function BlackFridayShopView:changeCoinNodeParent( )
    if not self.m_isZheKou then
        util_changeNodeParent(self:findChild("Node_shop_0"), self.m_coinsBar)
    else
        util_changeNodeParent(self:findChild("Node_shop"), self.m_coinsBar)
    end
end

return BlackFridayShopView