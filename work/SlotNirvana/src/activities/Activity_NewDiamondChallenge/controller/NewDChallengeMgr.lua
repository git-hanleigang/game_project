-- 新版钻石挑战 控制类
require("activities.Activity_NewDiamondChallenge.config.NewDChallengeConfig")
local NewDChallengeNet = require("activities.Activity_NewDiamondChallenge.net.NewDChallengeNet")
local NewDChallengeGuideMgr = util_require("activities.Activity_NewDiamondChallenge.controller.NewDChallengeGuideMgr")
local NewDChallengeMgr = class("NewDChallengeMgr", BaseActivityControl)

function NewDChallengeMgr:ctor()
    NewDChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.NewDiamondChallenge)
    self.m_guide = NewDChallengeGuideMgr:getInstance()
    self.m_Net = NewDChallengeNet:getInstance()
    self.m_flyPos = {}
    self.m_rankFlag = false
end

-- 获取 
function NewDChallengeMgr:getMainUI()
    if gLobalViewManager:getViewByExtendData("DChallengeMainUI") then
        return gLobalViewManager:getViewByExtendData("DChallengeMainUI")
    end
end

function NewDChallengeMgr:getGuide()
    return self.m_guide
end

-- 请求小游戏接口
function NewDChallengeMgr:sendMiniGameRequest(levelId, successFunc, faildFunc)
    self.m_Net:sendMiniGameRequest(levelId, successFunc, faildFunc)
    -- successFunc()
end

function NewDChallengeMgr:sendActionRank(_flag)
    self.m_Net:sendActionRank(_flag)
end

function NewDChallengeMgr:getRankFlag()
    return self.m_rankFlag
end

function NewDChallengeMgr:setRankFlag()
    self.m_rankFlag = false
end

--获取任务数据
function NewDChallengeMgr:getTaskList()
    local data = self:getRunningData()
    if not data then
        return
    end
    return data:getTaskList()
end

--获取奖励数据
function NewDChallengeMgr:getPassList()
    local data = self:getRunningData()
    if not data then
        return
    end
    return data:getPass()
end

--倍增器列表
function NewDChallengeMgr:getBeiZ()
    local list = self:getTaskList()
    if list then
        return list:getBoostList()
    end
    return nil
end

--当前倍增器等级
function NewDChallengeMgr:getBeiZLevel()
    local list = self:getTaskList()
    if list then
        return list:getBoostLevel()
    end
    return 1
end

--昨天倍增器等级
function NewDChallengeMgr:getBeiYZLevel()
    local list = self:getTaskList()
    if list then
        return list:getYesterdayBoostLevel()
    end
    return 1
end

--当前完成的数量
function NewDChallengeMgr:getFinishedNum()
    local list = self:getTaskList()
    if list then
        return list:getTodayFinishedNum()
    end
    return 0
end

--需要完成的数量
function NewDChallengeMgr:getNeedFinishNum()
    local list = self:getTaskList()
    if list then
        return list:getTodayNeedFinishNum()
    end
    return 0
end

--剩余刷新券的数量
function NewDChallengeMgr:getPayRushNum()
    local list = self:getTaskList()
    if list then
        return list:getPayRefreshNum()
    end
    return 0
end

--剩余刷新次数
function NewDChallengeMgr:getRemainNum()
    local list = self:getTaskList()
    if list then
        return list:getRemainingRefreshTimes()
    end
    return 0
end

--总刷新次数
function NewDChallengeMgr:getTotalRNum()
    local list = self:getTaskList()
    if list then
        return list:getTotalRefreshTimes()
    end
    return 0
end

--任务列表
function NewDChallengeMgr:getTaskInfo()
    local list = self:getTaskList()
    if list then
        return list:getTaskList()
    end
    return nil
end

function NewDChallengeMgr:getTaskShowList()
    local list = self:getTaskInfo()
    if list and #list > 0 then
        local newlist = {}
        for i,v in ipairs(list) do
            if v:getType() == "LIMIT" and v:getRemainTimes() ~= 0 then
                local todayLeftTime = tonumber(v:getLimitTime())/1000
                local curTime = os.time()
                if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
                    curTime = globalData.userRunData.p_serverTime / 1000
                end
                if todayLeftTime > tonumber(curTime) then
                    table.insert(newlist,v)
                end
            elseif v:getRemainTimes() ~= 0 then
                table.insert(newlist,v)
            end
        end
        table.sort( newlist, function(a,b)
            return a:getIndex() < b:getIndex()
        end)
        return newlist
    end
    return nil
