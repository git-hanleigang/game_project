--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-05 10:32:18
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-05 16:21:06
FilePath: /SlotNirvana/src/views/levelup/LevelUpLayer.lua
Description: 升级弹板
--]]
local LevelUpLayer = class("LevelUpLayer", BaseLayer)

function LevelUpLayer:initDatas(_closeCb)
    LevelUpLayer.super.initDatas(self)

    self._closeCb = _closeCb
    self._showMaxBetUpAni = false -- 显示最大bet值提升动画
    self._showCashMoneyAni = false -- 显示新cashMoney动画
    self.m_totalCoins = 0
    self._rewardList = {} -- 升级奖励列表
    self._levelOrderList = {} -- 升级奖励排序表

    self:setPauseSlotsEnabled(true)
    self:setExtendData("LevelUpLayer")
    self:setName("LevelUpLayer")

    self:setLandscapeCsbName("LevelUp_new/LevelUpLayer.csb")
    self:setPortraitCsbName("LevelUp_new/LevelUpLayer_p.csb")
    self:logLVUp()
end

function LevelUpLayer:getRewardList()
    return self._rewardList
end
function LevelUpLayer:getLevelOrderList()
    return self._levelOrderList 
end

function LevelUpLayer:initCsbNodes()
    LevelUpLayer.super.initCsbNodes(self)

    self.m_btnClose = self:findChild("btn_close")
    self.m_lb_coins = self:findChild("m_lb_coins")
    local uiList = {
        {node = self:findChild("m_sp_coins"), scale = 1},
        {node = self.m_lb_coins, alignX = 11, alignY = 1.5},
    }
    self.m_coinsUIList = uiList
end

function LevelUpLayer:initLevelUpData(_data)
    _data = _data or {}
    local curLevel = globalData.userRunData.levelNum
    local preLevel = _data[1] or (curLevel - 1)
    -- 
    --添加奖励列表
    local levelOrderList = globalData.userRunData:getLevelOrderDatas() or {}
    local rewardList = {}
    rewardList[LEVEL_REWARD_ENMU.MAXBET] = 0 -- MAXBET
    rewardList[LEVEL_REWARD_ENMU.CASHMONEY] = 0 -- 银库奖励
    rewardList[LEVEL_REWARD_ENMU.CASHWHEEL] = 0 -- 转盘奖励
    rewardList[LEVEL_REWARD_ENMU.VIP] = 0 -- 升级奖励vip 点数
    rewardList[LEVEL_REWARD_ENMU.CLUB] = 0 -- 高倍场奖励
    rewardList[LEVEL_REWARD_ENMU.COINS] = 0 -- 金币
    local rewardCoins = 0
    --从服务器获取升级通用奖励
    for i = preLevel, curLevel - 1 do
        local curData = globalData.userRunData:getLevelUpRewardInfo(i)
        if curData and curData.p_coins then
            rewardCoins = rewardCoins + curData.p_coins -- 升级到下一级奖励金币
            rewardList[LEVEL_REWARD_ENMU.CASHMONEY] = rewardList[LEVEL_REWARD_ENMU.CASHMONEY] + curData.p_treasury -- 银库奖励
            rewardList[LEVEL_REWARD_ENMU.CASHWHEEL] = rewardList[LEVEL_REWARD_ENMU.CASHWHEEL] + curData.p_wheel -- 转盘奖励
            rewardList[LEVEL_REWARD_ENMU.VIP] = rewardList[LEVEL_REWARD_ENMU.VIP] + curData.p_vipPoint -- 升级奖励vip 点数
            rewardList[LEVEL_REWARD_ENMU.CLUB] = rewardList[LEVEL_REWARD_ENMU.CLUB] + curData.p_clubPoint -- 高倍场奖励
        end
    end
    -- 金币
    rewardList[LEVEL_REWARD_ENMU.COINS] = rewardCoins

    --maxBet
    local maxBetData = globalData.slotRunData:getMaxBetData()
    rewardList[LEVEL_REWARD_ENMU.MAXBET] = maxBetData.p_totalBetValue
    -- 最大bet值提升动画节点
    if globalData.slotRunData.machineData:checkNewMaxBetActive() then
        local curMaxBetInfo, preMaxBetInfo = globalData.slotRunData.machineData:getMaxBetCfgData()
        self._showMaxBetUpAni = curMaxBetInfo and preMaxBetInfo
    end

    --cashmoney
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    if cashMoneyData and cashMoneyData.p_cashMultiply and cashMoneyData.p_vipMultiply then
        rewardList[LEVEL_REWARD_ENMU.CASHMONEY] = tonumber(cashMoneyData.p_cashMultiply) * tonumber(cashMoneyData.p_vipMultiply) * 4000
    end
    if rewardList[LEVEL_REWARD_ENMU.CASHMONEY] > 0 then
        local preLevelData = globalData.userRunData:getLevelUpRewardInfo(preLevel)
        local curLevelData = globalData.userRunData:getLevelUpRewardInfo(curLevel)
        if preLevelData and preLevelData.p_treasury and curLevelData and curLevelData.p_treasury then
            -- 本次升级  服务器给的数据有 升级再显示cashmoney
            self._showCashMoneyAni = tonumber(curLevelData.p_treasury) > tonumber(preLevelData.p_treasury)
        end
    end

    --移除为0的item
    for i = #levelOrderList, 1, -1 do
        local levelOrderItem = levelOrderList[i]
        if levelOrderItem and levelOrderItem.p_name then
            --根据枚举值获得客户端奖励名字
            local name = LEVEL_REWARD_ENMU[levelOrderItem.p_name]
            if name then
                --检测奖励值是否为0
                if not rewardList[name] or rewardList[name] == 0 then
                    table.remove(levelOrderList, i)
                end
            end
        end
    end

    self._rewardList = rewardList
    self._levelOrderList = levelOrderList

    -- 初始化 UI
    self:initContentUI()

    gLobalSendDataManager:getLogFeature():sendLevelUp(preLevel, curLevel, rewardCoins, rewardList[LEVEL_REWARD_ENMU.VIP])
