--[[
    @desc: 聚合挑战 manager 重新规划结构
    author:csc
    time:2021-10-12 16:36:11
    @return:
]]
local HolidayChallengeNet = util_require("activities.Activity_HolidayChallenge.net.HolidayChallengeNet")
local ShopItem = util_require("data.baseDatas.ShopItem")
local HolidayChallengeManager = class("HolidayChallengeManager", BaseActivityControl)

HolidayChallengeManager.TASK_TYPE = {
    -- 基础类型
    MISSION = "Mission",
    WHEELDAILY = "WheelDaily",
    LUCKYSTAMP = "LuckyStamp",
    CASHMONEY = "CashMoney",
    -- 活动类型
    COINPUSHER = "CoinPusher",
    LEVELRUSH = "LevelRush",
    BINGO = "Bingo",
    RICHMAN = "RichMan",
    BLAST = "Blast",
    DINNERLAND = "DinnerLand",
    QUEST = "Quest",
    LEAGUES = "Arena",
    PASS = "Pass",
    MegaWin = "MegaWin",
    EpicWin = "EpicWin",
    --... 任务类型来源 需要再对应位置填入
}

-- 构造函数
function HolidayChallengeManager:ctor()
    HolidayChallengeManager.super.ctor(self)

    self.m_currManager = nil
    self.m_configData = nil
    self.m_lightInfo = {}
    self.m_interruptTypeStr = "" --被什么游戏中断了

    self.m_spinLeft = 0   -- 转盘剩余次数
    self.m_lastPoint = 0 -- 上个阶段点数
    self.m_hasInit = false -- 是否首次初始化
    self.m_guide = false   -- 是否引导过
    self.m_completeTask = {}

    -- 设置当前 manager 捆绑的活动
    self:setRefName(ACTIVITY_REF.HolidayChallenge)
    -- 注册监听
    self:registerObservers()
end

--------------------------- 内部接口 ---------------------------
-- 判断 活动弹弹板是是否被中断
function HolidayChallengeManager:getIsInterrupt()
    return self.m_interruptTypeStr ~= ""
end

function HolidayChallengeManager:getPopName()
    local path = "views/HolidayChallengeBase/Activity_HolidayChallenge_BaseSendLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.MAINSENDER_LAYER then
        path = config.CODE_PATH.MAINSENDER_LAYER
    end

    return path
end

function HolidayChallengeManager:getPopPath(popName)
    return popName
end

-- 用来获取当前主题名拼接文件 -- splite:Activity_HolidayChallenge_Halloween -> [1]Activity [2]HolidayChallenge_Halloween
function HolidayChallengeManager:getCurrThemeName()
    local themename = self:getThemeName()
    -- themename = "Activity_HolidayChallenge_Halloween2022"
    return string.split(themename, "Activity_")[2]
end
--------------------------- 对外接口 ---------------------------
-- 设置 被中断的 游戏类型
function HolidayChallengeManager:setInterruptType(_type)
    self.m_interruptTypeStr = _type or ""
end
function HolidayChallengeManager:clearInterruptType()
    self.m_interruptTypeStr = ""
end

function HolidayChallengeManager:registerObservers()
    -- 监听零点刷新
    gLobalNoticManager:addObserver(
        self,
        function(sender)
            self:updateActivityData()
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_ZERO_REFRESH
    )
    -- 监听spinresult
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params[1] == true then
                local spinData = params[2]
                if spinData.action == "SPIN" then
                    self:onSpinResult(spinData)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function HolidayChallengeManager:getActivityData()
    --实际写法
    local activityData = clone(self:getRunningData())
    if activityData then
        return activityData
    end
    return nil
end

-- 获取配置文件
function HolidayChallengeManager:getConfig()
    if not self.m_configData and self:isCanShowLayer() then
        local pData = self:getActivityData()
        --获取主题名
        local configPath = "Activity/" .. self:getCurrThemeName() .. "Config" -- splite:Activity_ChocolateDate -> [1]Activity [2]ChocolateDate
        if not util_IsFileExist(configPath) then
            configPath = self:getThemeName() .."/" .. self:getCurrThemeName() .. "Config"
        end
        
        self.m_configData = util_require(configPath)
    end
    return self.m_configData
end

-- 零点刷新接口 更新数据
function HolidayChallengeManager:updateActivityData()
    local taskType = "Mission"
    self:sendRefreshReq(taskType, 0, true)
