---
--xcyy
--2018年5月23日
--FrogPrinceBonusView.lua

local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local FrogPrinceBonusView = class("BonusGame", BaseGame)
FrogPrinceBonusView.multiple = {
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    12,
    15,
    20,
    30,
    50,
    60,
    70,
    80,
    90,
    100,
    125,
    150,
    200,
    300,
    500,
    750,
    1000
} --奖励倍数
FrogPrinceBonusView.boxVec = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}
--玩家每一轮选择箱子的个数
FrogPrinceBonusView.pickNums = {7, 6, 5, 4, 2, 1}

FrogPrinceBonusView.Bonus_Stage_Type = {
    Start_Type = 1,
    Choose_Type = 2,
    Last_Choose_Type = 3,
    Over_Type = 4
}

function FrogPrinceBonusView:initUI()
    self:createCsbNode("FrogPrince/GameScreenFrogPrince_BonusGame1.csb")
    self:InitBonusUI()
    self.m_OpenFlag = false
end

-- function FrogPrinceBonusView:onEnter()
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:featureResultCallFun(params)
--         end,
--         ViewEventType.NOTIFY_GET_SPINRESULT
--     )
-- end

function FrogPrinceBonusView:initMachine(machine)
    self.m_machine = machine
end

function FrogPrinceBonusView:getNeedOpenBoxNum(_index)
    return self.pickNums[_index]
end

function FrogPrinceBonusView:initReconnectView(spinData, machine)
    self.m_machine = machine
    local leftPiggy = spinData.p_selfMakeData.bonusPickData.leftPiggy
    local leftMultiples = spinData.p_selfMakeData.bonusPickData.leftMultiples
    local function isOpenMultiples(_multiple)
        for i = 1, #leftMultiples do
            if _multiple == leftMultiples[i] then
                return false
            end
        end
        return true
    end

    for i = 1, #self.m_multipleLab do
        local lab = self.m_multipleLab[i]
        lab:runCsbAction("idle4")
        local multiple = self.multiple[i]
        if isOpenMultiples(multiple) == false then
            lab:runCsbAction("idle2")
        end
    end

    if self:getCurStage() == 1 or self:getCurStage() == 2 then
        self:showBonusPlayView()
        self.m_BonusPlayView:InitUIData(spinData)
        self.m_BonusPlayView:setVisible(false)
        self:showBonusChooseView()
    elseif self:getCurStage() == 4 then
        self:showBonusOverView()
    end
end

function FrogPrinceBonusView:changeMultipleLabToBonus()
    for i = 1, #self.m_multipleLab do
        local lab = self.m_multipleLab[i]
        lab:runCsbAction("idle2")
    end
end

--第几轮
function FrogPrinceBonusView:getChooseRound()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            return selfData.bonusPickData.count + 1
        end
    end
    return 1
end

--第几轮
function FrogPrinceBonusView:getBonusPrize()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            return selfData.bonusPickData.collectCoins
        end
    end
    return 1
end
function FrogPrinceBonusView:getChooseCount()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            return selfData.bonusPickData.pickNums[1]
        end
    end
    return 1
end

--要删掉的倍数
function FrogPrinceBonusView:getDisMultiples(_index)
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local disMultiples = selfData.bonusPickData.disMultiples
            if disMultiples then
                return disMultiples[_index]
            end
        end
    end
end

--要删掉的box
function FrogPrinceBonusView:getDisPiggy(_index)
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local disPiggy = selfData.bonusPickData.disPiggy
            if disPiggy then
                return disPiggy[_index]
            end
        end
    end
end

--当前阶段
function FrogPrinceBonusView:getCurStage()
    if self.m_machine ~= nil then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData then
            local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
            local curStage = selfData.bonusPickData.curStage
            if curStage then
                return curStage
            end
        end
    end
end

function FrogPrinceBonusView:getMultipleIndex(_Multiple)
    for i = 1, #self.multiple do
        if _Multiple == self.multiple[i] then
            return i
        end
    end
    return 1
end

function FrogPrinceBonusView:showMultipleOver(_multiple)
    local index = self:getMultipleIndex(_multiple)
    local lab = self.m_multipleLab[index]
    lab:runCsbAction("change")
    performWithDelay(
        self,
        function()
        end,
        0.5
    )
end

