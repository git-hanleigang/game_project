-- Created by jfwang on 2019-05-06.
-- 活动管理类
-- ioa 111
local ActivityManager = class("ActivityManager")
ActivityManager.instance = nil

--活动主类弹窗额外数据名称列表
local ACTIVITY_EXTRADATA_NAME_LIST = {
    "BingoGameUI",
    "BingoSelectUI",
    "BlastMainUI",
    "RichManMain",
    "WordMainUI",
    "WordLevel",
    "Activity_DinnerLand",
    "Activity_LuckyChipsDraw",
    "CoinPusherSelectUI",
    "Activity_SaleTicket",
    "CoinPusherTaskMainUI",
    "Activity_DiningRoom",
    "Activity_DiningRoomLevel",
    "Activity_DiningRoomGameMainLayer",
    "RedecorMainUI",
    "PokerMainUI"
}

function ActivityManager:getInstance()
    if not ActivityManager.instance then
        ActivityManager.instance = ActivityManager:create()
        ActivityManager.instance:initData()
    end

    return ActivityManager.instance
end

function ActivityManager:initData()
    self.m_rootNodeIsAdd = {}
    self.m_rootNodeIsAddEntry = {}
    self.m_nextShowEntryInfo = {}
    self.m_portraitFlag = false
    self._slotFloatLeftScaleList = {}
    self._slotFloatRightScaleList = {}
    --活动-大厅展示图相应
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showActivityView(params, false)
        end,
        ViewEventType.NOTIFY_CLICK_BROADCAST
    )

    --大厅展示图相应
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showActivityView(params, true)
        end,
        ViewEventType.NOTIFY_CLICK_BROADCAST_HALL
    )
end

function ActivityManager:clear()
    self.m_portraitFlag = false
end

function ActivityManager:purge()
    gLobalNoticManager:removeAllObservers(self)
    self:clear()
end

--创建大厅内入口Node
function ActivityManager:createLobbyNode(_refName, _activityId, _isBottomExtra)
    if _refName and _refName ~= "" then
        local entryNode = nil
        local _mgr = G_GetMgr(_refName)
        if _mgr then
            local _module = _mgr:getLobbyBottomModule()
            if _module ~= "" then
                entryNode = util_createView(_module, {activityId = _activityId, isBottomExtra = _isBottomExtra})
            end
        else
            --优先检测包内资源存放路径
            entryNode = util_createFindView("views/Activity_LobbyIcon/" .. _refName .. "LobbyNode", {activityId = _activityId})
            --将活动ID传入
            if not entryNode then
                entryNode = util_createFindView("Activity/" .. _refName .. "LobbyNode", {activityId = _activityId})
            end
        end
        return entryNode
    end

    return nil
end

