---
--xcyy
--2018年5月23日
--ZeusChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local ZeusChooseView = class("ZeusChooseView", BaseGame)

ZeusChooseView.m_ClickIndex = 1
ZeusChooseView.m_spinDataResult = {}

function ZeusChooseView:initUI(machine)
    self:createCsbNode("Zeus/ChooseCoin_0.csb")

    self.m_machine = machine

    self.m_Click = false

    self.m_isStart_Over_Action = true

    self:runCsbAction(
        "start",
        false,
        function()
            self:addClick(self:findChild("Button_lion1"))
            self:addClick(self:findChild("Button_lion0"))

            self.m_isStart_Over_Action = false

            self:runCsbAction("idle", true)
        end
    )
end

function ZeusChooseView:updateLable()
    if not self.m_machine then
        return
    end

    local freespindata = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local freespinTimes = self.m_machine.m_runSpinResultData.p_freeSpinsLeftCount or 0

    local fsNum_r = self:findChild("m_lb_num_r")
    if fsNum_r then
        fsNum_r:setString(freespinTimes)
    end

    local fsNum_l = self:findChild("m_lb_num_l")
    if fsNum_l then
        fsNum_l:setString(freespinTimes)
    end

    local wildTimes = freespindata.wilds or 0

    local wildNum_r = self:findChild("WildNum_r")
    if wildNum_r then
        wildNum_r:setString(wildTimes)
    end

    local wildNum_l = self:findChild("WildNum_l")
    if wildNum_l then
        wildNum_l:setString(wildTimes)
    end
end

-- function ZeusChooseView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function ZeusChooseView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function ZeusChooseView:checkAllBtnClickStates()
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
function ZeusChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_ChooseView_Click.mp3")

    self.m_Click = true

    if name == "Button_lion1" then
        self.m_ClickIndex = 1

        self:sendData(1)
    elseif name == "Button_lion0" then
        self.m_ClickIndex = 2

        self:sendData(0)
    end
end

--数据接收
function ZeusChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true

    local clickActName = "xuanzhong" .. self.m_ClickIndex

    local isFree = false
    local feature = self.m_machine.m_runSpinResultData.p_features
    local chooseId = 2
    if feature and feature[2] and feature[2] == 1 then
        isFree = true
        chooseId = 1
    end
    self:changeShowUi(isFree)

    gLobalSoundManager:playSound("ZeusSounds/music_Zeus_ChooseView_showCilck.mp3")

    self:runCsbAction(
        clickActName,
        false,
        function()
            self:closeUi(
                function()
                    self:showReward(chooseId)
                end
            )
        end
    )
end

--数据发送
function ZeusChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function ZeusChooseView:featureResultCallFun(param)
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
function ZeusChooseView:showReward(chooseId)
    if self.m_bonusEndCall then
        self.m_bonusEndCall(chooseId)
    end
end

function ZeusChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

function ZeusChooseView:closeUi(func)
    self:runCsbAction(
        "over" .. self.m_ClickIndex,
        false,
        function()
            if func then
                func()
            end
        end
    )
end

function ZeusChooseView:changeShowUi(isFree)
    self:findChild("xuanze_l_freespin"):setVisible(false)
    self:findChild("xuanze_r_freespin"):setVisible(false)
    self:findChild("xuanze_l_link"):setVisible(false)
    self:findChild("xuanze_r_link"):setVisible(false)

    if isFree then
        self:updateLable()

        self:findChild("xuanze_l_freespin"):setVisible(true)
        self:findChild("xuanze_r_freespin"):setVisible(true)

        if self.m_ClickIndex == 1 then
            self:findChild("xuanze_r_freespin"):setVisible(false)
        else
            self:findChild("xuanze_l_freespin"):setVisible(false)
        end
    else
        self:findChild("xuanze_l_link"):setVisible(true)
        self:findChild("xuanze_r_link"):setVisible(true)

        if self.m_ClickIndex == 1 then
            self:findChild("xuanze_r_link"):setVisible(false)
        else
            self:findChild("xuanze_l_link"):setVisible(false)
        end
    end
end

return ZeusChooseView