function FrogPrinceBonusView:InitBonusUI()
    self.m_multipleLab = {}
    for i = 1, #self.multiple do
        local node = self:findChild("Node_" .. i)
        local data = {}
        data._num = self.multiple[i]
        local lab = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusLab", data)
        lab:setScale(0.6)
        lab:runCsbAction("idle3")
        local pos = cc.p(node:getPosition())
        if i <= 13 then
            self:findChild("Node_28"):addChild(lab)
        else
            self:findChild("Node_29"):addChild(lab)
        end
        lab:setTag(i)
        lab:setPosition(pos)
        table.insert(self.m_multipleLab, lab)
    end
end

function FrogPrinceBonusView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

--显示打开到第几个了
function FrogPrinceBonusView:showBoxView(_num)
    local isOpen = false
    if self.m_BoxView then
        self.m_BoxView:setVisible(true)
        isOpen = true
    else
        self.m_BoxView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBoxView")
        self.m_BoxView:setParent(self)
        self:findChild("BonusGame"):addChild(self.m_BoxView)
    end
    if self.m_OpenFlag == true then
        self:runCsbAction("start2")
        self.m_BoxView:runCsbAction("start2")
        self.m_BoxView:setCollectBox(_num, self.m_OpenFlag)
    else
        self:runCsbAction("start")
        self.m_BoxView:showOpenBoxNum(_num)
        self.m_BoxView:runCsbAction(
            "start",
            false,
            function()
                self.m_BoxView:setCollectBox(_num, self.m_OpenFlag)
            end
        )
    end
end

function FrogPrinceBonusView:setOpenBonusFlag(_flag)
    self.m_OpenFlag = _flag
end

function FrogPrinceBonusView:hideBoxView()
    if self.m_machine:isTriggerBonusGame() then
        self.m_func()
    else
        self:runCsbAction(
            "over",
            false,
            function()
                self.m_func()
            end
        )
    end
end

function FrogPrinceBonusView:showStartView()
    if self.m_BoxView ~= nil then
        self.m_BoxView:removeFromParent()
        self.m_BoxView = nil
    end
    self.m_BoxStartView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusStartView")
    self.m_BoxStartView:setParent(self)
    self:findChild("BonusGame"):addChild(self.m_BoxStartView)
    self:changeMultipleLabToBonus()
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_tip_0_open.mp3")
end

function FrogPrinceBonusView:setFunCall(_func)
    self.m_func = _func
end

--bonus 玩法界面
function FrogPrinceBonusView:showBonusPlayView()
    if self.m_BonusPlayView ~= nil then
        self.m_BonusPlayView:setVisible(true)
    else
        local data = {}
        data.prize = self:getBonusPrize()
        self.m_BonusPlayView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusPlayView", data)
        self.m_BonusPlayView:setParent(self)
        self:findChild("BonusGame"):addChild(self.m_BonusPlayView)
    end
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_tip_0_open.mp3")
end

--bonus 结束
function FrogPrinceBonusView:ClickBonusGameOver()
    self.m_machine:BonusGameOver()
end

function FrogPrinceBonusView:ChangePlayAndChooseView(_bshow)
    if _bshow == true then
        if self:getCurStage() == 2 then
            self:hideBonusPlayView(false)
            self:showBonusLastView()
        else
            self:showRoundView()
            self:showBonusPlayView()
            self.m_BonusPlayView:showBonusWinLab()
            local num = self:getChooseCount()
            self.m_BonusPlayView:playChooseNun(num)
            self.m_BoxChooseView:setVisible(false)
        end
    else
        self.m_BonusPlayView:setVisible(false)
        self:showBonusChooseView()
    end
end

function FrogPrinceBonusView:hideBonusPlayView(_bshow)
    if self.m_BonusPlayView then
        self.m_BonusPlayView:setVisible(_bshow)
    end
end

function FrogPrinceBonusView:sendChooseMessage()
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = nil
    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = {}}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

function FrogPrinceBonusView:showRoundView(func)
    local round = self:getChooseRound()
    local num = self:getChooseCount()
    local data = {}
    data.round = round
    data.num = num
    self:showBonusRoundView(data, func)
end

--round 下一轮过渡界面
function FrogPrinceBonusView:showBonusRoundView(data, func)
    self.m_BonusRoundView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusRoundView", data)
    self.m_BonusRoundView:setParent(self)
    self:findChild("BonusGame"):addChild(self.m_BonusRoundView, 100)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_tip_0_open.mp3")
    self.m_BonusRoundView:runCsbAction(
        "start",
        false,
        function()
            self.m_BonusRoundView:runCsbAction(
                "idle",
                false,
                function()
                    self.m_BonusRoundView:runCsbAction(
                        "over",
                        false,
                        function()
                            self.m_BonusRoundView:removeFromParent()
                            self.m_BonusRoundView = nil
                            if func ~= nil then
                                func()
                            end
                        end
                    )
                end
            )
        end
    )
