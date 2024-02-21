-- blast 控制类
local BingoRushNet = require("activities.Activity_BingoRush.net.BingoRushNet")
local BingoRushManager = class("BingoRushManager", BaseActivityControl)

function BingoRushManager:ctor()
    BingoRushManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BingoRush)

    self.m_BingoRushNet = BingoRushNet:getInstance()
    self.bout_time = 10 -- 第三轮 一回合预估时间
    self.buff_time = 30 -- 第三轮 buff生效时间
    self.maintain_time = 30 * 60 -- 活动维护时间
    self.msgList = {}
end

function BingoRushManager:getConfig()
    if not self.BingoRushConfig then
        self.BingoRushConfig = util_require("activities.Activity_BingoRush.config.BingoRushConfig")
    end
    return self.BingoRushConfig
end

function BingoRushManager:getBoutTime()
    return self.bout_time
end

function BingoRushManager:getBuffTime()
    return self.buff_time
end

function BingoRushManager:getMaintainTime()
    return self.maintain_time
end

function BingoRushManager:getHallData()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return act_data:getHallData()
end

function BingoRushManager:getLevelData()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return act_data:getLevelData()
end

function BingoRushManager:clearData()
    local hall_data = self:getHallData()
    if hall_data then
        hall_data:clearData()
    end
    local game_data = self:getBingoGameData()
    if game_data then
        game_data:clearData()
    end

    self.msgList = {}
    self.bl_showBuff = nil
end

function BingoRushManager:getBingoGameData()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return act_data:getBingoGameData()
end

function BingoRushManager:getSaleData()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return act_data:getSaleData()
end

function BingoRushManager:getSaleNoCoinData()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return act_data:getSaleNoCoinData()
end

function BingoRushManager:getPassData()
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    return act_data:getPassData()
end

-- 发送获取排行榜消息
function BingoRushManager:getRank()
    -- 数据不全 不执行请求
    if not self:getRunningData() then
        return
    end

    local successCallFunc = function(rankData)
        if rankData ~= nil then
            local act_data = self:getRunningData()
            if act_data then
                act_data:parseMatchRankConfig(rankData)
            end
        end
    end

    local function failedCallFunc(target, code, errorMsg)
        gLobalViewManager:showReConnect()
    end

    self.m_BingoRushNet:requestRankData(successCallFunc, failedCallFunc)
end

function BingoRushManager:setLostBingoMatch(roomId, bl_lost)
    if not self.lostMatchs then
        self.lostMatchs = {}
    end
    self.lostMatchs[roomId] = bl_lost
end

function BingoRushManager:getLostBingoMatch(roomId)
    if self.lostMatchs then
        return self.lostMatchs[roomId] or false
    end
    return false
end

function BingoRushManager:setBingoMatchFailed(roomId, bl_failed)
    if roomId == nil or bl_failed == nil then
        return
    end
    if not self.matchsFailed then
        self.matchsFailed = {}
    end
    self.matchsFailed[roomId] = bl_failed
end

function BingoRushManager:getBingoMatchFailed(roomId)
    if self.matchsFailed then
        return self.matchsFailed[roomId] or false
    end
    return false
end

function BingoRushManager:resetBingoMatchState(roomId)
    if self.lostMatchs and self.lostMatchs[roomId] ~= nil then
        self.lostMatchs[roomId] = false
    end
end

-- 判断是否需要显示buff加成效果
function BingoRushManager:needShowBuff()
    if self.bl_showBuff == nil then
        local hall_data = self:getHallData()
        if not hall_data then
            self.bl_showBuff = false
        end
        local start_time = hall_data:getRoundStartTime(2)
        local cur_time = util_getCurrnetTime()
        self.bl_showBuff = (cur_time - start_time <= self.buff_time)
    end
    return self.bl_showBuff
end

-- buff显示完
function BingoRushManager:onBuffShown()
    self.bl_showBuff = false
