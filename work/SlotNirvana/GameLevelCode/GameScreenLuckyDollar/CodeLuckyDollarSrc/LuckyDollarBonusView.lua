---
--xcyy
--2018年5月23日
--LuckyDollarBonusView.lua

local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local LuckyDollarBonusView = class("BonusGame", BaseGame)
--对应的节点
local nodeNameList = {"Node_1000", "Node_x2_1", "Node_x2_2", "Node_5_1", "Node_5_2", "Node_10_1", "Node_10_2", "Node_20_1", "Node_20_2", "Node_50_1", "Node_50_2", "Node_100"}
--钞票csb
local WinCsbList = {
    "LuckyDollar_1000",
    "LuckyDollar_x2",
    "LuckyDollar_x2",
    "LuckyDollar_5_1",
    "LuckyDollar_5_2",
    "LuckyDollar_10_1",
    "LuckyDollar_10_2",
    "LuckyDollar_20_1",
    "LuckyDollar_20_2",
    "LuckyDollar_50_1",
    "LuckyDollar_50_2",
    "LuckyDollar_100"
}
--每一排的csb
local rowCsbList = {
    {9, 12, 10},
    {7, 11, 5},
    {4, 8, 6},
    {1, 2, 3}
}
--服务器id对应的位置

function LuckyDollarBonusView:initUI()
    self:createCsbNode("LuckyDollar_bonus.csb")
    self:InitBonusUI()
    self.m_bStartUpdata = false
    self.m_iPlayIndex = 0
    self.m_bFirstShow = false
    self.m_bRecvNetData = false
    self.m_bClick = false
    self.m_iUpDataTimes = 1
    self.m_bClickOver = false
    self.m_iRandomIndex = nil --随机显示的格子
    self.m_iRandomLine = 1 --按顺序播放
end

-- function LuckyDollarBonusView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

--开始随机
function LuckyDollarBonusView:beginUpdate()
    scheduler.performWithDelayGlobal(
        function()
            if self.m_bStartUpdata then
                self:updateBonus()
            end
        end,
        self.m_iUpDataTimes,
        "LuckyDollarBonus"
    )
end

function LuckyDollarBonusView:initMachine(machine)
    self.m_machine = machine
end

function LuckyDollarBonusView:initReconnectView()
    self.m_bStartUpdata = false
    self.m_bClick = true
    self.m_bClickOver = false
    self.m_iPlayIndex = 1
    self.m_stagePanel:setVisible(true)
    self:findChild("btnNode"):setVisible(true)
    -- self:runCsbAction("start2",false,function()
    self:runCsbAction("idle", true)
    -- end)
    self:setBonusViewDark()
    local hits = self.m_machine.m_runSpinResultData.p_selfMakeData.hits
    local times = self.m_machine.m_runSpinResultData.p_selfMakeData.leftTimes
    local points = self.m_machine.m_runSpinResultData.p_selfMakeData.points
    local winCoins = self.m_totleWimnCoins
    if #hits > 0 then
        for i, v in ipairs(hits) do
            local index = v + 1
            -- print("选中位置 ====" .. index)
            self.m_winLabList[index]:runCsbAction("win", false)
        end
        if times > 0 then
            self.m_WinNum:setString(points)
            self.m_LeftNum:setString(times)
            self.m_stagePanel:runCsbAction("idle1")
        end
    end
end

function LuckyDollarBonusView:InitBonusUI()
    self.m_winLabList = {}
    for i = 1, 12 do
        local csbName = WinCsbList[i]
        local dollarCsb = util_createAnimation(csbName .. ".csb")
        local NodeName = nodeNameList[i]
        self:findChild(NodeName):addChild(dollarCsb)
        dollarCsb:runCsbAction("idle")
        table.insert(self.m_winLabList, dollarCsb)
    end

    self.m_stagePanel = util_createAnimation("LuckyDollar_anniukuang.csb")
    self.m_WinNum = self.m_stagePanel:findChild("m_lb_num_1")
    self.m_LeftNum = self.m_stagePanel:findChild("m_lb_num_2")
    self:findChild("Node_anniux3"):addChild(self.m_stagePanel)
    self.m_stagePanel:runCsbAction("idle2")
    self.m_stagePanel:setVisible(false)
    self:runCsbAction("start")
    self:findChild("btnNode"):setVisible(false)
end