end

function NewDChallengeMgr:getTaskDesc(_data)
    local str = ""
    if not _data then
        return str
    end
    local desc = _data:getDec()
    local strList = util_string_split(desc," ")
    for i= 1,#strList do
        if strList[i] ~= "" then
            local dec = self:createElemnt(strList[i],i,_data:getParam())
            str = str.." "..dec
        end
    end
    return str
end

function NewDChallengeMgr:createElemnt(desc,index,params)
    local str = desc
    for i = 1,#params do
        if desc == "%s"..i then
            str = util_formatCoins(params[i],3,true,nil,true)
            break
        end
    end
    return str
end

function NewDChallengeMgr:getTaskDataByIndex(_index)
    local list = self:getTaskInfo()
    local current = nil
    if list and #list > 0 then
        for i,v in ipairs(list) do
            if v:getIndex() == _index then
                current = v
                break
            end
        end
    end
    return current
end

--任务未领取的数量
function NewDChallengeMgr:getTaskUnReward()
    local list = self:getTaskShowList()
    if not list or #list <= 0 then
        return 0
    end
    local num = 0
    for i,v in ipairs(list) do
        if v:getCompleted() and v:getRemainTimes() ~= 0 then
            num = num + 1
        end
    end
    return num
end

--奖励未领取的数量
function NewDChallengeMgr:getPrizeUnReward()
    local pass = self:getRunningData():getPass()
    local list = pass:getLevelList()
    if not list or #list <= 0 then
        return 0
    end
    local cur = pass:getCurExp()
    local num = 0
    for i,v in ipairs(list) do
        if not v.collected and cur >= v.exp then
            num = num + 1
        end
    end
    return num
end

function NewDChallengeMgr:getAllRed()
    local red = self:getPrizeUnReward() + self:getTaskUnReward() + G_GetMgr(ACTIVITY_REF.NewDCRush):getRushUnReward()
    return red
end

--检测是否是今天第一次
function NewDChallengeMgr:checkTodayFirst()
    local isCheck = false
    local oldTime = gLobalDataManager:getStringByField("NewDTaskT", "")
    if oldTime ~= "" then
        local oldTM = util_UTC2TZ(tonumber(oldTime)/1000, -8)
        local t = tonumber(globalData.userRunData.p_serverTime / 1000)
        local newTM = util_UTC2TZ(t, -8)
        if oldTM.day ~= newTM.day then
            isCheck = true
        end
    else
        self:setTodayFirst()
    end
    return isCheck
end

function NewDChallengeMgr:setTodayFirst()
    local time = globalData.userRunData.p_serverTime
    gLobalDataManager:setStringByField("NewDTaskT", tostring(time))
end

function NewDChallengeMgr:checkRequst()
    local ty = self:getBeiZLevel()
    local yy = self:getBeiYZLevel()
    if ty > yy then
        --播放增加动画
        self:showTaskBoostLayer(2)
    elseif ty < yy then
        --播放减少动画
        self:showTaskBoostLayer(3)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_KUATIAN)
    end
    self:setTodayFirst()
end

function NewDChallengeMgr:rushItems(_nIndex,_flag)
    local data = self:getTaskDataByIndex(_nIndex)
    local params = {}
    params.data = data
    params.index = _nIndex
    params.flag = _flag
    local check = self:checkTodayFirst()
    if check then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_LISTRESH,true)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_ITEMRESH,params)
    end
end

--获取加成buff
function NewDChallengeMgr:getBuffLeftTime()
    local BuffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_NEWDCJC_BOOST) -- 宝箱
    return BuffTimeLeft
end

function NewDChallengeMgr:getJCItem(data)
    --获取加成item
    local time = self:getBuffLeftTime()
    local myjc = data:getBoost()
    local multip = 0
    if time > 0 then
        local a = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPE_NEWDCJC_BOOST)
        multip = tonumber(a) + multip
    end
    if tonumber(myjc) > 0 then
        multip = multip + tonumber(myjc)
    end
    return multip