end

function LevelUpLayer:initContentUI()
    -- 等级
    self:initLVUI()
    -- 金币 及 加成
    self:initCoinsUI()
    -- 奖励 列表
    self:initRewardListUI()
    -- 最大bet 更新 动画
    if self._showMaxBetUpAni then
        self:initMaxBetUpAniUI()
    end
    -- cashmoeny动画
    if self._showCashMoneyAni then
        self:initCashMoneyANiUI()
    end
    -- 广告
    self:initAdUI()
end

-- 等级
function LevelUpLayer:initLVUI()
    local curLevel = globalData.userRunData.levelNum
    local lbLv = self:findChild("m_lb_num")
    lbLv:setString(curLevel)

    local uiList = {
        {node = self:findChild("sp_level"), scale = 1},
        {node = self:findChild("sp_up"), alignX = 9, alignY = 10, scale = 1},
        {node = lbLv, alignX = 11, alignY = 6.5, scale = 1}
    }
    util_alignCenter(uiList)
end

-- 金币 及 加成
function LevelUpLayer:initCoinsUI()
    local curLevel = globalData.userRunData.levelNum
    -- Buff倍数
    local multiple = globalData.buffConfigData:getAllCoinBuffMultiple(curLevel) or 1
    multiple = math.max(1, multiple)
    local lbBooster = self:findChild("m_lb_booster")
    lbBooster:setString("X" .. multiple)
    local spBooster = self:findChild("m_sp_booster")
    spBooster:setVisible(multiple > 1)

    -- 金币
    local rewardCoins = self._rewardList[LEVEL_REWARD_ENMU.COINS] or 0
    self.m_totalCoins = rewardCoins
    self:updateLbCoinsUI()

    -- 最终金币  金币 * 倍数
    local mulCoins = 0
    mulCoins = rewardCoins * multiple
    self.m_totalCoins = mulCoins

    --booster动画 有倍数要播放动画
    if mulCoins > 0 then
        performWithDelay(
            self,
            function()
                if not self.m_fastIdle then
                    local addV = (self.m_totalCoins - rewardCoins) / (0.6 * 60)
                    util_jumpNumExtra(self.m_lb_coins, rewardCoins, self.m_totalCoins, addV, 1/60, util_getFromatMoneyStr, {20}, nil, nil, util_node_handler(self, self.updateLbCoinsUI), util_node_handler(self, self.updateCoinLbSizeScale))
                end
            end,
            2.1
        )
    end