function LuckyDollarBonusView:playBonusStart()
    self.m_bClickOver = false
    self.m_stagePanel:setVisible(true)
    self:findChild("btnNode"):setVisible(true)
    self:runCsbAction("wait")
    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_first.mp3")
    self.m_iPlayIndex = 1
    self.m_bStartUpdata = true
    self.m_bFirstShow = true
    self.m_iUpDataTimes = 4 / 30
    self:sendData(0)
    self:beginUpdate()
end

function LuckyDollarBonusView:showBonusBtnPage()
    self.m_stagePanel:setVisible(true)
    self:findChild("btnNode"):setVisible(true)
    self.m_stagePanel:runCsbAction("idle3")
    self:runCsbAction("wait")
end

function LuckyDollarBonusView:updateBonus()
    if self.m_iPlayIndex <= 4 then
        for i = 1, 3 do
            local num = rowCsbList[self.m_iPlayIndex][i]
            self.m_winLabList[num]:runCsbAction("start")
        end
        if self.m_iPlayIndex == 4 then
            self.m_iUpDataTimes = 30 / 30
        end
    else
        self:showRandomChooseWinLab()
        self.m_iUpDataTimes = 6 / 30
        if self.m_iPlayIndex >= 16 and self.m_bRecvNetData then
            self.m_bFirstShow = false
            self.m_bStartUpdata = false
            performWithDelay(
                self,
                function()
                    self:showWinHit()
                end,
                6 / 30
            )
            return
        end
    end
    self:beginUpdate()
    self.m_iPlayIndex = self.m_iPlayIndex + 1
end

--随机显示中奖位置
function LuckyDollarBonusView:showRandomChooseWinLab()
    local function getRandomIndex()
        local index = 1
        local randomIndex = xcyy.SlotsUtil:getArc4Random() % 3 + 1
        if self.m_iRandomLine == 1 then
            local list = {4, 8, 6}
            index = list[randomIndex]
        elseif self.m_iRandomLine == 2 then
            local list = {7, 11, 5}
            index = list[randomIndex]
        elseif self.m_iRandomLine == 3 then
            local list = {9, 12, 10}
            index = list[randomIndex]
        else
            local list = {1, 2, 3}
            index = list[randomIndex]
        end

        return index
    end

    local index = getRandomIndex()
    self.m_iRandomIndex = index
    self.m_iRandomLine = self.m_iRandomLine + 1
    if self.m_iRandomLine > 4 then
        self.m_iRandomLine = 1
    end
    self.m_winLabList[index]:runCsbAction("start2")

    self:playShowDollarSoundbyIndex(index)
end

function LuckyDollarBonusView:playShowDollarSoundbyIndex(index)
    if index == 1 then
        gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollar10000.mp3")
    elseif index == 2 or index == 3 then
        gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollarx2.mp3")
    elseif index == 4 or index == 5 then
        gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollar100.mp3")
    elseif index == 6 or index == 7 then
        gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollar200.mp3")
    elseif index == 8 or index == 9 then
        gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollar500.mp3")
    elseif index == 10 or index == 11 then
        gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollar1000.mp3")
    elseif index == 12 then
        gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollar2000.mp3")
    end
end

function LuckyDollarBonusView:onExit()
    scheduler.unschedulesByTargetName("LuckyDollarBonus")
    gLobalNoticManager:removeAllObservers(self)
end

function LuckyDollarBonusView:resetBonusView()
    for i = 1, 12 do
        self.m_winLabList[i]:runCsbAction("idle", false)
    end
end

function LuckyDollarBonusView:setBonusViewDark()
    for i = 1, 12 do
        self.m_winLabList[i]:runCsbAction("start_q", false)
    end
end

function LuckyDollarBonusView:playBonusOver()
    self:resetBonusView()
    self.m_stagePanel:setVisible(false)
    self:findChild("btnNode"):setVisible(false)
    self:runCsbAction("start")
end

function LuckyDollarBonusView:showWinsByIndex(_bFirst)
    local delayTime = 30 / 30
    if _bFirst then
        delayTime = 0
    end
    performWithDelay(
        self,
        function()
            local hits = self.m_machine.m_runSpinResultData.p_selfMakeData.hits
            if hits and #hits > 0 then
                if self.m_iWinIndex <= #hits then
                    local index = hits[self.m_iWinIndex] + 1
                    self.m_winLabList[index]:runCsbAction("win", false)
                    self:playShowDollarSoundbyIndex(index)
                    self.m_iWinIndex = self.m_iWinIndex + 1
                    self:showWinsByIndex()
                else
                    self:showWinLab()
                end
            end
        end,
        delayTime
    )
