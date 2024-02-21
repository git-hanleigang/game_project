---
--xcyy
--2018年5月23日
--ReelRocksChooseView.lua 选择界面

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local ReelRocksChooseView = class("ReelRocksChooseView", BaseGame)

ReelRocksChooseView.m_ClickIndex = 1
ReelRocksChooseView.m_spinDataResult = {}

function ReelRocksChooseView:initUI(machine)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("ReelRocks/ReelRocks_featurepick.csb", isAutoScale)

    self.m_machine = machine

    self.m_Click = false

    self.m_isStart_Over_Action = true

    performWithDelay(
        self,
        function()
            -- gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_ChooseShow.mp3")
        end,
        0.3
    )
end

function ReelRocksChooseView:showStartAct()
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_isStart_Over_Action = false

            self:runCsbAction("idle", true)
        end
    )
end

function ReelRocksChooseView:onEnter()
    self.super.onEnter(self)
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         self:featureResultCallFun(params)
    --     end,
    --     ViewEventType.NOTIFY_GET_SPINRESULT
    -- )
end

function ReelRocksChooseView:setFreeNum(num)
end

function ReelRocksChooseView:onExit()
    self.super.onExit(self)
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function ReelRocksChooseView:checkAllBtnClickStates()
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
function ReelRocksChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end
    self.m_Click = true
    -- self:findChild("Particle_5"):stopSystem()
    -- gLobalSoundManager:playSound("AliceRubySounds/AliceRuby_ChooseClickd.mp3")

    if name == "Button_1" then
        self.m_ClickIndex = 1
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_chooseGame_click.mp3")
        self:runCsbAction(
            "over1",
            false,
            function()
                self:sendData(1)
            end
        )
    elseif name == "Button_2" then
        self.m_ClickIndex = 2
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_chooseGame_click.mp3")
        self:runCsbAction(
            "over2",
            false,
            function()
                self:sendData(0)
            end
        )
    end
end

function ReelRocksChooseView:getChooseIndex()
    return self.m_ClickIndex
end

--数据接收
function ReelRocksChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true

    self:closeUi(
        function()
            self:showReward()
        end
    )
end

--数据发送
function ReelRocksChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil
    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function ReelRocksChooseView:featureResultCallFun(param)
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
            self:recvBaseData(self.m_featureData)
        else
            dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function ReelRocksChooseView:showReward()
    if self.m_bonusEndCall then
        self.m_bonusEndCall()
    end
end

function ReelRocksChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

function ReelRocksChooseView:closeUi(func)
    -- self:runCsbAction("over",false,function(  )
    --     if func then
    --         func()
    --     end
    -- end)
    if func then
        func()
    end
end

return ReelRocksChooseView
