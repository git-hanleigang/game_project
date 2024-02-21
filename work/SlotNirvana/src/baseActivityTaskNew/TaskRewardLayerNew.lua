--[[
    任务奖励领取页
]]
-- ios fix
local BaseRotateLayer = require("base.BaseRotateLayer")
local TaskRewardLayerNew = class("TaskRewardLayerNew", BaseRotateLayer)
local ActivityTaskManager = util_require("manager.ActivityTaskNewManager"):getInstance()

function TaskRewardLayerNew:ctor()
    TaskRewardLayerNew.super.ctor(self)

    local csb_name = self:getCsbPath()

    self:setPortraitCsbName(csb_name)
    self:setLandscapeCsbName(csb_name)
end

--初始化数据
function TaskRewardLayerNew:initDatas()
    self.m_catFoodList = {}
    self.m_propsBagist = {}
    self.m_taskDataObj = ActivityTaskManager:getTaskReward(self:getActivityName())
    self.m_coins = self.m_taskDataObj.coins
    if self.m_taskDataObj.index then
        self.m_index = self.m_taskDataObj.index
    end
end

function TaskRewardLayerNew:initView()
    self:initDropList()
    self:addItems()
end

--添加道具
function TaskRewardLayerNew:addItems()
    if self.m_taskDataObj then
        local itemDataList = {}
        --金币道具
        if self.m_coins and self.m_coins > 0 then
            local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_coins)
            itemData:setTempData({p_limit = 3})
            itemDataList[#itemDataList + 1] = itemData
        end
        --通用道具
        local rewardItems = self.m_taskDataObj.itemList
        local count = #rewardItems
        if rewardItems and count > 0 then
            for i, v in ipairs(rewardItems) do
                itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)

                -- 高倍场小游戏猫粮会有单独 弹板并且弹板顺序有逻辑
                if string.find(v.p_icon, "CatFood") then
                    table.insert(self.m_catFoodList, v)
                end
                if string.find(v.p_icon, "Pouch") then
                    table.insert(self.m_propsBagist, v)
                end
            end
        end
        self.m_itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
        self.m_addItemNode:addChild(self.m_itemNode)
    end
end

--初始化节点
function TaskRewardLayerNew:initCsbNodes()
    self.m_addItemNode = self:findChild("Node_jiedian")
    assert(self.m_addItemNode, "用于添加道具的节点为空")
end

-- 弹出动画
function TaskRewardLayerNew:playShowAction()
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
    TaskRewardLayerNew.super.playShowAction(self, userDefAction)
end

-- 待机动画
function TaskRewardLayerNew:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function TaskRewardLayerNew:onClickMask()
    self:onClickCollect()
end

function TaskRewardLayerNew:clickFunc(_sander)
    self:onClickCollect()
end

function TaskRewardLayerNew:onClickCollect()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    ActivityTaskManager:requestCumulativeData(self:getActivityName())
end

--飞金币
function TaskRewardLayerNew:flyCoins(_flyCoinsEndCall)
    if self.m_coins and self.m_coins > 0 then
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
-- function TaskRewardLayerNew:playHideAction()
--     local userDefAction = function(callFunc)
--         self:runCsbAction(
--             "over",
--             false,
--             function()
--                 if callFunc then
--                     callFunc()
--                 end
--             end,
--             60
--         )
--     end
--     TaskRewardLayerNew.super.playHideAction(self, userDefAction)
-- end

--移除自身
function TaskRewardLayerNew:closeUI()
    TaskRewardLayerNew.super.closeUI(
        self,
        function()
            --领取结束
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_END,self.m_index)
        end
    )
end
function TaskRewardLayerNew:onEnter()
    TaskRewardLayerNew.super.onEnter(self)
    --领取成功
    gLobalNoticManager:addObserver(
        self,
        function(self, func)
            self:flyCoins(handler(self, self.triggerDropFuncNext))
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_SUCCESS
    )
end

------------------------------------------------------  子类必须重写  -----------------------------------------
function TaskRewardLayerNew:getCsbPath()
    assert("必要的界面资源名称")
end

function TaskRewardLayerNew:getActivityName()
    assert("必要的活动名称，用于获取相对应的活动任务")
end

function TaskRewardLayerNew:getCardSource()
    assert("必要的掉卡来源")
end
------------------------------------------------------  子类非必须重写 ----------------------------------------
function TaskRewardLayerNew:setLayerExtendData()
end

------------------------------------------------ 领取掉落 检测list ------------------------------------------------
-- 初始化 list
function TaskRewardLayerNew:initDropList()
    local _dropFuncList = {}

    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDropCrads)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerCatFoodView)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = handler(self, self.triggerPropsBagView)

    self.m_dropFuncList = _dropFuncList
end

-- 检测 list 调用方法
function TaskRewardLayerNew:triggerDropFuncNext()
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
function TaskRewardLayerNew:triggerDropCrads()
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
function TaskRewardLayerNew:triggerCatFoodView()
    local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
    catManager:popCatFoodRewardPanel(self.m_catFoodList, handler(self, self.triggerDropFuncNext))
end

-- 检测掉落 合成福袋
function TaskRewardLayerNew:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self.m_propsBagist, handler(self, self.triggerDropFuncNext))
end

-- 检测高倍场体验卡
function TaskRewardLayerNew:triggerDeluxeCard()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, handler(self, self.triggerDropFuncNext))
end
------------------------------------------------ 领取掉落 检测list ------------------------------------------------

return TaskRewardLayerNew