end

-- 大厅展示资源判断
function BingoRushManager:isDownloadLobbyRes()
    return self:isDownloadLoadingRes()
end

function BingoRushManager:checkReconnect()
    if not self:isCanShowLayer() then
        return
    end

    local success_call = function()
        local hall_data = self:getHallData()
        local round_idx, bl_inHall = hall_data:getCurRoundAndState()
        if bl_inHall == true then
            local bet_idx = hall_data:getBetIdx()
            if bet_idx and bet_idx >= 0 then
                self:showHallLayer(bet_idx)
            else
                self:showLevelLayer()
            end
        else
            if self:getLostBingoMatch(hall_data.roomId) then
                self:showHallLayer(bet_idx)
                return
            end

            if round_idx == 0 or round_idx == 1 then
                -- 跳转关卡界面
                self:showSpinLayer()
            elseif round_idx == 2 then
                -- 跳转bingo界面
                self:showBingoLayer()
            else
                self:showHallLayer(bet_idx)
            end
        end
    end

    local failed_call = function(errorCode, errorData)
        if errorData == "no room" then
            self:showLevelLayer()
        else
            printError("errorData " .. errorData)
        end
    end

    self:requestConnect(success_call, failed_call)
end

-- 跳转关卡选择界面
function BingoRushManager:showLevelLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("BingoRushLevelUI") == nil then
        local levelUI = util_createView("Activity.BingoRush.LevelUI.BingoRushLevelUI")
        if levelUI then
            self:showLayer(levelUI, ViewZorder.ZORDER_UI_LOWER)
        end
    end
end

-- 显示加载界面
function BingoRushManager:showLoadingLayer(preUI, msgType, showView, onActive)
    local loadingUI = util_createView("Activity.BingoRush.HallUI.BingoRushLoadingUI")
    if loadingUI and not tolua.isnull(loadingUI) then
        if msgType and string.len(msgType) > 0 then
            loadingUI:setWait(true)

            self:registStatusBack(
                function(bl_success)
                    self:unregistStatusBack()
                    -- 成功
                    if loadingUI and not tolua.isnull(loadingUI) then
                        loadingUI:setWait(false)
                    end
                end
            )
            self:requestStatus(msgType, nil, nil, true)
        end

        local delPreView = function()
            -- 移除旧界面
            local preView = gLobalViewManager:getViewByExtendData(preUI)
            if preView and not tolua.isnull(preView) then
                preView:closeUI()
            end
        end

        local createNewView = function()
            if not self:isCanShowLayer() then
                return
            end

            if showView then
                showView()
            end

            if loadingUI then
                loadingUI:setCloseCall(onActive)
            else
                if onActive then
                    onActive()
                end
            end
        end

        loadingUI:setOnShownCall(delPreView)
        loadingUI:setIdleOverCall(createNewView)

        self:showLayer(loadingUI, ViewZorder.ZORDER_UI_UPPER)
    end
end

-- 返回大厅
function BingoRushManager:backToHall()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("BingoRushHallUI") then
        return
    end

    local showHall = function()
        if gLobalViewManager:getViewByExtendData("BingoRushHallUI") then
            return
        end
        local data = self:getRunningData()
        if not data:isRunning() then
            return
        end
        local hall_data = data:getHallData()
        local curRound, bl_inHall = hall_data:getCurRoundAndState()
        if not bl_inHall then
            return
        end

        local hallUI = util_createView("Activity.BingoRush.HallUI.BingoRushHallUI")
        if hallUI ~= nil then
            hallUI:setViewActive(false)
            self:showLayer(hallUI, ViewZorder.ZORDER_UI_LOWER)
        end
    end

    local onActive = function()
        local hallUI = gLobalViewManager:getViewByExtendData("BingoRushHallUI")
        if hallUI and not tolua.isnull(hallUI) then
            hallUI:setViewActive(true)
        end
    end

    self:showLoadingLayer("BingoRushMiniMachine", "hall", showHall, onActive)