end

--加成个数，四舍五入
function NewDChallengeMgr:getFomartNum(_multip,_num)
    local dis = (_num*_multip) + 0.5
    local num = _num + math.floor(dis)
    return num
end

--引导第二部返回index
function NewDChallengeMgr:getGuideTwo()
    local index,shiji = 0,3
    local list = self:getTaskInfo()
    if list and #list > 0 then
        if list[3] then
            index = list[3]:getIndex()
        else
            shiji = 0
        end
    end
    return index,shiji
end

--引导第五部返回index
function NewDChallengeMgr:getGuideFive()
    local index,shiji = 0,0
    local list = self:getTaskInfo()
    if list and #list > 0 then
        for i,v in ipairs(list) do
            if v:getType() == "LEGEND" then
                index = v:getIndex()
                shiji = i
                break
            end
        end
    end
    return index,shiji
end

function NewDChallengeMgr:getCurLevelTask(p_id,_flag)
    if not p_id then
        return nil
    end
    local list = self:getTaskShowList()
    if not list or #list <= 0 then
        return nil
    end
    local task = {}
    local shenmi = nil
    local endtask = nil
    for i,v in ipairs(list) do
        if v:getGameId() and tonumber(v:getGameId()) == tonumber(p_id) then
            table.insert(task,v)
        end
        if v:getType() == "MYSTERY" then
            shenmi = v
        end
    end
    if #task > 0 then
        table.sort( task, function(a,b)
            return a:getBaiFenBi() > b:getBaiFenBi()
        end )
    end
    -- if shenmi ~= nil and not _flag then
    --     table.insert(task,shenmi)
    -- end
    return task
end

function NewDChallengeMgr:getTotalExp()
    local data = self:getRunningData()
    if data then
        return data:getTotal()
    end
end

function NewDChallengeMgr:setFlyPosition(_tag,_pos)
    self.m_flyPos["".._tag] = _pos
end

function NewDChallengeMgr:getFlyPosition(_tag)
    return self.m_flyPos["".._tag] or cc.p(0,0)
end

--判断有没有新增限时任务
function NewDChallengeMgr:checkLimite(_list)
    local newlist = self:getTaskShowList()
    local newL = false
    local limiteCell = nil
    for i,v in ipairs(newlist) do
        if v:getType() == "LIMIT" then
            newL = true
            limiteCell = v
            break
        end
    end
    for i,v in ipairs(_list) do
        if v:getCellType() == "LIMIT" then
            newL = false
            break
        end
    end
    return newL,limiteCell
end

--神秘任务跳转逻辑
function NewDChallengeMgr:gotoFun(jump)
    gLobalSendDataManager:getLogFeature():sendLuckyChallengeLog("Click", "GoSpin")
    if jump == 2 then --收集银库n次——跳转到cash bonus
        if gLobalViewManager:isLobbyView() then
            local cashBonusView = util_createView("views.cashBonus.cashBonusMain.CashBonusMainView")
            gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
        else
            globalData.isShowCashBonus = true
            release_print("LuckyChallenge jump " .. jump .. " back to lobby!!!")
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        end
    elseif jump == 3 or jump == 4 or jump == 5 then --收集vip点数n点——跳转到商店
        G_GetMgr(G_REF.Shop):showMainLayer()
    elseif jump == 7 then --完成每日任务n个——跳转到每日任务
        -- csc 2021-07-06 修改创建 tasklayer 的点位
        gLobalDailyTaskManager:createDailyMissionPassMainLayer()
    elseif jump == 6 then --玩link小游戏n次——跳转到集卡
        if CardSysManager:isDownLoadCardRes() then
            if CardSysManager.setEnterCardType then
                CardSysManager:setEnterCardType(1)
            end
            CardSysManager:enterCardCollectionSys()
        end
    elseif jump == 8 then --升级n次——跳转到大厅
        if not gLobalViewManager:isLobbyView() then
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        end
    elseif jump == 9 then --大轮盘
        if gLobalViewManager:isLobbyView() then
        else
            release_print("LuckyChallenge jump " .. jump .. " back to lobby!!!")
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        end
    end
end

