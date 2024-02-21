---
--xcyy
--BadgedCowboyChoosePlayView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "BadgedCowboyPublicConfig"
local BadgedCowboyChoosePlayView = class("BadgedCowboyChoosePlayView",BaseGame)

BadgedCowboyChoosePlayView.m_isClick = false
BadgedCowboyChoosePlayView.m_selectIndex = 0

function BadgedCowboyChoosePlayView:initUI()

    self:createCsbNode("BadgedCowboy/FeatureChoose.csb")

    self.m_FGLeft = util_createAnimation("BadgedCowboy_free.csb")
    self:findChild("Node_free"):addChild(self.m_FGLeft)

    self.m_RespinRight = util_createAnimation("BadgedCowboy_respin.csb")
    self:findChild("Node_respin"):addChild(self.m_RespinRight)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:addClick(self.m_FGLeft:findChild("click_left"))
    self:addClick(self.m_RespinRight:findChild("click_right"))
end

function BadgedCowboyChoosePlayView:onEnter()
    BadgedCowboyChoosePlayView.super.onEnter(self)
end

function BadgedCowboyChoosePlayView:onExit()
    BadgedCowboyChoosePlayView.super.onExit(self)
end

function BadgedCowboyChoosePlayView:initMachine(machine)
    self.m_machine = machine
end

function BadgedCowboyChoosePlayView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function BadgedCowboyChoosePlayView:refreshView()
    self.m_FGLeft:runCsbAction("idle",true)
    self.m_RespinRight:runCsbAction("idle",true)
end

function BadgedCowboyChoosePlayView:refreshData(_callFunc)
    self.callFunc = _callFunc
    self.m_isClick = true
end

--默认按钮监听回调
function BadgedCowboyChoosePlayView:clickFunc(sender)
    local name = sender:getName()

    if name == "click_left" and self:isCanTouch() then
        self:choosePlayIndex(0)
    elseif name == "click_right" and self:isCanTouch() then
        self:choosePlayIndex(1)
    end
end

function BadgedCowboyChoosePlayView:choosePlayIndex(_index)
    self.m_isClick = false
    self.m_selectIndex = _index

    --选择播放完成后
    if _index == 0 then
        gLobalSoundManager:playSound(PublicConfig.Music_Choose_Free)
        self.m_FGLeft:runCsbAction("actionframe", false, function()
            self.m_FGLeft:runCsbAction("idle1", true)
            self:sendData(self.m_selectIndex)
        end)

        self.m_RespinRight:runCsbAction("dark", false, function()
            self.m_RespinRight:runCsbAction("idle2", true)
        end)
    else
        gLobalSoundManager:playSound(PublicConfig.Music_Choose_Respin)
        self.m_RespinRight:runCsbAction("actionframe", false, function()
            self.m_RespinRight:runCsbAction("idle1", true)
            self:sendData(self.m_selectIndex)
        end)

        self.m_FGLeft:runCsbAction("dark", false, function()
            self.m_FGLeft:runCsbAction("idle2", true)
        end)
    end
end

function BadgedCowboyChoosePlayView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = selectIndex}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function BadgedCowboyChoosePlayView:receiveData()
    self.m_machine:addPlayEffect()
    self:hideSelf()
end

function BadgedCowboyChoosePlayView:featureResultCallFun(param)
    if self:isVisible() and param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
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

function BadgedCowboyChoosePlayView:isCanTouch()
    return self.m_isClick
end

function BadgedCowboyChoosePlayView:hideSelf()
    gLobalSoundManager:playSound(PublicConfig.Music_Choose_startOver)
    self:runCsbAction("over",false, function()
        if self.callFunc then
            self.callFunc()
            self.callFunc = nil
        end
        self:setVisible(false)
    end)
end

return BadgedCowboyChoosePlayView
