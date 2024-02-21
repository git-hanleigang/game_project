--[[
    author:JohnnyFred
    time:2019-11-19 10:14:53
]]
local LuckyChallengeNet = require("activities.Activity_LuckyChallenge.net.LuckyChallengeNet")
local LuckyChallengeManager = class("LuckyChallengeManager", BaseActivityControl)

-- function LuckyChallengeManager:getInstance()
--     if self.instance == nil then
--         self.instance = LuckyChallengeManager.new()
--     end
--     return self.instance
-- end

function LuckyChallengeManager:ctor()
    LuckyChallengeManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.LuckyChallenge)
    self.m_net = LuckyChallengeNet:create()
end

-- 大厅展示资源判断
function LuckyChallengeManager:isDownloadLobbyRes()
    return self:isDownloadLoadingRes()
end

-- 收集时会有两个请求：收集请求和小游戏请求
-- 为了避免两个loading，在此添加标记变量
function LuckyChallengeManager:setCollectLoadingDelay(isLoadingDelay)
    self.m_isLoadingDelay = isLoadingDelay
end

function LuckyChallengeManager:getCollectLoadingDelay()
    return self.m_isLoadingDelay
end

function LuckyChallengeManager:setPointsEndPos(endPos)
    self.m_endPos = endPos
end
function LuckyChallengeManager:flyToPoints(startPos, endCall)
    gLobalViewManager:flyCoins(
        startPos,
        self.m_endPos,
        nil,
        function()
            if endCall then
                endCall()
            end
        end
    )
end

function LuckyChallengeManager:showMainLayer(callback, startRootPos)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalSendDataManager:checkShowNetworkDialog() == true then
        if callback then
            callback()
        end
        return nil
    end

    local inner = function()
        if gLobalViewManager:getViewByExtendData("LuckyChallengeMainUI") == nil then
            local luckyChallengeData = self:getRunningData()
            if luckyChallengeData and luckyChallengeData:isAllOpen() then
                local data = {callback = callback}

                --活动开启中断弹窗
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, false)
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
                gLobalSendDataManager:getLogIap():setEntryType("GemsChallenge")
                local view = util_createView("Activity.Logic.LuckyChallengeMainUI", data)
                view:setRootStartPos(startRootPos)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            else
                if callback then
                    callback()
                end
            end
        else
            if callback then
                callback()
            end
        end
    end

    local luckyChallengeData = self:getRunningData()
    if luckyChallengeData and luckyChallengeData:isAllOpen() and luckyChallengeData:checkIsShowSettlement() then
        -- 弹窗
        local view =
            util_createView(
            "Activity.Logic.LuckyChallengeSeasonOver",
            function()
                inner()
            end
        )
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    else
        inner()
    end
end

function LuckyChallengeManager:getLobbyBottomNum()
    local _data = self:getRunningData()
    if not _data then
        return 0
    else
        return _data:getRedPoint(0)
    end
end