end

-- 获取点数是否
function HolidayChallengeManager:getIsMaxPoints()
    local pData = self:getActivityData()
    if not pData then
        return false
    end
    local currPoints = pData:getCurrentPoints()
    local maxPoints = pData:getMaxPoints()
    if currPoints >= maxPoints then
        return true
    end
    return false
end

-- 获取指定id的任务数据
function HolidayChallengeManager:getTaskDataByIndex(_index)
    local taskData = nil
    for k, v in pairs(self:getActivityData().m_taskData) do
        if v:getTaskSeqID() == _index then
            taskData = v
            break
        end
    end
    return taskData
end

-- 获取指定id的奖励数据
function HolidayChallengeManager:getRewardDataByIndex(_index)
    local pData = self:getActivityData()
    if not pData then
        return nil
    end
    return pData:getRewardData()[_index]
end

function HolidayChallengeManager:getTaskData(_ignoreComingsoon)
    local taskData = clone(self:getActivityData():getTaskData())
    if _ignoreComingsoon then
        for i = #taskData, 1, -1 do
            local task = taskData[i]
            if task:getStatus() == "comeSoon" then
                table.remove(taskData, i)
            end
        end
    end
    return taskData
end
--[[
    @desc: 获取所有的灯信息 
    @return: {pos = 对应灯的坐标 ,big = 是否为大块点 }
]]
function HolidayChallengeManager:getLightInfo(_scenePos)
    if not self.m_lightInfo[_scenePos] then
        self.m_lightInfo[_scenePos] = {}
        local config = self:getConfig()
        local lightConfig = config.LIGHTPOS_CONFIG

        local resConfig = config.RESPATH
        for i = 1, #lightConfig do
            local info = lightConfig[i]
            local data = {
                pos = info[_scenePos],
                big = info.big,
                actName = info.actName
            }
            table.insert(self.m_lightInfo[_scenePos], data)
        end
    end
    return self.m_lightInfo[_scenePos]
end

-- 提供方法刷新灯数组
function HolidayChallengeManager:refreshLightInfo()
    self.m_lightInfo = {}
end

-- 判断节日挑战是否完成了
function HolidayChallengeManager:getFinishAll()
    local pData = self:getActivityData()
    if pData then
        return pData:getFinishAll()
    end
    return false
end

-- 判断是否引导完成了 （考虑放弃这个方法,没啥用）
function HolidayChallengeManager:getCompletedGuide(_key)
    -- 这里需要处理当前主题的引导flag
    if not _key then
        _key = self:getConfig().GUIDE_KEY
    end
    return gLobalDataManager:getBoolByField(_key, false)
end

-- 专门为每日任务关闭收集之后做的接口
function HolidayChallengeManager:dailyTaskCollectOver(_taskType, _overFunc)
    if self:getHasTaskCompleted() then
        self:chooseCreatePopLayer(_taskType, _overFunc)
    else
        -- 后续行为
        if _overFunc then
            _overFunc()
        end
    end
end

-- 对外提供创建主界面的接口
function HolidayChallengeManager:showMainLayer(_callback)
    local mainlayer = nil
    if self:isCanShowLayer() then
        if not gLobalViewManager:getViewLayer():getChildByName("HolidayChallengeMainLayer") then
            local mainLayerPath = "views.HolidayChallengeBase.HolidayChallenge_BaseMainLayer"
            local config = self:getConfig()
            if config and config.CODE_PATH.MAIN_LAYER then
                mainLayerPath = config.CODE_PATH.MAIN_LAYER
            end
            mainlayer = util_createView(mainLayerPath)
            if _callback then
                -- 新的继承类,需要写一下回调
                mainlayer:setViewOverFunc(_callback)
            end
            mainlayer:setName("HolidayChallengeMainLayer")
            mainlayer:setExtendData("HolidayChallengeMainLayer")
            self:showLayer(mainlayer, ViewZorder.ZORDER_UI)
        end
    else
        if _callback then
            _callback()
        end
    end
    return mainlayer
end

