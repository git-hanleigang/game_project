---
--xcyy
--2018年5月23日
--DragonsWheelViewBg.lua
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local DragonsWheelViewBg = class("DragonsWheelViewBg", BaseGame)

DragonsWheelViewBg.bigWheelData = {"0", "MinorWheel", "3", "Major", "8", "MiniWheel", "5", "SuperWheel", "0", "Minor", "3", "MajorWheel", "8", "Mini", "5", "Grand"} --轮盘类型
DragonsWheelViewBg.bonusNumData = {3, 10, 5, 2, 8, 3, 10, 5, 2, 8, 3, 10, 5, 2, 8, 5} --bonus 乘倍数

function DragonsWheelViewBg:initUI(_machine)
    self.m_machine = _machine
    self:createCsbNode("Dragons_WheelBg.csb")

    local WheelData = {}
    WheelData.m_wheelData = self.bigWheelData
    self.m_BigWheel = util_createView("CodeDragonsSrc.DragonsBigWheelView", WheelData)
    self:findChild("Node_1"):addChild(self.m_BigWheel)
    self.m_BigWheel:setParent(self)

    self.m_BigWheel:initCallBack(
        function()
            self.m_machine:stopMusicBg()
            gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_wheel_win.mp3")
            self.m_BigWheel:runCsbAction("win", true)
            performWithDelay(
                self,
                function()
                    local _type = self:getCurStage()
                    if self:getCurStage() == "free" then
                        self:hideWheelBg()
                    elseif self:getCurStage() == "jackpot" then
                        self:showWheelJackpot()
                    elseif self:getCurStage() == "bonusJackpot" then
                        self:showWheelBonusJackpot()
                    end
                end,
                2
            )
        end
    )

    local bonusData = {}
    bonusData.m_wheelData = self.bonusNumData
    self.m_bonusWheel = util_createView("CodeDragonsSrc.DragonsBonusWheelView", bonusData)
    self:findChild("Node_2"):addChild(self.m_bonusWheel)
    self.m_bonusWheel:setParent(self)

    self.m_bonusWheel:initCallBack(
        function()
            self.m_machine:stopMusicBg()
            gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_wheel_win.mp3")
            self.m_bonusWheel:runCsbAction("win", true)
            performWithDelay(
                self,
                function()
                    local wins = self:getJackpotWinCoins()
                    self:showBonusMultipleView()
                    self:showJackpotEffect()
                    self.m_bonusJackpot:playIdleAction(
                        wins,
                        function()
                            performWithDelay(
                                self,
                                function()
                                    gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_wheel_down.mp3")
                                    self.m_bonusWheel:runCsbAction(
                                        "over",
                                        false,
                                        function()
                                            self.m_bonusJackpot:runCsbAction(
                                                "over",
                                                false,
                                                function()
                                                    local WinCoins = wins
                                                    globalData.slotRunData.lastWinCoin = self.m_machine.m_runSpinResultData.p_bonusWinCoins
                                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {WinCoins, false, true})
                                                    self.m_bonusJackpot:removeFromParent()
                                                    self.m_bonusJackpotEffect:removeFromParent()
                                                    self.m_bonusMultipleView:removeFromParent()
                                                    self.m_BigWheel:setTouchFlag(true)
                                                    self.m_BigWheel:runCsbAction("idleframe1", true)
                                                    self.m_machine:playWheelBg()
                                                end
                                            )
                                        end
                                    )
                                end,
                                1.5
                            )
                        end
                    )
                end,
                2
            )
        end
    )
end

function DragonsWheelViewBg:initMachine(machine)
    self.m_machine = machine
end

function DragonsWheelViewBg:playOpenAction()
    -- gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_big_wheel_start.mp3")
    self.m_BigWheel:runCsbAction(
        "open",
        false,
        function()
            self.m_BigWheel:runCsbAction("idle", true)
        end
    ) -- 播放时间线
end

-- function DragonsWheelViewBg:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

--轮盘个数
function DragonsWheelViewBg:getReelGameWheelEndIndex(type)
    local endIndex = nil
    for k, v in pairs(self.reelGameData) do
        if v == type then
            endIndex = k
            break
        end
    end
    return endIndex
end

--固定wild 列数
function DragonsWheelViewBg:getLockReelWheelEndIndex(type)
    local endIndex = nil

    for k, v in pairs(self.lockReelData) do
        if v == type then
            endIndex = k
            break
        end
    end
    return endIndex
end

--开始旋转
function DragonsWheelViewBg:beginBigWheelViewAction()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData then
        local endIndex = selfData.wheelIndex + 1
        self.m_BigWheel:beginWheelAction(endIndex)
    end
end

--开始旋转
function DragonsWheelViewBg:beginBonusWheelViewAction()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData then
        local endIndex = selfData.bonusWheelIndex + 1
        self.m_bonusWheel:beginWheelAction(endIndex)
    end
end

function DragonsWheelViewBg:playWheelOverEffect(_reelNum, _func)
    -- gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_big_wheel_over.mp3")
    if _reelNum == 2 then
        self.m_bonusWheel:runCsbAction(
            "over",
            false,
            function()
                self.m_BigWheel:runCsbAction("over")
                if _func then
                    _func()
                end
            end
        )
    else
        self.m_BigWheel:runCsbAction("over")
        self.m_bonusWheel:runCsbAction(
            "over",
            false,
            function()
                if _func then
                    _func()
                end
            end
        )
    end