end

--选择是否继续
function FrogPrinceBonusView:showBonusChooseView()
    if self.m_BoxChooseView ~= nil then
        self.m_BoxChooseView:setVisible(true)
        local base = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.collectCoins
        local offers = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.offers
        local multiple = offers[#offers]
        self.m_BoxChooseView:showCollectWinLab(multiple, base)
        self.m_BoxChooseView:playStartAni()
    else
        self.m_BoxChooseView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusChooseView")
        local base = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.collectCoins
        local offers = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.offers
        local multiple = offers[#offers]
        self.m_BoxChooseView:showCollectWinLab(multiple, base)
        self.m_BoxChooseView:setParent(self)
        self:findChild("BonusGame"):addChild(self.m_BoxChooseView)
    end
    self.m_BoxChooseView:inintUIData()
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_tip_0_open.mp3")
end

--获取位置对应的字母
function FrogPrinceBonusView:getValueByPos(pos)
    return self.boxVec[pos]
end

function FrogPrinceBonusView:showBonusLastView()
    local pos1 = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.yourPiggy
    local pos2 = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.leftPiggy[1]
    self:showBonusLastChooseView(pos1, pos2)
end

--最后一次 二选一
function FrogPrinceBonusView:showBonusLastChooseView(_pos1, _pos2)
    local data = {}
    data.bestOffer = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.bestOffer
    local myPos = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.yourPiggy
    self.m_BoxLastChooseView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusLastChooseView", data)
    local pos = cc.p(self:findChild("BonusGame"):getPosition())
    self.m_BoxLastChooseView:setParent(self)
    local data1 = {}
    data1._pos = _pos1
    local value1 = self:getValueByPos(_pos1)
    data1._value = value1
    local data2 = {}
    data2._pos = _pos2
    local value2 = self:getValueByPos(_pos2)
    data2._value = value2
    self.m_BoxLastChooseView:createBox(data1, data2, myPos)
    self:findChild("BonusGame"):addChild(self.m_BoxLastChooseView)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_tip_0_open.mp3")
end

--over
function FrogPrinceBonusView:showBonusOverView()
    if self.m_BoxChooseView ~= nil then
        self.m_BoxChooseView:setVisible(false)
    end
    if self.m_BoxLastChooseView ~= nil then
        self.m_BoxLastChooseView:setVisible(false)
    end
    self.m_BonusOverView = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusOverView")
    local base = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.collectCoins
    local offers = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.offers
    local winNum = self.m_machine.m_runSpinResultData.p_winAmount
    local multiple = offers[#offers]
    self.m_BonusOverView:showCollectWinLab(multiple, base, winNum)
    self.m_BonusOverView:setParent(self)
    self:findChild("BonusGame"):addChild(self.m_BonusOverView)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_tip_0_open.mp3")
end

--数据发送
function FrogPrinceBonusView:sendData(pos)
    self.m_action = self.ACTION_SEND
    self.m_isBonusCollect = true
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil
    if self.m_isBonusCollect then
        messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, true)
end

function FrogPrinceBonusView:featureResultCallFun(param)
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

function FrogPrinceBonusView:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action = self.ACTION_RECV
    if featureData.p_status == "START" then
        self:startGameCallFunc()
        return
    end
    self.m_featureData = featureData
    -- performWithDelay(self,function()
    -- end,1.3)

    if featureData.p_status == "CLOSED" then
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED, {self.m_bsWinCoins, GameEffect.EFFECT_BONUS})
        self:showBonusOverView()
    else
        if self:getCurStage() == 1 or self:getCurStage() == 2 then
            self.m_BonusPlayView:playOpenBoxOneRound()
        elseif self:getCurStage() == 3 then
            local offers = self.m_machine.m_runSpinResultData.p_selfMakeData.bonusPickData.offers
            local num = offers[#offers]
            self.m_BoxLastChooseView:openBox(num)
        elseif self:getCurStage() == 4 then
            self:showBonusOverView()
        end
    end
end

function FrogPrinceBonusView:setClickFlag(_bflag)
    if self.m_BoxView then
        self.m_BoxView:setClickFlag(_bflag)
    end
end

--默认按钮监听回调
function FrogPrinceBonusView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

return FrogPrinceBonusView
