--[[--
    每日任务 管理器
]]
local NetWorkBase = util_require("network.NetWorkBase")
local ShopItem = util_require("data.baseDatas.ShopItem")
local DailyTaskManager = class("DailyTaskManager")

DailyTaskManager.MISSION_TYPE = {
    DAILY_MISSION = "DailyMission",
    SEASON_MISSION = "SeasonMission",
    PROMOTION_SALE = "PromotionSale"
}

DailyTaskManager.ITEM_TYPE = {
    TYPE_ITEM = "item",
    TYPE_COIN = "coins"
}

-- 奖励收集类型
DailyTaskManager.COLLECT_TYPE = {
    MISSION_TYPE = "mission",
    REWARD_TYPE = "reward"
}

local miniGameIcons = {
    "DuckShot",
    "MiniGame_"
}

local useSpecialResDailyMission = {
    Christmas2023 = "DailyMission_Christmas/DailyMission_Res/"
}

DailyTaskManager.BASE_CONFIG_PATH = "views/baseDailyPassCode_New/DailyMissionPassConfig"

GD.DAILYMISSION_RES_PATH = "DailyMission_Res/"

GD.DAILYPASS_CODE_PATH = {}
GD.DAILYPASS_RES_PATH = {}
GD.DAILYPASS_EXTRA_CONFIG = {}
DailyTaskManager.m_instance = nil
function DailyTaskManager:getInstance()
    if DailyTaskManager.m_instance == nil then
        DailyTaskManager.m_instance = DailyTaskManager.new()
    end
    return DailyTaskManager.m_instance
end

-- 构造函数
function DailyTaskManager:ctor()
    self.m_configData = nil
    self.m_pageType = nil
    self.m_missionRefreshGuide = 0 -- 刷新按钮引导
    self.m_rewardBoxTipGuide = 0 -- 最终宝箱引导
    self:registerObservers()
    self:initBaseConfig()
end

-- 主界面点击关闭，记录一下别的界面用
function DailyTaskManager:setMainUICloseFlag(closedFlag)
    self.m_mainUIClosed = closedFlag
end

function DailyTaskManager:getMainUICloseFlag()
    return self.m_mainUIClosed
end

function DailyTaskManager:checkPopViewCD(_popViewKey, _popViewCD)
    local lastPopTime = gLobalDataManager:getNumberByField(_popViewKey, 0)
    local currTime = math.floor(globalData.userRunData.p_serverTime / 1000)
    local dis = currTime - lastPopTime
    if dis >= _popViewCD then
        gLobalDataManager:setNumberByField(_popViewKey, currTime)

        return true
    end
    return false
end

function DailyTaskManager:registerObservers()
    -- 监听零点刷新
    gLobalNoticManager:addObserver(
        self,
        function(sender)
            self:updateConfig()
        end,
        ViewEventType.NOTIFY_CONFIG_ZERO_REFRESH
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.NewPass then
                -- 零点刷新同时刷新下配置
                --self.m_lastThemeName = ACTIVITY_REF.NewPass
                self:updateConfig()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function DailyTaskManager:registerDLCompleteObservers()
    local newPassMgr = G_GetMgr(ACTIVITY_REF.NewPass)
    local newpassThemeName = newPassMgr:getThemeName()
    gLobalNoticManager:addObserver(
        self,
        function(target, percent)
            self:updateConfig()
        end,
        "DL_Complete" .. newpassThemeName
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, percent)
            self:updateConfig()
        end,
        "DL_Complete" .. newpassThemeName .. "Code"
    )
end

------------------------------ 多主题设计提供新接口 -----------------
--[[
    @desc: 初始化基础配置信息
]]
function DailyTaskManager:initBaseConfig()
    --备份基础配置
    self.m_baseConfigData = nil
    self.m_configData = nil
    self:loadConfig(self.BASE_CONFIG_PATH)
    self:bakBaseConfig()
    self.m_lastThemeName = ACTIVITY_REF.NewPass
end

function DailyTaskManager:bakBaseConfig()
    self.m_baseConfigData = clone(self.m_configData)
    -- 先刷新一次值
    DAILYPASS_CODE_PATH = {}
    DAILYPASS_RES_PATH = {}
    DAILYPASS_EXTRA_CONFIG = {}
    -- 重新导入一次 base 路径
    self:updateCodeInfo(self.m_baseConfigData.code)
    self:updateResInfo(self.m_baseConfigData.res)
    self:updateExtraInfo(self.m_baseConfigData.extra)
end

function DailyTaskManager:updateConfig()
    local activityThemeName = self:getThemeName()
    if self.m_lastThemeName and self.m_lastThemeName == activityThemeName then
        return
    end

    -- 是否下载完毕
    if not self:isDownloadRes(activityThemeName) then
        return
    end

    local bCheckTheme = false
    -- 如果当前没有开启任何pass主题活动
    -- if activityThemeName == "baseDailyPass" then
    if (activityThemeName == ACTIVITY_REF.NewPass) or (activityThemeName == "Activity_NewPass_New") then
        -- 不需要进行检测 默认走基础配置
    else
        -- 检测每个主题活动的配置文件是否存在
        if G_GetMgr(ACTIVITY_REF.NewPass):isDownloadRes() then
            local len = string.len("Activity_NewPass") + 1
            local themeName = string.sub(activityThemeName, len) -- 获取具体的主题名
            local filePath = "DailyPass" .. themeName .. "Code/" .. "DailyPass" .. themeName .. "Config"
            --重置基础配置
            local configPath = filePath
            self:loadConfig(configPath)
            bCheckTheme = true
            self.m_lastThemeName = activityThemeName
            if useSpecialResDailyMission[themeName] then
                if self:isDownloadRes("Activity_DailyMission_" .. themeName) then
                    GD.DAILYMISSION_RES_PATH = useSpecialResDailyMission[themeName]
                end
            end
        end
    end

    -- 重置一下路径
    DAILYPASS_CODE_PATH = {}
    DAILYPASS_RES_PATH = {}
    DAILYPASS_EXTRA_CONFIG = {}
    -- 重新导入一次 base 路径
    self:updateCodeInfo(self.m_baseConfigData.code)
    self:updateResInfo(self.m_baseConfigData.res)
    self:updateExtraInfo(self.m_baseConfigData.extra)

    if bCheckTheme then
        -- 再导入一次当前主题的配置
        self:updateCodeInfo(self.m_configData.code)
        self:updateResInfo(self.m_configData.res)
        self:updateExtraInfo(self.m_configData.extra)
    end
    GD.DAILYPASS_NEWUSER_CODE_PATH = DAILYPASS_CODE_PATH
    GD.DAILYPASS_NEWUSER_RES_PATH = DAILYPASS_RES_PATH
    GD.DAILYPASS_NEWUSER_EXTRA_CONFIG = DAILYPASS_EXTRA_CONFIG
