--[[
    转盘
]]
local HolidayChallenge_BaseWheelLayer = class("HolidayChallenge_BaseWheelLayer", BaseLayer)
local ShopItem = util_require("data.baseDatas.ShopItem")

local actTime = 3.5 -- 总时长
local slowTime = 0.5 --减速时长
local slowNum = 5 --减速的个数
local actNum = 3 -- 轮数

function HolidayChallenge_BaseWheelLayer:initDatas(_callback)
    self.m_needAction = false
    self.m_jackpotCoins = 0
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.WHEEL_LAYER)
    self:setExtendData("HolidayChallenge_WheelLayer")
    self:setBgm(self.m_activityConfig.RESPATH.MAIN_BGM_MP3)
    self.m_callback = _callback
    self.m_wheelCellList = {}

    self.m_isFreeWheel = true
    local wheelData = self:getWheelData()
    if wheelData then
        local isActivatePay = wheelData:getActivatePay()
        self.m_isFreeWheel = not isActivatePay
    end
    self.m_targetIndex = 0 --目标索引id
    self.m_isWheelRotate = false
    self:initActDatas()
end

-- 初始化动画数据
function HolidayChallenge_BaseWheelLayer:initActDatas()
    self.m_actList = {} --动画跳跃索引列表
    self.m_curIndex = 1 --当前所在索引位置
    self.m_slowNum = 1 --减速个数
    self.m_turnTime = 0 --转动时间
    self.m_slowTime = slowTime --减速时长（动态减少）
    self.m_slowTargetTime = slowTime --减速目标时长
end

function HolidayChallenge_BaseWheelLayer:initCsbNodes()
    self.m_lb_jackpot = self:findChild("lb_jackpot")

    self.m_lb_num = self:findChild("lb_num")
    self.m_lb_percent = self:findChild("lb_loading")
    self.m_loadingBar = self:findChild("LoadingBar_1")
    self.m_node_lock = self:findChild("node_lock")

    self.m_lb_num_pay = self:findChild("lb_num_pay")
    self.m_lb_percent_pay = self:findChild("lb_loading_pay")
    self.m_loadingBar_pay = self:findChild("LoadingBar_1_pay")
    self.m_node_lock_pay = self:findChild("node_lock_pay")

    self.m_sp_redpoint = self:findChild("sp_redpoint")
    self.m_btn_spin = self:findChild("btn_spin")
    self.m_btn_pay = self:findChild("btn_pay")
end

function HolidayChallenge_BaseWheelLayer:initView()
    self:addWheel()
    self:setSpinLeft()
    self:checkBarAction()
    self:initJackPot()
    self:initBtnShow()
    self:refreshUI()
    self:initBuyBtnLabel()
    --self:initLock()
end

function HolidayChallenge_BaseWheelLayer:getWheelData()
    local wheelData = nil
    local holidayData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if holidayData then
        wheelData = holidayData:getWheelData()
        return wheelData
    end
    return wheelData
end

function HolidayChallenge_BaseWheelLayer:isShowLock()
    local isShowLock = false
    local wheelData = self:getWheelData()
    if wheelData then
        local isActivatePay = wheelData:getActivatePay()
        local isWheelTypePay = wheelData:isWheelTypePay()
        local isWheelCanPay = wheelData:isWheelCanPay()
        if not isActivatePay and isWheelTypePay and isWheelCanPay then
            isShowLock = true
        end
    end
    return isShowLock
end

function HolidayChallenge_BaseWheelLayer:addWheel()
    local wheelData = self:getWheelData()
    local rewards = wheelData:getRewards()
    local cell_path = "views.HolidayChallengeBase.baseWheel.HolidayChallenge_BaseWheelCell"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.WHEEL_CELL then
        cell_path = self.m_activityConfig.CODE_PATH.WHEEL_CELL
    end

    if #rewards > 0 then
        for i, v in ipairs(rewards) do
            local node = self:findChild("Node_Cell_" .. i)
            if node then
                local cell = util_createView(cell_path, v)
                node:addChild(cell)
                table.insert(self.m_wheelCellList, cell)
            end
        end
    end
end

function HolidayChallenge_BaseWheelLayer:setSpinLeft()
    local wheelData = self:getWheelData()
    if wheelData then
        local spinLeft = wheelData:getSpinLeft()
        local pointsNext = wheelData:getPointsNext()
        self.m_lb_num:setString(spinLeft)
        self.m_lb_num_pay:setString(spinLeft)
        self.m_sp_redpoint:setVisible(spinLeft > 0)
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):setSpinLeft(spinLeft, pointsNext, true)
    end