--[[
    @desc: 外部任务完成界面调用弹出面板进行收集
    @return:是否有完成的任务
]]
function HolidayChallengeManager:getHasTaskCompleted()
    --判断是否被 中断了(cxc 2021-04-21 16:27:38 levelRush付费盖戳不要中断游戏)
    local bInterrupt = self:getIsInterrupt()
    if bInterrupt then
        return false
    end

    --判断当前是否有任务完成
    local bHas = false
    if self:isCanShowLayer() == false then
        return false
    end

    if self:getRewradAllCollected() == false then -- 如果当前有奖励没有收集 还是可以打开的
        bHas = true
    end

    for k, taskData in pairs(self:getActivityData().m_taskData) do
        if taskData then
            if taskData:getStatus() == "completed" then
                -- 弹出主界面
                bHas = true
                break
            end
        end
    end
    return bHas
end

function HolidayChallengeManager:getRewardIndex()
    local pData = self:getActivityData()
    if pData then
        local currPoints = pData:getCurrentPoints()
        for i = #pData:getRewardData(), 1, -1 do
            local rewardData = pData:getRewardData()[i]
            if currPoints >= rewardData:getPoints() then
                return i
            end
        end
    end
    return 1
end

-- 当前阶段一的奖励是否全都领取完毕
function HolidayChallengeManager:getRewradAllCollected()
    local pData = self:getActivityData()
    local bAllCollect = true
    local currPoints = pData:getCurrentPoints()
    if pData then
        for i = 1, #pData:getRewardData() do
            local rewardData = pData:getRewardData()[i]
            if currPoints >= rewardData:getPoints() and rewardData:getCollected() == false then --  只有有奖励没有领取,都返回 false
                bAllCollect = false
                break
            end
        end

        -- 新版聚合的情况下,需要判断是否有未领取的付费奖励
        if self:getActivityData():getPassSwitch() and self:getActivityData():getUnlocked() then
            for i = 1, #pData:getPayRewardData() do
                local rewardData = pData:getPayRewardData()[i]
                if currPoints >= rewardData:getPoints() and rewardData:getCollected() == false then --  只有有奖励没有领取,都返回 false
                    bAllCollect = false
                    break
                end
            end
        end
    end
    return bAllCollect
end

function HolidayChallengeManager:getProgressString()
    local pData = self:getActivityData()
    if not pData then
        return "0/0"
    end
    local currPoints = pData:getCurrentPoints()
    local maxPoints = pData:getMaxPoints()
    return currPoints .. "/" .. maxPoints
end

-- 领奖成功后弹出通用奖励弹板
function HolidayChallengeManager:openCollectRewardLayer(_rewardItems)
    local callbackfunc = function()
        local overFunc = function()
            --....关闭小游戏之后的操作
        end
        if CardSysManager:needDropCards("Holiday Challenge") == true then
            -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
            gLobalNoticManager:addObserver(
                self,
                function(self, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    self:checkMiniGame(overFunc)
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Holiday Challenge")
        else
            self:checkMiniGame(overFunc)
        end
        -- 刷新高倍场点数
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
        -- 刷新高倍场体验卡
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
    end
    -- 检测正常道具奖励
    local propList = {}
    local reward = _rewardItems.items
    if reward ~= nil and #reward > 0 then -- 有奖励的话,先把奖励赋值
        propList = clone(reward)
    end
    if _rewardItems.coins and tonumber(_rewardItems.coins) > 0 then
        propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(_rewardItems.coins), {p_limit = 3})
    end
    local resTag = nil
    if self.m_configData and self.m_configData.THEME_TAG then
        resTag = self.m_configData.THEME_TAG
    end
    local rewardLayer = gLobalItemManager:createRewardLayer(propList, callbackfunc, tonumber(_rewardItems.coins), true, resTag)
    self:showLayer(rewardLayer, ViewZorder.ZORDER_UI)
end
--[[
     ------------------------------ 新版聚合挑战使用的接口 ------------------------------
]]
function HolidayChallengeManager:getHasPayRewardPoint()
    local pData = self:getActivityData()
    if not pData then
        return nil
    end
    local payRewardInfo = pData:getPayRewardData()
    local hasMap = {}
    for i = 1, #payRewardInfo do
        table.insert(hasMap, payRewardInfo[i]:getPoints())
    end
    return hasMap
end

-- 获取指定id的奖励数据
function HolidayChallengeManager:getPayRewardDataByIndex(_index)
    local pData = self:getActivityData()
    if not pData then
        return nil
    end
    return pData:getPayRewardData()[_index]
end

-- 创建通用道具 要区分道具是否有角标 金币是否有角标
function HolidayChallengeManager:getItemNode(_rewardData, _type, _showItemMark, _showCoinMark)
    local itemNode = nil
    if _rewardData == nil then
        return itemNode
    end
    local type = _rewardData:getRewardType()
    if type == self:getConfig().ITEM_TYPE.TYPE_ITEM then
        local itemDatalist = self:getItemDataList(_rewardData, _showItemMark)
        if itemDatalist ~= nil and #itemDatalist > 0 then -- 当前是有道具奖励的
            --这里默认取第一个道具显示
            if string.find(itemDatalist[1].p_icon, "MiniGame_") then
                itemDatalist[1]:setTempData({p_num = 1}) -- 隐藏数量
            end
            if itemDatalist[1]:getType() == self:getConfig().ITEM_TYPE.TYPE_PACKAGE then
                itemDatalist[1]:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_X_ITEM}}) -- 正常情况下卡包 都是右下角x1,新增的拓展类型支持卡包角标居中
            end
            itemNode = gLobalItemManager:createRewardNode(itemDatalist[1], _type)
        end
    elseif type == self.m_configData.ITEM_TYPE.TYPE_COIN then
        --只有金币奖励
        local strCoins = "$" .. _rewardData:getCoinsValue()
        local coinItemData = gLobalItemManager:createLocalItemData("ChallengepPass_Coins", strCoins)
        -- 不显示角标
        if _showCoinMark == false then
            coinItemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        else
            coinItemData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}}) -- 自定义的coins 类型,需要显示设置角标格式
        end
        itemNode = gLobalItemManager:createRewardNode(coinItemData, _type)
    elseif type == self.m_configData.ITEM_TYPE.TYPE_PACKAGE then -- 卡包类型
        local _packet = gLobalItemManager:createLocalItemData("Card_Statue_Package", 1, {p_mark = {ITEM_MARK_TYPE.CENTER_X}, p_num = 1})
        if _showItemMark == false then
            _packet:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        end
        itemNode = gLobalItemManager:createRewardNode(_packet, _type)
    end
    return itemNode
