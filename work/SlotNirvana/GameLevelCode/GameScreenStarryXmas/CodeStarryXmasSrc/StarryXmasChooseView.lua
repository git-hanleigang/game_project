---
--xcyy
--2018年5月23日
--StarryXmasChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "StarryXmasPublicConfig"
local StarryXmasChooseView = class("StarryXmasChooseView", BaseGame)

StarryXmasChooseView.m_spinDataResult = {}
StarryXmasChooseView.m_clickNode = {}
StarryXmasChooseView.m_caidaiNode = {}

function StarryXmasChooseView:initUI(machine)

    self:createCsbNode("StarryXmas/GameChose.csb")
    self.m_chooseViewNode = util_spineCreate("StarryXmas_xztb", true, true)
    self:findChild("Node_spine"):addChild(self.m_chooseViewNode)
    -- self.m_chooseViewNode:setPosition(display.width * 0.5, display.height * 0.5)

    self.m_machine = machine
    -- 3个可点击的部分
    for i=1,3 do
        self.m_clickNode[i] = util_createAnimation("Socre_StarryXmas_GameChose.csb")
        --把不需要的隐藏
        for j=1,3 do
            self.m_clickNode[i]:findChild("pick_"..j):setVisible(false)
        end
        self.m_clickNode[i]:findChild("pick_"..i):setVisible(true)
        local m_offsetX = (i-2)*30
        self.m_clickNode[i]:setPositionX(m_offsetX)

        -- 点击之后的动效
        self.m_caidaiNode[i] = util_spineCreate("StarryXmas_caidai", true, true)
        self.m_clickNode[i]:findChild("Node_caidai"):addChild(self.m_caidaiNode[i])
        self.m_caidaiNode[i]:setVisible(false)

        self:addClick(self.m_clickNode[i]:findChild("Panel_" .. i))
    end 
    util_spinePushBindNode(self.m_chooseViewNode,"lfte",self.m_clickNode[2])
    util_spinePushBindNode(self.m_chooseViewNode,"zj",self.m_clickNode[1])
    util_spinePushBindNode(self.m_chooseViewNode,"right",self.m_clickNode[3])

    self.m_Click = false

    gLobalSoundManager:playSound(PublicConfig.Music_Choose_FreeStart)
    self.m_isStart_Over_Action = true
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
    end)

    util_spinePlay(self.m_chooseViewNode,"start")
    util_spineEndCallFunc(self.m_chooseViewNode,"start",function()
        self.m_isStart_Over_Action = false

        util_spinePlay(self.m_chooseViewNode,"idle",true)
        for i=1,3 do
            self.m_clickNode[i]:runCsbAction("idle",true)
        end
    end)
end

function StarryXmasChooseView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function StarryXmasChooseView:checkAllBtnClickStates()
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
function StarryXmasChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    self.m_Click = true

    if name == "Panel_1" then
        self:clickEffect(1,function()
            self:sendData(0)
        end)
    elseif name == "Panel_2" then
        self:clickEffect(2,function()
            self:sendData(1)
        end)
    elseif name == "Panel_3" then
        self:clickEffect(3,function()
            self:sendData(2)
        end)
    end
end

--[[
    点击之后的动效
]]
function StarryXmasChooseView:clickEffect(_index, _func)
    gLobalSoundManager:playSound(PublicConfig.Music_Choose_FreeFeedBack)
    self.m_caidaiNode[_index]:setVisible(true)
    util_spinePlay(self.m_caidaiNode[_index],"actionframe")
    util_spineEndCallFunc(self.m_caidaiNode[_index],"actionframe",function()
        self.m_caidaiNode[_index]:setVisible(false)
        if _func then
            _func()
        end
    end)

    self.m_clickNode[_index]:runCsbAction("actionframe",false)

    -- 未选择的压暗
    for i=1,3 do
        if i ~= _index then
            self.m_clickNode[i]:runCsbAction("yaan",false) 
        end
    end
end

--数据接收
function StarryXmasChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true

    self:closeUi(
        function()
            self:showReward()
        end
    )
end

--数据发送
function StarryXmasChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function StarryXmasChooseView:featureResultCallFun(param)
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
function StarryXmasChooseView:showReward()
    if self.m_bonusEndCall then
        self.m_bonusEndCall()
    end
end

function StarryXmasChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

function StarryXmasChooseView:closeUi(func)
    self:runCsbAction("over",false)
    gLobalSoundManager:playSound(PublicConfig.Music_Choose_FreeOver)
    util_spinePlay(self.m_chooseViewNode,"over")
    self.m_machine:waitWithDelay(21/30,function(  )
        if func then
            func()
        end
    end)
end

return StarryXmasChooseView