--任务跳过
function NewDChallengeMgr:sendTaskSkipReq(_nIndex)
    local successFunc = function(_netData)
        self:rushItems(_nIndex,true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_RED)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    end
    local fileFunc = function()
    end
    self.m_Net:sendTaskSkipReq(_nIndex,successFunc,fileFunc)
end

--选择关卡
function NewDChallengeMgr:sendTaskChoosGameReq(_nIndex,_gameId)
    local successFunc = function(_netData)
        local data = self:getTaskDataByIndex(_nIndex)
        local params = {}
        params.data = data
        params.index = _nIndex
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_ITEMRESH,params)
    end
    local fileFunc = function()
        -- body
        print("error")
    end
    self.m_Net:sendTaskChoosGameReq(_nIndex,_gameId,successFunc,fileFunc)
end

--刷新任务
function NewDChallengeMgr:sendTaskRefreshReq(_nIndex,_type,_flag)
    local successFunc = function(_netData)
        if _flag then
            local data = self:getTaskDataByIndex(_nIndex)
            local params = {}
            params.data = data
            params.index = _nIndex
            params.flag = 100
            G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getGuide():setGuideStep(4)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_ITEMRESH,params)
        else
            self:rushItems(_nIndex)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_RED)
    end
    local fileFunc = function()
        -- body
    end
    self.m_Net:sendTaskRefreshReq(_nIndex,_type,successFunc,fileFunc)
end

--任务领奖
function NewDChallengeMgr:sendTaskCollectReq(_nIndex,_data)
    local item_data = nil
    local jc = 0
    if _data then
        item_data = clone(_data)
        jc = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getJCItem(item_data)
    end
    local successFunc = function(_netData)
        -- body
        if item_data then
            local callback = function()
                --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_LISTRESH,true)
                
            end
            self:showTaskRewardLayer(item_data,callback,1,jc)
        else
            util_sendToSplunkMsg("NewDChallenge", "error")
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_RED)
        -- 完成任务领奖成功的时候刷排行榜数据
        self:sendActionRank()
        self.m_rankFlag = true
    end
    local fileFunc = function()
        -- body
        util_sendToSplunkMsg("NewDChallenge", "error1")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_ZHUDONG,true)
    end
    self.m_Net:sendTaskCollectReq(_nIndex,successFunc,fileFunc)
end

--主动刷新任务
function NewDChallengeMgr:sendTaskRushReq(_flag)
    local successFunc = function(_netData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_ZHUDONG,true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_RED)
    end
    local fileFunc = function()
        -- body
    end
    self.m_Net:sendTaskRushReq(successFunc,fileFunc,_flag)
end

-- Pass 领奖
function NewDChallengeMgr:sendPassCollectReq(_passLevel, _reawardType, _rewardDatas)
    -- local item_data = nil
    -- if _data then
    --     item_data = clone(_data)
    -- end
    
    local successFunc = function(_netData)
        -- body
        self:showPassRewardLayer(_passLevel, _reawardType, _rewardDatas)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_TASK_RED, {type = "passCollect"})
    end
    local fileFunc = function()
        -- body

    end
    self.m_Net:sendPassCollectReq(_passLevel, successFunc, fileFunc)
end

-- TODO 
function NewDChallengeMgr:showPassRewardLayer(_passLevel, _reawardType, _rewardDatas)
    if not self:isCanShowLayer() then
        return
    end

    if not _passLevel or not _reawardType then
        return
    end
    
    local passList = self:getPassList()
    local levelList = nil

    if passList then
        levelList = passList:getLevelList()
    end

    if not levelList then
        return
    end

    local data = self:getRunningData()

    if _reawardType == levelList[_passLevel].miniGameType then
        local gameLayer = nil
        if _reawardType == "PICK_BOX" then
            local pickGameData = data:getPickDataByLevelId(_passLevel)
            if pickGameData then
                gameLayer = self:showPickMainLayer(pickGameData)
            end
        elseif _reawardType == "DICE_BONUS" then
            local miniGameData = data:getDiceDataByLevelId(_passLevel)
            if miniGameData then
                gameLayer = self:showDiceMainUI(miniGameData)
            end
        elseif _reawardType == "COIN_GUESS" then
            local miniGameData = self:geCoinGuessDataByLevelId(_passLevel)
            if miniGameData then
                gameLayer = self:showCoinGuessMainLayer(miniGameData)
            end
        end
        return gameLayer
    elseif _reawardType == "UNLOCK" or _reawardType == "FRAME" or  _reawardType == "ITEM" then
        self:showRewardLayer(_reawardType, _rewardDatas)
    elseif _reawardType == levelList[_passLevel].rewardType then
        local flyCoins = tonumber(levelList[_passLevel].coins) or 0
        local itemList = levelList[_passLevel].items
        local view = gLobalItemManager:createRewardLayer(itemList, clickFunc, flyCoins, nil, nil)
        if view then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
        return view
    end
