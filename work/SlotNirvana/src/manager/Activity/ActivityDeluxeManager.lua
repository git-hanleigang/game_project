--[[
Author: cxc
Date: 2021-05-20 10:59:44
LastEditTime: 2021-07-21 15:39:23
LastEditors: Please set LastEditors
Description: 高倍场 管理器
FilePath: /SlotNirvana/src/manager/Activity/ActivityDeluxeManager.lua
--]]
local ActivityDeluxeManager = class("ActivityDeluxeManager", util_require("baseActivity.BaseActivityManager"))

-- 维护高倍场里促销列表 只包含大活动
local Activity_PowerUp = {
    [1] = ACTIVITY_REF.BingoSale,
    [2] = ACTIVITY_REF.BlastSale,
    [3] = ACTIVITY_REF.CoinPusherSale,
    [4] = ACTIVITY_REF.WordSale,
    [5] = ACTIVITY_REF.DiningRoomSale,
    [6] = ACTIVITY_REF.RedecorSale,
    [7] = ACTIVITY_REF.RichManSale,
    [8] = ACTIVITY_REF.PokerSale,
    [9] = ACTIVITY_REF.NewCoinPusherSale,
    [10] = ACTIVITY_REF.PipeConnectSale,
    [11] = ACTIVITY_REF.OutsideCaveSale,
    [12] = ACTIVITY_REF.EgyptCoinPusherSale,
}

function ActivityDeluxeManager:getInstance()
    if self.m_instance == nil then
        self.m_instance = ActivityDeluxeManager.new()
    end
    return self.m_instance
end
function ActivityDeluxeManager:ctor()
    ActivityDeluxeManager.super.ctor(self)

    self.m_deluxeViewCloseCb = nil
    self:registerListener()
    self.m_dayFirstTime = nil
end

-- 检测 是否能弹出高倍场体验卡
function ActivityDeluxeManager:checkPopExperienceCard()
    if not self:checkDownloadResCode() then
        return false
    end

    -- 高倍场未开启
    if not globalData.deluexeClubData:getDeluexeClubStatus() then
        return false
    end

    -- 高倍场未掉落 体验卡
    local experienceCardItem = globalData.deluexeClubData:getExperienceCardItem()
    if not experienceCardItem then
        return false
    end

    return true
end

-- 检测 高倍场体验卡 或者是 高倍场体验卡兑换金币
function ActivityDeluxeManager:popExperienceLayer(_cb)
    _cb = _cb or function()
        end
    local view = nil
    local cardList = globalData.deluexeClubData:getExperienceCardItemList()
    local cardCoinsList = globalData.deluexeClubData:getItemsCoinsList()
    if cardList and #cardList > 0 then
        if cardCoinsList == nil or #cardCoinsList == 0 then
            _cb()
        else
            -- 默认取第一个
            local cardData = cardList[1]
            local cardCoins = cardCoinsList[1]
            if cardData and cardCoins == 0 then
                view = util_createFindView("Activity/DeluexeClubSrc/" .. "Activity_DeluxeExperienceCardLayer", {cardItem = cardData})
            elseif cardData and cardCoins > 0 then
                view = util_createFindView("Activity/DeluexeClubSrc/" .. "Activity_DeluxeExperienceCardToCoinLayer", {cardItem = cardData, coins = cardCoins})
            end
            if view then
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                globalData.deluexeClubData:removeCurrExperienceCardData()
            else
                _cb()
            end
        end
    else
        _cb()
    end
    return view
end

function ActivityDeluxeManager:getLobbyBottomNum()
    -- 猫粮数量
    local actData = nil
    local count = 0
    local pointNum = 0

    local gameInfo = self:getDeluxeGameInfo()
    actData = G_GetActivityDataByRef(gameInfo.actRef)
    if actData and gameInfo.actRef == ACTIVITY_REF.DeluxeClubCatActivity then
        count = actData:getTotalFoodCount() or 0
    elseif actData and gameInfo.actRef == ACTIVITY_REF.DeluxeClubMergeActivity then
        count = actData:getActRedDotCount() or 0
    end

    pointNum = pointNum + count

    return pointNum
end

-- function ActivityDeluxeManager:popExperienceCardLayer(_cb)
--     _cb = _cb or function() end
--     -- csc 2021-08-31 15:46:10 高倍场体验卡优化 高倍场开启下获得的体验卡都转换为金币
--     local uiViewName = "Activity_DeluxeExperienceCardLayer"
--     if globalData.deluexeClubData:getDeluexeClubStatus() and globalData.deluexeClubData:getItemsCoins() > 0 then
--         uiViewName = "Activity_DeluxeExperienceCardToCoinLayer"
--     end

