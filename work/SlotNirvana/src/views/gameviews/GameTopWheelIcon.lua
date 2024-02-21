--顶部倍增器
local GameTopWheelIcon = class("GameTopWheelIcon", util_require("base.BaseView"))

function GameTopWheelIcon:initUI()
    self:createCsbNode("GameNode/GameTopWheelIcon.csb")

    self.LoadingBar_1 = self:findChild("LoadingBar_1")
 
    self.lunpan_strip = self:findChild("lunpan_strip") -- 顶部条
    self.m_lunpan_lizi = self:findChild("lunpan_lizi")
    self.m_lunpan_lizi:setVisible(false)
    self.lb_spinAccMul = self:findChild("txt_coins_0")

    -- node 节点控制
    self.m_nodeMultip = self:findChild("node_multip")
    self.m_nodeCashbonus = self:findChild("node_bonus")
    self.m_nodePushFrame = self:findChild("node_push")
    self.m_nodeBox = self:findChild("node_box")
    self.m_nodeWheel = self:findChild("node_wheel")
    -- 节点获取
    self.m_sprTime = self:findChild("sp_time")
    self.m_labelTime = self:findChild("font_time")
    self.m_sprGoldBox = self:findChild("sp_goldbox")
    self.m_sprSilverBox = self:findChild("sp_silverbox")
    self.m_labelReward = self:findChild("font_rewardnum")
    self.m_sprClaim = self:findChild("sp_claim")

    self.m_newTypeList = {}
    self.m_oldTypeList = {}
    self.m_updateFlag = true -- 倒计时是否可以通知刷新轮播页

    self.m_nodeMask = self:findChild("node_mask")

    self.m_beer = self:findChild("sp_jiuhua")
    self.m_beer:setVisible(false)
    self:initView()
end

function GameTopWheelIcon:initView()
    -- 啤酒花初始位置
    self.m_beerPosY = -18


    self:initMulView()

    self.m_click = false
    -- 初始化节点状态
    self:resetCashBonusStatus()
    -- 初始化定时器
    self:initCashTimer()
    self:initCarouseTimer()
end

function GameTopWheelIcon:initMulView()
    local multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
    self.m_preValue = multipleData.p_value
    self.lb_spinAccMul:setString("X" .. tostring(multipleData.p_value))
    local percent = multipleData:getMultiplePrenct()
    self.LoadingBar_1:setPercent(percent * 100)
    self:updateBeerPos(percent * 38)

    -- self:updateWheelTopStripPos()
end

function GameTopWheelIcon:updateMulView(callback)
    self.m_callback = callback
    self.m_multipleData = G_GetMgr(G_REF.CashBonus):getMultipleData()
    local preValue = self.m_preValue
    local curMul = self.m_multipleData.p_value
    if preValue and curMul then
        if preValue ~= curMul then
            -- spin等级提升时打点
            -- local extra = {}
            -- extra.name = "spin次数"
            -- extra.levelnum = globalData.userRunData.levelNum
            -- extra.coinNum = "" .. globalData.userRunData.coinNum
            -- extra.spinAccumulation = globalData.spinAccumulation
            -- extra.spinlevel = curMul
            globalTestDataManager:spinLevelUp(curMul)
        end

        local isLevelUp = false
        if curMul ~= self.m_preValue then
            -- 75
            -- self.m_lunpan_lizi:setVisible(true)
            -- self.m_lunpan_lizi:resetSystem()
            --播放升级音效
            isLevelUp = true
            self:showWheelAnim(true)
        else
            self:showWheelAnim(false)
        end
    end
    self.m_preValue = curMul
end