--轮播图&展示图 打开对应的活动弹版
function ActivityManager:showActivityView(params, isHALL)
    if params == nil then
        return
    end

    local activityId = params.id
    local data = params.d
    local clickFlag = params.clickFlag
    if activityId == nil or data == nil then
        return
    end
    local popupImage = nil
    if data.p_popupImage and data.p_popupImage ~= "" then
        popupImage = data.p_popupImage
    end

    --活动结束了
    if not globalData.commonActivityData:IsOpenActivityById(activityId) then
        return
    end

    local isEnterActivity = self:checkEnterActivity(data, isHALL)
    --进入了活动界面
    if isEnterActivity then
        return
    end

    local refName = data:getRefName()
    local themeName = data:getThemeName()
    local uiView = nil

    local vType = data:getType()
    if vType ~= nil and vType <= ACTIVITY_TYPE.COMMON then
        local refMgr = G_GetMgr(refName)
        if refMgr then
            local _popType = ACT_LAYER_POPUP_TYPE.SLIDE
            if isHALL then
                _popType = ACT_LAYER_POPUP_TYPE.HALL
            end
            local popInfo = {
                activityId = data:getActivityID(),
                name = popupImage,
                clickFlag = clickFlag,
                popupType = _popType
            }
            uiView = refMgr:showPopLayer(popInfo)
        else
            --活动
            if isHALL == true then
                uiView = util_createFindView("Activity/" .. themeName, {activityId = data:getActivityID(), name = popupImage, clickFlag = clickFlag, popupType = ACT_LAYER_POPUP_TYPE.HALL})
            else
                uiView =
                    util_createFindView("Activity/" .. themeName .. "PopupView", {activityId = data:getActivityID(), name = popupImage, clickFlag = clickFlag, popupType = ACT_LAYER_POPUP_TYPE.SLIDE})
                if uiView == nil then
                    uiView = util_createFindView("Activity/" .. themeName, {activityId = data:getActivityID(), name = popupImage, clickFlag = clickFlag, popupType = ACT_LAYER_POPUP_TYPE.SLIDE})
                end
            end

            if uiView ~= nil then
                gLobalViewManager:showUI(uiView, self:getUIZorder(themeName))
            end
        end

        if uiView then
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(themeName .. "_Popup", false)
            end
            if gLobalSendDataManager.getLogPopub then
                local urlType, pos, btnName = gLobalSendDataManager:getLogPopub():getClickUrl()
                if urlType and pos and btnName then
                    gLobalSendDataManager:getLogPopub():addNodeDot(uiView, btnName, DotUrlType.UrlName, true, urlType, pos)
                end
            end
        end
    end
end
--检测索引
function ActivityManager:getUIZorder(reference)
    local zorder = ViewZorder.ZORDER_UI
    if reference and reference == "Activity_LuckyChipsDraw" then
        zorder = ViewZorder.ZORDER_UI - 1
    end
    return zorder
end

--点击轮播展示图尝试直接进入指定玩法
function ActivityManager:checkEnterActivity(data, isHALL)
    --quest点击进入
    local luaName = data:getRefName()
    if data and luaName then
        -- local questLuaName = ActivityManager.getActivityRelativeBaseKey(data.p_reference)
        local questLuaName = data:getRefName()
        local isQuestActivity = globalData.saleRunData:isQuestActivity(luaName)
        --QUEST活动
        if isQuestActivity or questLuaName == "Activity_Quest" or questLuaName == "Activity_QuestShowTop" or questLuaName == "Activity_QuestNewLevel" then
            if isHALL then
                -- 只处理活动展示图
                if questLuaName == "Activity_QuestShowTop" then
                    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
                    if questConfig ~= nil then
                        if not questConfig:getLeftTime() or questConfig:getLeftTime() <= 0 then
                            return false
                        end
                        --尝试自动弹出排行榜
                        questConfig.m_isAutoShowTop = true
                    end
                elseif questLuaName == "Activity_QuestFirstWheel" then
                elseif questLuaName == "Activity_QuestCollectStar" then
                    --收集星星活动展示图打开
                    gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("lobbyDisplay")
                    return false
                end
                gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("lobbyDisplay")
                G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
                return true
            else
                gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("lobbyCarousel")
                return false
            end
        elseif questLuaName == "Activity_QuestNew" or questLuaName == "Activity_QuestNewShowTop" then
            if isHALL then
                -- 只处理活动展示图
                if questLuaName == "Activity_QuestNewShowTop" then
                    local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
                    if questConfig ~= nil then
                        if not questConfig:getLeftTime() or questConfig:getLeftTime() <= 0 then
                            return false
                        end
                        --尝试自动弹出排行榜
                        G_GetMgr(ACTIVITY_REF.QuestNew):setWillAutoShowRankLayer(true)
                        G_GetMgr(ACTIVITY_REF.QuestNew):jumpToPhaseViewAndWait(true)
                    end
                else
                    G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer()
                end
                gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("lobbyDisplay")
                return true
            else
                gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("lobbyCarousel")
                return false
            end
        elseif luaName == "Activity_BingoShowTop" and isHALL then
            G_GetMgr(ACTIVITY_REF.Bingo):showSelectLayer({openRankFlag = true})
            return true
        elseif luaName == "Activity_DinnerLandShowTop" and isHALL then
            local isOpen = function(expireAt, expire)
                local curTime = os.time()
                if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
                    curTime = globalData.userRunData.p_serverTime / 1000
                end
                if expireAt == 0 or curTime >= expireAt or expire <= 0 then
                    return false
                end
                return true
            end
            local config = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
            if not config or not isOpen(config:getExpireAt(), config:getExpire()) then
                return false
            end
            gLobalActivityManager:showActivityMainView("Activity_DinnerLand", "DinnerLandGameUI", {openRankFlag = true}, nil)
            return true
        elseif luaName == ACTIVITY_REF.Quest and isHALL then
            -- Activity_QuestChineseStyle
            local config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if not config or not config:getLeftTime() or config:getLeftTime() <= 0 then
                return false
            end
            G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
            return true
        elseif luaName == "Activity_OpenNewLevel" then
            -- 新关客户端写死，每次更新
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_OPEN_NEWLEVEL)
            return true
        elseif luaName == "Activity_CardOpen" or luaName == "Activity_CardOpen2" or luaName == "Activity_CardOpen3" then
            if not isHALL then
                if CardSysManager:isDownLoadCardRes() then
                    -- 打开集卡系统
                    CardSysManager:enterCardCollectionSys()
                end
                return true
            end
        end

        if luaName == "Activity_LuckyChipsDraw" then
            gLobalActivityManager:showActivityMainView("Activity_LuckyChipsDraw", "LuckyChipsDrawMainUI")
            return true
        end

        -- 暂时这么写，以后要改掉
        if luaName == ACTIVITY_REF.League and isHALL then
            G_GetMgr(ACTIVITY_REF.League):showMainLayer()
            return true
        end

        if luaName == "Activity_Redecor" then
            if G_GetMgr(ACTIVITY_REF.Redecor):isCanShowLayer() then
                gLobalActivityManager:showActivityMainView("Activity_Redecor", "RedecorMainUI", {}, nil)
                return true
            end
        end
        if luaName == "Activity_RedecorShowTop" then
            if G_GetMgr(ACTIVITY_REF.Redecor):isCanShowLayer() then
                gLobalActivityManager:showActivityMainView("Activity_Redecor", "RedecorMainUI", {openRankFlag = true}, nil)
                return true
            end
        end
    end

    return false
