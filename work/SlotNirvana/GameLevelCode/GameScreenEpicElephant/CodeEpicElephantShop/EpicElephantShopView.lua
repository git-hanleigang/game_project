---
--xcyy
--2018年5月23日
--EpicElephantShopView.lua
local SendDataManager = require "network.SendDataManager"
local EpicElephantShopView = class("EpicElephantShopView",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_LEFT          = 1001              --左翻页
local BTN_TAG_RIGHT         = 1002              --右翻页
local BTN_TAG_CLOSE         = 9999              --关闭
local BTN_TAG_PAGE1         = 5001              --页码1
local BTN_TAG_PAGE2         = 5002              --页码2
local BTN_TAG_PAGE3         = 5003              --页码3
local BTN_TAG_PAGE4         = 5004              --页码4
local BTN_TAG_PAGE5         = 5005              --页码5

local SHOP_ITEM_TAG         =   2001  -- 


function EpicElephantShopView:initUI(params)
    self.m_machine = params.machine
    self.m_isTriggerSuper = false

    self.m_clickPosAry = {}
    self:createCsbNode("EpicElephant/EpicElephantShop.csb")
    self:setVisible(false)

    self:findChild("Btn_L"):setTag(BTN_TAG_LEFT)
    self:findChild("Btn_R"):setTag(BTN_TAG_RIGHT)
    self:findChild("Btn_Close"):setTag(BTN_TAG_CLOSE)

    self:findChild("Page1_click"):setTag(BTN_TAG_PAGE1)
    self:findChild("Page2_click"):setTag(BTN_TAG_PAGE2)
    self:findChild("Page3_click"):setTag(BTN_TAG_PAGE3)
    self:findChild("Page4_click"):setTag(BTN_TAG_PAGE4)
    self:findChild("Page5_click"):setTag(BTN_TAG_PAGE5)
    for i=1,5 do
        self:addClick(self:findChild("Page" .. i .. "_click"))
    end

    self.m_item_reel = util_createAnimation("EpicElephant_shop_stuff_reel.csb")
    self:findChild("Node_Page"):addChild(self.m_item_reel)

    for index = 1,9 do
        local shopItem = util_createView("CodeEpicElephantShop.EpicElephantShopItem",{parent = self,index = index})
        self.m_item_reel:findChild("Node_"..index):addChild(shopItem)
        shopItem:setTag(SHOP_ITEM_TAG)
    end

    --super free类型
    self.m_superType = util_createAnimation("EpicElephant_superwild.csb")
    self:findChild("Node_wanfa_super"):addChild(self.m_superType)

    --金币栏
    self.m_coinsBar = util_createAnimation("EpicElephant_coin_shouji_shop.csb")
    self:findChild("Node_shouji"):addChild(self.m_coinsBar)

    --金币不足标签
    self.m_tip = util_createAnimation("EpicElephant_shop_stuff_Tip.csb")
    self:addChild(self.m_tip)
    self.m_tip:setVisible(false)

    --隐藏标签用
    self:addClick(self:findChild("zhezhao"))
end

function EpicElephantShopView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function EpicElephantShopView:initIsPlayingEffect( )
    self.m_isPlayingEffect = {}
    for i=1,9 do
        self.m_isPlayingEffect[i] = false
    end
end

function EpicElephantShopView:getIsPlayingEffect( )
    for i,v in ipairs(self.m_isPlayingEffect) do
        if v then
            return true
        end
    end
    return false
end
--[[
    显示金币不足标签
]]
function EpicElephantShopView:showCoinNotEnough(clickPos,isHide,isLocked)
    if isHide or self.m_tip:isVisible() then
        if self.m_scheduleId then
            self:stopAction(self.m_scheduleId)
            self.m_scheduleId = nil
        end

        self.m_tip:runCsbAction("over",false, function()
            self.m_tip:setVisible(false)
        end)
        return
    end

    --设置标签位置
    local shopItem = self.m_item_reel:findChild("Node_"..clickPos):getChildByTag(SHOP_ITEM_TAG)    
    if shopItem then
        local pos = util_convertToNodeSpace(shopItem:findChild("Node_stuff_tip"),self)
        self.m_tip:setPosition(pos)
        self.m_tip:setVisible(true)
        if isLocked then
            self.m_tip:findChild("tip"):setVisible(false)
            self.m_tip:findChild("tip_0"):setVisible(true)
        else
            self.m_tip:findChild("tip"):setVisible(true)
            self.m_tip:findChild("tip_0"):setVisible(false)
        end
        self.m_tip:runCsbAction("start",false, function()
            self.m_tip:runCsbAction("idle",true)
        end)
        self.m_scheduleId = schedule(self, function(  )

            if self.m_scheduleId then
                self:stopAction(self.m_scheduleId)
                self.m_scheduleId = nil
            end

            self.m_tip:runCsbAction("over",false, function()
                self.m_tip:setVisible(false)
            end)
        end, 5)
    end
end

--默认按钮监听回调
function EpicElephantShopView:clickFunc(sender)
    self:showCoinNotEnough(nil,true,false)
    --已经触发superfree后不允许点击按钮
    if self.m_isTriggerSuper then
        return
    end

    -- 正在播放动画 不切换翻页
    if self:getIsPlayingEffect() then
        return
    end

    -- 正在播放关闭动画 不可点击
    if self.m_isPlayCloseView then
        return 
    end

    if self.m_tip:isVisible() then
        if self.m_scheduleId then
            self:stopAction(self.m_scheduleId)
            self.m_scheduleId = nil
        end

        -- self.m_tip:runCsbAction("over",false, function()
            self.m_tip:setVisible(false)
        -- end)
        -- return
    end

    local name = sender:getName()
    local btnTag = sender:getTag()
    
    if btnTag == BTN_TAG_LEFT then --左翻页
        self.m_curPageIndex = self.m_curPageIndex - 1
        if self.m_curPageIndex < 1 then
            self.m_curPageIndex = 1
        end
        self:refreshView()
    elseif btnTag == BTN_TAG_RIGHT then --右翻页
        self.m_curPageIndex = self.m_curPageIndex + 1
        if self.m_curPageIndex > 5 then
            self.m_curPageIndex = 1
        end
        self:refreshView()
    elseif btnTag == BTN_TAG_CLOSE then --关闭
        self.m_isPlayCloseView = true
        self.m_isWaiting = true
        self.m_machine:checkTriggerOrInSpecialGame(function(  )
            self.m_machine:reelsDownDelaySetMusicBGVolume( ) 
        end)

        self:hideView()
    elseif btnTag == BTN_TAG_PAGE1 then
        self.m_curPageIndex = 1
        self:refreshView()
    elseif btnTag == BTN_TAG_PAGE2 then
        self.m_curPageIndex = 2
        self:refreshView()
    elseif btnTag == BTN_TAG_PAGE3 then
        self.m_curPageIndex = 3
        self:refreshView()
    elseif btnTag == BTN_TAG_PAGE4 then
        self.m_curPageIndex = 4
        self:refreshView()
    elseif btnTag == BTN_TAG_PAGE5 then
        self.m_curPageIndex = 5
        self:refreshView()
    end
end

--[[
    刷新界面
]]
function EpicElephantShopView:refreshView(isSuperFreeBack)
    self:initIsPlayingEffect()

    local shopConfig = self.m_machine.m_shopConfig
    if not isSuperFreeBack then
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_click)
    end
    --当前页是否锁定
    self.m_isLocked = not shopConfig.finished[self.m_curPageIndex]

    for index = 1,5 do
        self:findChild("Node_Page_"..index):setVisible(index == self.m_curPageIndex)
        self:findChild("map_"..index):setVisible(index == self.m_curPageIndex)
        self.m_superType:findChild("Node_"..index):setVisible(index == self.m_curPageIndex)
    end

    self:findChild("Btn_L"):setVisible(self.m_curPageIndex ~= 1)
    self:findChild("Btn_R"):setVisible(self.m_curPageIndex ~= 5)

    self:updateCoins()

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
        local shopItem = self.m_item_reel:findChild("Node_"..index):getChildByTag(SHOP_ITEM_TAG)    
        if shopItem then
            shopItem:refreshUI(curShopPageData, isSuperFreeBack, index == 9)
        end
    end
