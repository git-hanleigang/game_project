---
--xcyy
--2018年5月23日
--BeerGirlBonus_WheelView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")

local BeerGirlBonus_WheelView = class("BeerGirlBonus_WheelView", util_require("base.BaseGame"))
BeerGirlBonus_WheelView.m_wheelSumIndex = 16

BeerGirlBonus_WheelView.m_isShowAct = false

BeerGirlBonus_WheelView.SYMBOL_JackPot_Grand = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 -- 101
BeerGirlBonus_WheelView.SYMBOL_JackPot_Major = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9 -- 102
BeerGirlBonus_WheelView.SYMBOL_JackPot_Minor = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 -- 103
BeerGirlBonus_WheelView.SYMBOL_JackPot_Mini = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 -- 104

function BeerGirlBonus_WheelView:initUI(data)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("BeerGirl_Wheel.csb", isAutoScale)

    self.m_wheel =
        require("CodeBeerGirlSrc.wheel.BeerGirlBonus_WheelAction"):create(
        self:findChild("wheel"),
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

    performWithDelay(
        self,
        function()
            self:runCsbAction(
                "show",
                false,
                function()
                    self:runCsbAction("idle", true)
                    self:addClick(self:findChild("click"))
                end
            )

            performWithDelay(
                self,
                function()
                    self:findChild("Particle_1"):resetSystem()
                end,
                0.33
            )
        end,
        1
    )

    self.m_wheelData = data.wheelData
    self.m_machine = data.machine

    self:initWheelLittleNode()
end

function BeerGirlBonus_WheelView:isHightWheel()
    for i = 1, self.m_wheelSumIndex do
        local data = self.m_wheelData[i]

        if data == "free" then
            return true
        end
    end

    return false
end

function BeerGirlBonus_WheelView:getCsbId(str)
    if str == "Grand" then
        return 1
    elseif str == "Major" then
        return 2
    elseif str == "Minor" then
        return 3
    elseif str == "Mini" then
        return 4
    elseif str == "free" then
        return 7
    else
        if self:isHightWheel() then
            return 5, str
        else
            return 6, str
        end
    end
end

function BeerGirlBonus_WheelView:isBluePos(pos)
    local posList = {2, 4, 6, 8, 10, 12, 14, 16}

    for i = 1, #posList do
        local index = posList[i]
        if index == pos then
            return true
        end
    end

    return false
end

function BeerGirlBonus_WheelView:isPurple(pos)
    local posList = {3, 7, 11, 15}

    for i = 1, #posList do
        local index = posList[i]
        if index == pos then
            return true
        end
    end

    return false
end

function BeerGirlBonus_WheelView:initWheelLittleNode()
    for i = 1, self.m_wheelSumIndex do
        local data = self.m_wheelData[i]

        local node = self:findChild("num_" .. i)
        local csbid, betnum = self:getCsbId(data)
        local LittleNodeData = {}

        if betnum then
            if self:isBluePos(i) then
                csbid = 6
            end

            if self:isPurple(i) then
                csbid = 5
            end
        end

        LittleNodeData.csbid = csbid
        LittleNodeData.posIndex = i

        local wheelLittleNode = util_createView("CodeBeerGirlSrc.wheel.BeerGirlBonus_LittleNode", LittleNodeData)
        if node then
            node:addChild(wheelLittleNode)
        end
        if betnum then
            local lb = wheelLittleNode:findChild("BitmapFontLabel_1")
            if lb then
                lb:setString(betnum)
            end
        end
    end
end

-- function BeerGirlBonus_WheelView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function BeerGirlBonus_WheelView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function BeerGirlBonus_WheelView:beginWheel(data)
    self.m_endIndex = (data.choose + 1)

    self.m_callFunc = function()
        if data.endCallBack then
            data.endCallBack()
        end
    end

    self.m_wheel:updateEndCallFunc(self.m_callFunc)

    -- 接受到消息后开始停止
    self.m_wheel:recvData(self.m_endIndex)
end

function BeerGirlBonus_WheelView:beginWheelAction()
    local wheelData = {}
    wheelData.m_startA = 600 --加速度
    wheelData.m_runV = 600
    --匀速
    wheelData.m_runTime = 0 --匀速时间
    wheelData.m_slowA = 450 --动态减速度
    wheelData.m_slowQ = 0 --减速圈数
    wheelData.m_stopV = 150 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel(false)
end

function BeerGirlBonus_WheelView:setWheelRotModel()
    self.m_wheel:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

function BeerGirlBonus_WheelView:setRotionAction(distance, targetStep, isBack)
    self.distance_now = (distance / targetStep) + 0.5

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_Wheel_run.mp3")
    end
end

--默认按钮监听回调
function BeerGirlBonus_WheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self:findChild("click"):setVisible(false)

        self:runCsbAction(
            "start",
            false,
            function()
                self:runCsbAction("turn", true)
            end
        )

        gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_Wheel_Click.mp3")

        self:sendData()

        -- 开始滚动
        self:beginWheelAction()
    end
end

function BeerGirlBonus_WheelView:function_name()
end

function BeerGirlBonus_WheelView:isFree(wheelType)
    if wheelType == "free" then
        return true
    end

    return false
end

function BeerGirlBonus_WheelView:isJackPot(wheelType)
    if wheelType == "Grand" then
        return true, self.SYMBOL_JackPot_Grand
    elseif wheelType == "Major" then
        return true, self.SYMBOL_JackPot_Major
    elseif wheelType == "Minor" then
        return true, self.SYMBOL_JackPot_Minor
    elseif wheelType == "Mini" then
        return true, self.SYMBOL_JackPot_Mini
    end

    return false
end

--数据接收
function BeerGirlBonus_WheelView:recvBaseData(featureData)
    local wheelIndex = self.m_spinDataResult.selfData.wheelIndex or 1

    local rewordType = self.m_wheelData[wheelIndex + 1]

    local data = {}
    data.choose = wheelIndex
    data.endCallBack = function()
        print("滚完了   -- 开始滚完了的逻辑")

        gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_Wheel_Win.mp3")

        self:runCsbAction("zhongjiang", true)

        performWithDelay(
            self,
            function()
                if self:isFree(rewordType) then
                    -- 中freespin
                    self:showReward()
                elseif self:isJackPot(rewordType) then
                    -- 中jackpot

                    local isjp, symbolType = self:isJackPot(rewordType)
                    self.m_machine:showJackPotWinView(
                        self.m_serverWinCoins,
                        symbolType,
                        function()
                            -- 更新游戏内每日任务进度条
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

                            -- 通知bonus 结束， 以及赢钱多少
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_serverWinCoins, GameEffect.EFFECT_BONUS})
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, true, false})
                            self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_serverWinCoins))

                            performWithDelay(
                                self,
                                function()
                                    self:showReward()
                                end,
                                1
                            )
                        end
                    )
                else
                    -- 中钱
                    self.m_machine:showWheelOverView(
                        self.m_serverWinCoins,
                        function()
                            -- 更新游戏内每日任务进度条
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

                            -- 通知bonus 结束， 以及赢钱多少
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_serverWinCoins, GameEffect.EFFECT_BONUS})
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, true, false})
                            self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_serverWinCoins))

                            performWithDelay(
                                self,
                                function()
                                    self:showReward()
                                end,
                                1
                            )
                        end
                    )
                end
            end,
            3
        )
    end

    self:beginWheel(data)
end

--数据发送
function BeerGirlBonus_WheelView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    local jpData = nil
    if self.m_machine then
        jpData = self.m_machine:getWheelJackpotList()
        if type(jpData) == "table" and #jpData == 0 then
            jpData = nil
        end
    end

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos, jackpot = jpData}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function BeerGirlBonus_WheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
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
            self:recvBaseData(self.m_featureData)
        else
            dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function BeerGirlBonus_WheelView:showReward()
    if self.m_bonusEndCall then
        self.m_bonusEndCall()
    end
end

function BeerGirlBonus_WheelView:setEndCall(func)
    self.m_bonusEndCall = func
end

return BeerGirlBonus_WheelView