end

-- 跳转大厅界面
function BingoRushManager:showHallLayer(betIdx)
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("BingoRushHallUI") then
        return
    end

    local showHall = function()
        if gLobalViewManager:getViewByExtendData("BingoRushHallUI") == nil then
            local hallUI = util_createView("Activity.BingoRush.HallUI.BingoRushHallUI", betIdx)
            if hallUI ~= nil then
                hallUI:setViewActive(false)
                self:showLayer(hallUI, ViewZorder.ZORDER_UI_LOWER)
            end
        end
    end

    local onActive = function()
        local hallUI = gLobalViewManager:getViewByExtendData("BingoRushHallUI")
        if hallUI and not tolua.isnull(hallUI) then
            hallUI:setViewActive(true)
        end
    end

    self:showLoadingLayer("BingoRushLevelUI", nil, showHall, onActive)
end

-- 跳转spin轮次
function BingoRushManager:showSpinLayer()
    if not self:isCanShowLayer() then
        return false
    end

    if gLobalViewManager:getViewByExtendData("BingoRushMiniMachine") then
        return false
    end

    local showSpin = function()
        local MachineData = require "activities.Activity_BingoRush.model.BingoRushMachineData"
        local machineData = MachineData:create()
        machineData:parseMachineBetsData()
        globalData.slotRunData.machineData = machineData

        local machineView = util_createView("Activity.BingoRush.BingoRushMachine.BingoRushMiniMachine")
        self:showLayer(machineView, ViewZorder.ZORDER_UI_LOWER)
    end

    local onActive = function()
        local machineView = gLobalViewManager:getViewByExtendData("BingoRushMiniMachine")
        if machineView and not tolua.isnull(machineView) then
            local hall_data = self:getHallData()
            if not hall_data then
                printError("BingoRushManager:showSpinLayer 数据错误 2")
                return
            end

            local delay = 0
            local leftTime = 4
            local cur_round = hall_data:getCurRoundAndState()
            local start_time = hall_data:getRoundStartTime(cur_round)
            if start_time and start_time > 0 then
                local curTime = util_getCurrnetTime()
                delay = start_time - curTime - leftTime
                --计算进入轮盘界面后距离可以开始spin的时间
                if delay < 0 then
                    leftTime = delay + leftTime
                    delay = 0
                end
            end
            machineView:gameStart(leftTime)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGORUSH_CLOSE_DELAY, delay)
        end
    end

    self:showLoadingLayer("BingoRushHallUI", "spin", showSpin, onActive)

    return true
end

-- 跳转bingo轮次
function BingoRushManager:showBingoLayer()
    if not self:isCanShowLayer() then
        return false
    end
    if gLobalViewManager:getViewByExtendData("BingoRushMatchUI") then
        return false
    end

    local showBingo = function()
        local game_data = self:getBingoGameData()
        if not game_data then
            printError("BingoRushManager:showSpinLayer 数据错误 3")
            return
        end
        game_data:resetBout() -- 预先准备好数据
        local bingoUI = util_createView("Activity.BingoRush.BingoGame.BingoRushMatchUI")
        if bingoUI ~= nil then
            self:showLayer(bingoUI, ViewZorder.ZORDER_UI_LOWER)
        end
    end

    local onActive = function()
        local bingoUI = gLobalViewManager:getViewByExtendData("BingoRushMatchUI")
        if bingoUI and not tolua.isnull(bingoUI) then
            bingoUI:onMatchBegin()
        end
    end

    self:showLoadingLayer("BingoRushHallUI", "bingo", showBingo, onActive)

    return true
end