end

--处理具体活动大厅入口
function ActivityManager:InitLobbyNode(activityName, commingSoon, _isBottomExtra)
    local entryLayer = nil
    -- if activityName == "Activity_QuestNewUser" then
    --     entryLayer = self:createLobbyNode(activityName)
    -- else
    -- 活动已经结束了 但是需要展示comming soon 状态
    -- if entryLayer == nil and commingSoon then
    --     entryLayer = self:createLobbyNode({p_reference = activityName})
    --     if entryLayer then
    --         entryLayer:showCommingSoon()
    --     end
    -- end
    -- local isQuest = false
    -- if activityName == "Activity_Quest" then
    --     isQuest = true
    -- end
    -- local hasActivity,activityData = globalData.commonActivityData:getActivityIsOpen(activityName)
    local activityData = G_GetActivityDataByRef(activityName, true)
    if not activityData then
        -- 没有数据则从配置中查找
        local activityCfg = globalData.GameConfig:getActivityConfigByRef(activityName)
        if activityCfg and not activityCfg:isTimeout() then
            -- 判断是否过期
            activityData = activityCfg
        end
    end

    if activityData then
        entryLayer = self:createLobbyNode(activityName, activityData:getActivityID(), _isBottomExtra)
    elseif commingSoon then
        -- 活动不存在 但是需要展示comming soon 状态
        entryLayer = self:createLobbyNode(activityName, nil, _isBottomExtra)
        if entryLayer then
            entryLayer:showCommingSoon()
        end
    end
    -- end

    return entryLayer
end