function GameTopWheelIcon:showWheelAnim(isLevelUp)
    performWithDelay(
        self,
        function()
            if isLevelUp then
                self.LoadingBar_1:setPercent(100)
                self:updateBeerPos(38)
                -- 去掉顶部小白条
                --self:updateWheelTopStripPos()
            else
                local percent = self.m_multipleData:getMultiplePrenct()
                self.LoadingBar_1:setPercent(percent * 100)
                self:updateBeerPos(percent * 38)
                --self:updateWheelTopStripPos()
            end
        end,
        1 / 6
    )
    -- 需要检测当前是否轮播在增倍器界面
    if self.m_iCarouseIndex == 1 then
        self:runCsbAction(
            "lunpan_buman",
            false,
            function()
                if isLevelUp then
                    self:runCsbAction("lunpan_man",false,function ()
                        self:showWaterDown()
                    end,60)
                end
            end,
            60
        )
    else
        if isLevelUp then
            self:runCsbAction("lunpan_man",false,function ()
                self:showWaterDown()
            end,60)
        end
    end
end

function GameTopWheelIcon:showWaterDown()
    self:stopLoadBarTimer()
    local times = 10
    local space = 0.5 / times
    local percent = self.m_multipleData:getMultiplePrenct()
    local startVlaue = 100
    local endValue = percent * 100
    local perReduce = (startVlaue - endValue) / times
    self.m_schduleTimeID =
        util_schedule(
        self,
        function()
            startVlaue = startVlaue - perReduce
            self.LoadingBar_1:setPercent(startVlaue)
            -- 此时已经满了需要重新回到初始位置
            self:updateBeerPos(0,true)
            if startVlaue <= endValue then
                startVlaue = endValue
                self:stopLoadBarTimer()
                self:showWheelFly()
                self:runCsbAction("zi",false)
            end
        end,
        space
    )
end

function GameTopWheelIcon:stopLoadBarTimer()
    if self.m_schduleTimeID ~= nil then
        self:stopAction(self.m_schduleTimeID)
        self.m_schduleTimeID = nil
    end
end

function GameTopWheelIcon:showWheelFly()
    -- 增倍器如果升级了，需要停止轮播
    self:stopCarouseTimer()
    self:resetCashBonusStatus()

    -- local flyIcon = util_createAnimation("GameNode/GameTopWheelIconFly.csb")

    -- local node_wheel = gLobalViewManager:getViewLayer()
    -- flyIcon:findChild("lizi"):setPositionType(0)

    -- local maskUI = util_createAnimation("GameNode/GameTopWheelIconBg.csb")
    -- maskUI:playAction("start", false, nil, 60)
    -- node_wheel:addChild(maskUI, -2)
    -- node_wheel:addChild(flyIcon, -1)
    -- local pos = node_wheel:convertToNodeSpace(cc.p(display.width / 2, display.height / 2))
    -- flyIcon:setPosition(cc.p(pos.x, pos.y))
    -- maskUI:setPosition(cc.p(pos.x, pos.y))

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_CASHBONUS_BZQ)


    if not tolua.isnull(self) then
        if self.m_callback then
            self.m_callback(self.m_preValue)
        end
        -- 重新启动轮播
        self:initCarouseTimer()
        performWithDelay(
            self,
            function()
                self.lb_spinAccMul:setString("X" .. tostring(self.m_preValue))
            end,
            0.25
        )
    end

    -- -- 倍增器升级 不需要在屏幕中间播放动效 注释以下代码
    -- local wheelUPWaterSpine = util_createView("views.gameviews.GameTopWheelUP")
    -- flyIcon:findChild("Node_jindutiao"):addChild(wheelUPWaterSpine)
    -- flyIcon:findChild("lizi_qipao1"):setPositionType(0)
    -- flyIcon:findChild("shuipaobaokai"):setPositionType(0)
    -- flyIcon:playAction(
    --     "start2",
    --     false,
    --     function()
    --         if tolua.isnull(self) then
    --             return
    --         end

    --         local endCall = function ()

    --             local pos = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
    --             local endPos = gLobalViewManager:getViewLayer():convertToNodeSpace(cc.p(pos))
    --             local move = cc.EaseSineIn:create(cc.MoveTo:create(35 / 60, pos))
    --             flyIcon:runAction(cc.Sequence:create(move))
    --             maskUI:playAction("over", false, nil, 60)
    --             flyIcon:playAction(
    --                 "idle2",
    --                 false,
    --                 function()
    --                     flyIcon:removeFromParent()
    --                     maskUI:removeFromParent()
    --                     if tolua.isnull(self) then
    --                         return
    --                     end
    --                     self:runCsbAction(
    --                         "lunpan_shouji",
    --                         false,
    --                         function()
    --                             -- self:updateWheelTopStripPos()
    --                             if self.m_callback then
    --                                 self.m_callback(self.m_preValue)
    --                             end
    --                             -- 重新启动轮播
    --                             self:initCarouseTimer()
    --                         end,
    --                         60
    --                     )
    --                     performWithDelay(
    --                         self,
    --                         function()
    --                             self.lb_spinAccMul:setString("X" .. tostring(self.m_preValue))
    --                         end,
    --                         0.25
    --                     )
    --                 end,
    --                 60
    --             )
    --         end

    --         endCall()

    --         -- -- 在这里处理进度条spine
    --         -- if wheelUPWaterSpine then
    --         --     wheelUPWaterSpine:progressAnimation(endCall)
    --         -- else
    --         --     endCall()
    --         -- end
    --     end,
    --     60
    -- )