end

--[[
    刷新金币
]]
function EpicElephantShopView:updateCoins()
    local shopConfig = self.m_machine.m_shopConfig
    local coins = shopConfig.coins
    self.m_coinsBar:findChild("m_lb_coins"):setString(util_formatCoins(coins,10))
    self:updateLabelSize({label=self.m_coinsBar:findChild("m_lb_coins"),sx=1,sy=1},286)

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
        local shopItem = self.m_item_reel:findChild("Node_"..index):getChildByTag(SHOP_ITEM_TAG)    
        if shopItem then
            shopItem:refreshUIPrice(curShopPageData)
        end
    end
end

--[[
    显示界面
]]
function EpicElephantShopView:showView(isSuperFreeBack)
    self:setVisible(true)

    self.m_clickPosAry = {}

    self.m_isTriggerSuper = false

    self.m_isPlayCloseView = true

    self.m_isWaiting = false

    local shopConfig = self.m_machine.m_shopConfig
    
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

    self:refreshView(isSuperFreeBack)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_shop_start)

    self:runCsbAction("start",false, function()

        self.m_isPlayCloseView = false

        self:runCsbAction("idle",true)
        self.m_coinsBar:runCsbAction("idle",true)
    end)
end

--[[
    关闭界面
]]
function EpicElephantShopView:hideView(func)
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_shop_over)

    self:runCsbAction("over",false, function()
        self:setVisible(false)
        if func then
            func()
        end
    end)
    