end

-- 专门用来获取道具list
function HolidayChallengeManager:getItemDataList(_rewardData, _showItemMark)
    local itemList = {}
    local rewardItem = clone(_rewardData:getRewardItem())
    if rewardItem ~= nil and #rewardItem > 0 then -- 当前是有道具奖励的
        for i = 1, #rewardItem do
            local itemData = rewardItem[i]
            -- 不显示角标
            if _showItemMark == false then
                itemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
            end
            table.insert(itemList, itemData)
        end
    end
    return itemList
end

function HolidayChallengeManager:canOpenProcessLayer(_type)
    local bFlag = false
    local config = self:getConfig()
    if config.ROAD_CONFIG.NEED_CHECK_PROCESS_OPEN then
        local actData = self:getActivityData()
        if actData then
            -- 本次任务给的点数 n
            local taskUnCollectNum = 0
            local tbTaskData = actData:getTaskData()
            for i = 1 ,#tbTaskData do
                local taskData = tbTaskData[i] 
                if taskData and taskData:getStatus() == "completed" then -- 防止用户有不同类型的任务完成跳过 这里需要累加
                    taskUnCollectNum = taskUnCollectNum + taskData:getUnCollectedNums()
                end
            end
    
            local currTotalProgress = actData:getCurrentPoints() + taskUnCollectNum
            currTotalProgress = currTotalProgress >= actData:getMaxPoints() and actData:getMaxPoints() or currTotalProgress
            if self:isArriveRewardPoint(actData:getCurrentPoints(),currTotalProgress) then -- 当前有奖励可以领取
                bFlag = true
            end

            if taskUnCollectNum > 0 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_ENTRY_OPEN_BUBBLE, taskUnCollectNum)
            end
        end
    else
        bFlag = true
    end

    return bFlag
end

--新版本接口  需要传入当前点数来确定是否有达到奖励点数
function HolidayChallengeManager:isArriveRewardPoint(_oldPoint, _newPoint)
    local pData = self:getActivityData()
    local bArrive = false
    if pData then
        --找到有奖励的点数判断即可
        local rewardPointList = self:getHasPayRewardPoint()
        for i = 1, #rewardPointList do
            if _oldPoint < rewardPointList[i] then -- 找到得到点数之前离得最近的奖励点数
                if _newPoint >= rewardPointList[i] then -- 如果新点数 满足奖励点数的话返回
                    bArrive = true
                end
                break
            end
        end
    end
    return bArrive
end