function ActivityManager:checktActivityOpen(activityName)
    -- 具体做活动名称的判断 判断当前活动是否开启

    local openFlag = false

    local _activityMgr = G_GetMgr(activityName)
    if _activityMgr then
        if _activityMgr:isRunning() then
            openFlag = true
        end
    else
        local data = G_GetActivityDataByRef(activityName)
        if data ~= nil then
            local themeName = data:getThemeName()
            if globalDynamicDLControl:checkDownloaded(themeName) and data:isRunning() then
                openFlag = true
            end
        end
    end

    return openFlag
end

--处理大厅背景
--data["img_bg"] = self:findChild("img_bg")
--data["layerMask"] = self:findChild("layerMask")
function ActivityManager:InitLobbyBackground(data)
    if data == nil or data.img_bg == nil or data.layerMask == nil then
        return
    end

    local backgroundSprite = data.img_bg
    local fengeSprite = data.layerMask
    local bgicon = ""
    local fengeicon = ""

    if bgicon ~= "" and util_IsFileExist(bgicon) then
        util_changeTexture(backgroundSprite, bgicon)
    end

    if fengeicon ~= "" and util_IsFileExist(fengeicon) then
        util_changeTexture(fengeSprite, fengeicon)
    end
end

--处理大厅特殊Fenge
-- data["spPendant"] = self.m_spPendant
-- data["spSlot"] = self.m_spSlot
function ActivityManager:InitLobbyFengeLine(data)
    if data == nil or data.spPendant == nil then
        return
    end

    local fengeSprite = data.spPendant
    local fengeicon = ""

    if fengeicon ~= "" and util_IsFileExist(fengeicon) then
        util_changeTexture(fengeSprite, fengeicon)
    end
end

function ActivityManager:IsCreateEnd(reference)
    for i = 1, #self.m_rootNodeIsAdd do
        local node = self.m_rootNodeIsAdd[i]
        if node then
            local name = node:getName()
            if name and name == reference then
                return true
            end
        end
    end
    return false
end

function ActivityManager:showFindUIView(callBack)
    local uiView = util_createFindView("Activity/FindItem/FindView")
    if uiView ~= nil then
        uiView:setOverFunc(
            function()
                if self.m_portraitFlag == true then
                    globalData.slotRunData.isChangeScreenOrientation = true
                    globalData.slotRunData:changeScreenOrientation(self.m_portraitFlag)
                end

                if callBack ~= nil then
                    callBack()
                end
            end
        )
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

--打开find界面
function ActivityManager:showFindView(callBack)
    --关卡横竖屏
    self.m_portraitFlag = false
    if globalData.slotRunData.machineData ~= nil then
        self.m_portraitFlag = globalData.slotRunData.machineData.p_portraitFlag
    end

    if self.m_portraitFlag == true then
        globalData.slotRunData.isChangeScreenOrientation = false
        globalData.slotRunData:changeScreenOrientation(not self.m_portraitFlag)

        self:showFindUIView(callBack)
    else
        self:showFindUIView(callBack)
    end
end

--find界面恢复
function ActivityManager:recoveryFindView(callback)
    --findView恢复
    if not globalData.findData:IsHaveData() or not globalData.findData:IsNeedRecovery() then
        if callback ~= nil then
            callback()
        end
        return
    end

    -- self:showFindView(function(  )
    if callback ~= nil then
        callback()
    end
    -- end)
end

function ActivityManager:showBlastMainUI(param, func)
    -- if gLobalViewManager:getViewByExtendData("BlastMainUI") == nil then
    --     local blastMainUI = util_createFindView("Activity/BlastGame/MainUI/BlastMainUI", param)
    --     if blastMainUI ~= nil then
    --         gLobalViewManager:showUI(blastMainUI, ViewZorder.ZORDER_UI - 2)
    --     end
    -- end
    -- if func then
    --     func()
    -- end
    G_GetMgr(ACTIVITY_REF.Blast):showMainLayer(param)
end

function ActivityManager:showLuckyChipsDrawMainUI(param, func)
    local luckyChipsDrawMgr = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw)
    if luckyChipsDrawMgr and luckyChipsDrawMgr.showMainLayer then
        luckyChipsDrawMgr:showMainLayer(param)
    end
    if func then
        func()
    end