-- function LuckyChallengeManager:showFlyCoins(startPos,endCall)
--     local index = 1
--     self.m_flyScha = scheduler.performWithDelayGlobal(function ()
--         if index >= 5 then
--             if self.m_flyScha ~= nil then
--                 scheduler.unscheduleGlobal(self.m_flyScha)
--             end
--             return
--         end
--         local actionList = {}
--         local sp = util_createAnimation("Activity/MainUI/LC_missionItem_zuanshi.csb")
--         sp:playAction("animation0",false,nil,60)
--         display.getRunningScene():addChild(sp, ViewZorder.ZORDER_SPECIAL) -- 是否添加在最上层
--         sp:setPosition(startPos)
--         actionList[#actionList + 1] = cc.EaseExponentialIn:create(cc.MoveTo:create(0.5,self.m_endPos))
--         if i == 5 then
--             actionList[#actionList + 1] = cc.CallFunc:create(function()
--                 if  endCall then
--                     endCall()
--                 end
--             end)
--         end
--         sp:runAction(cc.Sequence:create(actionList))
--         index = index + 1
--     end,0.1)
--  end

function LuckyChallengeManager:requestLCRank(succCallback)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local function successCallFun(rankData)
        -- gLobalViewManager:removeLoadingAnima()

        self:setChallengeChangeTag(false)

        if rankData ~= nil then
            globalData.parseLuckyChallengeRankConfig(rankData)
        end
        if succCallback then
            succCallback()
        end
    end

    local function failedCallFun()
        -- gLobalViewManager:removeLoadingAnima()
    end
    -- gLobalViewManager:addLoadingAnima()

    self.m_net:sendLCActionRank(successCallFun, failedCallFun)
end

function LuckyChallengeManager:getExtraDataKey()
    return nil
end

function LuckyChallengeManager:showPickGameUI()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.PickGame.LC_PickGameStartUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 领取奖励
function LuckyChallengeManager:requestLCReward(index, callBack)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(resData)
        if not self.m_isLoadingDelay then
            gLobalViewManager:removeLoadingAnima()
        end

        if callBack then
            callBack(true, resData)
        end
    end

    local failedCallFun = function()
        if not self.m_isLoadingDelay then
            gLobalViewManager:removeLoadingAnima()
        end
        if callBack then
            callBack(false)
        end
        gLobalViewManager:showReConnect()
    end

    self.m_net:sendActionLCGetReward(index, successCallFun, failedCallFun)
end

-- 领取奖励
function LuckyChallengeManager:requestLCCollectTask(index, callBack)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(resData)
        self:setChallengeChangeTag(true)

        globalData.syncActivityConfig(resData.activity)

        gLobalViewManager:removeLoadingAnima()
        if callBack then
            callBack(true, resData.result)
        end
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if callBack then
            callBack(false)
        end
        gLobalViewManager:showReConnect()
    end

    self.m_net:sendActionLCCollectTask(index, successCallFun, failedCallFun)
end

function LuckyChallengeManager:requestLCSkipTask(index, callBack)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(resData)
        self:setChallengeChangeTag(true)

        gLobalViewManager:removeLoadingAnima()
        if callBack then
            callBack(true, resData.result)
        end
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if callBack then
            callBack(false)
        end
        gLobalViewManager:showReConnect()
    end

    self.m_net:sendActionLCSkipTask(index, successCallFun, failedCallFun)
end

function LuckyChallengeManager:showPickMainUI(rewardId)
    if not self:isCanShowLayer() then
        return
    end
    if self.m_reguestPick then
        return
    end
    self.m_reguestPick = true
    self:sendPickAction(
        1,
        rewardId,
        function(isCleanLocalData)
            local view = util_createView("Activity.PickGame.LC_PickMainUI", rewardId, isCleanLocalData)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    )
end

function LuckyChallengeManager:showDiceMainUI(rewardId, succFunc, failedFunc)
    if not self:isCanShowLayer() then
        return false
    end
    if self.m_reguestDice then
        return
    end
    self.m_reguestDice = true
    self:sendDiceAction(
        1,
        rewardId,
        function(isCleanLocalData)
            local hasLC_DiceMainUI = gLobalViewManager:getViewByExtendData("LC_DiceMainUI")
            if not hasLC_DiceMainUI then
                local view = util_createView("Activity.DiceGame.LC_DiceMainUI", rewardId, isCleanLocalData)
                view:setExtendData("LC_DiceMainUI")
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            else
                util_sendToSplunkMsg("DiceMainUI_ERROR", "DiceMainUI--重复创建")
            end
            if succFunc then
                succFunc()
            end
        end,
        function ()
            self.m_reguestDice = false
            if failedFunc then
                failedFunc()
            end
        end
    )
    return true
end

function LuckyChallengeManager:clearDiceMark()
    self.m_reguestDice = false
end

function LuckyChallengeManager:sendPickAction(status, rewardId, successFunc)
    if status == 1 then
        local innerFun = function(pickBonus)
            if not pickBonus or (pickBonus and pickBonus.status == "PREPARE") then
                gLobalSendDataManager:getNetWorkFeature():sendPickRequest(
                    "play",
                    rewardId,
                    function()
                        self:setCollectLoadingDelay(false)
                        -- 如果重新请求了，那么就得删除本地的进度缓存
                        if successFunc then
                            successFunc(true)
                        end
                    end,
                    function()
                        self:setCollectLoadingDelay(false)
                        self.m_reguestPick = false
                    end,
                    self.m_isLoadingDelay
                )
            else
                gLobalViewManager:removeLoadingAnima()
                self:setCollectLoadingDelay(false)
                if successFunc then
                    successFunc()
                end
            end
        end

        local luckyChallengeData = self:getRunningData()
        if luckyChallengeData then
            if rewardId == 0 then
                local pickBonus = luckyChallengeData:getPickData()
                innerFun(pickBonus)
            else
                local rewardData = luckyChallengeData:getRewardByRewardId(rewardId)
                local pickBonus = rewardData:getPickBonusData()
                innerFun(pickBonus)
            end
        end
    elseif status == 2 then
        gLobalSendDataManager:getNetWorkFeature():sendPickRequest("finish", rewardId, successFunc
        ,function ()
            self.m_reguestPick = false
        end)
    end
end

function LuckyChallengeManager:clearPickMark()
    self.m_reguestPick = false
end

function LuckyChallengeManager:sendDiceAction(status, rewardId, successFunc, faildFunc)
    if status == 1 then
        local luckyChallengeData = self:getRunningData()
        local rewardData = luckyChallengeData:getRewardByRewardId(rewardId)
        local diceBonus = rewardData:getDiceBonusData()
        if not diceBonus or (diceBonus and diceBonus.status == "PREPARE") then
            gLobalSendDataManager:getNetWorkFeature():sendDiceRequest(
                "play",
                rewardId,
                function()
                    self:setCollectLoadingDelay(false)
                    -- 如果重新请求了，那么就得删除本地的进度缓存
                    if successFunc then
                        successFunc(true)
                    end
                end,
                function()
                    self:setCollectLoadingDelay(false)
                    if faildFunc then
                        faildFunc()
                    end
                end,
                self.m_isLoadingDelay
            )
        else
            self:setCollectLoadingDelay(false)
            gLobalViewManager:removeLoadingAnima()
            if successFunc then
                successFunc()
            end
        end
    elseif status == 2 then
        gLobalSendDataManager:getNetWorkFeature():sendDiceRequest("finish", rewardId, successFunc,faildFunc)
    end
end

function LuckyChallengeManager:gotoFun(jump)
    gLobalSendDataManager:getLogFeature():sendLuckyChallengeLog("Click", "GoSpin")
    if jump == 2 then --收集银库n次——跳转到cash bonus
        if gLobalViewManager:isLobbyView() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_CLOSE)
            local cashBonusView = util_createView("views.cashBonus.cashBonusMain.CashBonusMainView")
            gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_CLOSE, 1)
            globalData.isShowCashBonus = true
            release_print("LuckyChallenge jump " .. jump .. " back to lobby!!!")
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        end
    elseif jump == 3 or jump == 4 or jump == 5 then --收集vip点数n点——跳转到商店
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_CLOSE)
        G_GetMgr(G_REF.Shop):showMainLayer()
    elseif jump == 7 then --完成每日任务n个——跳转到每日任务
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_CLOSE)
        -- csc 2021-07-06 修改创建 tasklayer 的点位
        gLobalDailyTaskManager:createDailyMissionPassMainLayer()
    elseif jump == 6 then --玩link小游戏n次——跳转到集卡
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_CLOSE)
        if CardSysManager:isDownLoadCardRes() then
            if CardSysManager.setEnterCardType then
                CardSysManager:setEnterCardType(1)
            end
            CardSysManager:enterCardCollectionSys()
        end
    elseif jump == 8 then --升级n次——跳转到大厅
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_CLOSE)
    elseif jump == 9 then --大轮盘
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_CLOSE)
        if gLobalViewManager:isLobbyView() then
        else
            release_print("LuckyChallenge jump " .. jump .. " back to lobby!!!")
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        end
    end
end

function LuckyChallengeManager:setChallengeChangeTag(isChange)
    self.m_isChange = isChange
end

function LuckyChallengeManager:getChallengeChangeTag()
    return self.m_isChange
end

function LuckyChallengeManager:setCloseFlag(status)
    self.m_isCloseMainUI = status
end

function LuckyChallengeManager:getCloseFlag()
    return self.m_isCloseMainUI or nil
end

return LuckyChallengeManager