--     if gLobalViewManager:getViewByExtendData(uiViewName) then
--         _cb()
--         return
--     end

--     local uiView = util_createFindView("Activity/DeluexeClubSrc/"..uiViewName)
--     if uiView then
--         gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
--     else
--         _cb()
--     end

--     return uiView
-- end

function ActivityDeluxeManager:showDeluexeClubView(_cb)
    _cb = _cb or function()
        end
    if not self:checkDownloadResCode() then
        _cb()
        return
    end

    if CardSysManager:getPuzzleGameMgr():isInPuzzleGame() then
        _cb()
        return
    end

    -- csc 2021年09月17日18:41:38 如果当前已经在高倍场界面了
    if gLobalViewManager:getViewByExtendData("Activity_DeluexeClubView") then
        local view = gLobalViewManager:getViewByName("Activity_DeluexeClubView")
        if view then
            view:updateView()
        end
        _cb()
        return
    end

    local uiView = util_createFindView("Activity/DeluexeClubSrc/Activity_DeluexeClubView")
    if not uiView then
        _cb()
        return
    end
    -- 按钮名字  类型是url
    if gLobalSendDataManager.getLogPopub then
        local entryType = DotEntryType.Lobby
        if gLobalViewManager:isLevelView() then
            entryType = DotEntryType.Game
        end
        gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "deluexeBtn", DotUrlType.UrlName, true, DotEntrySite.DownView, entryType)
    end

    if uiView.m_dotLog then
        uiView.onHangExit = function()
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():removeUrlKey(uiView.__cname)
            end
        end
        -- 界面名字  类型是url
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():pushUrlKey(uiView.__cname, DotUrlType.ViewName, false)
        end
    end

    uiView:setOverFunc(_cb)
    uiView:setName("Activity_DeluexeClubView")
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function ActivityDeluxeManager:pushDeluexeClubViews(_cb)
    if not self:checkDownloadResCode() then
        return
    end

    local view = nil
    if globalData.deluexeStatus ~= globalData.deluexeClubData:getDeluexeClubStatus() and globalData.deluexeClubData:getDeluexeClubStatus() == true then
        view = self:popupDeluexeClubStartView(_cb)
    elseif globalData.deluexeClubData:getDeluexeClubCrownNum() == 1 and globalData.deluexeClubData:getChangeCoinNum() > 0 then
        -- 一个皇冠 有可兑换金币显示
        view = self:popupDeluexeClubChangeCoinView(_cb)
    end
    return view
end

function ActivityDeluxeManager:popupDeluexeClubStartView(_cb)
    if not self:checkDownloadResCode() then
        return
    end
    
    globalData.deluexeStatus = true
    local uiView = util_createFindView("Activity/DeluexeClubSrc/Activity_DeluexeClubStartView")
    if gLobalSendDataManager.getLogPopub then
        local entryType = DotEntryType.Lobby
        if gLobalViewManager:isLevelView() then
            entryType = DotEntryType.Game
        end
        gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, true, DotEntrySite.UpView, entryType)
    end
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    uiView:setCallBack(_cb)
    return uiView
end

function ActivityDeluxeManager:popupDeluexeClubChangeCoinView()
    if not self:checkDownloadResCode() then
        return
    end

    local uiView = util_createFindView("Activity/DeluexeClubSrc/Activity_DeluexeClubChangeCoin")
    if gLobalSendDataManager.getLogPopub then
        local entryType = DotEntryType.Lobby
        if gLobalViewManager:isLevelView() then
            entryType = DotEntryType.Game
        end
        gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, true, DotEntrySite.UpView, entryType)
    end
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function ActivityDeluxeManager:popupDeluexeClubExAddTimeView()
    local uiView = util_createFindView("Activity/DeluexeClubSrc/Activity_DeluxeExperienceCardAddTimeLayer")
    if gLobalSendDataManager.getLogPopub then
        local entryType = DotEntryType.Lobby
        if gLobalViewManager:isLevelView() then
            entryType = DotEntryType.Game
        end
        gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "Push", DotUrlType.UrlName, true, DotEntrySite.UpView, entryType)
    end
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function ActivityDeluxeManager:checkDownloadResCode()
    if globalDynamicDLControl:checkDownloading("Activity_DeluexeClub") then
        return false
    end

    if globalDynamicDLControl:checkDownloading("Activity_DeluexeClub_Code") then
        return false
    end

    return true
end

function ActivityDeluxeManager:setDeluxeViewCloseCallFunc(_cb)
    self.m_deluxeViewCloseCb = _cb
end

