---
--xcyy
--2018年5月23日
--OZBonus_WheelView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")

local OZBonus_WheelView = class("OZBonus_WheelView", util_require("base.BaseGame"))
OZBonus_WheelView.m_wheelSumIndex = 16

OZBonus_WheelView.m_isShowAct = false

OZBonus_WheelView.SYMBOL_JackPot_Major = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9 -- 102
OZBonus_WheelView.SYMBOL_JackPot_Minor = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 -- 103
OZBonus_WheelView.SYMBOL_JackPot_Mini = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 -- 104
OZBonus_WheelView.m_littleUI = {}
function OZBonus_WheelView:initUI(data)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("OZ_wheel.csb", isAutoScale)

    self.m_wheel =
        require("CodeOZSrc.Wheel.OZBonus_WheelAction"):create(
        self:findChild("zhuan"),
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

    -- self:findChild("Particle_1"):stopSystem()

    self.m_wheelData = data.wheelData
    self.m_machine = data.machine
    self.m_wheelBg = data.wheelBg
    self:initWheelLittleNode()
    self:addClick(self:findChild("click"))
    self:findChild("click"):setVisible(false)
    self:runCsbAction(
        "open",
        false,
        function()
            self:runCsbAction("idle", true)
            self:findChild("click"):setVisible(true)
        end
    )
end

function OZBonus_WheelView:showLittleIdle()
    for i = 1, #self.m_littleSaoGuangUI do
        local littleNode = self.m_littleSaoGuangUI[i]
        if littleNode then
            littleNode:runCsbAction("idle")
        end
    end
end

function OZBonus_WheelView:getCsbId(str)
    if str == "lucky" then
        return 1
    elseif str == "Major" then
        return 2
    elseif str == "Minor" then
        return 3
    elseif str == "Mini" then
        return 4
    else
        return 5, tonumber(str)
    end
end

function OZBonus_WheelView:initWheelLittleNode()
    self.m_littleUI = {}
    self.m_littleSaoGuangUI = {}

    for i = 1, self.m_wheelSumIndex do
        local data = self.m_wheelData[i]

        local node = self:findChild("text" .. i)
        local csbid, betnum = self:getCsbId(data)
        local LittleNodeData = {}

        LittleNodeData.csbid = csbid
        LittleNodeData.posIndex = i

        local wheelLittleNode = util_createView("CodeOZSrc.Wheel.OZBonus_LittleNode", LittleNodeData)

        if node then
            node:addChild(wheelLittleNode)
        end
        if betnum then
            local lb = wheelLittleNode:findChild("BitmapFontLabel_1")
            if lb then
                lb:setString(util_formatCoins(betnum, 6))
                wheelLittleNode:updateLabelSize({label = lb, sx = 1, sy = 1}, 231)
            end
        end

        table.insert(self.m_littleUI, wheelLittleNode)

        ------------------------ 扫光

        local saoGuangCsb = {
            "OZ_wheel_lucky_SaoGuang",
            "OZ_wheel_Jp_SaoGuang",
            "OZ_wheel_Jp_SaoGuang",
            "OZ_wheel_Jp_SaoGuang",
            "OZ_wheel_text_SoGuang"
        }
        local saoGuangPath = saoGuangCsb[csbid]

        local wheelSaoGuangNode = util_createView("CodeOZSrc.Wheel.OZBonus_LSaoGuangNode", saoGuangPath)
        self:findChild("zhuan"):addChild(wheelSaoGuangNode)
        wheelSaoGuangNode:setPosition(cc.p(node:getPosition()))
        wheelSaoGuangNode:runCsbAction("idle")
        local listRotation = {0, 22.50, 45.00, 67.50, 90.00, 112.50, 135.00, 157.50, 180.00, -157.50, -135.00, -112.50, -90.00, -67.50, -45.00, -22.50}
        wheelSaoGuangNode:setRotation(listRotation[i])

        table.insert(self.m_littleSaoGuangUI, wheelSaoGuangNode)
    end
end

-- function OZBonus_WheelView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function OZBonus_WheelView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function OZBonus_WheelView:beginWheel(data)
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

function OZBonus_WheelView:beginWheelAction()
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

function OZBonus_WheelView:setWheelRotModel()
    self.m_wheel:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

function OZBonus_WheelView:setRotionAction(distance, targetStep, isBack)
    self.distance_now = (distance / targetStep) + 0.5

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_Wheel_run.mp3")
    end
end

--默认按钮监听回调
function OZBonus_WheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self:findChild("click"):setVisible(false)

        self:runCsbAction("actionframe")
        self:sendData()

        -- 开始滚动
        self:beginWheelAction()
    end
end

function OZBonus_WheelView:islucky(wheelType)
    if wheelType == "lucky" then
        return true
    end

    return false
end

function OZBonus_WheelView:isJackPot(wheelType)
    if wheelType == "Major" then
        return true, self.SYMBOL_JackPot_Major
    elseif wheelType == "Minor" then
        return true, self.SYMBOL_JackPot_Minor
    elseif wheelType == "Mini" then
        return true, self.SYMBOL_JackPot_Mini
    end

    return false
end

--数据接收
function OZBonus_WheelView:recvBaseData(featureData)
    local wheelIndex = self.m_spinDataResult.selfData.wheelIndex or 1

    local rewordType = self.m_wheelData[wheelIndex + 1]

    local data = {}
    data.choose = wheelIndex
    data.endCallBack = function()
        print("滚完了   -- 开始滚完了的逻辑")

        gLobalSoundManager:playSound("OZSounds/music_OZ_Wheel_winEnd.mp3")

        self.m_littleSaoGuangUI[wheelIndex + 1]:runCsbAction("winstart")

        if self:islucky(rewordType) then
            performWithDelay(
                self,
                function()
                    self.m_wheelBg.m_WheelJPView:runCsbAction("over")
                    self:runCsbAction(
                        "over",
                        false,
                        function()
                            self.m_wheelBg:wheelWinLucy()
                        end
                    )
                end,
                3
            )
        elseif self:isJackPot(rewordType) then
            performWithDelay(
                self,
                function()
                    local time = 1
                    local endNode = self.m_wheelBg:getNetShowDiamond(rewordType)
                    local csbName = self.m_wheelBg:getDiamondCsbName(rewordType)
                    local startNode = self:findChild("Node_fly")

                    gLobalSoundManager:playSound("OZSounds/music_OZ_baoshi_shouji.mp3")

                    local flyNode =
                        self.m_wheelBg:runFlyWildActJumpTo(
                        startNode,
                        endNode,
                        csbName,
                        function()
                            gLobalSoundManager:playSound("OZSounds/music_OZ_baoshi_za_ban.mp3")

                            endNode:setVisible(true)
                            endNode:runCsbAction("shouji")

                            self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_WheelWinCoins))

                            performWithDelay(
                                self,
                                function()
                                    self.m_wheelBg:wheelWinJackPot(
                                        rewordType,
                                        self.m_WheelWinCoins,
                                        function()
                                            self.m_machine.m_wheelOver = true

                                            -- 更新游戏内每日任务进度条
                                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                                            -- 通知bonus 结束， 以及赢钱多少
                                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_WheelWinCoins, GameEffect.EFFECT_BONUS})
                                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_WheelWinCoins, true, false})
                                            self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_WheelWinCoins))
                                        end
                                    )
                                end,
                                1
                            )
                        end,
                        time,
                        0.49848
                    )

                    local shoujilizi = "OZ_shoujilizi_tuowei_L.csb"
                    if rewordType == "Major" then
                        shoujilizi = "OZ_shoujilizi_tuowei_L_R.csb"
                    elseif rewordType == "Minor" then
                        shoujilizi = "OZ_shoujilizi_tuowei_L_P.csb"
                    elseif rewordType == "Mini" then
                        shoujilizi = "OZ_shoujilizi_tuowei_L_B.csb"
                    end

                    local Particle = util_createAnimation(shoujilizi)
                    flyNode:addChild(Particle, -1)
                    Particle:findChild("Particle_1"):setPositionType(0)
                    Particle:findChild("Particle_1"):setDuration(time)
                end,
                1.5
            )
        else
            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("OZSounds/music_OZ_Wheel_Collect_Coins.mp3")

                    local time = 0.8
                    local startNode = self:findChild("Node_fly")
                    local endNode = self.m_machine.m_bottomUI:findChild("win_guang_0")
                    local csbName = "OZ_shoujilizi_tuowei_M"
                    local flyNode =
                        self.m_wheelBg:runFlyWildAct(
                        startNode,
                        endNode,
                        csbName,
                        function()
                            self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_WheelWinCoins))

                            gLobalSoundManager:playSound("OZSounds/music_OZ_Wheel_Dispear.mp3")

                            self.m_wheelBg.m_WheelJPView:runCsbAction("over")

                            self:runCsbAction(
                                "over",
                                false,
                                function()
                                    self.m_wheelBg:wheelWinCoins()
                                end
                            )
                        end,
                        time
                    )
                    flyNode:findChild("Particle_1"):setPositionType(0)
                    flyNode:findChild("Particle_1"):setDuration(time)
                end,
                1.5
            )
        end
    end

    self:beginWheel(data)
end

--数据发送
function OZBonus_WheelView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    local jpData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos, jackpot = jpData}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function OZBonus_WheelView:featureResultCallFun(param)
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
function OZBonus_WheelView:showReward()
    if self.m_bonusEndCall then
        self.m_bonusEndCall()
    end
end

function OZBonus_WheelView:setEndCall(func)
    self.m_bonusEndCall = func
end

return OZBonus_WheelView