end
function LevelUpLayer:updateLbCoinsUI()
    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_totalCoins))
    self:updateCoinLbSizeScale()
end
function LevelUpLayer:updateCoinLbSizeScale()
    util_alignCenter(self.m_coinsUIList)
end

-- 奖励 列表
function LevelUpLayer:initRewardListUI()
    local parent = self:findChild("node_itemList")
    local view = util_createView("views.levelup.LVUpRewardListUI", self, self._levelOrderList, self._rewardList)
    parent:addChild(view)
    self._rewardListView = view
end

-- 最大bet 更新 动画
function LevelUpLayer:initMaxBetUpAniUI()
    local curMaxBetInfo, preMaxBetInfo = globalData.slotRunData.machineData:getMaxBetCfgData()
    local nodeMaxBetUp = self:findChild("node_maxbet")
    local maxBetUpAniView = util_createView("views.levelup.LVUpMaxBetUpAniUI", {preMaxBetInfo.p_totalBetValue, curMaxBetInfo.p_totalBetValue})
    nodeMaxBetUp:addChild(maxBetUpAniView)
    self._maxBetUpAniView = maxBetUpAniView
end

-- cashmoeny动画
function LevelUpLayer:initCashMoneyANiUI()
    local cashMoneyParent = self:findChild("node_cashmoney")
    local cashMoneyAniView = util_createView("views.levelup.LVUpCashMoneyUpAniUI", self._rewardList[LEVEL_REWARD_ENMU.CASHMONEY])
    cashMoneyParent:addChild(cashMoneyAniView)
    self._cashMoneyAniView = cashMoneyAniView
end

-- 广告
function LevelUpLayer:initAdUI()
    self:hideDoubleBtn(false)
    -- 广告打点
    if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.LevelUp) then
        self._bCanDoAD = true
        self:logADPush()
        self:hideDoubleBtn(true)
    end
end

function LevelUpLayer:hideDoubleBtn(_flag)
    self.m_btnClose:setVisible(_flag)
    self._rewardListView:hideDoubleBtn(_flag)
end

-- 骨骼 npc
function LevelUpLayer:initSpineUI()
    local parent = self:findChild("node_spine")
    self.m_spineNpc = util_spineCreate("LevelUp_new/spine/lvUpRole", false, true, 1)
    parent:addChild(self.m_spineNpc)

    util_spinePlay(self.m_spineNpc, "start", false)
    util_spineEndCallFunc(
        self.m_spineNpc,
        "start",
        function()
            util_spinePlay(self.m_spineNpc, "idleframe", true)
        end
    )
end