end

function DragonsWheelViewBg:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

--数据发送
function DragonsWheelViewBg:sendData()
    self.m_action = self.ACTION_SEND
    self.m_isBonusCollect = true
    local httpSendMgr = SendDataManager:getInstance()
    local jpData = nil
    if self.m_machine then
        jpData = self.m_machine:getWheelJackpotList()
        if type(jpData) == "table" and #jpData == 0 then
            jpData = nil
        end
    end
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, jackpot = jpData}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

function DragonsWheelViewBg:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
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
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            -- self.m_featureData = self.m_featureData
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--当前阶段
function DragonsWheelViewBg:getCurStage()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local curStage = selfData.bonusResult
            if curStage then
                return curStage
            end
        end
    end
end

function DragonsWheelViewBg:getExtraSpinTimes()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local times = selfData.extraSpinTimes
            if times then
                return times
            else
                return 0
            end
        end
    end
end

function DragonsWheelViewBg:getBonusMultipleNum()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local _multiple = selfData.bonusWheelResult
            if _multiple then
                return _multiple
            else
                return 1
            end
        end
    end
end

function DragonsWheelViewBg:getBonusBaseJackpotWinCoins()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local WinCoins = selfData.baseJackpotWinCoins
            if WinCoins then
                return WinCoins
            else
                return 0
            end
        end
    end
end

function DragonsWheelViewBg:getJackpotType()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local _type = selfData.jackpot
            if _type then
                return _type
            else
                return nil
            end
        end
    end
end

function DragonsWheelViewBg:getJackpotWinCoins()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData then
            local WinCoins = self.m_machine.m_runSpinResultData.p_winAmount
            if WinCoins then
                return WinCoins
            else
                return 0
            end
        end
    end
end

function DragonsWheelViewBg:recvBaseData(featureData)
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
        self:beginBigWheelViewAction()
    end
end

function DragonsWheelViewBg:setCallFun(func)
    self.m_func = function()
        if func then
            func()
        end
    end
end

function DragonsWheelViewBg:hideWheelBg()
    self.m_machine:showExtraFreeSpinView()
    performWithDelay(
        self,
        function()
            self.m_func()
        end,
        1
    )
end

function DragonsWheelViewBg:showWheelJackpot()
    self.m_wheelJackpot = util_createView("CodeDragonsSrc.DragonsWheelJackPotWinView", self.m_machine)
    self.m_bonusWheel:findChild("jackpot"):addChild(self.m_wheelJackpot)
    local _type = self:getJackpotType()
    local _wins = self:getJackpotWinCoins()
    self.m_wheelJackpot:initJackpotType(
        _type,
        _wins,
        function()
            local jackpotOver = self.m_machine.m_runSpinResultData.p_selfMakeData.jackpotOver
            local WinCoins = _wins
            globalData.slotRunData.lastWinCoin = self.m_machine.m_runSpinResultData.p_bonusWinCoins
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {WinCoins, false, true})
            if jackpotOver == 1 then
                self:hideWheelBg()
            else
                self.m_machine:playWheelBg()
                self.m_BigWheel:setTouchFlag(true)
                self.m_BigWheel:runCsbAction("idleframe1", true)
                self.m_bonusJackpotEffect:removeFromParent()
                self.m_wheelJackpot:removeFromParent()
            end
        end
    )
    self:showJackpotEffect()
end

function DragonsWheelViewBg:showBonusMultipleView(_func)
    self.m_bonusMultipleView = util_createView("CodeDragonsSrc.DragonsBonusMultipleView")
    self.m_bonusWheel:findChild("multipleNode"):addChild(self.m_bonusMultipleView)
    local _multiple = self:getBonusMultipleNum()
    self.m_bonusMultipleView:playMultipleEffect(_multiple)
    self.m_bonusMultipleView:runCsbAction(
        "start",
        false,
        function()
            if _func then
                _func()
            end
        end
    ) -- 播放时间线
end

function DragonsWheelViewBg:showWheelBonusJackpot()
    self.m_bonusJackpot = util_createView("CodeDragonsSrc.DragonsBonusJackPotWinView")
    self.m_bonusWheel:findChild("jackpot"):addChild(self.m_bonusJackpot)
    local _type = self:getJackpotType()
    local _multiple = self:getBonusMultipleNum()
    local _wins = self:getBonusBaseJackpotWinCoins()
    self.m_bonusJackpot:initJackpotType(
        _type,
        _multiple,
        _wins,
        function()
            self.m_bonusJackpotEffect:removeFromParent()
            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_wheel_up.mp3")
                    self.m_bonusWheel:runCsbAction(
                        "start",
                        false,
                        function()
                            self.m_machine:playWheelBg()
                            performWithDelay(
                                self,
                                function()
                                    self:beginBonusWheelViewAction()
                                end,
                                1.5
                            )
                        end
                    )
                end,
                1.0
            )
        end
    )
    self:showJackpotEffect()
end

function DragonsWheelViewBg:showJackpotEffect()
    self.m_bonusJackpotEffect = util_createView("CodeDragonsSrc.DragonsDropCoinEffectView")
    self:findChild("jackpotEffect"):addChild(self.m_bonusJackpotEffect)
    self.m_bonusJackpotEffect:runCsbAction("actionframe", false)
end

return DragonsWheelViewBg