end

-- 奖励界面里面 收集到 头像框排行榜 等奖励时展示
function NewDChallengeMgr:showRewardLayer(_reawardType, _rewardDatas)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("DCRewardLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCPrize.DCRewardLayer", _reawardType, _rewardDatas)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
        view:setName("DCRewardLayer")
    end
    return view
end

function NewDChallengeMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:shwoMiniGameLayer() then
        return
    end
    if self:getLayerByName("DChallengeMainUI") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.MainUI.DChallengeMainUI")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- all小游戏
function NewDChallengeMgr:shwoMiniGameLayer()
    local data = self:getRunningData()
    local miniGameData = data:getPlayingMiniGameData()
    if miniGameData then
        local miniGameType = miniGameData:getMiniGameType()
        if miniGameType == "PICK_BOX" then
            return self:showPickMainLayer(miniGameData)
        elseif miniGameType == "DICE_BONUS" then
            return self:showDiceMainUI(miniGameData)
        elseif miniGameType == "COIN_GUESS" then
            return self:showCoinGuessMainLayer(miniGameData)
        end
    end
    return nil
end

function NewDChallengeMgr:showTaskSkipLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("DCMissionTips") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCMission.DCMissionTips",_params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function NewDChallengeMgr:showTaskRewardLayer(_params,_callback,_type,_jc)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("DCMissionRewardLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCMission.DCMissionRewardLayer",_params,_callback,_type,_jc)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function NewDChallengeMgr:showTaskFlyLayer(_params,_jc)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("DCMissionFly") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCMission.DCMissionFly",_params,_jc)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--增倍器
function NewDChallengeMgr:showTaskBoostLayer(_type)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("DCMissionBoost") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCMission.DCMissionBoost",_type)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI + 1)
    end
    return view
end
--挑战规则
function NewDChallengeMgr:showMainRuleLayer(_params)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("DCMainRule") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.MainUI.DCMainRule",_params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function NewDChallengeMgr:getEntryPath(entryName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. themeName .. "EntryNode"
end

function NewDChallengeMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "_loading" .. "/Icons/" .. themeName .. "HallNode"
end

function NewDChallengeMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "_loading" .. "/Icons/" .. themeName .. "SlideNode"
end

function NewDChallengeMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "_loading/" .. themeName
end

--================================================ DiceGame 投骰子小游戏 S ================================================--
-- DiceGame 主界面
function NewDChallengeMgr:showDiceMainUI(miniGameData)
    if not self:isCanShowLayer() then
        return
    end
    local diceMainUI = gLobalViewManager:getViewByExtendData("DC_DiceMainUI")
    if diceMainUI then
        return diceMainUI
    end
    local view = util_createView("Activity_NewDChallenge.DCDiceGame.DC_DiceMainUI", miniGameData)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- DiceGame 引导界面
function NewDChallengeMgr:showDiceGuideUI(_overFunc)
    if not self:isCanShowLayer() then
        return
    end
    local DC_DiceGuideUI = gLobalViewManager:getViewByExtendData("DC_DiceGuideUI")
    if DC_DiceGuideUI then
        return DC_DiceGuideUI
    end
    local view = util_createView("Activity_NewDChallenge.DCDiceGame.DC_DiceGuideUI", _overFunc)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- DiceGame 结算界面
function NewDChallengeMgr:showDiceOverUI(_coins, _overFunc)
    if not self:isCanShowLayer() then
        return
    end
    local DC_DiceOverUI = gLobalViewManager:getViewByExtendData("DC_DiceOverUI")
    if DC_DiceOverUI then
        return DC_DiceOverUI
    end
    local view = util_createView("Activity_NewDChallenge.DCDiceGame.DC_DiceOverUI", _coins, _overFunc)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end