end

--[[
    点击商店道具
]]
function EpicElephantShopView:clickItem(clickPos)
    self:sendData(clickPos)
end

--[[
    数据发送
]]
function EpicElephantShopView:sendData(clickPos)
    if self.m_isWaiting then
        return
    end

    if self.m_machine.m_shopConfig.shop[self.m_curPageIndex][clickPos] == 1 then
        return
    end

    --防止连续点击
    self.m_isWaiting = true

    self.m_isPlayingEffect[clickPos] = true

    self.m_clickPos = clickPos

    local data = {self.m_curPageIndex - 1, clickPos - 1}
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = data, clickPos = clickPos - 1}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function EpicElephantShopView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        if spinData.action == "SPECIAL" then
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        
            self:recvBaseData(spinData.result)
        end
    else
        gLobalViewManager:showReConnect(true)
    end
end


--[[
    接收数据
]]
function EpicElephantShopView:recvBaseData(featureData)
    if not self:isVisible() then
        return
    end
    
    self.m_machine.m_shopConfig.finished = featureData.selfData.finished
    self.m_machine.m_shopConfig.shop = featureData.selfData.shop
    self.m_machine.m_shopConfig.shopCoins = featureData.selfData.shopCoins
    self.m_machine.m_shopConfig.coins = featureData.selfData.coins
    self.m_machine.m_shopConfig.firstRound = featureData.selfData.firstRound
    self.m_machine.m_shopConfig.features = featureData.features[2] or 0
    self.m_machine.m_runSpinResultData.p_selfMakeData = featureData.selfData
    self.m_machine:refreshShopScore()
    -- 判断下次 购买 是否免费
    if featureData.selfData.shopCoins[self.m_curPageIndex][self.m_clickPos] == "extraPick" then
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
    
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_shop_click_shangpin)

    self:updateCoins()
    if featureData.features[2] ~= SLOTO_FEATURE.FEATURE_FREESPIN then
        self.m_machine:delayCallBack(0.3,function()
            self.m_isWaiting = false
        end)
    else
        self.m_isTriggerSuper = true
    end 

    local selfData = featureData.selfData
    if selfData and selfData.pickResult then
        self.m_clickPosAry[#self.m_clickPosAry + 1] = selfData.pickResult[#selfData.pickResult][2] + 1
    end

    self:updateClickPosReward(featureData.selfData.pickResult, featureData.selfData, featureData, function()

        if featureData.features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
            --触发free时只更新点击位置的奖励
            self.m_isTriggerSuper = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
            
            self:hideView(function()
                self.m_isWaiting = false
            end)
            self.m_machine.m_runSpinResultData:parseResultData(featureData, self.m_machine.m_lineDataPool)
            self.m_machine:triggerSuperFree()
            
        end
        
    end)
end

--[[
    更新点击位置的奖励
]]
function EpicElephantShopView:updateClickPosReward(rewardData, selfData, featureData, func)
    local featureDataList = clone(featureData)
    local reward = rewardData[#rewardData - 1]
    local clickPos = rewardData[#rewardData][2] + 1
    --当前页数不符
    if self.m_curPageIndex ~= rewardData[#rewardData][1] + 1 then
        return
    end

    --设置标签位置
    local shopItem = self.m_item_reel:findChild("Node_"..clickPos):getChildByTag(SHOP_ITEM_TAG) 
    if #rewardData > 2 and rewardData[2] > 1 then
        shopItem:findChild("m_lb_coins_price"):setVisible(false)
        shopItem:findChild("free"):setVisible(true)
        
        shopItem:updateReward(rewardData[1], true, function()
            local startpos = 1
            local shopConfig = self.m_machine.m_shopConfig
            if shopConfig.extraPickPos and shopConfig.extraPickPos[self.m_curPageIndex] and shopConfig.extraPickPos[self.m_curPageIndex][2] then
                startpos = shopConfig.extraPickPos[self.m_curPageIndex][2] + 1
            end
            
            self:collectChengBeiFly(startpos, clickPos, function()
                shopItem:updateReward(reward, false, function()
                    self:getCoinsAndFlyEffect(clickPos, reward, function()
                        local pos = self.m_clickPosAry[1]
                        table.remove(self.m_clickPosAry,1)
                        if self.m_isPlayingEffect and self.m_isPlayingEffect[pos] then
                            self.m_isPlayingEffect[pos] = false
                        end

                        func(featureDataList)
                    end)
                end, true)
            end)
        end)
    else  
        shopItem:updateReward(reward, true, function()
            if reward ~= "extraPick" then
                self:getCoinsAndFlyEffect(clickPos, reward, function()
                    local pos = self.m_clickPosAry[1]
                    table.remove(self.m_clickPosAry,1)
                    if self.m_isPlayingEffect and self.m_isPlayingEffect[pos] then
                        self.m_isPlayingEffect[pos] = false
                    end

                    func(featureDataList)
                end)
            else
                self.m_isWaiting = false
                local pos = self.m_clickPosAry[1]
                table.remove(self.m_clickPosAry,1)
                if self.m_isPlayingEffect and self.m_isPlayingEffect[pos] then
                    self.m_isPlayingEffect[pos] = false
                end
            end
        end)
    end
end

function EpicElephantShopView:getCoinsAndFlyEffect(startpos, addValue, func)
    local startPos = self.m_item_reel:findChild("Node_"..startpos):getParent():convertToWorldSpace(cc.p(self.m_item_reel:findChild("Node_"..startpos):getPosition()))
    -- local cuyMgr = G_GetMgr(G_REF.Currency)
    -- if cuyMgr then
    --     local cuyType = FlyType.Coin
    --     cuyMgr:playFlyCurrency(
    --         {
    --             cuyType = cuyType,
    --             addValue = addValue,
    --             startPos = startPos
    --         },
    --         function()
    --             if func then
    --                 func()
    --             end
    --         end
    --     )
    -- end

    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount 
    gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,addValue,function ()
         if not tolua.isnull(self) and func then
            func()
        end
    end,nil,10,nil,nil,nil,true)
end

-- 成倍飞
function EpicElephantShopView:collectChengBeiFly(startpos, endPos, func)
    local shopItem = self.m_item_reel:findChild("Node_"..startpos):getChildByTag(SHOP_ITEM_TAG)
    shopItem:runCsbAction("idle1",true)

    local flyNode = util_createAnimation("EpicElephant_jindutiao_fly.csb")
    self:addChild(flyNode)

    local startWorldPos = self.m_item_reel:findChild("Node_"..startpos):getParent():convertToWorldSpace(cc.p(self.m_item_reel:findChild("Node_"..startpos):getPosition()))
    local startPos = self:convertToNodeSpace(startWorldPos)
    local endWorldPos = self.m_item_reel:findChild("Node_"..endPos):getParent():convertToWorldSpace(cc.p(self.m_item_reel:findChild("Node_"..endPos):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))
    flyNode:setPosition(startPos)
    flyNode:findChild("lizi"):setDuration(1)     --设置拖尾时间(生命周期)
    flyNode:findChild("lizi"):setPositionType(0)   --设置可以拖尾

    flyNode:findChild("lizi"):setVisible(false)
    flyNode:runCsbAction("shouji", false)

    self.m_machine:delayCallBack(10/60, function()
        local actList = {}
        actList[#actList + 1]  = cc.MoveTo:create(15/60,endPos)
        
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            flyNode:findChild("lizi"):stopSystem()
            -- flyNode:findChild("zi"):setVisible(false)
            self.m_machine:delayCallBack(0.5, function()
                flyNode:removeFromParent()
            end)

            if func then
                func()
            end

        end)
        flyNode:runAction(cc.Sequence:create(actList))

        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_shop_chengbei_fly)

    end)
end

return EpicElephantShopView