end

function HolidayChallenge_BaseWheelLayer:setBarPercent()
    local wheelData = self:getWheelData()
    if wheelData then
        local allPoints = wheelData:getAllPoints()
        local pointsNext = wheelData:getPointsNext()
        if allPoints >= pointsNext then
            self.m_loadingBar:setPercent(100)
            self.m_loadingBar_pay:setPercent(100)
            self.m_lb_percent:setString("--/--")
            self.m_lb_percent_pay:setString("--/--")
        else
            local percent = math.floor(allPoints / pointsNext * 100)
            self.m_loadingBar:setPercent(percent)
            self.m_loadingBar_pay:setPercent(percent)
            self.m_lb_percent:setString(allPoints .. "/" .. pointsNext)
            self.m_lb_percent_pay:setString(allPoints .. "/" .. pointsNext)
        end
    end
end

function HolidayChallenge_BaseWheelLayer:checkBarAction()
    local wheelData = self:getWheelData()
    if wheelData then
        local lastSpinLeft, lastPoint = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getSpinLeft()
        local curSpinLeft = wheelData:getSpinLeft()
        if curSpinLeft > lastSpinLeft then
            self.m_loadingBar:setPercent(100)
            self.m_loadingBar_pay:setPercent(100)
            self.m_lb_percent:setString(lastPoint .. "/" .. lastPoint)
            self.m_lb_percent_pay:setString(lastPoint .. "/" .. lastPoint)
            self.m_needAction = true
        else
            self:setBarPercent()
        end
    end
end

-- 按钮显示
function HolidayChallenge_BaseWheelLayer:initBtnShow()
    local holidayData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if holidayData then
        local wheelData = holidayData:getWheelData()
        if wheelData then
            local isActivatePay = wheelData:getActivatePay()
            local isWheelTypePay = wheelData:isWheelTypePay()
            if not isActivatePay and isWheelTypePay then
                self.m_btn_spin:setVisible(false)
                self.m_btn_pay:setVisible(true)
                local isWheelCanPay = wheelData:isWheelCanPay()
                self.m_sp_redpoint:setVisible(isWheelCanPay)
                self:setButtonLabelDisEnabled("btn_pay", isWheelCanPay)
            else
                self.m_btn_spin:setVisible(true)
                self.m_btn_pay:setVisible(false)
                local spinLeft = wheelData:getSpinLeft()
                self:setButtonLabelDisEnabled("btn_spin", spinLeft > 0)
            end
        end
    end
end

function HolidayChallenge_BaseWheelLayer:refreshUI()
    local wheelData = self:getWheelData()
    if wheelData then
        local isWheelTypePay = wheelData:isWheelTypePay()
        local aniName = "idle1"
        if isWheelTypePay then
            aniName = "idle2"
        end
        self:runCsbAction(aniName, true, nil, 60)
    end
end

-- 按钮文本
function HolidayChallenge_BaseWheelLayer:initBuyBtnLabel()
    local wheelData = self:getWheelData()
    if wheelData then
        local wheelPay = wheelData:getWheelPay()
        local priceStr = wheelPay.m_price
        local key = "HolidayChallenge_BaseWheelLayer:btn_pay"
        local lbString = gLobalLanguageChangeManager:getStringByKey(key) or "$%s"
        self:setButtonLabelContent("btn_pay", string.format(lbString, priceStr))
    end
end
function HolidayChallenge_BaseWheelLayer:onEnter()
    HolidayChallenge_BaseWheelLayer.super.onEnter(self)
    self:initLock()
end
-- 轮盘锁
function HolidayChallenge_BaseWheelLayer:initLock()
    local isShowLock = self:isShowLock()
    -- local lockNode = util_spineCreate(self.m_activityConfig.RESPATH.SPINE_PATH_WHEEL_LOCK, false, true, 1)
    -- if lockNode then
    --     self.m_node_lock:addChild(lockNode)
    --     lockNode:setVisible(isShowLock)
    --     self.m_lockNode = lockNode
    --     if isShowLock then
    --         util_spinePlay(lockNode, "lock_B", true)
    --     end
    -- end

    local lockPayNode = util_spineCreate(self.m_activityConfig.RESPATH.SPINE_PATH_WHEEL_LOCK, false, true, 1)
    if lockPayNode then
        self.m_node_lock_pay:addChild(lockPayNode)
        lockPayNode:setVisible(isShowLock)
        self.m_lockPayNode = lockPayNode
        if isShowLock then
            util_spinePlay(lockPayNode, "idle_Y", true)
        end
    end