end

function ActivityManager:showCoinPusherSelectUI(param, func)
    -- if gLobalViewManager:getViewByExtendData("CoinPusherSelectUI") == nil then
    --     if not util_isSupportVersion("1.3.7") then
    --         gLobalViewManager:showUpgradeAppView()
    --         return
    --     end
    --     local CoinPusherSelectUI = util_createFindView("Activity/CoinPusherGame/CoinPusherSelectUI", param)
    --     if CoinPusherSelectUI ~= nil then
    --         gLobalViewManager:showUI(CoinPusherSelectUI, ViewZorder.ZORDER_UI - 1)
    --     end
    -- end
    G_GetMgr(ACTIVITY_REF.CoinPusher):showSelectLayer()
    if func then
        func()
    end
end

function ActivityManager:showNewCoinPusherSelectUI(param, func)
    G_GetMgr(ACTIVITY_REF.NewCoinPusher):showSelectLayer()
    if func then
        func()
    end
end

function ActivityManager:showEgyptCoinPusherSelectUI(param, func)
    G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):showSelectLayer()
    if func then
        func()
    end
end

function ActivityManager:showBattlePassMainUI(param, func)
    if gLobalViewManager:getViewByExtendData("") == nil then
        local view = util_createFindView("Activity/BattlePassCode/BattlePassMainLayer", param)
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI - 1)
        end
    end
    if func then
        func()
    end
end

-- 餐厅活动
function ActivityManager:showDinnerLandGameUI(param, func)
    local dinnerLandData = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
    if not dinnerLandData then
        return
    end

    if util_IsFileExist("Activity/DinnerLandGame/DinnerLandManager.lua") or util_IsFileExist("Activity/DinnerLandGame/DinnerLandManager.luac") then
        local DinnerLandManager = util_require("Activity.DinnerLandGame.DinnerLandManager")
        DinnerLandManager:getInstance():openMainUI(param)
        if func then
            func()
        end
    end
end

-- 新版餐厅 关卡选择界面
function ActivityManager:showDiningRoomSelectUI(param, func)
    local diningRoomData = G_GetActivityDataByRef(ACTIVITY_REF.DiningRoom)
    if not diningRoomData then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_DiningRoomLevel") == nil then
        local diningRoomSelectUI = util_createFindView("Activity/LevelUI/Activity_DiningRoomLevel", param)
        if diningRoomSelectUI ~= nil then
            gLobalViewManager:showUI(diningRoomSelectUI, ViewZorder.ZORDER_UI - 2)
        end
    end
    if func then
        func()
    end
end

-- 新版餐厅活动
function ActivityManager:showDiningRoomGameUI(param, func)
    local diningRoomData = G_GetActivityDataByRef(ACTIVITY_REF.DiningRoom)
    if not diningRoomData then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_DiningRoomGameMainLayer") == nil then
        local diningRoomMainUI = util_createFindView("Activity/GameUI/Activity_DiningRoomGameMainLayer", param)
        if diningRoomMainUI ~= nil then
            gLobalViewManager:showUI(diningRoomMainUI, ViewZorder.ZORDER_UI)
        end
    end
    if func then
        func()
    end
end

function ActivityManager:showBingoSelectUI(param, func)
    G_GetMgr(ACTIVITY_REF.Bingo):showSelectLayer()
end

function ActivityManager:showBingoGameUI(param, func)
    G_GetMgr(ACTIVITY_REF.Bingo):showMainLayer()
end

-- function ActivityManager:showRichMan(param, func)
--     if gLobalViewManager:getViewByExtendData("RichManMain") == nil then
--         local richman = util_createFindView("Activity/RichManGame/RichManMain")
--         if richman ~= nil then
--             gLobalViewManager:showUI(richman, ViewZorder.ZORDER_UI - 2)
--         end
--     end
--     if func then
--         func()
--     end
-- end