end

--子类重写lua文件更新路径
function DailyTaskManager:updateCodeInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            DAILYPASS_CODE_PATH[key] = value
        end
    end
end
--子类修改资源路径
function DailyTaskManager:updateResInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            DAILYPASS_RES_PATH[key] = value
        end
    end
end
--子类修改资源路径
function DailyTaskManager:updateExtraInfo(infoList)
    if infoList then
        for key, value in pairs(infoList) do
            DAILYPASS_EXTRA_CONFIG[key] = value
        end
    end
end

--是否已经下载
function DailyTaskManager:isDownloadRes(themeName)
    -- themeName = ACTIVITY_REF.NewPass
    -- -- 基础资源
    -- local isDownloaded = globalDynamicDLControl:checkDownloaded(themeName) and globalDynamicDLControl:checkDownloaded(themeName .. "Code")
    -- return isDownloaded

    return G_GetMgr(ACTIVITY_REF.NewPass):isDownloadRes()
end

-- 每日任务界面是否可以弹出
function DailyTaskManager:isCanShowLayer()
    if not G_GetMgr(ACTIVITY_REF.NewPass):isRunning() then
        return true
    end
    if not self:isDownloadRes(ACTIVITY_REF.NewPass) then
        return false
    end
    return true
end

--获得当前活动名称
function DailyTaskManager:getThemeName()
    -- local baseThemeName = "baseDailyPass" -- 默认主题名
    -- local baseThemeName = ACTIVITY_REF.NewPass
    -- local themeName = ""
    -- local activityData = clone(G_GetActivityDataByRef(ACTIVITY_REF.NewPass))
    -- if activityData then
    --     -- 每次获取到最新的数据,需要更新一遍主题名
    --     themeName = activityData:getThemeName()
    --     if themeName == ACTIVITY_REF.NewPass then
    --         themeName = baseThemeName
    --     end
    -- else
    --     themeName = baseThemeName
    -- end
    -- return themeName

    local themeName = ACTIVITY_REF.NewPass
    if G_GetMgr(ACTIVITY_REF.NewPass):isRunning() then
        themeName = G_GetMgr(ACTIVITY_REF.NewPass):getThemeName()
    end
    return themeName
end

------------------------------ 新版mission pass 使用接口 -----------------
function DailyTaskManager:loadConfig(_path)
    self.m_configData = nil
    local configPath = _path
    self.m_configData = util_require(configPath)
end

function DailyTaskManager:getConfig()
    if self.m_configData == nil then
        self:loadConfig()
    end
    return self.m_configData
end

function DailyTaskManager:setEnterPageType(_pageType)
    self.m_pageType = _pageType
end

function DailyTaskManager:getEnterPageType()
    return self.m_pageType
end

-- function DailyTaskManager:getNewPassActivity()
--     local actionData = G_GetActivityDataByRef(ACTIVITY_REF.NewPass)
--     return actionData
-- end

-- 检测pass 额外的奖励数据
function DailyTaskManager:checkExtraRewardData(_params)
    ------------- 检索starPick小游戏 mq -------------
    local giftPickBonusList = {}
    for _, data in ipairs(_params.items or {}) do
        if string.find(data.p_icon, "GiftPickBonusIcon") then
            table.insert(giftPickBonusList, data)
        end
    end
    if next(giftPickBonusList) then
        _params.giftPickBonusList = giftPickBonusList
    end
    ------------- 检索starPick小游戏 mq -------------
end

-- 检测 额外的活动数据
function DailyTaskManager:checkExtraActivtyData(_collectData, _params)
    ------------- 检测 missionRush 活动产出 csc-------------
    if _collectData.luckyMissionItems and #_collectData.luckyMissionItems > 0 then
        local itemData = {}
        for i = 1, #_collectData.luckyMissionItems do
            local shopItem = ShopItem:create()
            shopItem:parseData(_collectData.luckyMissionItems[i], true)
            itemData[i] = shopItem
        end
        _params.luckyMissionItems = itemData
    end
    -- seasonMissionRush 活动下发的道具
    if _collectData.seasonMissionItems and #_collectData.seasonMissionItems > 0 then
        local itemData = {}
        for i = 1, #_collectData.seasonMissionItems do
            local shopItem = ShopItem:create()
            shopItem:parseData(_collectData.seasonMissionItems[i], true)
            itemData[i] = shopItem
        end
        _params.seasonMissionItems = itemData
    end
    ------------- 检索猫粮 cxc-------------
    local rewardItems = _params.items or {}
    local catFoodList = {}
    for _, data in ipairs(rewardItems) do
        if string.find(data.p_icon, "CatFood") then
            table.insert(catFoodList, data)
        end
    end
    if next(catFoodList) then
        _params.catFoodList = catFoodList
    end
    ------------- 检索猫粮 cxc-------------

    ------------- 检索合成福袋 zkk-------------
    local rewardItems = _params.items or {}
    local propsBagList = {}
    for _, data in ipairs(rewardItems) do
        if string.find(data.p_icon, "Pouch") then
            table.insert(propsBagList, data)
        end
    end
    if next(propsBagList) then
        _params.propsBagList = propsBagList
    end
    ------------- 检索合成福袋 zkk-------------

    ------------- 掉落公会点数 cxc-------------
    if _params.clanPointsDailyTask then
        local ClanManager = util_require("manager.System.ClanManager"):getInstance()
        local clanData = ClanManager:getClanData()
        local myPoints = clanData:getMyPoints()
        ClanManager:parseClanInfoData(_params.clanPointsDailyTask)
        local newMyPoints = clanData:getMyPoints()
        if newMyPoints > myPoints then
            _params.addClanPoints = newMyPoints - myPoints
            -- 关卡内更新 宝箱任务进度
            self:setNotifyAddClanPointsEvt(gLobalViewManager:isLevelView())
        end
    end
    ------------- 掉落公会点数 cxc-------------
    ------------- 检索Lettory dhs-------------
    local rewardItems = _params.items or {}
    local lotteryList = {}
    for _, data in ipairs(rewardItems) do
        if string.find(data.p_icon, "Lottery_icon") then
            table.insert(lotteryList, data)
        end
    end
    if next(lotteryList) then
        _params.lotteryList = lotteryList
    end
    ------------- 检索Lettory dhs-------------