function BingoRushManager:showRankLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local rankUI = nil
    if gLobalViewManager:getViewByExtendData("BingoRushRankUI") == nil then
        gLobalNoticManager:postNotification(ViewEventType.RANK_BTN_CLICKED, {name = ACTIVITY_REF.BingoRush})
        rankUI = util_createView("Activity.BingoRush.RankUI.BingoRushRankUI")
        self:showLayer(rankUI, ViewZorder.ZORDER_UI_LOWER)
    end
end

function BingoRushManager:enterRoom(betIdx)
    if not self:isCanShowLayer() then
        return
    end

    local success_call = function()
        self:showHallLayer(betIdx)
    end

    local failed_call = function(errorCode, errorData)
        printError(errorData)
    end

    self:requestEnterRoom(betIdx, success_call, failed_call)
end

-- 显示binggo 比赛 促销弹板
function BingoRushManager:showPromotionSaleLayer()
    if gLobalViewManager:getViewByExtendData("Promotion_BingoRush") then
        return
    end
    -- 与没钱促销互斥
    if gLobalViewManager:getViewByExtendData("Promotion_BingoRushNoCoin") then
        return
    end

    local saleData = self:getSaleData()
    if not saleData then
        return
    end

    local leftTimes = saleData:getLeftTimes()
    if leftTimes <= 0 then
        return
    end

    local saleLayer = util_createView("Activity.BingoRush.Promotion.Promotion_BingoRush", saleData)
    gLobalViewManager:showUI(saleLayer, ViewZorder.ZORDER_UI)
end

-- 显示binggo 比赛 没钱促销弹板
function BingoRushManager:showPromotionNoCoinSaleLayer()
    if gLobalViewManager:getViewByExtendData("Promotion_BingoRushNoCoin") then
        return
    end

    -- 与常规促销互斥
    if gLobalViewManager:getViewByExtendData("Promotion_BingoRush") then
        return
    end

    gLobalSendDataManager:getNetWorkFeature():sendBingoRushNoCoin(
        function()
            local saleData = self:getSaleNoCoinData()
            if not saleData then
                return
            end

            local saleLayer = util_createView("Activity.BingoRush.Promotion.Promotion_BingoRushNoCoin", saleData)
            gLobalViewManager:showUI(saleLayer, ViewZorder.ZORDER_UI)
        end
    )
end

-- 显示binggo 比赛 pass弹板
function BingoRushManager:showPassLayer()
    if gLobalViewManager:getViewByExtendData("BingoRushPassMainLayer") then
        return
    end

    local passView = util_createView("Activity.BingoRush.Pass.BingoRushPassMainLayer")
    if passView then
        self:showLayer(passView, ViewZorder.ZORDER_UI_LOWER)
    end
end

function BingoRushManager:showHelpLayer()
    if gLobalViewManager:getViewByExtendData("BingoRushHelpUI") then
        return
    end

    local infoLayer = util_createView("Activity.BingoRush.PayTable.BingoRushHelpUI")
    self:showLayer(infoLayer, ViewZorder.ZORDER_UI_LOWER)
end

function BingoRushManager:pushMsg(msg_type, msg_data)
    if not self.msgList[msg_type] then
        self.msgList[msg_type] = {}
    end

    -- TODO 这里是不是多条信息的数组
    table.insert(self.msgList[msg_type], msg_data)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGORUSH_NEW_MSG, msg_type)
end

function BingoRushManager:closePops()
    --local promotionUI = gLobalViewManager:getViewByExtendData("Promotion_BingoRush")
    --if promotionUI then
    --    promotionUI:closeUI()
    --end
    local helpUI = gLobalViewManager:getViewByExtendData("BingoRushHelpUI")
    if helpUI then
        helpUI:close()
    end
end

function BingoRushManager:getHallNumsMsg()
    -- 当消息队列空的时候 塞入一条当前房间人数的消息
    local hall_data = self:getHallData()
    if not hall_data then
        return
    end
    local curRound = hall_data:getCurRoundAndState()
    if curRound == -1 then
        local players = hall_data:getPlayers()
        local cur_nums = table.nums(players)
        local msg_data = {joined = cur_nums, bl_stay = true}
        return msg_data
    end