-- ==================== PickGame 小游戏 ========================
function NewDChallengeMgr:showPickMainLayer(_data)
    local view = gLobalViewManager:getViewByExtendData("LC_PickMainLayer")
    if view then
        return view
    end

    view = util_createView("Activity_NewDChallenge.DCPickGame.LC_PickMainUI", _data)
    if view then
        view:setName("LC_PickMainLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end
--================================================ DiceGame 投骰子小游戏 E ================================================--

-- 猜正反 主界面
function NewDChallengeMgr:showCoinGuessMainLayer(_data)
    local view = gLobalViewManager:getViewByExtendData("DC_CoinGuessMainLayer")
    if view then
        return view
    end

    view = util_createView("Activity_NewDChallenge.CoinGame.DC_CoinGuessMainLayer", _data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 猜正反 奖励界面
function NewDChallengeMgr:showCoinGuessRewardLayer(_data)
    local view = gLobalViewManager:getViewByExtendData("DC_CoinGuessRewardLayer")
    if view then
        return view
    end

    view = util_createView("Activity_NewDChallenge.CoinGame.DC_CoinGuessRewardLayer", _data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 猜正反 开始界面
function NewDChallengeMgr:showCoinGuessStartLayer(_data)
    local view = gLobalViewManager:getViewByExtendData("DC_CoinGuessStartLayer")
    if view then
        return view
    end

    view = util_createView("Activity_NewDChallenge.CoinGame.DC_CoinGuessStartLayer", _data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function NewDChallengeMgr:geCoinGuessDataByLevelId(_id)
    local dcData = self:getRunningData()
    if not dcData then
        return
    end

    local miniGameData = dcData:geCoinGuessDataByLevelId(_id)
    return miniGameData
end

--==================== 商店

-- 打开 兑换界面
function NewDChallengeMgr:showShopBuyLayer(data)
    local view = gLobalViewManager:getViewByExtendData("NewDCExchangeLayer")
    if view then
        return view
    end
    view = util_createView("Activity_NewDChallenge.DCStore.NewDCExchangeLayer",data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 兑换
function NewDChallengeMgr:shopBuy(_data)
    local successFunc = function(_netData)   
        gLobalViewManager:removeLoadingAnima()
        if _data then
            self:showStoreRewardLayer(_data)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_EXCHANGE,{success = true,data = _data})
    end

    local fileFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_EXCHANGE)
        gLobalViewManager:removeLoadingAnima()
    end
    gLobalViewManager:addLoadingAnima()
    self.m_Net:sendShopBuy(_data, successFunc, fileFunc)
end

-- 领取兑换奖励
function NewDChallengeMgr:showStoreRewardLayer(data)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("NewDCStoreRewardLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.DCStore.NewDCStoreRewardLayer",data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--================刷新券商店
function NewDChallengeMgr:showRefreshStore()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("RefStoreMainLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.RefreshStore.RefStoreMainLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 购买刷新券
function NewDChallengeMgr:buyRefreshTicket(data,succFun)

    globalData.iapRunData.p_contentId = tostring(data.index)
    local successFunc = function(_netData) 
        gLobalViewManager:removeLoadingAnima()
        succFun()
        -- local callFunc =  function()
        --     gLobalViewManager:checkBuyTipList(
        --         function()
        --             gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_BUY_REFRESH_TICKET,{success = true}) 
        --         end
        --     )
        -- end
        -- gLobalViewManager:removeLoadingAnima()
        -- if data then
        --     local theData = {
        --         itemData = data.itemData,
        --         coins = data.coins
        --     }
        --     self:showRefreshRewardLayer(data,callFunc)
        -- end
    end
     

    local fileFunc = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NDC_BUY_REFRESH_TICKET)
    end
    gLobalViewManager:addLoadingAnima()
    self.m_Net:buyRefreshTicket(data,successFunc, fileFunc)
end

-- 购买刷新券领奖
function NewDChallengeMgr:showRefreshRewardLayer(data,callFunc)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("RefStoreRewardLayer") ~= nil then
        return
    end
    local view = util_createView("Activity_NewDChallenge.RefreshStore.RefStoreRewardLayer",data,callFunc)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

return NewDChallengeMgr