function ActivityManager:showWordLevelChooseUI(param, func)
    G_GetMgr(ACTIVITY_REF.Word):showLevelChooseLayer(param)
    if func then
        func()
    end
end

function ActivityManager:showWordMainUI(param, func)
    G_GetMgr(ACTIVITY_REF.Word):showMainLayer(param)
    if func then
        func()
    end
end

--打开推币机任务界面
-- function ActivityManager:showCoinPusherTaskMainUI(param, func)
--     if gLobalViewManager:getViewByExtendData("CoinPusherTaskMainLayer") == nil then
--         local CoinPusherTaskUI = util_createFindView("Activity/CoinPusherTask/CoinPusherTaskMainLayer", param)
--         if CoinPusherTaskUI ~= nil then
--             gLobalViewManager:showUI(CoinPusherTaskUI, ViewZorder.ZORDER_UI - 2)
--         end
--     end
--     if func then
--         func()
--     end
-- end

--打开装修活动主页
function ActivityManager:showRedecorMainUI(param, func)
    G_GetMgr(ACTIVITY_REF.Redecor):showMainLayer(param, func)
end

--打开活动主UI入口
function ActivityManager:showActivityMainView(downLoadName, activityName, openParam, callBack)
    local activityMainViewMap = {
        -- ["BingoGameUI"] = handler(self, self.showBingoGameUI),
        -- ["BingoSelectUI"] = handler(self, self.showBingoSelectUI),
        ["DefenderGameUI"] = handler(self, self.showDefenderGameUI),
        ["FindItemPopupView"] = handler(self, self.showFindPopupUI),
        ["DinnerLandGameUI"] = handler(self, self.showDinnerLandGameUI),
        ["DiningRoomSelectUI"] = handler(self, self.showDiningRoomSelectUI),
        ["DiningRoomGameUI"] = handler(self, self.showDiningRoomGameUI),
        -- ["RichManMain"] = handler(self, self.showRichMan),
        ["BlastMainUI"] = handler(self, self.showBlastMainUI),
        ["LuckyChipsDrawMainUI"] = handler(self, self.showLuckyChipsDrawMainUI),
        ["CoinPusherSelectUI"] = handler(self, self.showCoinPusherSelectUI),
        ["BattlePassMainLayer"] = handler(self, self.showBattlePassMainUI),
        ["WordLevel"] = handler(self, self.showWordLevelChooseUI),
        ["WordMainUI"] = handler(self, self.showWordMainUI),
        -- ["CoinPusherTaskMainUI"] = handler(self, self.showCoinPusherTaskMainUI),
        ["RedecorMainUI"] = handler(self, self.showRedecorMainUI),
        ["NewCoinPusherSelectUI"] = handler(self, self.showNewCoinPusherSelectUI),
        ["EgyptCoinPusherSelectUI"] = handler(self, self.showEgyptCoinPusherSelectUI)
    }
    -- downLoadName = ActivityManager.getRelativeDownloadKey(downLoadName)
    local config = globalData.GameConfig:getActivityConfigByRef(downLoadName)
    if config then
        downLoadName = config:getThemeName()
    end
    if globalDynamicDLControl:checkDownloaded(downLoadName) then
        -- 资源已经下载，活动开启中断弹窗
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, false)
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        local openFunc = activityMainViewMap[activityName]
        if openFunc ~= nil then
            openFunc(openParam, callBack)
        end
    else
        if downLoadName == ACTIVITY_REF.Quest or downLoadName == "Activity_QuestNewUser" then
            --quest活动特殊处理
            if openParam then
                openParam()
            end
        else
            if callBack then
                callBack()
            else
                if gLobalPopViewManager:isStepType(POP_VC_STEP.NEW_GUDIE) then
                    --弹窗逻辑执行下一个事件
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                else
                    --服务器配置下一个弹窗逻辑
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
            end
        end
        print(string.format("%s activity is downloading", activityName))
    end
end

function ActivityManager:getPromotionDataByName(referenceName)
    return G_GetActivityDataByRef(referenceName)
end

function ActivityManager:getActivityDataByName(referenceName)
    return G_GetActivityDataByRef(referenceName)
