---
--xcyy
--2018年5月23日
--FourInOneBonus_WheelView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")

local FourInOneBonus_WheelView = class("FourInOneBonus_WheelView", util_require("base.BaseGame"))
FourInOneBonus_WheelView.m_wheelSumIndex = 12

FourInOneBonus_WheelView.m_littleUI = {}
function FourInOneBonus_WheelView:initUI(data)
    self:createCsbNode("4in1_wheel.csb")

    self.m_wheel =
        require("CodeFourInOneSrc.Wheel.FourInOneBonus_WheelAction"):create(
        self:findChild("WheelNode"),
        self.m_wheelSumIndex,
        function()
            -- 滚动结束调用
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end
    )
    self:addChild(self.m_wheel)

    self:setWheelRotModel()

    self.m_wheelData = data.wheelData
    self.m_machine = data.machine

    self.m_bonusEndCall = nil

    self:runCsbAction("idleframe", true)

    self:initWheelLittleNode()
    self:addClick(self:findChild("click"))
    self:findChild("click"):setVisible(false)
    self:findChild("click"):setVisible(true)
end

function FourInOneBonus_WheelView:getCsbName(str)
    if str == "Grand" then
        return "Grand"
    elseif str == "Major" then
        return "Major"
    elseif str == "Minor" then
        return "Minor"
    elseif str == "Mini" then
        return "Mini"
    elseif str == "Free" then
        return "FS"
    elseif str == "SuperFree" then
        return "SuperFS"
    end
end

function FourInOneBonus_WheelView:initWheelLittleNode()
    self.m_littleUI = {}

    for i = 1, self.m_wheelSumIndex do
        local data = self.m_wheelData[i]

        local node = self:findChild("text" .. i)
        local csbName = self:getCsbName(data)
        local LittleNodeData = {}

        LittleNodeData.csbName = csbName
        LittleNodeData.posIndex = i

        local wheelLittleNode = util_createView("CodeFourInOneSrc.Wheel.FourInOneBonus_LittleNode", LittleNodeData)
        node:addChild(wheelLittleNode)

        if csbName == "SuperFS" then
            node:setLocalZOrder(10)
        end

        table.insert(self.m_littleUI, wheelLittleNode)
    end
end

-- function FourInOneBonus_WheelView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function FourInOneBonus_WheelView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function FourInOneBonus_WheelView:beginWheel(data)
    self.m_endIndex = (data.choose + 1)

    self.m_callFunc = function()
        self.m_machine:clearCurMusicBg()

        self:runCsbAction("animation0", true)

        gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Wheel_Win.mp3")

        performWithDelay(
            self,
            function()
                if data.endCallBack then
                    data.endCallBack()
                end
            end,
            1.5
        )
    end

    self.m_wheel:updateEndCallFunc(self.m_callFunc)

    -- 接受到消息后开始停止
    self.m_wheel:recvData(self.m_endIndex)
end

function FourInOneBonus_WheelView:beginWheelAction()
    local wheelData = {}
    wheelData.m_startA = 150 --加速度
    wheelData.m_runV = 400
    --匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 50 --动态减速度
    wheelData.m_slowQ = 3 --减速圈数
    wheelData.m_stopV = 30 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel(false)
end

function FourInOneBonus_WheelView:setWheelRotModel()
    self.m_wheel:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

function FourInOneBonus_WheelView:setRotionAction(distance, targetStep, isBack)
    self.distance_now = (distance / targetStep) + 0.5

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Wheel_run.mp3")
    end
end

--默认按钮监听回调
function FourInOneBonus_WheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self:findChild("click"):setVisible(false)

        self:runCsbAction("click")
        gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Wheel_Click.mp3")

        self:sendData()

        -- 开始滚动
        self:beginWheelAction()
    end
end

function FourInOneBonus_WheelView:isFS(wheelType)
    if wheelType == "Free" then
        return true
    end

    return false
end

function FourInOneBonus_WheelView:isSuperFree(wheelType)
    if wheelType == "SuperFree" then
        return true
    end

    return false
end

function FourInOneBonus_WheelView:CheckIsJackPot(wheelType)
    if wheelType == "Grand" then
        return true, 1
    elseif wheelType == "Major" then
        return true, 2
    elseif wheelType == "Minor" then
        return true, 3
    elseif wheelType == "Mini" then
        return true, 4
    end

    return false
end

--数据接收
function FourInOneBonus_WheelView:recvBaseData(featureData)
    local wheelIndex = self.m_spinDataResult.selfData.wheelIndex or 1

    local rewordType = self.m_spinDataResult.selfData.wheel

    local data = {}
    data.choose = wheelIndex
    data.endCallBack = function()
        print("滚完了   -- 开始滚完了的逻辑")

        local isJackpot, jackpotId = self:CheckIsJackPot(rewordType)

        if self:isFS(rewordType) then
            self.m_machine:featuresOverAddFreespinEffect()

            self:CloseUI()
        elseif self:isSuperFree(rewordType) then
            self.m_machine:featuresOverAddFreespinEffect()

            self:CloseUI()
        elseif isJackpot then
            local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
            local jackpotWinCoins = selfdata.jackpotWinCoins or self.m_WheelWinCoins

            self.m_machine:showJackpotView(
                jackpotId,
                jackpotWinCoins,
                function()
                    -- 更新游戏内每日任务进度条
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                    -- 通知bonus 结束， 以及赢钱多少
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_WheelWinCoins, GameEffect.EFFECT_BONUS})
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_WheelWinCoins, true, false})
                    self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_WheelWinCoins))

                    -- 同时触发的情况需要检测是否添加effect
                    self.m_machine:featuresOverAddFreespinEffect()

                    self:CloseUI(true)
                end
            )
        end
    end

    self:beginWheel(data)
end

--数据发送
function FourInOneBonus_WheelView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    local jpData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos, jackpot = jpData}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function FourInOneBonus_WheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_WheelWinCoins = spinData.result.bonus.bsWinCoins

        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result

            self.m_machine:SpinResultParseResultData(spinData)

            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function FourInOneBonus_WheelView:showReward()
end

function FourInOneBonus_WheelView:setOverCall(func)
    self.m_bonusEndCall = func
end

function FourInOneBonus_WheelView:CloseUI(isJpOver)
    if self.m_bonusEndCall then
        self.m_bonusEndCall(isJpOver)
    end
end

return FourInOneBonus_WheelView
