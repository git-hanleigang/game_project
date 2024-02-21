---
--xcyy
--BankCrazeChooseRewardView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeChooseRewardView = class("BankCrazeChooseRewardView",BaseGame)

BankCrazeChooseRewardView.m_isClick = false
BankCrazeChooseRewardView.m_selectIndex = 0

function BankCrazeChooseRewardView:initUI(_machine)

    self:createCsbNode("BankCraze/LixiTanban.csb")

    self.m_machine = _machine
    
    self.m_chooseLog = require("CodeBankCrazeBonusSrc.BankCrazeChooseRewardLog"):create()

    self.m_baseCoinText = self:findChild("m_lb_coin_base")
    self.m_coinMinText = self:findChild("m_lb_coin_min")
    self.m_coinMaxText = self:findChild("m_lb_coin_max")

    local spineNameTbl = {
        {"Socre_BankCraze_8", "BankCraze_tanban_baoxiangui2", "BankCraze_tanban_qiandai2"},
        {"Socre_BankCraze_9", "BankCraze_tanban_baoxiangui1", "BankCraze_tanban_qiandai1"},
    }
    self.m_spineActNameTbl = {"choose_idle", "idle_small", "idle_small"}
    self.m_spineClickActNameTbl = {"choose_choose", "actionframe_small", "actionframe_small"}
    self.m_rewardSpineTbl = {}
    -- 不同银行显示不同类型；直接先加上；控制显隐
    -- 类型依次为1：more；2；银、3：金（从下往上）
    for i=1, 2 do
        local tempTbl = {}
        for index, spineName in pairs(spineNameTbl[i]) do
            tempTbl[index] = util_spineCreate(spineName,true,true)
            self:findChild("Node_spine"..index):addChild(tempTbl[index])
            util_spinePlay(tempTbl[index], self.m_spineActNameTbl[index], true)
        end
        table.insert(self.m_rewardSpineTbl, tempTbl)
    end

    -- 选择光效
    -- 类型依次为1：more；2；银、3：金（从下往上）
    self.m_chooseAniTbl = {}
    -- dark光效
    self.m_darkAniTbl = {}
    for i=1, 3 do
        self.m_chooseAniTbl[i] = util_createAnimation("BankCraze_LixiTanban_choose.csb")
        self:findChild("Node_dark"..i):addChild(self.m_chooseAniTbl[i])
        self.m_chooseAniTbl[i]:setVisible(false)

        self.m_darkAniTbl[i] = util_createAnimation("BankCraze_LixiTanban_dark.csb")
        self:findChild("Node_dark"..i):addChild(self.m_darkAniTbl[i])
        self.m_darkAniTbl[i]:setVisible(false)
    end

    for i=1, 3 do
        self:addClick(self:findChild("Panel_click_"..i))
    end

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BankCrazeChooseRewardView:onEnter()
    BankCrazeChooseRewardView.super.onEnter(self)
end

function BankCrazeChooseRewardView:onExit()
    BankCrazeChooseRewardView.super.onExit(self)
end

function BankCrazeChooseRewardView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function BankCrazeChooseRewardView:setBonusBankLevel(_curBankLevel)
    self.m_curBankLevel = _curBankLevel
end

function BankCrazeChooseRewardView:resetData(_bankData)
    local bankData = _bankData
    self.m_baseCoins = bankData.baseCoins
    self.m_maxCoins = bankData.maxCoins
    self.m_minCoins = bankData.minCoins
    self:setBonusBankLevel(bankData.curBankLevel)
    self:setRewardCoins()
    self:findChild("Node_silver"):setVisible(self.m_curBankLevel == 2)
    self:findChild("Node_gold"):setVisible(self.m_curBankLevel == 3)
    for i=1, #self.m_rewardSpineTbl do
        local tempTbl = self.m_rewardSpineTbl[i]
        if i == self.m_curBankLevel-1 then
            for k, v in pairs(tempTbl) do
                v:setVisible(true)
                util_spinePlay(v, self.m_spineActNameTbl[k], true)
            end
        else
            for k, v in pairs(tempTbl) do
                v:setVisible(false)
            end
        end
    end

    for i=1, 3 do
        self.m_chooseAniTbl[i]:setVisible(false)
        self.m_darkAniTbl[i]:setVisible(false)
    end

    self.m_isClickBonus = false
    self.m_isClose = false
end

function BankCrazeChooseRewardView:showRewardChoose(_bankData, _callFunc, _isClickBonus)
    self:resetData(_bankData)
    self.m_isClickBonus = _isClickBonus
    self.m_callFunc = _callFunc
    self.m_isClick = false
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChooseDialog_Open)
    self:runCsbAction("start",false, function()
        self:runCsbAction("idle",true)
        self.m_isClick = true
    end)
end

--默认按钮监听回调
function BankCrazeChooseRewardView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if (name == "Panel_click_1" or name == "Button_close") and self:isCanTouch() then
        if name == "Button_close" then
            self.m_isClose = true
        end
        self:choosePlayIndex(0)
    elseif name == "Panel_click_2" and self:isCanTouch() then
        self:choosePlayIndex(1)
    elseif name == "Panel_click_3" and self:isCanTouch() then
        self:choosePlayIndex(2)
    -- elseif name == "Button_close" and self:isCanTouch() then
    --     self:hideSelf()
    end