end

function ActivityManager:checkActivityOpen(referenceName)
    local activityData = gLobalActivityManager:getActivityDataByName(referenceName)
    if activityData and globalData.userRunData.levelNum >= activityData.p_openLevel and activityData:getLeftTime() > 0 then
        return true
    end
    return false
end

function ActivityManager:checkPromotionOpen(referenceName)
    local peomotionData = gLobalActivityManager:getPromotionDataByName(referenceName)
    if peomotionData and globalData.userRunData.levelNum >= peomotionData.p_openLevel and peomotionData:getLeftTime() > 0 then
        return true
    end
    return false
end

function ActivityManager:checkAddNewLevelCount(gameId)
    local data = G_GetMgr(ACTIVITY_REF.OpenNewLevel):getRunningData()
    if not (data and data.p_start and data.p_start ~= "") then
        return
    end
    if gameId and globalData.constantData.OPEN_NEWLEVEL_ID and gameId == globalData.constantData.OPEN_NEWLEVEL_ID then
        if not self.m_enterNewLevelCount then
            self.m_enterNewLevelCount = gLobalDataManager:getNumberByField("OpenNewLevel_Count" .. data.p_start, 0)
        end
        self.m_enterNewLevelCount = self.m_enterNewLevelCount + 1
        gLobalDataManager:setNumberByField("OpenNewLevel_Count" .. data.p_start, self.m_enterNewLevelCount)
    end
end

--是否有活动打开着(要来检测关闭界面是否恢复暂停)
function ActivityManager:isShowActivity()
    for i = 1, #ACTIVITY_EXTRADATA_NAME_LIST do
        local extraDataName = ACTIVITY_EXTRADATA_NAME_LIST[i]
        if gLobalViewManager:getViewByExtendData(extraDataName) then
            return true
        end
    end
    return false
end
--获取大厅背景音乐路径(检测是否存在主题背景音乐)
function ActivityManager:getLobbyMusicPath()
    -- local bgmThemePath = globalData.GameConfig:getChangeThemeResPath(CHANGE_THTMERES_TYPE.BGM_LOBBY)
    -- if bgmThemePath then
    --     return bgmThemePath
    -- end
    -- return "Sounds/bkg_lobby_new.mp3"
    return globalData.GameConfig:getLobbyBGM()
end

-- 刷新CashBack活动 buff显示
function ActivityManager:refreshCashBackBuff()
    if self.m_requireCashBackBuff then
        return
    end
    local activityData = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
    if not activityData then
        return
    end
    local tbData = {
        data = {
            params = {}
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        self.m_requireCashBackBuff = false
        if _result.error then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CASHBACK_REFRESH, false)
            return
        end
        if activityData then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CASHBACK_REFRESH, true)
        end
    end
    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        self.m_requireCashBackBuff = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_2YEARS_COLLECT, false)
    end
    local netModel = gLobalNetManager:getNet("Activity")
    self.m_requireCashBackBuff = true
    netModel:sendActionMessage(ActionType.CashBackRefresh, tbData, successCallback, failedCallback)
end

-- 改变 入口气泡GZOrder层级 
function ActivityManager:changeBubbleGZorder(_node, _gZOrder, _bRight)
    if not self:checkBubbleGZOrderEnabled(_bRight) then
        -- 是否支持
        return
    end
    if not _node then
        return
    end 

    _gZOrder = _gZOrder or 0
    _node:setGlobalZOrder(_gZOrder)
    local children = _node:getChildren()
    for _, child in ipairs(children) do
        self:changeBubbleGZorder(child, _gZOrder, _bRight)
    end
end

-- 是否支持 改变入口气泡 GZOrder
function ActivityManager:checkBubbleGZOrderEnabled(_bRight)
    if _bRight then
        return globalData.slotRunData.isPortrait == false  -- 右边条横版sclView支持
    else
        return globalData.slotRunData.isPortrait == true  -- 左边条竖版sclView支持
    end
end

return ActivityManager