-- 是否有转盘奖励
function HolidayChallengeManager:checkShowWheel()
    -- 是否有转盘次数
    local pData = self:getActivityData()
    local bReward = false
    if pData then
        local wheelData = pData:getWheelData()
        -- local Unlock = pData:getUnlocked()
        if wheelData then
            local maxPoints = pData:getMaxPoints()
            local allPoint = wheelData:getAllPoints()
            local spinLeft = wheelData:getSpinLeft()
            if spinLeft > self.m_spinLeft and allPoint > maxPoints then
                bReward = true
            end
        end
    end
    return bReward
end

-- 新版接口,需要区分当前要弹出哪个界面 （直接调用方法不改变） return view
function HolidayChallengeManager:chooseCreatePopLayer(_type, _callback, _params)
    local params = _params or {}
    local view = nil
    if self:isCanShowLayer() then
        -- 完成任务记录一下
        local task = self.m_completeTask[_type]
        if task then
            task = task + 1
        else
            self.m_completeTask[_type] = 1
        end
        -- csc 2021-10-18 需要检测当前是否存在这个type类型的任务完成，防止有点数未领的情况下弹出了进度板子
        if not self:getHasTaskCompletedByType(_type) then
            if self:checkShowWheel() then
                view = self:createProgressLayer("holidayChallengeWhell", _callback, params)
            else
                if _callback then
                    _callback()
                end
            end
        else
            if self:getActivityData():getPassSwitch() then --新版pass聚合需要先走进度弹板 
                -- 需要判断当前真的是否有任务完成  - 避免有奖励可领的情况也可以弹出进度板
                -- 有奖励才弹出
                local flag = self:canOpenProcessLayer(_type)
                if self:getHasOneTaskCompleted() and flag and not self:getIsMaxPoints() then -- 满星以后不需要再弹出
                    view = self:createProgressLayer(_type, _callback, params)
                elseif self:checkShowWheel() then
                    view = self:createProgressLayer("holidayChallengeWhell", _callback, params)
                else
                    if _callback then
                        _callback()
                    end
                end
            else
                view = self:showMainLayer(_callback) -- 老板pass 聚合直接创建主界面
            end
        end
    else
        if _callback then
            _callback()
        end
    end
    return view
end
--新版pass 需要先展示进度面板，在跳转到主界面
function HolidayChallengeManager:createProgressLayer(_type, _callback, _params)
    local processLayer = nil
    if self:isCanShowLayer() then
        if not gLobalViewManager:getViewLayer():getChildByName("HolidayChallengeProgressLayer") then
            local processLayerPath = "views.HolidayChallengeBase.HolidayChallenge_BaseProcessLayer"
            local config = self:getConfig()
            if config and config.CODE_PATH.PROCESS_LAYER then
                processLayerPath = config.CODE_PATH.PROCESS_LAYER
            end
            processLayer = util_createView(processLayerPath, _type, _params)
            if _callback then
                -- 新的继承类,需要写一下回调
                processLayer:setViewOverFunc(_callback)
            end
            processLayer:setName("HolidayChallengeProgressLayer")
            self:showLayer(processLayer, ViewZorder.ZORDER_UI)
        else
            if _callback then
                _callback()
            end
        end
    else
        if _callback then
            _callback()
        end
    end
    return processLayer
end

-- 从新版进度进来之后，如果当前已经在主界面了,又有任务完成的情况下,直接进行检测
function HolidayChallengeManager:checkMainLayer(_callback)
    local mainLayer = gLobalViewManager:getViewLayer():getChildByName("HolidayChallengeMainLayer")
    if not mainLayer then
        mainLayer = self:showMainLayer(_callback)
    else
        -- 再次请求任务
        mainLayer:checkTaskStatus()
        if _callback then
            _callback()
        end
    end
    return mainLayer
end

function HolidayChallengeManager:getHasOneTaskCompleted()
    local bHas = false
    local actData = self:getActivityData()
    if not actData then
        return bHas
    end
    for k, taskData in pairs(self:getActivityData().m_taskData) do
        if taskData then
            if taskData:getStatus() == "completed" then
                -- 弹出主界面
                bHas = true
                break
            end
        end
    end
    return bHas
end

function HolidayChallengeManager:checkMiniGame(_overFunc)
    -- 关闭主界面的时候刷新一次邮箱
    if self.m_bParseMiniGame and gLobalMiniGameManager:checkHasMiniGame() then
        self.m_bParseMiniGame = nil
        gLobalMiniGameManager:startMiniGame(_overFunc)
    else
        if _overFunc then
            _overFunc()
        end
    end