end

function BankCrazeChooseRewardView:choosePlayIndex(_selectIndex)
    self.m_isClick = false
    self.m_selectIndex = _selectIndex
    local clickIndex = _selectIndex + 1
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChooseDialog_Choose)

    local curSpine = self.m_rewardSpineTbl[self.m_curBankLevel-1][clickIndex]
    if curSpine then
        util_spinePlay(curSpine, self.m_spineClickActNameTbl[clickIndex], false)
        util_spineEndCallFunc(curSpine, self.m_spineClickActNameTbl[clickIndex], function()
            util_spinePlay(curSpine, self.m_spineActNameTbl[clickIndex], false)
            self:sendData(self.m_selectIndex)
        end)
    end
    -- 其余压暗
    for i=1, 3 do
        if clickIndex ~= i then
            self.m_darkAniTbl[i]:setVisible(true)
            self.m_darkAniTbl[i]:runCsbAction("actionframe", false, function()
                self.m_darkAniTbl[i]:runCsbAction("idle", false)
            end)
        end
    end
    -- 选择点亮
    self.m_chooseAniTbl[clickIndex]:setVisible(true)
    self.m_chooseAniTbl[clickIndex]:runCsbAction("actionframe", false, function()
        self.m_chooseAniTbl[clickIndex]:setVisible(false)
    end)
end

function BankCrazeChooseRewardView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    -- local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = selectIndex}
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = selectIndex}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function BankCrazeChooseRewardView:receiveData()
    -- 选择类型
    local chooseType
    if self.m_isClose then
        chooseType = "Close"
    else
        chooseType = 3 - self.m_selectIndex
    end
    -- 弹板打开方式（自动和主动）
    local entryOpen = "PushOpen"
    if self.m_isClickBonus then
        entryOpen = "TapOpen"
    end

    local gameName = self.m_machine.m_moduleName
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = self.m_machine.m_moduleName .. "_H"
    end
    self.m_chooseLog:sendChooseRewardLog(chooseType, entryOpen, gameName)
    local endCallFunc = function()
        self:hideSelf()
    end

    local parmsTbl = {
        callFunc = self.m_callFunc,
        hideCallFunc = endCallFunc,
        isGold = self.m_curBankLevel == 3,
        baseCoins = self.m_baseCoins,
    }

    if self.m_selectIndex == 0 then
        self.m_machine:showBonusMoreView(parmsTbl)
    else
        self.m_machine:resetBonusPlay()
        self.m_machine:addPlayEffect()
        -- 宝箱
        if self.m_selectIndex == 1 then
            self.m_machine:showBonusBoxWinView(parmsTbl)
        -- 袋子
        elseif self.m_selectIndex == 2 then
            self.m_machine:showBonusBagWinView(parmsTbl)
        end
    end
end

function BankCrazeChooseRewardView:featureResultCallFun(param)
    if self:isVisible() and param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "SPECIAL" then
            self.m_runSpinResultData = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_featureData:parseFeatureData(spinData.result)
            self:receiveData()
            -- self:recvBaseData(isSuperFreeGame)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            -- self:recvBaseData()
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

function BankCrazeChooseRewardView:setRewardCoins()
    local baseCoinsStr = tostring(toLongNumber(self.m_baseCoins))
    local baseCoins = util_formatCoinsLN(baseCoinsStr,50)
    self.m_baseCoinText:setString(baseCoins)

    local minCoinsStr = tostring(toLongNumber(self.m_minCoins))
    local minCoins = util_formatCoinsLN(minCoinsStr,50)
    self.m_coinMinText:setString(minCoins)

    local maxCoinsStr = tostring(toLongNumber(self.m_maxCoins))
    local maxCoins = util_formatCoinsLN(maxCoinsStr,50)
    self.m_coinMaxText:setString(maxCoins)
    
    self:updateLabelSize({label=self.m_baseCoinText,sx=0.35,sy=0.35},826)
    self:updateLabelSize({label=self.m_coinMinText,sx=0.23,sy=0.23},826)
    self:updateLabelSize({label=self.m_coinMaxText,sx=0.23,sy=0.23},826)
end

function BankCrazeChooseRewardView:isCanTouch()
    return self.m_isClick
end

-- 是否为最高级
function BankCrazeChooseRewardView:getLastBankLevelIsHeight()
    return self.m_curBankLevel==3
end

function BankCrazeChooseRewardView:hideSelf(_isRunFunc)
    local isRunFunc = _isRunFunc
    self:runCsbAction("over", false, function()
        self:setVisible(false)
        if isRunFunc and type(self.m_callFunc) == "function" then
            self.m_callFunc()
            self.m_callFunc = nil
        end
        self.m_machine.m_bonusBtnView:setCilckState(true)
    end)
end

return BankCrazeChooseRewardView