end

function LuckyDollarBonusView:showWinHit()
    local hits = self.m_machine.m_runSpinResultData.p_selfMakeData.hits
    local times = self.m_machine.m_runSpinResultData.p_selfMakeData.leftTimes
    local points = self.m_machine.m_runSpinResultData.p_selfMakeData.points
    local winCoins = self.m_totleWimnCoins
    self.m_iWinIndex = 1
    if hits and #hits > 0 then
        self:showWinsByIndex(true)
    else
        self.m_stagePanel:runCsbAction("idle1")
        self:showBonusOver(winCoins)
    end
end

function LuckyDollarBonusView:showWinLab()
    local times = self.m_machine.m_runSpinResultData.p_selfMakeData.leftTimes
    local points = self.m_machine.m_runSpinResultData.p_selfMakeData.points
    local winCoins = self.m_totleWimnCoins
    local hits = self.m_machine.m_runSpinResultData.p_selfMakeData.hits
    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_dollar_win.mp3")
    if hits and #hits > 0 then
        for i, v in ipairs(hits) do
            local index = v + 1
            self.m_winLabList[index]:runCsbAction("win1", false)
        end
    end
    performWithDelay(
        self,
        function()
            self.m_WinNum:setString(points)
            self.m_LeftNum:setString(times)
            self.m_stagePanel:runCsbAction("idle1")
            gLobalSoundManager:setBackgroundMusicVolume(1)
            if times > 0 then
                self.m_bClick = true
                self:runCsbAction(
                    "start2",
                    false,
                    function()
                        self:runCsbAction("idle", true)
                    end
                )
            else
                self:showBonusOver(winCoins)
            end
        end,
        40 / 30
    )
end

function LuckyDollarBonusView:showBonusOver(winCoins)
    self.m_machine:showBonusOver(winCoins)
end

function LuckyDollarBonusView:getLeftTimes()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.leftTimes then
        local times = selfData.leftTimes
        return times
    end
end

function LuckyDollarBonusView:updataLeftNum()
    if self:getLeftTimes() > 0 then
        if self:getLeftTimes() == 3 then
            gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_second.mp3")
            self.m_stagePanel:runCsbAction("idle4")
        elseif self:getLeftTimes() == 2 then
            gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_third.mp3")
            self.m_stagePanel:runCsbAction("idle5")
        elseif self:getLeftTimes() == 1 then
            gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_final.mp3")
            self.m_stagePanel:runCsbAction("idle6")
        end
    end
end

function LuckyDollarBonusView:playClickEffect()
    self.m_iPlayIndex = 1
    self.m_iRandomIndex = nil
    self.m_iRandomLine = 1
    self:setBonusViewDark()
    self:updataLeftNum()
    self.m_machine:showBonusBgAction()
    self.m_iUpDataTimes = 4 / 30
    self:beginUpdate()
end
--默认按钮监听回调
function LuckyDollarBonusView:clickFunc(sender)
    local name = sender:getName()
    if self.m_bClick == true then
        self.m_bClick = false
        self.m_bStartUpdata = true
        if name == "Button_blue" then
            self:runCsbAction("wait")
            --next
            if self:getLeftTimes() > 0 then
                self:sendData(0)
                self:playClickEffect()
            elseif self:getLeftTimes() == 0 then
                self.m_bClickOver = true
                self:sendData(1)
            end
        elseif name == "Button_red" then
            self.m_bClickOver = true
            self:runCsbAction("wait")
            --over
            self:sendData(1)
        end
    end
end

--数据发送 pos = 0 继续 ；pos = 1 结束
function LuckyDollarBonusView:sendData(pos)
    self.m_bRecvNetData = false
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

function LuckyDollarBonusView:featureResultCallFun(param)
    if param[1] == true and self.m_machine.m_bInBonus then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
        print("不在Bonus里面了")
    end
end

function LuckyDollarBonusView:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action = self.ACTION_RECV
    if featureData.p_status == "START" then
        self:startGameCallFunc()
        return
    end
    self.m_featureData = featureData

    if featureData.p_status == "CLOSED" then
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_bsWinCoins, GameEffect.EFFECT_BONUS})
    else
        self.m_bRecvNetData = true
        if self.m_bClickOver then
            self:showWinHit()
        end
    end
end

return LuckyDollarBonusView