end

function HolidayChallenge_BaseWheelLayer:initJackPot()
    local wheelData = self:getWheelData()
    if wheelData then
        self.m_jackpotCoins = wheelData:getJackpotCoins()
        self.m_lb_jackpot:setString(util_formatCoins(self.m_jackpotCoins, 11))
    end
end

-- jackpot滚动
function HolidayChallenge_BaseWheelLayer:jackPotAnimation()
    local wheelData = self:getWheelData()
    if wheelData then
        local jackpot = wheelData:getJackpotCoins()
        if self.m_jackpotCoins > 0 and jackpot > self.m_jackpotCoins then
            local coinsLabelNode = self.m_lb_jackpot
            local startCoins = self.m_jackpotCoins
            local endCoins = tonumber(jackpot)
            local addCoins = (endCoins - startCoins) / 20
            local spendTime = 1 / 20
            util_jumpNum(
                coinsLabelNode,
                startCoins,
                endCoins,
                addCoins,
                spendTime,
                {11},
                nil,
                nil,
                function()
                end
            )
        else
            self.m_lb_jackpot:setString(util_formatCoins(jackpot, 11))
        end
        self.m_jackpotCoins = jackpot
    end
end

function HolidayChallenge_BaseWheelLayer:clickFunc(_sender)
    if self.m_isTouch then
        return
    end

    local name = _sender:getName()
    if name == "btn_spin" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local wheelData = self:getWheelData()
        if wheelData then
            local spinLeft = wheelData:getSpinLeft()
            if spinLeft > 0 then
                self.m_isTouch = true
                local gridIndexList = wheelData:getWheelLeftIndexList()
                local params = {gridIndexList = gridIndexList}
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):sendWheelSpin(params)
            end
        end
    elseif name == "btn_pay" then
        self:buyWheelPay()
    elseif name == "btn_close" then
        local wheelData = self:getWheelData()
        if wheelData then
            local spinLeft = wheelData:getSpinLeft()
            if spinLeft > 0 then
                local tipOverFunc = function()
                    if not tolua.isnull(self) then
                        self:closeUI(
                            function()
                                if self.m_callback then
                                    self.m_callback()
                                end
                            end
                        )
                    end
                end
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):showWheelTipLayer(tipOverFunc)
            else
                self:closeUI(
                    function()
                        if self.m_callback then
                            self.m_callback()
                        end
                    end
                )
            end
        end
    elseif name == "btn_info" then
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):showWheelInfoLayer()
    end
end

function HolidayChallenge_BaseWheelLayer:onShowedCallFunc()
    local wheelData = self:getWheelData()
    if wheelData then
        local spinLeft = wheelData:getSpinLeft()
        local pointsNext = wheelData:getPointsNext()
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):setSpinLeft(spinLeft, pointsNext, true)

        if self.m_needAction then
            local progressAction = function()
                local allPoints = wheelData:getAllPoints()
                local endPercent = math.floor(allPoints / pointsNext * 100)
                self.m_lb_percent:setString(allPoints .. "/" .. pointsNext)
                self.m_lb_percent_pay:setString(allPoints .. "/" .. pointsNext)
                local count = 0
                local curPercent = 100
                local addPercent = (endPercent - curPercent) / 20
                local setPercent = function()
                    count = count + 1
                    if count > 20 then
                        self.m_loadingBar:stopAllActions()
                        self:setBarPercent()
                        return
                    end
                    curPercent = curPercent + addPercent
                    self.m_loadingBar:setPercent(curPercent)
                    self.m_loadingBar_pay:setPercent(curPercent)
                end
                setPercent()
                schedule(self.m_loadingBar, setPercent, 0.02)
            end

            progressAction()
        end
    end
end

function HolidayChallenge_BaseWheelLayer:registerListener()
    HolidayChallenge_BaseWheelLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params and params.isSuccess then
                self.m_wheelSpinReward = params.rewardItems
                self.m_targetIndex = 0
                if self.m_wheelSpinReward then
                    self.m_targetIndex = self.m_wheelSpinReward.hitIndex + 1
                end
                self.m_gridIndexList = params.gridIndexList or {}
                self:setSpinLeft()
                self:initActList()
                self:rotateWheel()
            else
                self.m_isTouch = false
            end
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_WHEEL_SPIN
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:closeUI(
                    function()
                        if self.m_callback then
                            self.m_callback()
                        end
                    end
                )
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

