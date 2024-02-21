--[[
    任务奖励领取页
]]
-- ios fix
local TaskRewardLayer = class("TaskRewardLayer", BaseLayer)
local ActivityTaskManager = util_require("manager.ActivityTaskManager"):getInstance()
local ShopItem = require "data.baseDatas.ShopItem"

-- 显示为竖版
local PortraitActList = {
    [ACTIVITY_REF.Activity_CoinPusherTask] = 1,
    [ACTIVITY_REF.Activity_NewCoinPusherTask] = 2,
    [ACTIVITY_REF.Activity_EgyptCoinPusherTask] = 3,
}

function TaskRewardLayer:ctor()
    TaskRewardLayer.super.ctor(self)

    local csb_name = self:getCsbPath()

    if PortraitActList[self:getActivityName()] then
        self:setShownAsPortrait(true)
        self:setPortraitCsbName(csb_name)
    else
        self:setLandscapeCsbName(csb_name)
    end
end

--初始化数据
function TaskRewardLayer:initDatas()
    self.m_catFoodList = {}
    self.m_propsBagist = {}
    self.m_taskDataObj = ActivityTaskManager:getCurrentTaskByActivityName(self:getActivityName())
    self.m_coins = self.m_taskDataObj:getCoins()
end

function TaskRewardLayer:initView()
    self:initDropList()
    self:addItems()
end

--添加道具
function TaskRewardLayer:addItems()
    if self.m_taskDataObj then
        local itemDataList = {}
        --金币道具
        if self.m_coins and toLongNumber(self.m_coins) > toLongNumber(0) then
            local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_coins)
            itemData:setTempData({p_limit = 3})
            itemDataList[#itemDataList + 1] = itemData
        end
        --通用道具
        local rewardItems = self.m_taskDataObj:getItemData()
        local count = #rewardItems
        if rewardItems and count > 0 then
            for i, v in ipairs(rewardItems) do
                local tempData = ShopItem:create()
                tempData:parseData(v)
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(tempData.p_icon, tempData.p_num, tempData)

                -- 高倍场小游戏猫粮会有单独 弹板并且弹板顺序有逻辑
                if string.find(tempData.p_icon, "CatFood") then
                    table.insert(self.m_catFoodList, tempData)
                end
                if string.find(tempData.p_icon, "Pouch") then
                    table.insert(self.m_propsBagist, tempData)
                end
            end
        end
        self.m_itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD, self:getItemScale())
        self.m_addItemNode:addChild(self.m_itemNode)
    end
end

--初始化节点
function TaskRewardLayer:initCsbNodes()
    self.m_addItemNode = self:findChild("Node_jiedian")
    assert(self.m_addItemNode, "用于添加道具的节点为空")
end

-- 弹出动画
function TaskRewardLayer:playShowAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "show",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    TaskRewardLayer.super.playShowAction(self, userDefAction)
end

-- 待机动画
function TaskRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function TaskRewardLayer:onClickCollect()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    local activityCommonType = self.m_taskDataObj:getActivityCommonType()
    local activityTaskPhase = self.m_taskDataObj:getPhase()
    ActivityTaskManager:requestCumulativeData(activityCommonType, activityTaskPhase)
end

function TaskRewardLayer:onClickMask()
    self:onClickCollect()
end

function TaskRewardLayer:clickFunc(_sander)
    self:onClickCollect()
end

--领取成功
function TaskRewardLayer:collectSuccess()
    self:flyCoins(handler(self, self.triggerDropFuncNext))
end

--领取失败
function TaskRewardLayer:collectFailed()
    gLobalViewManager:showReConnect()
    self.m_isCanTouch = false
end

--飞金币
function TaskRewardLayer:flyCoins(_flyCoinsEndCall)
    if self.m_coins and toLongNumber(self.m_coins) > toLongNumber(0) then
        local rewardCoins = self.m_coins
        local coinNode = self.m_itemNode:getChildByTag(1)
        local senderSize = coinNode:getContentSize()
        local startPos = coinNode:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
        view:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            rewardCoins,
            function()
                if _flyCoinsEndCall ~= nil then
                    _flyCoinsEndCall()
                end
            end
        )
    else
        if _flyCoinsEndCall ~= nil then
            _flyCoinsEndCall()
        end
    end
end

-- 收回动画
function TaskRewardLayer:playHideAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "over",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    TaskRewardLayer.super.playHideAction(self, userDefAction)
end

--移除自身
function TaskRewardLayer:closeUI()
    TaskRewardLayer.super.closeUI(
        self,
        function()
            --领取结束
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_END)
        end
    )
end
function TaskRewardLayer:onEnter()
    TaskRewardLayer.super.onEnter(self)

    --领取成功
    gLobalNoticManager:addObserver(
        self,
        function(self, func)
            self:collectSuccess()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_SUCCESS
    )
    --领取失败
    gLobalNoticManager:addObserver(
        self,
        function(self, func)
            self:collectFailed()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_FAILED
    )
end

------------------------------------------------------  子类必须重写  -----------------------------------------
function TaskRewardLayer:getCsbPath()
    assert("必要的界面资源名称")
end

function TaskRewardLayer:getActivityName()
    assert("必要的活动名称，用于获取相对应的活动任务")
end

function TaskRewardLayer:getCardSource()
    assert("必要的掉卡来源")
end
------------------------------------------------------  子类非必须重写 ----------------------------------------
--道具的缩放值
function TaskRewardLayer:getItemScale()
    return 1
end

function TaskRewardLayer:setLayerExtendData()
end

------------------------------------------------ 领取掉落 检测list ------------------------------------------------
-- 初始化 list
function TaskRewardLayer:initDropList()
    local _dropFuncList = {}

    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDropCrads)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerCatFoodView)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerPropsBagView)

    self.m_dropFuncList = _dropFuncList
end

-- 检测 list 调用方法
function TaskRewardLayer:triggerDropFuncNext()
    if not self.m_dropFuncList or #self.m_dropFuncList <= 0 then
        if not tolua.isnull(self) and self.closeUI then
            self:closeUI()
        end
        return
    end

    local func = table.remove(self.m_dropFuncList, 1)
    func()
end

-- 检测掉卡
function TaskRewardLayer:triggerDropCrads()
    local cardSource = self:getCardSource()
    if CardSysManager:needDropCards(cardSource) == true then
        -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                print("callFunc")
                release_print("callFunc")
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                self:triggerDropFuncNext()
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards(cardSource, nil)
    else
        self:triggerDropFuncNext()
    end
end

-- 检测掉落猫粮
function TaskRewardLayer:triggerCatFoodView()
    local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
    catManager:popCatFoodRewardPanel(self.m_catFoodList, handler(self, self.triggerDropFuncNext))
end

-- 检测掉落 合成福袋
function TaskRewardLayer:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self.m_propsBagist, handler(self, self.triggerDropFuncNext))
end

-- 检测高倍场体验卡
function TaskRewardLayer:triggerDeluxeCard()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, handler(self, self.triggerDropFuncNext))
end
------------------------------------------------ 领取掉落 检测list ------------------------------------------------

return TaskRewardLayer