end

function DailyTaskManager:autoCollectMission()
    return self:createDailyMissionPassMainLayer(true)
end



function DailyTaskManager:showDailyMissionMainLayer(_autoOpen, _isNewUser)
    if globalData.missionRunData:isSleeping() then
        --剩余时间小于两秒不让进了
        return false
    end
    if not gLobalViewManager:getViewLayer():getChildByName("DailyMissionMainLayer") then
        local mainlayer = util_createView("views.baseDailyMissionCode.DailyMissionMainLayer", _autoOpen)
        mainlayer:setName("DailyMissionMainLayer")
        mainlayer:setExtendData("DailyMissionMainLayer")
        gLobalViewManager:showUI(mainlayer, ViewZorder.ZORDER_UI)
        return true
    else
        return false
    end
end


function DailyTaskManager:createDailyMissionPassMainLayer(_autoOpen)
    if self:isDownloadSystemRes() then
        local isNewUser = self:isWillUseNovicePass()
        return self:showDailyMissionMainLayer(_autoOpen, isNewUser)
    end
end

function DailyTaskManager:createBuyPassTicketLayer(fromPop,isNewUserPass)
    return G_GetMgr(ACTIVITY_REF.NewPass):showBuyTicketLayer(fromPop)
end

-- 专门新增接口，用作 buy 弹板活动打开界面时候的逻辑判断
function DailyTaskManager:createBuyActivityLayer(isNewUserPass)
    local activityData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not activityData then
        -- 打开基础版主界面
        self:createDailyMissionPassMainLayer()
    else
        -- 判断当前是否已经买过门票
        if activityData:isUnlocked() then
            -- 打开基础版主界面
            self:createDailyMissionPassMainLayer()
        else
            -- 打开门票页
            local view = self:createBuyPassTicketLayer(true,isNewUserPass)
            if not view then
                self:createDailyMissionPassMainLayer()
            end
        end
    end
end

------------------------------ pass 活动相关接口 ------------------------------
-- 获取当前season 活动是否开始
-- function DailyTaskManager:getSeasonActivityOpen()
--     local activityData = self:getNewPassActivity()
--     if not activityData then
--         return false
--     end

--     if activityData:isRunning() and globalData.userRunData.levelNum >= globalData.constantData.NEWPASS_OPEN_LEVEL then
--         return true
--     end

--     return false
-- end

-- function DailyTaskManager:getSeasonMission()
--     local activityData = self:getNewPassActivity()
--     if activityData then
--         return activityData:getPassTask()
--     end
--     return nil
-- end

-- 创建通用道具 要区分道具是否有角标 金币是否有角标
function DailyTaskManager:getItemNode(_itemData, _type, _showItemMark, _showCoinMark, _multip, _oldItemNode)
    local itemNode = _oldItemNode
    if _itemData == nil then
        return itemNode
    end
    if _type == self.ITEM_TYPE.TYPE_ITEM then
        if _itemData.items ~= nil and #_itemData.items > 0 then -- 当前是有道具奖励的
            local itemData = _itemData.items[1]
            -- 不显示角标
            if _showItemMark == false then
                itemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
            end
            local mul = (_multip and _multip > 1) and _multip or 1
            if not itemNode then
                itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.BATTLE_PASS, mul)
            else
                gLobalItemManager:updateItem(itemNode, itemData, ITEM_SIZE_TYPE.BATTLE_PASS, mul)
            end
        end
    elseif _type == self.ITEM_TYPE.TYPE_COIN then
        --只有金币奖励
        -- local strCoinsValus = "$".._itemData.p_coinsValue -- 如果需要展示价值
        local coinItemData = gLobalItemManager:createLocalItemData("Coins", tonumber(_itemData.coins), {p_limit = 3})
        -- 不显示角标
        if _showCoinMark == false then
            coinItemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        else
            coinItemData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}}) -- 自定义的coins 类型,需要显示设置角标格式
        end
        if not itemNode then
            itemNode = gLobalItemManager:createRewardNode(coinItemData, ITEM_SIZE_TYPE.BATTLE_PASS)
        else
            gLobalItemManager:updateItem(itemNode, coinItemData, ITEM_SIZE_TYPE.BATTLE_PASS)
        end
    end
    
    if itemNode and itemNode.setIconTouchEnabled then
        itemNode:setIconTouchEnabled(false)
    end
    return itemNode
end

--[[
    @desc: 根据额外的角标需求修改创建出来的道具
]]
function DailyTaskManager:setItemNodeByExtraData(_itemData, _itemNode, _multip)
    local cellLabNode = _itemNode:getValue()
    _multip = _multip or 1
    -- 先找到创建好的 itemnode 节点下的文本字体
    if cellLabNode then
        local newStr = nil
        -- 重新根据需求组装文本
        if string.find(_itemData.p_icon, "club_pass_") then -- 高倍场体验卡
            -- 需要把文字设置成居中模式
            newStr = "X" .. (1 * _multip) -- 高倍场体验卡需要根据倍数来显示个数
        elseif string.find(_itemData.p_icon, "Coupon") then -- 折扣券
            newStr = _itemData.p_num .. "%"
        elseif string.find(_itemData.p_icon, "GiftPickBonusIcon") then -- starpick 小游戏
            -- 需要把文字设置成居中模式
            newStr = "X" .. (1 * _multip) -- 小游戏需要根据倍数来显示个数
        elseif self:isMiniGameIcon(_itemData.p_icon) then
            newStr = "X" .. (1 * _multip) -- 小游戏需要根据倍数来显示个数
        elseif string.find(_itemData.p_icon, "PropFrame") then
            newStr = "X" .. (1 * _multip) -- 头像框
        elseif _itemData.p_type == "Buff" and _itemData.p_buffInfo and _itemData.p_buffInfo.buffType == "CashBack" then
            if _itemData.forReward then
                newStr = _itemData.p_buffInfo.buffMultiple .. "%"
            else
                newStr = ""
            end
        end
        if newStr then
            cellLabNode:setString(newStr)
        end
    end