-- 掉落高倍场体验卡 事件
function ActivityDeluxeManager:dropExperienceCardItemEvt(_cb)
    self:setDeluxeViewCloseCallFunc(_cb)

    if not self:checkPopExperienceCard() then
        if _cb then
            _cb()
            self.m_deluxeViewCloseCb = nil
        end
        self:setDeluxeViewCloseCallFunc(nil)
        return
    end
    local view = self:popExperienceLayer(_cb)
    if not view then
        self:setDeluxeViewCloseCallFunc(nil)
    end
    return view
end

-- 高倍场关闭 事件(体验卡打开的 高倍场关闭)
function ActivityDeluxeManager:expCardDeluxeViewCloseEvt(_cb)
    if self.m_deluxeViewCloseCb then
        self.m_deluxeViewCloseCb()
    end
    self.m_deluxeViewCloseCb = nil
end

function ActivityDeluxeManager:checkPowerUpSale()
    -- Activity_PowerUp
    local result = nil
    for i = 1, #Activity_PowerUp do
        local ref = Activity_PowerUp[i]
        local manger = G_GetMgr(ref)
        if manger then
            result = manger:showMainLayer()
            if result then
                break
            end
        end
    end
    return result
end
-- 注册消息事件
function ActivityDeluxeManager:registerListener()
    gLobalNoticManager:addObserver(self, "dropExperienceCardItemEvt", ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
    gLobalNoticManager:addObserver(self, "expCardDeluxeViewCloseEvt", ViewEventType.NOTIFY_EXP_CARD_DELUXE_VIEW_CLOSE)
end

---------------------------------------- 小游戏 ----------------------------------------
function ActivityDeluxeManager:getDeluxeGameInfo()
    if self.m_info then
        return self.m_info
    end

    local infoList = {
        CAT_GROWING = {
            -- 养猫小游戏
            actRef = ACTIVITY_REF.DeluxeClubCatActivity, -- 活动引用名
            luaPath = "Activity/DeluexeClubSrc/Activity_DeluexeClubFunctionIconCat", -- 高倍场主界面入口
            lobbyEntryNodeName = "KITTENS",
            lobbyEntryLuaName = "LobbyBottom_CatteryNode"
        },
        CASTLE_MERGE = {
            -- 合成城堡小游戏
            actRef = ACTIVITY_REF.DeluxeClubMergeActivity,
            luaPath = "Activity/DeluexeClubSrc/Activity_DeluexeClubFunctionIconMerge",
            lobbyEntryNodeName = "MERGE",
            lobbyEntryLuaName = "LobbyBottom_MergeNode"
        }
    }

    self.m_info = infoList.CASTLE_MERGE
    for _, info in pairs(infoList) do
        local actData = G_GetActivityDataByRef(info.actRef)
        if actData then
            self.m_info = info
            break
        end
    end

    return self.m_info
end
-- 小游戏是否开启(小游戏开启 + 高倍场开启)
function ActivityDeluxeManager:checkDeluxeGameOpen()
    if not globalData.deluexeClubData:getDeluexeClubStatus() then
        return false
    end

    local gameInfo = self:getDeluxeGameInfo()
    return gLobalActivityManager:checkActivityOpen(gameInfo.actRef)
end

---------------------------------------- 小游戏 ----------------------------------------

-- 每日首次进入
function ActivityDeluxeManager:getDayFirstTime()
    if self.m_dayFirstTime == nil then
        -- 从缓存中获取
        local time = gLobalDataManager:getNumberByField("ActivityDeluxeManager_dayFirstTime", -1,true)
        if time and time ~= -1 then
            self.m_dayFirstTime = time
        else
            local curServerTime = tonumber(globalData.userRunData.p_serverTime / 1000)        
            self.m_dayFirstTime = curServerTime
            gLobalDataManager:setNumberByField("ActivityDeluxeManager_dayFirstTime", curServerTime)
        end 
    end
    return self.m_dayFirstTime
end

function ActivityDeluxeManager:recordDayFirstTime()
    -- 当前时间戳
    local curServerTime = tonumber(globalData.userRunData.p_serverTime / 1000)
    -- 当天剩余时间戳
    local todayLeftTime = util_get_today_lefttime() 
    -- 第二天0点时间戳
    local nextDay0Time = curServerTime + todayLeftTime
    self.m_dayFirstTime = nextDay0Time
    gLobalDataManager:setNumberByField("ActivityDeluxeManager_dayFirstTime", self.m_dayFirstTime)
end

-- 是否是每天的第一次
function ActivityDeluxeManager:getIsFirst()
    -- 获取时间
    local time = self:getDayFirstTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if curTime >= time then
        return true
    end
    return false
end

return ActivityDeluxeManager