end

function BingoRushManager:getNextMsg(_type)
    if self.msgList and self.msgList[_type] then
        if table.nums(self.msgList[_type]) > 0 then
            local msg = self.msgList[_type][1]
            return msg
        end
    end
    if _type and _type == self.BingoRushConfig.MSG_TYPE.HALL then
        return self:getHallNumsMsg()
    end
end

function BingoRushManager:popMsg(_type)
    if self.msgList and self.msgList[_type] then
        if table.nums(self.msgList[_type]) > 0 then
            local msg = self.msgList[_type][1]
            table.remove(self.msgList[_type], 1)
            return msg
        end
    end
end

function BingoRushManager:getMsgCounts(msg_type)
    if not self.msgList or not self.msgList[msg_type] or type(self.msgList[msg_type]) ~= "table" then
        return 0
    end
    return table.nums(self.msgList[msg_type])
end

function BingoRushManager:clearMsgList(_type)
    if not self.msgList then
        return
    end

    if not self.msgList[_type] then
        return
    end

    self.msgList[_type] = nil
end

function BingoRushManager:isTeamReady()
    local hall_data = self:getHallData()
    if hall_data then
        return hall_data:isTeamReady()
    end
end

function BingoRushManager:getBingoLines()
    local game_data = self:getBingoGameData()
    if not game_data then
        return {}
    end
    local bingo_list = {}
    local bout_data = game_data:getCurBoutData()
    local item_idx = game_data:getCellIdxByNum(bout_data.ball)
    bingo_list = self:getBingoLineByIdx(item_idx)

    local ball_data = game_data:getCellDataByIdx(item_idx)
    if ball_data.buff_data and ball_data.buff_data.type then
        if ball_data.buff_data.type == "LINK" then
            local link_idx = ball_data.buff_data.idx
            local bingo_list_link = self:getBingoLineByIdx(link_idx)
            table.merge(bingo_list, bingo_list_link)
        end
    end
    return bingo_list
end

function BingoRushManager:getLinesByIdx(item_idx)
    local game_data = self:getBingoGameData()
    if not game_data then
        return {}
    end
    local ball_data = game_data:getCellDataByIdx(item_idx)

    local row = ball_data.row
    local col = ball_data.col
    local lines = {{}, {}, {}, {}}
    for i = 1, 5 do
        -- 横向
        local item1 = game_data:getCardByRowAndCol(i, col)
        if item1.state >= 1 then
            table.insert(lines[1], item1)
        end
        -- 竖向
        local item2 = game_data:getCardByRowAndCol(row, i)
        if item2.state >= 1 then
            table.insert(lines[2], item2)
        end
        -- 左斜
        if row == col then
            local item3 = game_data:getCardByRowAndCol(i, i)
            if item3.state >= 1 then
                table.insert(lines[3], item3)
            end
        end

        -- 右斜
        if row == 6 - col then
            local item4 = game_data:getCardByRowAndCol(i, 6 - i)
            if item4.state >= 1 then
                table.insert(lines[4], item4)
            end
        end
    end
    return lines
end

function BingoRushManager:getBingoLineByIdx(item_idx)
    local lines = self:getLinesByIdx(item_idx)
    local bingo_list = {}
    for i = 1, 4 do
        -- 5个连城线的算一条bingo
        if lines[i] and table.nums(lines[i]) == 5 then
            -- bingo线
            table.insertto(bingo_list, lines[i])
        end
    end
    return bingo_list
end