end

-- 判断是否是小游戏Icon
function DailyTaskManager:isMiniGameIcon(itemIcon)
    local result = false
    for i, v in ipairs(miniGameIcons) do
        if string.find(itemIcon, v) then
            result = true
            break
        end
    end
    return result
end
-- 获取当前有多少个没有领取的箱子数量
-- function DailyTaskManager:getCanClaimNum(isAll)
--     local actData = self:getNewPassActivity()
--     if not actData then
--         return 0
--     end
--     local startLevel = actData:getLevel()
--     local function checkState(info, pay)
--         if info == nil then
--             return false
--         end
--         local pState = false
--         if not info:getCollected() then --当前没有被领取过 或者 付费已经解锁了并且有未领取的
--             pState = true
--             if pay and actData:isUnlocked() == false then
--                 pState = false
--             end
--         end
--         return pState
--     end
--     local sumNoClaim = 0
--     for i = 1, startLevel do
--         local freeInfo = actData:getFressPointsInfo()[i]
--         local payInfo = actData:getPayPointsInfo()[i]
--         if checkState(freeInfo) then
--             sumNoClaim = sumNoClaim + 1
--         end
--         if checkState(payInfo, true) then
--             sumNoClaim = sumNoClaim + 1
--         end
--     end
--     -- printf("------ 当前未领取的个数为 sumNoClaim "..sumNoClaim)
--     return sumNoClaim
-- end

-- 当前是否完成pass进度
-- function DailyTaskManager:getIsMaxPoints()
--     local actData = self:getNewPassActivity()
--     if not actData then
--         return false
--     end
--     local levelExpList = actData:getLevelExpList()
--     local curExp = actData:getCurExp()
--     if curExp >= levelExpList[#levelExpList] then
--         return true
--     end
--     return false
-- end

-- function DailyTaskManager:getInBuffTime()
--     local actData = self:getNewPassActivity()
--     if not actData then
--         return false
--     end
--     local buffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BATTLEPASS_BOOSTER)
--     if buffTimeLeft <= 0 then
--         return false
--     else
--         return true
--     end
--     return false
-- end

-- 需要计算当前活动开启的情况下对任务经验的加成
-- function DailyTaskManager:getPassExpMultipByActivity()
--     local multip = 1
--     local actData = self:getNewPassActivity()
--     local actDoubleData = G_GetActivityDataByRef(ACTIVITY_REF.NewPassDoubleMedal)
--     if actDoubleData then
--         if actData.getDoubleActMultiple and actData:getDoubleActMultiple() > 0 then
--             multip  = multip + actData:getDoubleActMultiple()
--         end
--     end

--     if self:getInBuffTime() then
--         multip  = multip + 1
--     end
--     return multip
-- end

-- function DailyTaskManager:getInSafeBoxStatus()
--     local actData = self:getNewPassActivity()
--     if not actData then
--         return false
--     end
--     local curLevel = actData:getLevel()
--     if curLevel >= actData:getMaxLevel() then
--         return true
--     end
--     return false
-- end

-- 检索当前能完成的任务
function DailyTaskManager:getCompletedMissionTask(isNewUserPass)
    -- 优先每日任务
    local taskInfo = {}
    local missionData = globalData.missionRunData
    local inSeasonMission = false
    if missionData.p_allMissionCompleted == true and missionData.p_taskInfo.p_taskCollected == true then --全部完成
        -- print("----csc 当前每日任务全部完成")
    else
        if missionData.p_taskInfo.p_taskCompleted == true then --已经完成
            -- print("----csc 当前每日任务 有完成的 可以返回")
            taskInfo.taskData = missionData.p_taskInfo
            taskInfo.taskId = missionData.p_taskInfo.p_taskId
            taskInfo.taskExp = missionData.p_taskInfo.p_taskPoint
            taskInfo.taskType = self.MISSION_TYPE.DAILY_MISSION
            return taskInfo
        end
    end

    -- 检索season 任务
    missionData = G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission()
    if missionData and not missionData:getInCd() and missionData:getTaskInfo().p_taskCompleted == true then
        -- print("----csc 当前 season 任务有完成的 可以返回")
        taskInfo.taskData = missionData:getTaskInfo()
        taskInfo.taskId = missionData:getTaskInfo().p_taskId
        taskInfo.taskExp = missionData:getPassExp()
        taskInfo.taskType = self.MISSION_TYPE.SEASON_MISSION
        return taskInfo
    end

    return nil
end

