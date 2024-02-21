--[[
Author: cxc
Date: 2021-06-11 12:03:09
LastEditTime: 2021-07-09 18:22:37
LastEditors: Please set LastEditors
Description: RippleDash 活动(LevelRush挑战活动) 管理器
FilePath: /SlotNirvana/src/activities/Activity_RippleDash/controller/ActivityRippleDashManager.lua
--]]
local RippleDashNet = require("activities.Activity_RippleDash.net.RippleDashNet")
local Activity_RippleDashConfig = util_require("activities.Activity_RippleDash.config.Activity_RippleDashConfig")
local ActivityRippleDashManager = class("ActivityRippleDashManager", BaseActivityControl)

-- function ActivityRippleDashManager:getInstance()
--     if self.m_instance == nil then
--         self.m_instance = ActivityRippleDashManager.new()
-- 	end
-- 	return self.m_instance
-- end

function ActivityRippleDashManager:ctor()
    ActivityRippleDashManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RippleDash)
    self.m_bHadSpin = false -- 进入关卡 第一次 spin
    self.m_bReqIng = false -- 请求中标识

    self.m_bClickPurchase = false -- 是否点过充值按钮
    self:registerListener()
end

function ActivityRippleDashManager:getActivityData(bForce)
    if self.m_activityData and not bForce then
        return self.m_activityData
    end
    -- local activityData = clone(G_GetActivityDataByRef(ACTIVITY_REF.RippleDash))
    local activityData = clone(self:getRunningData())
    self.m_activityData = activityData
    return activityData
end

function ActivityRippleDashManager:getRunningData()
    local data = BaseActivityControl.getRunningData(self)
    if data and not self.m_themeName then
        local themeName = data:getThemeName()
        self.m_themeName = themeName
    end

    return data
end

-- function ActivityRippleDashManager:getConfig()
--     -- if not self.m_configData then
--     --     local actData = self:getActivityData()
--     --     local configPath = "Activity/" .. self.m_themeName .. "Config"
--     --     self.m_configData = util_getRequireFile(configPath)
--     -- end

--     -- return self.m_configData

--     return  Activity_RippleDashConfig
-- end

-- 领取奖励成功后，金币的数量 会变
function ActivityRippleDashManager:getNewRewardData(_phase, bPayType)
    -- local newActData = G_GetActivityDataByRef(ACTIVITY_REF.RippleDash)
    local newActData = self:getRunningData()
    if not newActData then
        return
    end

    local rewardDataList = {}
    if not bPayType then
        rewardDataList = newActData:getNormalRewardList()
    else
        rewardDataList = newActData:getPayRewardList()
    end

    for i, data in ipairs(rewardDataList) do
        local phase = data:getPhase()
        if phase == _phase then
            return data
        end
    end

    return nil
end

-- 弹出主面板
function ActivityRippleDashManager:popUpMainLayer(_cb, _params)
    _cb = _cb or function()
        end

    if not self:isCanShowLayer() then
        _cb()
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_RippleDashMainLayer") then
        _cb()
        return
    end

    -- csc 2021-08-11
    local view = self:checkPopLayerCondition(_cb, _params)
    return view
end

-- 弹出进度板 csc 2021年08月11日 新增
function ActivityRippleDashManager:createProgressLayer(_cb, _params)
    _cb = _cb or function()
        end

    local progressLayer = util_createFindView("Activity/" .. self.m_themeName .. "ProgressLayer", _params)
    if not progressLayer then
        local view = self:createMainLayer(_cb)
        return view
    end

    progressLayer:setViewOverFunc(_cb)
    progressLayer:setExtendData("Activity_RippleDashProgressLayer")
    gLobalViewManager:showUI(progressLayer, ViewZorder.ZORDER_UI)
    return progressLayer
end

-- 弹出主面板
function ActivityRippleDashManager:createMainLayer(_cb)
    _cb = _cb or function()
        end

    local mainlayer = util_createFindView("Activity/" .. self.m_themeName .. "MainLayer")
    if not mainlayer then
        _cb()
        return
    end

    mainlayer:setOverFunc(_cb)
    mainlayer:setExtendData("Activity_RippleDashMainLayer")
    gLobalViewManager:showUI(mainlayer, ViewZorder.ZORDER_UI)
    return mainlayer
end

-- 诱导支付面板
function ActivityRippleDashManager:popupPurchaseLayer(_cb)
    _cb = _cb or function()
        end

    if not self:isCanShowLayer() then
        _cb()
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_RippleDashPurchase") then
        _cb()
        return
    end

    self:createPurchaseLayer(_cb)
end