end

function HolidayChallengeManager:getHasTaskCompletedByType(_type)
    local bHas = false
    local actData = self:getActivityData()
    if not actData then
        return bHas
    end
    for k, taskData in pairs(actData.m_taskData) do
        if taskData then
            if taskData:getTaskType() == _type and taskData:getStatus() == "completed" then
                bHas = true
                break
            end
        end
    end
    return bHas
end

-- 对外提供创建主界面的接口
function HolidayChallengeManager:createPayLayer()
    local paylayer = nil
    if self:isCanShowLayer() then
        local saleData = self:getActivityData():getHighPriceSaleData()
        if saleData and saleData:getPay() then
            if not gLobalViewManager:getViewLayer():getChildByName("HolidayChallengePayShowLayer") then
                local payShowPath = "views.HolidayChallengeBase.HolidayChallenge_BasePayShowLayer"
                local config = self:getConfig()
                if config and config.CODE_PATH.UNLOCKPAYShow_LAYER then
                    payShowPath = config.CODE_PATH.UNLOCKPAYShow_LAYER
                end
                local paylayer = util_createView(payShowPath)
                self:showLayer(paylayer, ViewZorder.ZORDER_UI)
            end
        else
            if not gLobalViewManager:getViewLayer():getChildByName("HolidayChallengeSaleLayer") then
                local payPath = "views.HolidayChallengeBase.HolidayChallenge_BaseSaleLayer"
                local config = self:getConfig()
                if config and config.CODE_PATH.UNLOCKPAY_LAYER then
                    payPath = config.CODE_PATH.UNLOCKPAY_LAYER
                end
                local paylayer = util_createView(payPath)
                self:showLayer(paylayer, ViewZorder.ZORDER_UI)
            end
        end
    end
    return paylayer
end

------------------------------ 针对 比赛收集点数 是否能弹出板子的判断 ------------------------------
function HolidayChallengeManager:onSpinResult(_spinData)
    assert(_spinData, "HolidayChallengeManager onSpinResult 数值错误")
    if not self:isCanShowLayer() then
        return
    end
    if _spinData and _spinData.extend and _spinData.extend.christmasTour then
        globalData.commonActivityData:parseActivityData(_spinData.extend.christmasTour, ACTIVITY_REF.HolidayChallenge)
        self:setLeaguesCollectStatus(true)
    end
end

function HolidayChallengeManager:setLeaguesCollectStatus(_status)
    self.m_bLeaguesCollect = _status
end

function HolidayChallengeManager:getLeaguesCollectStatus()
    return self.m_bLeaguesCollect
end
--[[
     ------------------------------ 服务器接口 ------------------------------
]]
function HolidayChallengeManager:sendRefreshReq(_taskType, _actionType, _bZeroRefresh)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local successCallFun = function()
        if _bZeroRefresh then
            -- 判断当前是否进入阶段二
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_ZERO_REFRESH_SUCCESS)
        else
            -- 正常领取 刷新task
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_REFRESH, {success = true})
        end
    end

    local failedCallFunFail = function()
        -- 什么都用做
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_REFRESH, {success = false})
    end

    HolidayChallengeNet:sendRefreshReq(_taskType, _actionType, successCallFun, failedCallFunFail)
end

function HolidayChallengeManager:sendCollectReq(_phase, _points, _type)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima()

    local successCallFun = function(target, resultData)
        local rewardItems = nil
        if resultData:HasField("result") == true then
            rewardItems = util_cjsonDecode(resultData.result)
        end

        local bHadMiniGame = false
        if rewardItems.items ~= nil then
            local itemData = {}
            for i = 1, #rewardItems.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(rewardItems.items[i], true)
                itemData[i] = shopItem
                -- 判断当前奖励中有 小游戏奖励的 话才进行解析
                if string.find(shopItem.p_icon, "MiniGame_") then
                    bHadMiniGame = true
                    shopItem:setTempData({p_num = 1}) -- 隐藏数量
                end
            end
            rewardItems.items = itemData
            -- 判断当前奖励为小游戏的话才进行解析
            if bHadMiniGame then
                if resultData:HasField("miniGame") == true then
                    -- 解析 minigame 数据
                    self.m_bParseMiniGame = true
                    gLobalMiniGameManager:parseData(resultData.miniGame)
                end
            end
        end
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_COLLECT_REWARD, {isSuccess = true, rewardItems = rewardItems})
    end

    local failedCallFunFail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_COLLECT_REWARD, {isSuccess = false})
    end

    HolidayChallengeNet:sendCollectReq(_phase, _points, _type, successCallFun, failedCallFunFail)