-- 判断当前哪个任务增长了进度 DAILY_MISSION = 1, SEASON_MISSION = 2
function DailyTaskManager:checkIncreaseProgressTask(isNewUserPass)
    local missionType = nil
    local dailyMissionProgress = nil
    local seasonMissionProgress = nil
    local seasonCompleted = false
    --1.先获取两种任务各自状态
    local missionData = globalData.missionRunData
    if missionData.p_allMissionCompleted == true and missionData.p_taskInfo.p_taskCollected == true then --全部完成
        -- 每日任务全部完成
    else
        dailyMissionProgress = self:getProgress(globalData.missionRunData.p_taskInfo)
        -- printInfo("----csc checkIncreaseProgressTask 最新进度 dailyMissionProgress = "..dailyMissionProgress)
        if self.m_dailyMissionProgress == nil then
            self.m_dailyMissionProgress = dailyMissionProgress
        end
    end
    -- season 任务
    missionData = G_GetMgr(ACTIVITY_REF.NewPass):getSeasonMission()
    if missionData and not missionData:getInCd() then
        seasonMissionProgress = self:getProgress(missionData:getTaskInfo())
        -- printInfo("----csc checkIncreaseProgressTask 最新进度 seasonMissionProgress = "..seasonMissionProgress)
        if self.m_seasonMissionProgress == nil then
            self.m_seasonMissionProgress = seasonMissionProgress
        end
        if missionData:getTaskInfo():checkCanCollect() then
            -- printInfo("----csc checkIncreaseProgressTask 当前 seasonmission 完成了")
            seasonCompleted = true
        end
    else
        -- printInfo("----csc checkIncreaseProgressTask 最新进度 seasonMissionProgress 进入了CD或者是没有数据 ")
        self.m_seasonMissionProgress = nil
    end
    local dailyChange = false
    -- 如果当前有每日任务数据
    if dailyMissionProgress then
        -- 检测每日任务数据是否有增长
        -- printInfo("----csc checkIncreaseProgressTask 检测每日任务数据是否有增长")
        if self.m_dailyMissionProgress ~= dailyMissionProgress then
            -- printInfo("----csc checkIncreaseProgressTask 每日任务数据 有增长")
            self.m_dailyMissionProgress = dailyMissionProgress
            dailyChange = true
            missionType = 1
        end
    end
    -- 如果当前有 season 任务数据
    if seasonMissionProgress then
        -- 检测season任务数据是否有增长
        -- printInfo("----csc checkIncreaseProgressTask 检测 season 任务数据是否有增长")
        if self.m_seasonMissionProgress ~= seasonMissionProgress then
            self.m_seasonMissionProgress = seasonMissionProgress
            -- printInfo("----csc checkIncreaseProgressTask season 任务数据 有增长")
            if dailyChange and not seasonCompleted then
                -- 当前有每日任务数据增长,并且当前 pass任务 没有完成 不发生type 切换
                -- printInfo("----csc checkIncreaseProgressTask season 因为每日任务数据有增长,并且当前 pass任务 没有完成,不能切换类型")
            else
                missionType = 2
            end
        end
    end

    if missionType == nil then
        missionType = 1
    end

    if self.m_currMissionType == nil then
        self.m_currMissionType = missionType
    else
        if self.m_currMissionType ~= missionType and missionType ~= nil then
            self.m_currMissionType = missionType
        end
    end
    -- printInfo("----csc checkIncreaseProgressTask 最终 type = " .. self.m_currMissionType)
    return self.m_currMissionType
end

function DailyTaskManager:getProgress(_taskData)
    local m_numPercent, m_endValue = _taskData:getTaskSchedule()
    if not m_numPercent then
        return nil
    end
    -- 进度条更新
    local loadingPercent = tonumber(m_numPercent)/ tonumber(m_endValue) * 100
    if loadingPercent > 100 then
        -- body
        loadingPercent = 100
    end
    return loadingPercent
end

-- 返回大厅任务节点数字  未完成的任务 + 未领取的任务 + pass 可领奖励数
function DailyTaskManager:getLobbyBottomNum()
    local sum = 0
    --未完成的任务数量
    local dailyTask = globalData.missionRunData.p_taskInfo
    if dailyTask then
        if dailyTask.p_taskCompleted == false or (dailyTask.p_taskCompleted == true and dailyTask.p_taskCollected == false) then
            sum = sum + 1
        end
    end
    local newPassMgr = G_GetMgr(ACTIVITY_REF.NewPass)
    local passMissionData = newPassMgr:getSeasonMission()
    if passMissionData then
        local passTask = passMissionData:getTaskInfo()
        if passTask and passTask.p_taskCompleted == false or (passTask.p_taskCompleted == true and passTask.p_taskCollected == false) then
            sum = sum + 1
        end
    end
    sum = sum + newPassMgr:getCanClaimNum()

    return sum
end

function DailyTaskManager:getCurrRefreshInfo()
    local currTask = nil
    local currMissionType = nil
    -- 默认都要检测每日任务
    if globalData.missionRunData.p_allMissionCompleted == false then --还有没完成的任务
        local task = globalData.missionRunData.p_taskInfo
        if task then
            currTask = task
            currMissionType = self.MISSION_TYPE.DAILY_MISSION
        end
    end

    if currTask == nil then
        local newPassMgr = G_GetMgr(ACTIVITY_REF.NewPass)
        local task = newPassMgr:getSeasonMission()
        if task and not task:getInCd() then
            currTask = task:getTaskInfo()
            currMissionType = self.MISSION_TYPE.SEASON_MISSION
        end
    end
    return currTask, currMissionType
end

-- function DailyTaskManager:getSafeBoxIsCompleted()
--     -- 获取当前保险箱是否能收集
--     local actData = self:getNewPassActivity()
--     if not actData then
--         return false
--     end
--     if self:getIsMaxPoints() == false then
--         return false
--     end

--     local boxData = actData:getSafeBoxConfig()
--     if boxData:getCurPickNum() == boxData:getTotalNum() then
--         return true
--     end
--     return false
-- end

------------------------------ 刷新接口 ------------------------------
-- 服务器返回刷新 pass 任务
-- function DailyTaskManager:refreshPassTaskData(_passTask)
--     if _passTask and self:getSeasonActivityOpen() then
--         local data = self:getNewPassActivity()
--         if data then
--             data:parsePassTask(_passTask)
--         end
--     end
-- end