function BingoRushManager:getJackpotLines(jackpot_type)
    local game_data = self:getBingoGameData()
    if not game_data then
        return {}
    end
    if jackpot_type == "mini" then
        -- mini 十 线上的格子
        local bingo_list = {}
        for i = 1, 5 do
            -- 横向
            local item1 = game_data:getCardByRowAndCol(i, 3)
            if item1 then
                table.insert(bingo_list, item1)
            end
            -- 竖向
            local item2 = game_data:getCardByRowAndCol(3, i)
            if item2 then
                table.insert(bingo_list, item2)
            end
        end
        return bingo_list
    elseif jackpot_type == "major" then
        -- major X 线上的格子
        local bingo_list = {}
        for i = 1, 5 do
            -- 左斜
            local item3 = game_data:getCardByRowAndCol(i, i)
            if item3 then
                table.insert(bingo_list, item3)
            end
            -- 右斜
            local item4 = game_data:getCardByRowAndCol(i, 6 - i)
            if item4 then
                table.insert(bingo_list, item4)
            end
        end
        return bingo_list
    elseif jackpot_type == "grand" then
        -- grand 所有的格子
        local player_data = game_data:getPlayerData()
        return player_data.card
    end

    return {}
end

-----------------------------------------------  网络消息  -----------------------------------------------
-- 报名比赛
function BingoRushManager:requestEnterRoom(idx, onSuccess, onFailed)
    local success_call_fun = function(resData)
        if resData.lostUser ~= nil then
            self:clearData()
            self:setLostBingoMatch(resData.roomId, resData.lostUser)
        end
        if resData.matchFail ~= nil then
            self:clearData()
            self:setBingoMatchFailed(resData.roomId, resData.matchFail)
        end

        local act_data = self:getRunningData()
        if act_data then
            act_data:parseHallData(resData)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.BingoRush})
        end
        if onSuccess then
            onSuccess()
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        if onFailed then
            onFailed(errorCode, errorData)
        end
    end
    self.m_BingoRushNet:requestEnterRoom(idx, success_call_fun, faild_call_fun)
end

-- 退出报名
function BingoRushManager:requestQuitRoom()
    local success_call_fun = function(resData)
        self:clearData()
        printInfo("Bingo比赛 退出房间成功")
    end

    local faild_call_fun = function(target, errorCode, errorData)
        printInfo("Bingo比赛 退出房间失败")
    end
    self.m_BingoRushNet:requestQuitRoom(success_call_fun, faild_call_fun)
end

function BingoRushManager:requestConnect(onSuccess, onFailed)
    self:requestStatus("hall", onSuccess, onFailed, true)
end

-- 状态刷寻
function BingoRushManager:requestStatus(status, onSuccess, onFailed, bl_showLoading)
    local success_call_fun = function(resData)
        local act_data = self:getRunningData()
        if act_data and resData then
            if resData.lostUser ~= nil then
                self:clearData()
                self:setLostBingoMatch(resData.roomId, resData.lostUser)
            end
            if resData.matchFail ~= nil then
                self:clearData()
                self:setBingoMatchFailed(resData.roomId, resData.matchFail)
            end

            act_data:parseHallData(resData)
            act_data:parseLevelGameData(resData)
            act_data:parseBingoData(resData)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.BingoRush})
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGORUSH_STATUS, resData)

        if onSuccess and type(onSuccess) == "function" then
            onSuccess()
        end
        self:onStatusBack(true)
    end

    local faild_call_fun = function(target, errorCode, errorData)
        if onFailed and type(onFailed) == "function" then
            onFailed(errorCode, errorData)
        end
        self:onStatusBack(false)
    end
    if bl_showLoading == nil then
        bl_showLoading = false
    end
    self.m_BingoRushNet:requestStatus(status, success_call_fun, faild_call_fun, bl_showLoading)
end

function BingoRushManager:registStatusBack(call_back)
    if call_back and type(call_back) == "function" then
        self.notifyStatusBack = call_back
    end
end

function BingoRushManager:unregistStatusBack()
    self.notifyStatusBack = nil
end

function BingoRushManager:onStatusBack(bl_success)
    if self.notifyStatusBack then
        self.notifyStatusBack(bl_success)
    end
end