end

function HolidayChallengeManager:showBoxBubbleLayer()
    local boxBubblePath = "views.HolidayChallengeBase.HolidayChallenge_BaseBoxBubbleLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.BOX_BUBBLE_NODELAYER then
        boxBubblePath = config.CODE_PATH.BOX_BUBBLE_NODELAYER
    end
    local view = util_createView(boxBubblePath)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function HolidayChallengeManager:showRuleLayer(callback)
    local rulePath = "views.HolidayChallengeBase.HolidayChallenge_BaseRuleLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.RULE_LAYER then
        rulePath = config.CODE_PATH.RULE_LAYER
    end
    local view = util_createView(rulePath,callback)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function HolidayChallengeManager:showInfoLayer(callback)
    local infoPath = ""
    local config = self:getConfig()
    if config and config.CODE_PATH.INFO_LAYER then
        infoPath = config.CODE_PATH.INFO_LAYER
    end
    if infoPath == "" then
        return
    end
    local view = util_createView(infoPath,callback)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function HolidayChallengeManager:showWheelLayer(_overFunc)
    local wheelPath = "views.HolidayChallengeBase.baseWheel.HolidayChallenge_BaseWheelLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.WHEEL then
        wheelPath = config.CODE_PATH.WHEEL
    end
    if wheelPath and wheelPath ~= "" then
        local theme_name = self:getThemeName()
        local wheelLayer = gLobalViewManager:getViewByExtendData("HolidayChallenge_WheelLayer")
        if not wheelLayer then
            gLobalDataManager:setNumberByField(theme_name.."_showWheel", 10)
            local view = util_createView(wheelPath, _overFunc)
            self:showLayer(view, ViewZorder.ZORDER_UI)
            return view
        else
            if _overFunc then
                _overFunc()
            end
        end
    else
        if _overFunc then
            _overFunc()
        end
    end
    return nil
end

-- 轮盘规则界面
function HolidayChallengeManager:showWheelInfoLayer()
    local wheelInfoPath = "views.HolidayChallengeBase.baseWheel.HolidayChallenge_BaseWheelInfoLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.WHEEL_INFO_LAYER then
        wheelInfoPath = config.CODE_PATH.WHEEL_INFO_LAYER
    end
    if wheelInfoPath and wheelInfoPath ~= "" then
        local wheelInfoLayer = gLobalViewManager:getViewByExtendData("HolidayChallenge_WheelInfoLayer")
        if not wheelInfoLayer then
            local view = util_createView(wheelInfoPath)
            self:showLayer(view, ViewZorder.ZORDER_UI)
            return view
        end

    end
    return nil
end

-- 轮盘奖励界面
function HolidayChallengeManager:showWheelRewardLayer(itemList, clickFunc, flyCoins, theme)
    local wheelRewardPath = "views.HolidayChallengeBase.baseWheel.HolidayChallenge_BaseWheelRewardLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.WHEEL_REWARD_LAYER then
        wheelRewardPath = config.CODE_PATH.WHEEL_REWARD_LAYER
    end
    if wheelRewardPath and wheelRewardPath ~= "" then
        local wheelRewardLayer = gLobalViewManager:getViewByExtendData("HolidayChallenge_WheelRewardLayer")
        if not wheelRewardLayer then
            local view = util_createView(wheelRewardPath, itemList, clickFunc, flyCoins, theme)
            self:showLayer(view, ViewZorder.ZORDER_UI)
            return view
        end
    end
    return nil
end

-- 轮盘关闭 二次确认界面
function HolidayChallengeManager:showWheelTipLayer(_overFunc)
    local wheelTipPath = "views.HolidayChallengeBase.baseWheel.HolidayChallenge_BaseWheelTipLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.WHEEL_TIP_LAYER then
        wheelTipPath = config.CODE_PATH.WHEEL_TIP_LAYER
    end
    if wheelTipPath and wheelTipPath ~= "" then
        local wheelRewardLayer = gLobalViewManager:getViewByExtendData("HolidayChallenge_WheelTipLayer")
        if not wheelRewardLayer then
            local view = util_createView(wheelTipPath, _overFunc)
            self:showLayer(view, ViewZorder.ZORDER_UI)
            return view
        end
    end
    return nil