-- 领取成功
function DailyTaskManager:collectCallBack(_success, _resultData, _data, _collectAll,isSpecial)
    if _success then
        local rewardParams = {}

        local result = _resultData.result
        local collectData = util_cjsonDecode(result)
        if collectData then
            if collectData.items ~= nil then
                local itemData = {}
                for i = 1, #collectData.items do
                    local shopItem = ShopItem:create()
                    shopItem:parseData(collectData.items[i], true)
                    itemData[i] = shopItem
                end
                rewardParams.items = itemData
                rewardParams.gems = self:getTotalGem(itemData)
            end
            rewardParams.coins = collectData.coins
            rewardParams.clanPointsDailyTask = collectData.clanPointsDailyTask
            rewardParams.flowerCoins = collectData.flowerCoins
        end
        --在这之前就已经把道具跟金币先组装进去  剩下的是区分 领奖类型进行组装数据
        print("----csc DailyTaskManager:collectCallBack 领取成功 ！！")
        if _data.missionType ~= nil then -- 普通任务类型领取
            rewardParams.collectType = self.COLLECT_TYPE.MISSION_TYPE
            -- 检测基础数据
            rewardParams.missionType = _data.missionType
            rewardParams.addExp = _data.addExp
            -- 字段中有buff ,但是ui展示的时候只获取items中的buff道具进行展示

            -- 检测额外的数据
            self:checkExtraActivtyData(collectData, rewardParams)
        else
            if _data.type ~= nil then -- 如果是领取reward 的话组装一下宝箱信息
                rewardParams.collectType = self.COLLECT_TYPE.REWARD_TYPE
                rewardParams.level = _data.level
                rewardParams.boxType = _data.type
                if _collectAll then
                    rewardParams.collectAll = _collectAll
                end
                -- tpye 3 = 保险箱
                if _data.type == 3 then
                    rewardParams.safeBox = true
                end

                -- 检测额外的数据
                self:checkExtraRewardData(rewardParams)
            end
        end
        local collectType = ""
        if rewardParams.collectType == self.COLLECT_TYPE.MISSION_TYPE then
            collectType = "mission"
            --通知界面播放礼物盒飞的动画  --奖励界面照常打开
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_OPENGIFT_ACTION, rewardParams)
        elseif rewardParams.collectType == self.COLLECT_TYPE.REWARD_TYPE and rewardParams.safeBox then
            collectType = "safebox"
        end
        self:openRewardLayer(rewardParams, collectType,isSpecial)
    else
        release_print("---- csc DailyTaskManager:collectCallBack 领取失败 ")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_COLLECT_FAILED)
        gLobalViewManager:showReConnect()
    end
end

function DailyTaskManager:getTotalGem(itemList)
    local gems = 0
    if itemList and #itemList > 0 then
        for i = 1, #itemList do
            local itemInfo = itemList[i]
            if itemInfo.p_icon == "Gem" then
                gems = gems + itemInfo.p_num
            end
        end
    end
    return gems
end

function DailyTaskManager:openRewardLayer(_reward, _collectType,isSpecial)
    local spot = 0
    if G_GetMgr(G_REF.Flower) and _reward.missionType == "DailyMission" then
        local fl_data = G_GetMgr(G_REF.Flower):getData()
        if fl_data:getOpen() and globalData.userRunData.levelNum >= fl_data:getOpenLevel() then
            if globalData.missionRunData.p_totalMissionNum == 3 then
                if globalData.missionRunData.p_allMissionCompleted then
                    spot = 1
                end
            else
                if globalData.missionRunData.p_currMissionID == 4 and not globalData.missionRunData.p_allMissionCompleted then
                    spot = 1
                end
            end
        end
    end
    local path = DAILYPASS_CODE_PATH.DailyMissionPass_RewardLayer
    local rewardLayer = util_createView(path, _collectType)
    gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
    rewardLayer:updateView(_reward, spot)
end

function DailyTaskManager:setAutoColectFlag(_flag)
    self.m_autoCollect = _flag
end

function DailyTaskManager:getAutoColectFlag()
    return self.m_autoCollect
end

-- function DailyTaskManager:getInGuide()
--     local actData = self:getNewPassActivity()
--     if not actData then
--         return false
--     end

--     if actData:getGuideIndex() == -1 then
--         -- 当前引导已经结束了
--         return false
--     end
--     return true
-- end

function DailyTaskManager:createFlyGifNode(_source, _startPos,useSpecial)
    local path = "views.baseDailyMissionCode.DailyMissionGiftNode"
    local flyGift = util_createView(path, _source)
    gLobalViewManager:getViewLayer():addChild(flyGift, ViewZorder.ZORDER_UI + 2)
    flyGift:setPosition(cc.p(display.cx, display.cy))
    flyGift:playFlyAction()

    gLobalSoundManager:playSound(DAILYPASS_RES_PATH.PASS_OPEN_GIFT_MP3)
end

-- 特殊任务类型文本展示
function DailyTaskManager:getSpecialTaskDesc(_taskInfo)
    local tipStr = _taskInfo:getTaskDescription()
    if _taskInfo.p_taskType == 1011 then
        -- 如果是 1011 需要手动组装一文本参数
        local newStr = nil
        if #_taskInfo.p_taskProcess > 1 and #_taskInfo.p_taskParams > 1 then
            local leftTime = _taskInfo.p_taskParams[2] - _taskInfo.p_taskProcess[2]
            if leftTime > 0 then
                newStr = "(" .. leftTime .. " spins left " .. ")"
                if leftTime == 1 then
                    newStr = "(" .. leftTime .. " spin left " .. ")"
                end
                if _taskInfo.p_taskId == "35" then
                    newStr = "(" .. util_formatCoins(tonumber(leftTime),3,nil,nil,nil,true) .. " coins left " .. ")"
                end
            end
        end
        if newStr then
            tipStr = tipStr .. ":" .. newStr
        end
    elseif _taskInfo.p_taskType == 2006 then
        local newStr = nil
        if #_taskInfo.p_taskProcess > 1 and #_taskInfo.p_taskParams > 1 then
            local leftTime = _taskInfo.p_taskParams[3] - _taskInfo.p_taskProcess[3]
            if leftTime > 0 then
                if _taskInfo.p_taskId == "34" then
                    newStr = "(" .. leftTime .. " spins left " .. ")"
                    if leftTime == 1 then
                        newStr = "(" .. leftTime .. " spin left " .. ")"
                    end
                else
                    newStr = "(" .. util_formatCoins(tonumber(leftTime),3,nil,nil,nil,true) .. " bet left " .. ")"
                end
            end
        end
        if newStr then
            tipStr = tipStr .. ":" .. newStr
        end
    end

    return tipStr
end