-- 领取奖励
function BingoRushManager:requestReward(onSuccess, onFailed)
    local success_call_fun = function(resData)
        printInfo("resData")
        if onSuccess then
            onSuccess(resData)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        printError("BingoRushManager:requestReward errorCode " .. errorCode)
        if onFailed then
            onFailed()
        end
    end
    self.m_BingoRushNet:requestReward(success_call_fun, faild_call_fun)
end

-- 排行榜pass 任务 领取
function BingoRushManager:requestPassCollect(_idx, _bPay)
    local success_call_fun = function(resData)
        resData.idx = _idx
        resData.bl_pay = (_bPay == 1)

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGORUSH_TASK_PASS_COLLECT_SUCCESS, resData)
    end

    local faild_call_fun = function(target, errorCode, errorData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGORUSH_TASK_PASS_COLLECT_FAILED, errorData)
    end
    self.m_BingoRushNet:requestPassCollect(_idx, _bPay, success_call_fun, faild_call_fun)
end

function BingoRushManager:requestPaccCollectAll()
    self:requestPassCollect(-1, 2)
end

-- 获取spin结果
function BingoRushManager:requestSpin(onSuccess, onFailed)
    local success_call_fun = function(resData)
        local spinData = cjson.decode(resData.result)
        local act_data = self:getRunningData()
        if act_data then
            act_data:setSpinData(spinData)
        end

        local spinResult = spinData.spinResult
        if not spinResult then
            return
        end
        local _extendData = spinResult.extend
        if _extendData then
            if _extendData.highLimit ~= nil then
                globalData.syncDeluexeClubData(_extendData.highLimit)
            end
        end
        if type(onSuccess) == "function" then
            onSuccess(spinData, resData)
        end
    end

    local faild_call_fun = function(target, errorCode, errorData)
        if type(onFailed) == "function" then
            onFailed(target, errorCode, errorData)
        end
    end
    self.m_BingoRushNet:requestSpin(success_call_fun, faild_call_fun)
end

-- 获取排行榜消息
function BingoRushManager:requestRankData()
    local success_call_fun = function(resultData)
    end

    local faild_call_fun = function(target, code, errorMsg)
    end
    self.m_BingoRushNet:requestRankData(success_call_fun, faild_call_fun)
end

-- 获取排行榜消息
function BingoRushManager:requestLostData(onSuccess, onFailed)
    local success_call_fun = function(resultData)
    end

    local faild_call_fun = function(target, code, errorMsg)
    end
    self.m_BingoRushNet:requestLostData(success_call_fun, faild_call_fun)
end

-------------------- 付费重置 --------------------
function BingoRushManager:goPurchaseSale(bl_nocoin)
    self.m_BingoRushNet:goPurchaseSale(bl_nocoin)
end
function BingoRushManager:goPurchasePass()
    self.m_BingoRushNet:goPurchasePass()
end
-------------------- 付费重置 --------------------

-- 飞金币相关参数记录
function BingoRushManager:recordCoinParams()
    self.topUIScale = globalData.topUIScale
    self.flyCoinsEndPos = globalData.flyCoinsEndPos
    if globalData.slotRunData.isPortrait == false then
        self.recordHorizontalEndPos = globalData.recordHorizontalEndPos
    end
end

function BingoRushManager:resetCoinParams()
    if self.topUIScale then
        globalData.topUIScale = self.topUIScale
    end
    if self.flyCoinsEndPos then
        globalData.flyCoinsEndPos = self.flyCoinsEndPos
    end
    if globalData.slotRunData.isPortrait == false then
        if self.recordHorizontalEndPos then
            globalData.recordHorizontalEndPos = self.recordHorizontalEndPos
        end
    end
end

function BingoRushManager:resetFinalRoundTime()
    local hall_data = self:getHallData()
    if not hall_data then
        return
    end
    hall_data:resetFinalRoundTime()
end

return BingoRushManager