function ActivityRippleDashManager:createPurchaseLayer(_cb)
    _cb = _cb or function()
        end

    --csc 2021-08-28 14:28:24 付费界面也需要做成多主题
    local layer = util_createFindView("Activity/" .. self.m_themeName .. "Purchase")
    if not layer then
        _cb()
        return
    end

    layer:setOverFunc(_cb)
    layer:setExtendData("Activity_RippleDashPurchase")
    gLobalViewManager:showUI(layer, ViewZorder.ZORDER_UI)
end

function ActivityRippleDashManager:checkPopLayerCondition(_cb, _params)
    local view
    -- 如果有新阶段产生，需要区分阶段是否满足可领奖励
    if self.m_bHasNewPhase then
        self.m_bHasNewPhase = false
        -- local newActData = G_GetActivityDataByRef(ACTIVITY_REF.RippleDash)
        local newActData = self:getRunningData()
        local newPhase = newActData:getCurPhase()
        local bHadAllCollect = self:getHadAllCollect(newActData, newPhase, false)
        -- 这里需要检测一次当前要弹出什么板子  没有奖励可以领的话,弹进度板
        if bHadAllCollect then
            view = self:createMainLayer(_cb)
        else
            view = self:createProgressLayer(_cb, _params)
        end
    else
        view = self:createMainLayer(_cb)
    end
    return view
end

--------------------- 网络 ---------------------

function ActivityRippleDashManager:goPurchase()
    -- local actData = self:getActivityData()
    -- if not actData or not actData:isRunning() then
    --     return
    -- end

    -- local goodsInfo = {}
    -- goodsInfo.discount = -1
    -- goodsInfo.goodsId = actData:getGoodsKeyId()
    -- goodsInfo.goodsPrice = tostring(actData:getPrice())
    -- gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)

    -- self:sendIapLog(goodsInfo, actData:getCurPhase())

    -- --添加道具log
    -- local itemList = gLobalItemManager:checkAddLocalItemList(actData)
    -- gLobalSaleManager:purchaseGoods(BUY_TYPE.RIPPLE_DASH,  goodsInfo.goodsId, goodsInfo.goodsPrice, 0, 0, handler(self, self.buySuccess), handler(self, self.buyFailed))
    self.m_bClickPurchase = true
    RippleDashNet:getInstance():goPurchase()
end
-- function ActivityRippleDashManager:buySuccess()
--     self:getActivityData(true)
--     gLobalViewManager:checkBuyTipList(function()
--         gLobalNoticManager:postNotification(self.m_configData.EventName.NOTIFY_RIPPLE_DASH_BUY_SUCCESS)
--     end)
-- end
-- function ActivityRippleDashManager:buyFailed()

-- end

-- 领取奖励
function ActivityRippleDashManager:sendCollectReward(_phase, _bPay)
    -- if self.m_bReqIng then
    --     return
    -- end
    -- gLobalViewManager:addLoadingAnima(true)
    -- self.m_bReqIng = true

    -- local function successCallFunc(target, resData)
    --     gLobalViewManager:removeLoadingAnima()

    --     local config = self:getConfig()
    --     local eventName = "NOTIFY_COLLECT_RD_REWARD_SUCCESS"
    --     if config then
    --        eventName = config.EventName.NOTIFY_COLLECT_RD_REWARD_SUCCESS
    --     end
    --     gLobalNoticManager:postNotification(eventName)
    -- end

    -- local function failedCallFunc(target, code, errorMsg)
    --     gLobalViewManager:removeLoadingAnima()
    --     self.m_bReqIng = false
    -- end

    -- local actionData = self:getSendActionData(ActionType.RippleDashCollect)
    -- local params = {}
    -- params["times"] = _phase
    -- params["type"] = _bPay and "pay" or "free"
    -- actionData.data.params = json.encode(params)
    -- self:sendMessageData(actionData, successCallFunc, failedCallFunc)
    RippleDashNet:getInstance():sendCollectReward(_phase, _bPay)
end

--------------------- 网络 ---------------------
-- 是否解锁 支付奖励
function ActivityRippleDashManager:checkIsUnlockPayReward()
    local actData = self:getActivityData()
    if not actData or not actData:isRunning() then
        return false
    end

    return actData:checkHadPurchase()
end