--[[
    @desc: 获取任务界面气泡奖励信息
]]
function DailyTaskManager:getTaskRewardData(_currMissionType)
    local missionTaskData = nil
    if _currMissionType == "Daily" then
        missionTaskData = globalData.missionRunData.p_taskInfo
    elseif _currMissionType == "Season" then
        local newPassMgr = G_GetMgr(ACTIVITY_REF.NewPass)
        local actData = newPassMgr:getRunningData()
        if not actData then
            return
        end
        missionTaskData = newPassMgr:getSeasonMission():getTaskInfo()
    end

    -- 获取所有道具
    local commonReward = missionTaskData:getCommonReward() -- 金币 + 道具
    local clanReward = missionTaskData:getClanReward() -- 只有 道具

    -- 组合一下奖励
    local rewardData = {}
    local itemTemp = {}
    local bCardNovice = CardSysManager:isNovice()
    if commonReward then
        rewardData.coins = commonReward.p_coins
        for i = 1, #commonReward.p_items do
            local itemDta = commonReward.p_items[i]
            if string.find(itemDta.p_icon, "Card_Obsidian") then
                --  每日任务 新手期集卡 不显示 黑曜卡
                if not bCardNovice then
                    table.insert(itemTemp, itemDta)
                end
            else
                table.insert(itemTemp, itemDta)
            end
        end
    end

    if clanReward and #clanReward > 0 then
        for i = 1, #clanReward do
            local itemDta = clanReward[i]
            table.insert(itemTemp, itemDta)
        end
    end
    if itemTemp and #itemTemp > 0 then
        rewardData.items = itemTemp
    end
    return rewardData
end

-- 关闭界面 是否刷新公会关卡内入口
function DailyTaskManager:setNotifyAddClanPointsEvt(_bNotify)
    self.m_bPopNotifyClanPointsEvt = _bNotify
end
function DailyTaskManager:getNotifyAddClanPointsEvt()
    return self.m_bPopNotifyClanPointsEvt
end

------------------------------ DailyMissionRush 活动使用接口 -----------------------------
function DailyTaskManager:getIsDailyMissionPlus()
    local activtyData = G_GetMgr(ACTIVITY_REF.DailyMissionRush)
    if activtyData then
        if activtyData:getThemeName() == "Activity_DailyMissionRushPlus" then
            return true
        end
    end
    return false
end
function DailyTaskManager:createRushSendLayer(_activityData)
    -- 两套活动走一样的接口
    if _activityData then
        local path = _activityData:getPopModule()
        if path ~= "" then
            local sendLayer = util_createView(path)
            gLobalViewManager:showUI(sendLayer, ViewZorder.ZORDER_UI)
        end
    end
end

function DailyTaskManager:createRushCardItemNode(_actData, _type)
    local cardNode = nil
    local rewards = _actData:getRewards()
    for k, v in ipairs(rewards) do
        local item = v
        if item:getType() == "Package" then
            cardNode = gLobalItemManager:createRewardNode(item, _type)
            break
        end
    end
    return cardNode
end

function DailyTaskManager:createRushRewardLayer(_activityData, _rewardData, _callback)
    -- 可以弹出板子
    if _activityData then
        local path = _activityData:getRewardLayer()
        if path ~= "" then
            local rewardLayer = util_createView(path)
            gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
            rewardLayer:updateView(_rewardData)
            rewardLayer:setOverFunc(
                function()
                    if _callback then
                        _callback()
                    end
                end
            )
            gLobalSoundManager:playSound(_activityData:getSoundPath())
        end
    else
        if _callback then
            _callback()
        end
    end
end

------------------------------ 服务器接口 ------------------------------
-- 刷新任务
function DailyTaskManager:sendActionDailyTaskRefreshTask(_action,isNewUserPass)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    isNewUserPass = self:isWillUseNovicePass()
    local actionType = nil
    if _action == self.MISSION_TYPE.DAILY_MISSION then
        actionType = ActionType.DailyTaskGemsRefresh
    elseif _action == self.MISSION_TYPE.SEASON_MISSION then
        actionType = ActionType.PassTaskGemsRefresh
        if isNewUserPass then
            actionType = ActionType.NewUserPassTaskGemsRefresh
            if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
                actionType = ActionType.NewUserTriplePassTaskGemsRefresh
            end
        end
    end
    gLobalViewManager:addLoadingAnima(true)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_REFRESH_SUCCESS, {missionType = _action})
    end
    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    local actionData = NetWorkBase:getSendActionData(actionType)
    actionData.data.extra = cjson.encode({})
    NetWorkBase:sendMessageData(actionData, successFunc, failedCallFun)
end
-- 跳过任务
function DailyTaskManager:sendActionDailyTaskSkipTask(_action, _func)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionType = nil
    if _action == self.MISSION_TYPE.DAILY_MISSION then
        actionType = ActionType.DailyTaskSkipTask
    elseif _action == self.MISSION_TYPE.SEASON_MISSION then
        actionType = ActionType.PassTaskGemsSkip
    elseif _action == self.MISSION_TYPE.PROMOTION_SALE then
        actionType = ActionType.PassGemBuySale
    end

    local data = {
        missionType = _action
    }
    gLobalViewManager:addLoadingAnima(true)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_GEMCONSUME_SUCCESS, data)
    end
    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    local actionData = NetWorkBase:getSendActionData(actionType)
    actionData.data.extra = cjson.encode({})
    NetWorkBase:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 任务完成收集
function DailyTaskManager:sendMissionCollectAction(_missionType, _taskId, _addExp,isNewUserPass,isSpecial)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima(true)

    local actType = nil

    local isNewUser = self:isWillUseNovicePass()

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    if _missionType == self.MISSION_TYPE.DAILY_MISSION then
        actType = ActionType.DailyTaskAwardCollect
    elseif _missionType == self.MISSION_TYPE.SEASON_MISSION then
        actType = ActionType.PassTaskCollect
        if isNewUser then
            actType = ActionType.NewUserPassTaskCollect
            if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
                actType = ActionType.NewUserTriplePassTaskCollect
            end
        end
        -- 先取出一下Season的未领取的数据存在manager本地缓存中
        local rewardData = gLobalDailyTaskManager:getTaskRewardData("Season")
        gLobalDailyTaskManager:saveLastTaskData(rewardData)
    end

    local actionData = NetWorkBase:getSendActionData(actType)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.exp = globalData.userRunData.currLevelExper
    actionData.data.level = globalData.userRunData.levelNum
    actionData.data.vipLevel = globalData.userRunData.vipLevel
    actionData.data.vipPoint = globalData.userRunData.vipPoints
    actionData.data.version = NetWorkBase:getVersionNum()
    local extraData = {}
    extraData.taskId = _taskId
    actionData.data.extra = cjson.encode(extraData)

    local data = {
        missionType = _missionType,
        addExp = _addExp
    }
    local successFunc = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        self:collectCallBack(true, resultData, data, false,isSpecial)
    end
    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        self:collectCallBack(false, nil, data, false,isSpecial)
    end

    NetWorkBase:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 刷新 pass 任务