end

function HolidayChallengeManager:getRoadNodePath()
    local roadNodePath = "views.HolidayChallengeBase.HolidayChallenge_BaseGiftNode"
    local config = self:getConfig()
    if config and config.CODE_PATH.ROAD_NODE then
        roadNodePath = config.CODE_PATH.ROAD_NODE
    end
    return roadNodePath
end

function HolidayChallengeManager:getGuideLayerPath()
    local roadNodePath = "views.HolidayChallengeBase.HolidayChallenge_BaseGuideLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.GUIDE_LAYER then
        roadNodePath = config.CODE_PATH.GUIDE_LAYER
    end
    return roadNodePath
end

function HolidayChallengeManager:getFlyLayerPath()
    local roadNodePath = "views.HolidayChallengeBase.HolidayChallenge_BaseGiftFlyLayer"
    local config = self:getConfig()
    if config and config.CODE_PATH.FLY_LAYER then
        roadNodePath = config.CODE_PATH.FLY_LAYER
    end
    return roadNodePath
end

function HolidayChallengeManager:setSpinLeft(_num, _point, _isWheelLayer)
    if not self.m_hasInit then
        self.m_hasInit = true
        self.m_spinLeft = _num
        self.m_lastPoint = _point
    elseif _isWheelLayer then
        self.m_spinLeft = _num
        self.m_lastPoint = _point
    end
end

function HolidayChallengeManager:getSpinLeft()
    return self.m_spinLeft, self.m_lastPoint
end

function HolidayChallengeManager:showDoubleRewardLayer()
    local config = self:getConfig()
    if config and config.CODE_PATH.MAIN_UI_DOUBLEREWARD_LAYER then
        local rulePath = config.CODE_PATH.MAIN_UI_DOUBLEREWARD_LAYER
        local view = util_createView(rulePath)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
end

-- 游戏关卡内入口
function HolidayChallengeManager:createMachineEntryNode()
    if not self:isCanShowLayer() then
        return nil
    end 
    local activityData = self:getRunningData()
    if not activityData then
        return nil
    end

    local config = self:getConfig()
    if config and config.CODE_PATH.GAME_ENTRY_NODE then
        local codePath = config.CODE_PATH.GAME_ENTRY_NODE
        local view = util_createFindView(codePath)
        return view
    end

    return nil
end

function HolidayChallengeManager:getEntryModule()
    if not self:isCanShowLayer() then
        return ""
    end
    local config = self:getConfig()
    if config and config.CODE_PATH.GAME_ENTRY_NODE then
        local codePath = config.CODE_PATH.GAME_ENTRY_NODE
        return codePath
    end
    return ""
end

function HolidayChallengeManager:sendWheelSpin(params)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallFun = function(target, resultData)
        local rewardItems = nil
        if resultData:HasField("result") == true then
            rewardItems = util_cjsonDecode(resultData.result)
        end
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_WHEEL_SPIN, {isSuccess = true, rewardItems = rewardItems, gridIndexList = params.gridIndexList})
    end

    local failedCallFunFail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_WHEEL_SPIN, {isSuccess = false})
    end

    HolidayChallengeNet:sendWheelSpin(successCallFun, failedCallFunFail)
end

function HolidayChallengeManager:getCompleteTask()
    return self.m_completeTask
end

function HolidayChallengeManager:clearCompleteTask()
    self.m_completeTask = {}
end

function HolidayChallengeManager:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function HolidayChallengeManager:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end


-- 请求排行榜数据
function HolidayChallengeManager:sendActionRank(callBack)
    HolidayChallengeNet:sendActionRank(function()
        if callBack then
            callBack()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.HolidayChallenge})
    end)
end

function HolidayChallengeManager:showRankLayer(callBack)
    local rankMgr = G_GetMgr(ACTIVITY_REF.HolidayChallengeRank)
    if rankMgr then

        if gLobalViewManager:getViewByExtendData("HolidayChallengeRank") then
            return
        end
        
        local view = rankMgr:showPopLayer(nil,callBack)
        if view then
            local theme_name = self:getThemeName()
            gLobalDataManager:setNumberByField(theme_name.."_showRank", 10)
        end
    else
        if callBack then
            callBack()
        end
    end
end

return HolidayChallengeManager