-- 创建奖励界面
function HolidayChallenge_BaseWheelLayer:createRewardLayer()
    if not self.m_wheelSpinReward then
        self.m_isTouch = false
        return
    end

    -- 道具列表
    local coins = tonumber(self.m_wheelSpinReward.coins or 0)
    local itemDataList = {}
    -- 金币道具
    if coins and coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        itemData:setTempData({p_limit = 3})
        itemDataList[#itemDataList + 1] = itemData
    end
    -- 通用道具
    if self.m_wheelSpinReward.items and #self.m_wheelSpinReward.items > 0 then
        for i, v in ipairs(self.m_wheelSpinReward.items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            local itemData = gLobalItemManager:createLocalItemData(tempData.p_icon, tempData.p_num, tempData)
            if string.find(itemData.p_icon, "club_pass") or string.find(itemData.p_icon, "coupon") then
                itemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
            end
            itemDataList[#itemDataList + 1] = itemData
        end
    end

    local clickFunc = function()
        local func = function()
            local cb = function()
                if not tolua.isnull(self) then
                    self:refreshView()
                end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, cb)
        end

        if CardSysManager:needDropCards("Supply Draw") == true then
            CardSysManager:doDropCards(
                "Supply Draw",
                function()
                    func()
                end
            )
        else
            func()
        end
    end

    local type = ""
    if coins and coins > 0 then -- jackpot
        type = "jackpot"
    end
    local view = G_GetMgr(ACTIVITY_REF.HolidayChallenge):showWheelRewardLayer(itemDataList, clickFunc, coins, type)
    self.m_wheelSpinReward = nil
    if not view then
        clickFunc()
    end
end

function HolidayChallenge_BaseWheelLayer:resetNodeItem()
    for i=1,#self.m_wheelCellList do
        local cell = self.m_wheelCellList[i]
        if cell and cell.resetNodeItem then
            cell:resetNodeItem()
        end
    end
end

function HolidayChallenge_BaseWheelLayer:resetDarkTick()
    for i=1,#self.m_wheelCellList do
        local cell = self.m_wheelCellList[i]
        if cell and cell.resetDarkTick then
            cell:resetDarkTick()
        end
    end
end

function HolidayChallenge_BaseWheelLayer:refreshView()
    self:initBuyBtnLabel()
    self:initBtnShow()
    self:jackPotAnimation()
    self:transitionAni()
end

-- free转场pay 动效
function HolidayChallenge_BaseWheelLayer:transitionAni()
    if self:isShowLock() then
        local actionName = "shuaxin"
        if self.m_isFreeWheel then
            self:resetNodeItem()
            actionName = "shengji"
            gLobalSoundManager:playSound(self.m_activityConfig.RESPATH.WHEEL_DRAW_UPGRADE_MP3)
        end
        self:runCsbAction(
            actionName,
            false,
            function()
                self:runCsbAction("idle2", true)
                self:resetDarkTick()
                self:playAddLock()
                self.m_isTouch = false
            end,
            60
        )
    else
        self.m_isTouch = false
    end
end

function HolidayChallenge_BaseWheelLayer:playAddLock()
    if self.m_lockPayNode then
        self.m_lockPayNode:setVisible(true)
        util_spinePlay(self.m_lockPayNode, "lock_Y", false)
        util_spineEndCallFunc(self.m_lockPayNode, "lock_Y", function()
            util_spinePlay(self.m_lockPayNode, "idle_Y",true)
        end) 
    end
end

function HolidayChallenge_BaseWheelLayer:playUnlock()
    if self.m_lockPayNode then
        util_spinePlay(self.m_lockPayNode, "unlock_Y", false)
        util_spineEndCallFunc(self.m_lockPayNode, "unlock_Y", function()
            self.m_lockPayNode:setVisible(false)
            self.m_isTouch = false
        end) 
    end
end

-- 购买付费轮盘
function HolidayChallenge_BaseWheelLayer:buyWheelPay()
    local wheelData = self:getWheelData()
    if not wheelData then
        return
    end
    self.m_isTouch = true
    local wheelPayData = wheelData:getWheelPay()
    local params = {}
    params.keyId = wheelPayData.m_keyId
    params.price = wheelPayData.m_price

    self:sendIapLog(params)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.HOLIDAY_WHEEL_PAY,
        params.keyId,
        params.price,
        0,
        0,
        function()
            if not tolua.isnull(self) then
                self:buySuccess()
            end
        end,
        function()
            if not tolua.isnull(self) then
                self:buyFailed()
            end
        end
    )
end

function HolidayChallenge_BaseWheelLayer:buySuccess()
    self.m_isFreeWheel = false
    self:initBtnShow()
    self:setSpinLeft()
    self:setBarPercent()
    gLobalViewManager:checkBuyTipList(
        function()
            if not tolua.isnull(self) then
                self:playUnlock()
            end
        end
    )
end

function HolidayChallenge_BaseWheelLayer:buyFailed()
    self.m_isTouch = false
end

function HolidayChallenge_BaseWheelLayer:sendIapLog(params)
    -- 商品信息
    local goodsInfo = {}
    goodsInfo.goodsTheme = "HolidayPayWheel"
    goodsInfo.goodsId = params.keyId
    goodsInfo.goodsPrice = params.price
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "HolidayPayWheel"
    purchaseInfo.purchaseStatus = "HolidayPayWheel"

    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

-- ============================ 动画部分 ============================
-- 开始转动
function HolidayChallenge_BaseWheelLayer:rotateWheel()
    if self.m_targetIndex <= 0 then
        return
    end

    self.m_isWheelRotate = true
end

--初始化动画队列
function HolidayChallenge_BaseWheelLayer:initActList()
    local wheelData = self:getWheelData()
    if not wheelData or self.m_targetIndex <= 0 then
        self:createRewardLayer()
        return
    end
    local gridIndexList = self.m_gridIndexList
    if #gridIndexList > 1 then
        local targetIndex = 0
        for i = 1, #gridIndexList do
            if self.m_targetIndex == gridIndexList[i] then
                targetIndex = i
                break
            end
        end
        local tempActTime = actNum
        if #gridIndexList >= 9 then
            tempActTime = tempActTime - 1
        end
        local tempSlowNum = slowNum
        local actLen = tempActTime * #gridIndexList + targetIndex
        if actLen < 20 then
            tempSlowNum = actLen - 20
        end
        local inx = 1
        for i = 1, actLen do
            table.insert(self.m_actList, gridIndexList[inx])
            inx = inx + 1
            if inx > #gridIndexList then
                inx = 1
            end
        end
        self.m_interval = (actTime - slowTime) / (actLen - tempSlowNum)

        self:unscheduleUpdate()
        self:onUpdate(handler(self, self.updateActScheduler))
    else
        self:wheelRotateEnd()
    end
end

function HolidayChallenge_BaseWheelLayer:updateActScheduler(dt)
    self.m_turnTime = self.m_turnTime + dt
    if self.m_interval > self.m_turnTime then
        return
    end
    if #self.m_actList - self.m_curIndex <= slowNum then
        self.m_slowTime = self.m_slowTime - dt
        local slowT = self.m_slowTargetTime - (self.m_slowTargetTime / slowNum) * self.m_slowNum
        if self.m_slowTime <= slowT then
            self.m_slowNum = self.m_slowNum + 1
            self.m_slowTime = slowTime
        else
            return
        end
    end

    gLobalSoundManager:playSound(self.m_activityConfig.RESPATH.WHEEL_DRAW_MP3)
    local index = self.m_actList[self.m_curIndex]
    local cell = self.m_wheelCellList[index]
    if cell then
        cell:playStart()
    end
    self.m_turnTime = 0
    if self.m_curIndex >= #self.m_actList then
        self:unscheduleUpdate()
        self:initActDatas()
        self:wheelRotateEnd()
    else
        self.m_curIndex = self.m_curIndex + 1
    end
end

-- 转动结束
function HolidayChallenge_BaseWheelLayer:wheelRotateEnd()
    local cell = self.m_wheelCellList[self.m_targetIndex]
    self.m_isWheelRotate = false
    self.m_targetIndex = 0
    local stopMp3 = self.m_activityConfig.RESPATH.WHEEL_DRAW_STOP_MP3
    local coins = self.m_wheelSpinReward and tonumber(self.m_wheelSpinReward.coins or 0) or 0
    if coins > 0 then
        stopMp3 = self.m_activityConfig.RESPATH.WHEEL_DRAW_WINALL_MP3
    end
    gLobalSoundManager:playSound(stopMp3)
    if cell then
        cell:playOver(
            function()
                if not tolua.isnull(self) then
                    self:createRewardLayer()
                end
            end
        )
    end
end

return HolidayChallenge_BaseWheelLayer