end

-- 创建轮盘条，在进度上涨时
function GameTopWheelIcon:updateWheelTopStripPos()
    -- local stripView = self.lunpan_strip:getChildByName("WheelStrip")
    if not self.m_stripView then
        self.m_stripView = util_createView("views.gameviews.WheelTopStrip")
        self.m_stripView:setName("WheelStrip")
        self.lunpan_strip:addChild(self.m_stripView)
    end
    local wheelSize = self.lunpan_strip:getContentSize()
    local percent = self.m_multipleData:getMultiplePrenct()
    self.m_stripView:setPosition(cc.p(wheelSize.width * 0.5, wheelSize.height * percent))
    self.m_stripView:stopFrameAt(percent)
end

------------- 创建定时器刷新cashbonus倒计时  -------------≥
function GameTopWheelIcon:initCashTimer()
    self:stopCashTimer()
    -- 开启调度
    self.m_schduleTimeCashBonus =
        util_schedule(
        self,
        function()
            self:updateCashTimer()
        end,
        0.1
    )
end

function GameTopWheelIcon:stopCashTimer()
    if self.m_schduleTimeCashBonus ~= nil then
        self:stopAction(self.m_schduleTimeCashBonus)
        self.m_schduleTimeCashBonus = nil
    end
end

function GameTopWheelIcon:updateCashTimer()
    local coldDownTable = {}

    local gold_data = G_GetMgr(G_REF.CashBonus):getGoldData()
    local gold_time = gold_data:getLeftTime()
    if gold_time > 0 then
        coldDownTable[#coldDownTable + 1] = gold_time
    end

    local silver_data = G_GetMgr(G_REF.CashBonus):getSilverData()
    local silver_time = silver_data:getLeftTime()
    if silver_time > 0 then
        coldDownTable[#coldDownTable + 1] = silver_time
    end

    local wheel_data = G_GetMgr(G_REF.CashBonus):getWheelData()
    local wheel_time = wheel_data:getLeftTime()
    if wheel_time > 0 then
        coldDownTable[#coldDownTable + 1] = wheel_time
    end

    if #coldDownTable > 0 then
        local minColdTime = coldDownTable[1]
        for i = 2, #coldDownTable do
            minColdTime = math.min(minColdTime, coldDownTable[i])
        end
        self.m_sprTime:setVisible(true)
        self.m_labelTime:setString(util_count_down_str(minColdTime))
        if minColdTime <= 1 and self.m_updateFlag then -- 延迟一秒之后通知轮播页进行刷新
            self.m_updateFlag = false
            performWithDelay(
                self,
                function()
                    self:initCarouseTimer()
                    self.m_updateFlag = true
                end,
                1
            )
        end
    else
        -- cashbonus 全为可领取的状态则不显示倒计时
        self:stopCashTimer()
        self.m_sprTime:setVisible(false)
    end

    -- csc 2021-08-26 14:35:32 新手期ABTEST 第三版A组用户如果不够等级不开启轮播
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        if globalData.userRunData.levelNum < globalData.constantData.NOVICE_CASHBONUS_OPEN_LEVEL then
            self.m_sprTime:setVisible(false)
        end
    end
end

------------- 创建定时器进行图标的轮播  -------------
-- 计算出当前轮播节点
function GameTopWheelIcon:initCarouselNode()
    -- 将需要轮播的节点放入
    self.m_oldTypeList = clone(self.m_newTypeList)
    self.m_newTypeList = {}
    self.m_nodeAction = {}
    self.m_nodeAction[#self.m_nodeAction + 1] = {node = self.m_nodeMultip, type = "MULTIP"}
    -- 默认第一个节点一定是增倍器
    self.m_newTypeList[#self.m_newTypeList + 1] = "MULTIP"

    local addCashBonus = true
    -- csc 2021-08-26 14:35:32 新手期ABTEST 第三版A组用户如果不够等级不开启轮播
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        if globalData.userRunData.levelNum < globalData.constantData.NOVICE_CASHBONUS_OPEN_LEVEL then
            addCashBonus = false
        end
    end

    if addCashBonus then
        --金库
        local gold_data = G_GetMgr(G_REF.CashBonus):getGoldData()
        local gold_time = gold_data:getLeftTime()
        if gold_time <= 0 then
            self.m_nodeAction[#self.m_nodeAction + 1] = {node = self.m_sprGoldBox, type = "GOLD", anima = "box", clickfunc = handler(self, self.collectGoldBonus)}
            self.m_newTypeList[#self.m_newTypeList + 1] = "GOLD"
        end
        --银库
        local silver_data = G_GetMgr(G_REF.CashBonus):getSilverData()
        local silver_time = silver_data:getLeftTime()
        if silver_time <= 0 then
            self.m_nodeAction[#self.m_nodeAction + 1] = {node = self.m_sprSilverBox, type = "SILVER", anima = "box", clickfunc = handler(self, self.collectSilverBonus)}
            self.m_newTypeList[#self.m_newTypeList + 1] = "SILVER"
        end
        --每日轮盘
        local wheel_data = G_GetMgr(G_REF.CashBonus):getWheelData()
        local wheel_time = wheel_data:getLeftTime()
        if wheel_time <= 0 then
            self.m_nodeAction[#self.m_nodeAction + 1] = {node = self.m_nodeWheel, type = "WHEEL", anima = "wheel", clickfunc = handler(self, self.collectWheel)}
            self.m_newTypeList[#self.m_newTypeList + 1] = "WHEEL"
        end
    end

    -- 检测一下当时否有新增的轮播节点
    if #self.m_newTypeList > #self.m_oldTypeList then
        for i = 1, #self.m_newTypeList do
            if table.keyof(self.m_oldTypeList, self.m_newTypeList[i]) == nil then
                -- 改变轮播index
                print("----- 新增的节点是 " .. self.m_newTypeList[i] .. " 当前 self.m_iCarouseIndex = " .. self.m_iCarouseIndex)
                if self.m_iCarouseIndex == 1 then
                    self.m_iCarouseIndex = i - 1
                end
                break
            end
        end
    end
end

-- 重置状态
function GameTopWheelIcon:resetCashBonusStatus()
    self.m_sprGoldBox:setVisible(false)
    self.m_sprSilverBox:setVisible(false)
    self.m_nodeWheel:setVisible(false)
    self.m_nodeCashbonus:setVisible(false)
    self.m_nodeMultip:setVisible(true)
    self.m_nodePushFrame:setVisible(false)
    self.m_iCarouseIndex = 1
    -- self.m_sprClaim:setVisible(false)
end

-- 每5秒钟进行一次轮播切换
function GameTopWheelIcon:initCarouseTimer()
    self:stopCarouseTimer()
    -- 开启调度
    self.m_schduleTimeCarouse =
        util_schedule(
        self,
        function()
            self:updateCarouseTimer()
        end,
        5
    )

    self:updateCarouseTimer()
end

function GameTopWheelIcon:stopCarouseTimer()
    if self.m_schduleTimeCarouse ~= nil then
        self:stopAction(self.m_schduleTimeCarouse)
        self.m_schduleTimeCarouse = nil
    end
end

function GameTopWheelIcon:updateCarouseTimer()
    -- 每次进行切换的时候,都需要重新生成一遍当前最新的奖励信息
    self:initCarouselNode()

    if not self.m_iCarouseIndex then
        self.m_iCarouseIndex = 1
    else
        self.m_iCarouseIndex = self.m_iCarouseIndex + 1
    end
    -- 如果当前轮播下标超出了轮播个数，重置回第一个
    if self.m_iCarouseIndex > #self.m_nodeAction then
        self.m_iCarouseIndex = 1
        self.m_nodeMultip:setVisible(true) -- 设置状态
        self.m_nodeCashbonus:setVisible(false)
    end

    -- 展示轮播
    if self.m_iCarouseIndex == 1 then
        self.m_nodeMultip:setVisible(true) -- 设置状态
        self.m_nodeCashbonus:setVisible(false)
    else
        self.m_nodeMultip:setVisible(false) -- 设置状态
        self.m_nodeCashbonus:setVisible(true)
        for i = 1, #self.m_nodeAction do
            local node = self.m_nodeAction[i].node
            local type = self.m_nodeAction[i].type
            local anima = self.m_nodeAction[i].anima
            node:setVisible(false)
            if i == self.m_iCarouseIndex then -- 如果是对应index的展示
                node:setVisible(true)
                if anima then
                    self:runCsbAction(anima, true, nil, 60)
                end
                if type == CASHBONUS_TYPE.BONUS_GOLD or type == CASHBONUS_TYPE.BONUS_SILVER then
                    self.m_nodeBox:setVisible(true)
                else
                    self.m_nodeBox:setVisible(false)
                end
            end
        end
    end
end

-- 将gametop 的点击事件转换到节点上来处理
function GameTopWheelIcon:touchFunc(_callback)
    if self.m_click then
        return
    end
    local info = self.m_nodeAction[self.m_iCarouseIndex]
    if not info or not info.clickfunc then
        if _callback then
            _callback()
        end
        self.m_click = false
        return
    end

    if info.clickfunc then
        self.m_click = true
        -- 需要先停止轮播
        self:stopCarouseTimer()
        self:resetCashBonusStatus()
        info.clickfunc()
    end
end

function GameTopWheelIcon:collectGoldBonus()
    print("------ 收集金库!!")
    local coins = self:getCashBonusTypeValue(CASHBONUS_TYPE.BONUS_GOLD)
    G_GetMgr(G_REF.CashBonus):sendActionCashVaultCollect(CASHBONUS_TYPE.BONUS_GOLD, coins)
end

function GameTopWheelIcon:collectSilverBonus()
    print("------ 收集银库!!")
    local coins = self:getCashBonusTypeValue(CASHBONUS_TYPE.BONUS_SILVER)
    G_GetMgr(G_REF.CashBonus):sendActionCashVaultCollect(CASHBONUS_TYPE.BONUS_SILVER, coins)
end

function GameTopWheelIcon:collectWheel()
    print("------ 收集每日轮盘!!!!")
    local bonusWheelView = util_createView("views.cashBonus.DailyBonus.DailybonusLayer")
    gLobalViewManager:showUI(bonusWheelView, ViewZorder.ZORDER_UI)
    bonusWheelView:setOverFunc(
        function()
            local data = G_GetMgr(G_REF.LuckyStamp):getData()
            if not self.m_reconnect and data then
                local checkOpenView = function(_callback)
                    if G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasTaskCompleted() then
                        local taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.WHEELDAILY
                        G_GetMgr(ACTIVITY_REF.HolidayChallenge):chooseCreatePopLayer(taskType, _callback)
                    else
                        if _callback then
                            _callback()
                        end
                    end
                end
                --掉卡之前的提示
                gLobalViewManager:checkAfterBuyTipList(
                    function()
                        gLobalViewManager:checkBuyTipList(function()
                            checkOpenView(
                                function()
                                    globalData.saleRunData:getCouponGift()
                                end
                            )
                        end)
                    end,
                    "CashBonus"
                )
            end

            if tolua.isnull(self) then
                return
            end
            -- 如果当前时间调度停止了，需要开启
            if self.m_schduleTimeCashBonus == nil then
                self:initCashTimer()
            end
            -- 重新开启轮播
            self:initCarouseTimer()
            self.m_click = false
        end
    )
end

function GameTopWheelIcon:getCashBonusTypeValue(type)
    local cashBonusShowList = G_GetMgr(G_REF.CashBonus):getRunningData():getCashBonusShowList()
    if not cashBonusShowList then
        G_GetMgr(G_REF.CashBonus):getRunningData():updateCashBonusIncrease(true)
        cashBonusShowList = G_GetMgr(G_REF.CashBonus):getRunningData():getCashBonusShowList()
    end
    for i = 1, #cashBonusShowList do
        if cashBonusShowList[i].type == type then
            return cashBonusShowList.curValue
        end
    end
    return 0
end

function GameTopWheelIcon:requestPickGameCallBack(_isSucc)
    if _isSucc then
        local cBGameData = G_GetMgr(G_REF.CashBonus):getRunningData():getCashVaultGame()
        local totalCoins = cBGameData.totalCoins
        -- 下拉条动画 并且赋值
        local str = util_formatCoins(totalCoins, 4)
        self.m_labelReward:setString(str)
        local endFunc = function()
            if tolua.isnull(self) then
                return
            end
            -- 飞金币
            local flyIcon = self:findChild("sp_coinIcon")
            local contet = flyIcon:getContentSize()
            local startPos = flyIcon:convertToWorldSpace(cc.p(contet.width / 2, contet.height / 2))
            local endPos = globalData.flyCoinsEndPos
            local baseCoins = globalData.topUICoinCount
            local callbackFunc = function()
                if tolua.isnull(self) then
                    return
                end
                -- 收集金币飞行完毕重新开启调度
                self.m_nodePushFrame:setVisible(false)
                self:initCarouseTimer()
                self.m_click = false
                if self.m_schduleTimeCashBonus == nil then -- 如果当前时间调度停止了，需要开启
                    self:initCashTimer()
                end
            end
            gLobalViewManager:pubPlayFlyCoin(startPos, endPos, baseCoins, totalCoins, callbackFunc, nil, 15, nil, nil, nil, true)
        end
        self.m_nodePushFrame:setVisible(true)
        self:runCsbAction("xiala", false, endFunc, 60)
    else
        -- 如果收集失败 重新开启轮播
        self:initCarouseTimer()
        self.m_click = false
    end
end

function GameTopWheelIcon:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local success = params.success
            self:requestPickGameCallBack(success)
        end,
        ViewEventType.CASHBONUS_VAULT_COLLECT_CALLBACK
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            self:initMulView()
        end,
        ViewEventType.CASHBONUS_UPDATE_MULTIPLE
    )
end

-- 处理收集进度啤酒杯的位置
function GameTopWheelIcon:updateBeerPos(_pos,_isFull)

    if self.m_beer then
        if not self.m_beer:isVisible() and _pos ~= 0 then
            self.m_beer:setVisible(true)
        end
        local posY = self.m_beerPosY + _pos
        if _isFull then
            -- 满了
            self.m_beer:setVisible(false)
        end
        
        self.m_beer:setPosition(cc.p(0,posY))
    end
end

function GameTopWheelIcon:onExit()
    GameTopWheelIcon.super.onExit(self)
    self:stopCashTimer()
    self:stopCarouseTimer()
    self:stopAllActions()
end

return GameTopWheelIcon
