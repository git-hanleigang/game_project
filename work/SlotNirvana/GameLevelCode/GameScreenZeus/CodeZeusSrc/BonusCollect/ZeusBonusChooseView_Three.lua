---
--xcyy
--2018年5月23日
--ZeusBonusChooseView_Three.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local ZeusBonusChooseView_Three = class("ZeusBonusChooseView_Three", BaseGame)

function ZeusBonusChooseView_Three:initUI(machine)
    self:createCsbNode("BonusView/Zeus_BonusRdle_3.csb")

    self.m_machine = machine

    self.m_Click = true

    self:runCsbAction(
        "start",
        false,
        function()
            self.m_Click = false
            self:addClick(self:findChild("click1"))
            self:addClick(self:findChild("click2"))
            self:addClick(self:findChild("click3"))

            self:runCsbAction("idle", true)
        end
    )
end

-- function ZeusBonusChooseView_Three:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function ZeusBonusChooseView_Three:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function ZeusBonusChooseView_Three:setEndCallFunc(func)
    self.m_callFunc = func
end

function ZeusBonusChooseView_Three:updateLable(chooseIndex)
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}

    local multiply = selfdata.multiply
    local otherMultiplies = selfdata.otherMultiplies

    local otherIndex = 1
    for i = 1, 3 do
        local m_lb_bet = self:findChild("m_lb_bet_" .. i)

        if i == chooseIndex then
            if multiply and m_lb_bet then
                m_lb_bet:setString("x" .. multiply)
            end
        else
            if otherMultiplies and otherMultiplies[otherIndex] and m_lb_bet then
                m_lb_bet:setString("x" .. otherMultiplies[otherIndex])
            end

            otherIndex = otherIndex + 1
        end
    end
end

--默认按钮监听回调
function ZeusBonusChooseView_Three:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_Click then
        return
    end

    self.m_Click = true

    if name == "click1" then
        self.m_ClickIndex = 1
        self:sendData(1)
    elseif name == "click2" then
        self.m_ClickIndex = 2
        self:sendData(3)
    elseif name == "click3" then
        self.m_ClickIndex = 3
        self:sendData(3)
    end
end

--数据接收
function ZeusBonusChooseView_Three:recvBaseData(featureData)
    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_FanZhuang.mp3")

    if self.m_ClickIndex == 1 then
        self:updateLable(1)

        self:runCsbAction(
            "turn1",
            false,
            function()
                self:closeUi()
            end
        )
    elseif self.m_ClickIndex == 2 then
        self:updateLable(2)

        self:runCsbAction(
            "turn2",
            false,
            function()
                self:closeUi()
            end
        )
    elseif self.m_ClickIndex == 3 then
        self:updateLable(3)

        self:runCsbAction(
            "turn3",
            false,
            function()
                self:closeUi()
            end
        )
    end
end

--数据发送
function ZeusBonusChooseView_Three:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function ZeusBonusChooseView_Three:featureResultCallFun(param)
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

function ZeusBonusChooseView_Three:closeUi()
    performWithDelay(
        self,
        function()
            self:runCsbAction("show" .. self.m_ClickIndex)

            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_Collect_Bonus_OverView.mp3")

                    self:runCsbAction(
                        "over" .. self.m_ClickIndex,
                        false,
                        function()
                            -- 更新游戏内每日任务进度条
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, true, false})
                            -- 通知bonus 结束， 以及赢钱多少
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_serverWinCoins, GameEffect.EFFECT_BONUS})

                            if self.m_callFunc then
                                self.m_callFunc()
                            end
                        end
                    )
                end,
                1
            )
        end,
        1.5
    )
end

--弹出结算奖励
function ZeusBonusChooseView_Three:showReward(chooseId)
end

return ZeusBonusChooseView_Three