-- 检查是否 更新了阶段
-- cxc 2021-07-02 02:46:06  触发条件（产生 新阶段 或者 有未领取任务首次spin）
-- cxc 2021-07-02 14:52:49 触发条件 改
-- 1. 激活 LevelRush任务
-- 2. 产生新阶段
-- 3. 有未领取奖励 首次spin
function ActivityRippleDashManager:checkUpatePhase(_bUp)
    if not self:isCanShowLayer() then
        self.m_bHadSpin = true
        return false
    end

    local preActData = self:getActivityData()
    -- local newActData = G_GetActivityDataByRef(ACTIVITY_REF.RippleDash)
    local newActData = self:getRunningData()
    if not newActData then
        -- 没有新的活动数据 返回false
        return false
    end

    local curPhase = preActData:getCurPhase()
    local newPhase = newActData:getCurPhase()
    local bHadAllCollect = self:getHadAllCollect(newActData, newPhase)

    -- 产生新的阶段
    if newPhase > curPhase then
        self.m_bHadSpin = true
        self.m_bHasNewPhase = true
        local bCompleteAllTask = newActData:checkCompleteAllTask()
        if bCompleteAllTask then
            -- 完成所有任务 (-是否有可领取的)
            self.m_bHasNewPhase = false
            return bHadAllCollect
        end
        return true
    end

    -- LevelRush任务激活 关闭UpView弹窗后也 弹这个活动
    if gLobalLevelRushManager:isSpinActiveUpView() then
        gLobalLevelRushManager:resetSpinActiveUpView()
        self.m_bHadSpin = true
        local bCompleteAllTask = newActData:checkCompleteAllTask()
        if bCompleteAllTask then
            -- 完成所有任务 (-是否有可领取的)
            return bHadAllCollect
        end
        return true
    end

    if self.m_bHadSpin then
        -- 不是第一次 spin
        return false
    end
    self.m_bHadSpin = true
    return bHadAllCollect
end

-- 是否有未领取的奖励
function ActivityRippleDashManager:getHadAllCollect(_actData, _newPhase, _ignorePurchase)
    if not _actData or not _newPhase then
        return false
    end

    -- 1. 判断普通阶段的 奖励是否领取
    local bCanCollect = false
    local unRewardList = _actData:getNormalRewardList()
    for i = 1, 3 do
        local data = unRewardList[i]
        if not data then
            return false
        end

        local phase = data:getPhase()
        if phase > _newPhase then
            break
        end

        if not data:checkIsCollected() then
            bCanCollect = true
            break
        end
    end

    -- 2. new逻辑：充值阶段的不需要判断是否充值。没充值也算未领取诱导去打开界面充值
    -- csc 2021-08-11 添加新值 _ignorePurchase 用来判断是否忽略充值状态
    _ignorePurchase = _ignorePurchase == nil and true or self:checkIsUnlockPayReward()
    if not bCanCollect and _ignorePurchase == true then
        local unRewardList = _actData:getPayRewardList()
        for i = 1, 3 do
            local data = unRewardList[i]
            if not data then
                return false
            end

            local phase = data:getPhase()
            if phase > _newPhase then
                break
            end

            if not data:checkIsCollected() then
                bCanCollect = true
                break
            end
        end
    end

    return bCanCollect
end

-- 重置 进入关卡 spin 标识
function ActivityRippleDashManager:resetFirstSpinSign()
    self.m_bHadSpin = false
end

-- 请求中 标识
function ActivityRippleDashManager:setReqIngSign(_bIng)
    -- self.m_bReqIng = _bIng
    RippleDashNet:getInstance():setReqIngSign(_bIng)
end
function ActivityRippleDashManager:getReqIngSign()
    -- return self.m_bReqIng
    return RippleDashNet:getInstance():getReqIngSign()
end

-- 是否点击过充值按钮
function ActivityRippleDashManager:checkIsClickPurchase()
    return self.m_bClickPurchase
end
function ActivityRippleDashManager:resetClickPurchaseSign()
    self.m_bClickPurchase = false
end

-- 注册消息事件
function ActivityRippleDashManager:registerListener()
    gLobalNoticManager:addObserver(self, "resetFirstSpinSign", ViewEventType.NOTIFY_CLEAR_RIPPLEDASH_LEVEL_SIGN)
end

-- function ActivityRippleDashManager:sendIapLog(_goodsInfo, _curPhase)
--     if not _goodsInfo or not _curPhase then
--         return
--     end

--     -- 商品信息
--     local goodsInfo = {}

--     goodsInfo.goodsTheme = "RippleDashUnlock"
--     goodsInfo.goodsId = _goodsInfo.goodsId
--     goodsInfo.goodsPrice = _goodsInfo.goodsPrice
--     goodsInfo.discount = 0
--     goodsInfo.totalCoins = 0

--     -- 购买信息
--     local purchaseInfo = {}
--     purchaseInfo.purchaseType = "LimitBuy"
--     purchaseInfo.purchaseName = "RippleDashUnlock"
--     purchaseInfo.purchaseStatus = _curPhase

--     gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo,nil,nil,self)
-- end

return ActivityRippleDashManager