function DailyTaskManager:sendQuerySeasonMission(isNewUserPass)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima(true)
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        -- 刷新成功通知
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_SEASONMISSON_REFRESH, {success = true})
    end
    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
    end

    local actionType = ActionType.PassRefreshTask
    isNewUserPass = self:isWillUseNovicePass()
    if isNewUserPass then
        actionType = ActionType.NewUserPassRefreshTask
        if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
            actionType = ActionType.NewUserTriplePassRefreshTask
        end
    end

    local actionData = NetWorkBase:getSendActionData(actionType)
    actionData.data.extra = cjson.encode({})
    NetWorkBase:sendMessageData(actionData, successFunc, failedCallFun)
end

function DailyTaskManager:rememberCollectRewardCount(forceCount)
    if forceCount then
        self.m_collectRewardCount = forceCount
    else
        local newPassMgr = G_GetMgr(ACTIVITY_REF.NewPass)
        if newPassMgr:isRunning() then
            self.m_collectRewardCount = newPassMgr:getCanClaimNum()
        else
            self.m_collectRewardCount = 0
        end
    end
end

function DailyTaskManager:getCollectRewardCount()
    return self.m_collectRewardCount
end

-- 领取 reward 奖励 0- 免费  1- 付费 2-全部 3-保险箱
function DailyTaskManager:sendActionPassRewardCollect(_level, _type, _collectAll,isNewUserPass,isThreeLinePass,isSpecial)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima(true)
    -- 处理回调
    local data = {
        level = _level,
        type = _type
    }
    if _type == 2 and _collectAll then
        self:rememberCollectRewardCount()
    end
    
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        self:collectCallBack(true, resultData, data, _collectAll,isSpecial)
    end
    local fail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        self:collectCallBack(false, nil, data, _collectAll,isSpecial)
    end

    local actionType = ActionType.PassLevelCollect
    
    isNewUserPass = self:isWillUseNovicePass()
    if isNewUserPass then
        actionType = ActionType.NewUserPassLevelCollect
        if isThreeLinePass then
            actionType = ActionType.NewUserTriplePassLevelCollect
        end
    elseif isThreeLinePass then
        actionType = ActionType.TriplexPassLevelCollect
    end
   

    -- 组装数据发送
    local actionData = NetWorkBase:getSendActionData(actionType)
    local params = {}
    params["level"] = _level
    params["type"] = _type
    actionData.data.params = json.encode(params)

    NetWorkBase:sendMessageData(actionData, success, fail)
end

-- Pass 引导进度打点
function DailyTaskManager:sendActionPassGuideStep(index, isNewUserPass)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionType = ActionType.NewPassGuide
    if isNewUserPass then
        actionType = ActionType.NewUserPassGuide
        if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
            actionType = ActionType.NewUserTriplePassGuide
        end
    end

    local actionData = NetWorkBase:getSendActionData(actionType)
    local params = {}

    params["NewPassGuide"] = index
    actionData.data.params = json.encode(params)

    NetWorkBase:sendMessageData(actionData, nil, nil)
end

-- -- 任务 刷新
-- function DailyTaskManager:updateServerTimeZero()
--     -- csc 2021-11-26 pass如果结束了不再请求这个方法
--     if not G_GetMgr(ACTIVITY_REF.NewPass):isRunning() then
--         return
--     end
--     local udid = globalData.userRunData.userUdid
--     local commonQueryRequest = GameProto_pb.CommonQueryRequest()
--     commonQueryRequest.udid = udid
--     local bodyData = commonQueryRequest:SerializeToString()
--     local httpSender = xcyy.HttpSender:createSender()
--     local url = DATA_SEND_URL .. RUI_INFO.QUERY_ACTIVITY_PASS -- 拼接url 地址
--     -- 发送消息
--     local success_call_fun = function(responseTable)
--         local resData = BaseProto_pb.BattlePassConfigV2()
--         local responseStr = NetWorkBase:parseResponseData(responseTable)
--         resData:ParseFromString(responseStr)

--         --活动相关
--         globalData.commonActivityData:parseActivityData(resData, ACTIVITY_REF.NewPass)

--         httpSender:release()
--     end

--     local faild_call_fun = function(errorCode, errorData)
--         httpSender:release()
--     end
--     local offset = NetWorkBase:getOffsetValue()
--     local token = globalData.userRunData.loginUserData.token
--     local serverTime = globalData.userRunData.p_serverTime
--     httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
-- end

-- 缓存一下当前任务数据
function DailyTaskManager:saveLastTaskData(_data)
    self.m_lastTaskData = _data
end

function DailyTaskManager:getLastTaskData()
    return self.m_lastTaskData or nil
end

function DailyTaskManager:sendExtraRequest(_extraType, _stepId)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[_extraType] = _stepId
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

function DailyTaskManager:setRefreshGuideId(_guideId)
    if _guideId then
        self.m_refreshGuideId = tonumber(_guideId)
    end
end
function DailyTaskManager:getRefreshGuideId()
    return self.m_refreshGuideId or 0
end
function DailyTaskManager:setSafeBoxGuideId(_guideId)
    if _guideId then
        self.m_safeBoxGuideId = tonumber(_guideId)
    end
end
function DailyTaskManager:getSafeBoxGuideId()
    return self.m_safeBoxGuideId or 0
end


function DailyTaskManager:isWillUseNovicePass()
    local result  = false
    local newPassData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if globalData.constantData.NEWUSERPASS_OPEN_SWITCH and globalData.constantData.NEWUSERPASS_OPEN_SWITCH > 0 then
        if newPassData and newPassData:isNewUserPass() then
            result  = true
        else
            if globalData.userRunData.levelNum < globalData.constantData.NEWUSERPASS_OPEN_LEVEL then
                result  = true
            end
        end
    end
    return result
end

function DailyTaskManager:isDownloadSystemRes()
    return  globalDynamicDLControl:checkDownloaded("Activity_NewPass_New")
end

return DailyTaskManager