-- 开启动画
function LevelUpLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/level_up2.mp3")
    LevelUpLayer.super.playShowAction(self, "start")

    local delayTime = 45 / 60
    local actionList = {
        cc.DelayTime:create(delayTime)
    }
    if self._showMaxBetUpAni and self._maxBetUpAniView then
        -- maxBet 提升动画
        local maxBetUpAniAct = cc.CallFunc:create(function()
            self._maxBetUpAniView:playShowAct()
        end)
        table.insert(actionList, maxBetUpAniAct)
        local maxBetDelayTime = self._maxBetUpAniView:getShowActTime()
        table.insert(actionList, cc.DelayTime:create(maxBetDelayTime))
    end
    if self._showCashMoneyAni and self._cashMoneyAniView then
        -- cashMoney 动画
        local cashMoneyUpAniAct = cc.CallFunc:create(function()
            self._cashMoneyAniView:playShowAct()
        end)
        table.insert(actionList, cashMoneyUpAniAct)
        local cashMoneyDelayTime = self._cashMoneyAniView:getShowActTime()
        table.insert(actionList, cc.DelayTime:create(cashMoneyDelayTime))
    end
   
    -- 奖励列表动画
    local rewardListViewAniAct = cc.CallFunc:create(function()
        self._rewardListView:playShowAct()
        self._bLayerShowOver = true
    end)
    table.insert(actionList, rewardListViewAniAct)

    -- 无广告播放自动关闭
    if not self._bCanDoAD then
        table.insert(actionList, cc.DelayTime:create(5))
        local autoCloseAct = cc.CallFunc:create(function()
            local uiView = gLobalViewManager:getViewByExtendData("AdsChallengeMainLayer")
            if not uiView then
                self:closeUI()
            end
        end)
        table.insert(actionList, autoCloseAct)
    end
    self:runAction(cc.Sequence:create(actionList))
end
function LevelUpLayer:onShowedCallFunc()   
    self:runCsbAction("idle", true, nil, 60)
end

function LevelUpLayer:logLVUp()
    if globalData.userRunData.levelNum == 15 then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_Level15)
        end
    elseif globalData.userRunData.levelNum == 10 then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_Level10)
        end
    elseif globalData.userRunData.levelNum == 20 then
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_Level20)
        end
    end
end
function LevelUpLayer:logADPush()
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.LevelUp)
    gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.LevelUp})

    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.LevelUp)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
end

-- 看完广告后双倍奖励
function LevelUpLayer:autoShowADReward()
    self:_addBlockMask()
    -- 播放音效
    local audioId = gLobalSoundManager:playSound("DailyBonusSound/coinIncrease.mp3")
    local spendTime = 1 / 60
    util_jumpNumExtra(
        self.m_lb_coins,
        self.m_totalCoins,
        self.m_totalCoins * 2,
        self.m_totalCoins * 0.05,
        spendTime,
        util_getFromatMoneyStr,
        {3},
        nil,
        nil,
        function()
            if audioId then
                gLobalSoundManager:stopAudio(audioId, true)
            end
            gLobalSoundManager:playSound("DailyBonusSound/coinIncreaseEnd.mp3")
            if gLobalAdChallengeManager:isShowMainLayer() then
                gLobalAdChallengeManager:showMainLayer()
            end
            self:_removeBlockMask()
        end
    )
end

function LevelUpLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function LevelUpLayer:onEnter()
    LevelUpLayer.super.onEnter(self)
    gLobalSoundManager:pauseBgMusic()
end
function LevelUpLayer:onExit()
    LevelUpLayer.super.onExit(self)
    gLobalSoundManager:resumeBgMusic()
end

function LevelUpLayer:closeUI()
    if not self._bLayerShowOver or self.isClose then
        return
    end
    self.isClose = true

    local cb = function()
        LevelUpLayer.super.closeUI(self, self._closeCb)
    end

    local startPos = self._rewardListView:getFlyCoinsPosWorld()
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        if self.m_totalCoins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_totalCoins, startPos = startPos})
        end
        curMgr:playFlyCurrency(flyList, cb)
    end
end

function LevelUpLayer:registerListener()
    LevelUpLayer.super.registerListener(self)
    
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalSoundManager:pauseBgMusic()
        end,
        ViewEventType.NOTIFY_PLAYBGMUSIC
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalSoundManager:pauseBgMusic()
        end,
        ViewEventType.NOTIFY_SETBGMUSICVOLUME
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) then
                if params[1] == "success" then
                    self:hideDoubleBtn(false)
                    self:autoShowADReward()
                else
                    self:hideDoubleBtn(false)
                end
            end
        end,
        ViewEventType.NOTIFY_ADS_DOUBLELEVELUP
    )
end

return LevelUpLayer