---
--xcyy
--2018年5月23日
--PussChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PussChooseView = class("PussChooseView", BaseGame)

PussChooseView.m_ClickIndex = 1
PussChooseView.m_spinDataResult = {}

function PussChooseView:initUI(machine)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("Puss/GameChoose.csb", isAutoScale)

    self.m_machine = machine

    self:updateLable()

    self.m_Click = false

    self.m_isStart_Over_Action = true

    self:runCsbAction(
        "start",
        false,
        function()
            self:addClick(self:findChild("freespinClick"))
            self:addClick(self:findChild("respinClick"))

            self.m_isStart_Over_Action = false

            self:runCsbAction("idle", true)
        end
    )
end

function PussChooseView:updateLable()
    if not self.m_machine then
        return
    end

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local freespinTimes = selfdata.freespinTimes

    local fsNum = self:findChild("BitmapFontLabel_3")

    if fsNum then
        fsNum:setString(freespinTimes)
    end
end

function PussChooseView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function PussChooseView:checkAllBtnClickStates()
    local notClick = false

    if self.m_action == self.ACTION_SEND then
        notClick = true
    end

    if self.m_Click then
        notClick = true
    end

    if self.m_isStart_Over_Action then
        notClick = true
    end

    return notClick
end

--默认按钮监听回调
function PussChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    gLobalSoundManager:playSound("PussSounds/music_Puss_ChooseView_Click.mp3")

    self.m_Click = true

    if name == "freespinClick" then
        self.m_ClickIndex = 2
        local clickActName = "select" .. (3 - self.m_ClickIndex)
        self:runCsbAction(
            clickActName,
            false,
            function()
                self:runCsbAction("selectidle" .. (3 - self.m_ClickIndex), true)
                self:sendData(1)
            end
        )
    elseif name == "respinClick" then
        self.m_ClickIndex = 1
        local clickActName = "select" .. (3 - self.m_ClickIndex)
        self:runCsbAction(
            clickActName,
            false,
            function()
                self:runCsbAction("selectidle" .. (3 - self.m_ClickIndex), true)
                self:sendData(0)
            end
        )
    end
end

--数据接收
function PussChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true

    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("PussSounds/music_Puss_ChooseView_Over.mp3")

            self:closeUi(
                function()
                    self:showReward()
                end
            )
        end,
        0.5
    )
end

--数据发送
function PussChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function PussChooseView:featureResultCallFun(param)
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
function PussChooseView:showReward()
    if self.m_bonusEndCall then
        self.m_bonusEndCall(self.m_ClickIndex)
    end
end

function PussChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

function PussChooseView:closeUi(func)
    self:runCsbAction(
        "over" .. (3 - self.m_ClickIndex),
        false,
        function()
            if func then
                func()
            end
        end
    )
end

return PussChooseView
