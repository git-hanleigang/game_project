---
--xcyy
--PudgyPandaChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaChooseView = class("PudgyPandaChooseView",BaseGame)

PudgyPandaChooseView.m_isClick = false
PudgyPandaChooseView.m_selectIndex = 0

function PudgyPandaChooseView:initUI(_machine)

    self:createCsbNode("PudgyPanda/FeatureChoice.csb")

    self.m_machine = _machine

    self.m_caidaiSpine = util_spineCreate("PudgyPanda_caidai",true,true)
    self:findChild("Node_caidai"):addChild(self.m_caidaiSpine)
    util_spinePlay(self.m_caidaiSpine, "ide", true)

    self.m_clickCaidaiSpine = util_spineCreate("PudgyPanda_caidai",true,true)
    self:findChild("Node_caidai"):addChild(self.m_clickCaidaiSpine, 2)
    self.m_clickCaidaiSpine:setVisible(false)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:addClick(self:findChild("click_play"))
    self:addClick(self:findChild("click_cancel"))
end

function PudgyPandaChooseView:onEnter()
    PudgyPandaChooseView.super.onEnter(self)
end

function PudgyPandaChooseView:onExit()
    PudgyPandaChooseView.super.onExit(self)
end

function PudgyPandaChooseView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function PudgyPandaChooseView:showFeatureChoose(_selectIndex, _callFunc)
    self.m_isClick = false
    self.m_selectIndex = _selectIndex
    self.callFunc = _callFunc
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectPlay_Start)
    self:runCsbAction("start",false, function()
        self:runCsbAction("idle",true)
        self.m_isClick = true
    end)
end

--默认按钮监听回调
function PudgyPandaChooseView:clickFunc(sender)
    local name = sender:getName()

    if name == "click_play" and self:isCanTouch() then
        self:choosePlayIndex()
    elseif name == "click_cancel" and self:isCanTouch() then
       self:playCancel()
    end
end

-- 取消
function PudgyPandaChooseView:playCancel()
    self.m_isClick = false
    self.m_clickCaidaiSpine:setVisible(true)
    util_spinePlay(self.m_clickCaidaiSpine, "actionframe_cancel", false)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    self.m_machine.m_collectView:setCurProcess(selfData.collect_num, true)
    
    self:selectAndCloseSound()
    self:runCsbAction("actionframe_cancel",false, function()
        -- self:runCsbAction("idle",true)
        self:hideSelf()
    end)
end

-- 弹板选中关闭音效
function PudgyPandaChooseView:selectAndCloseSound()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectPlay_Select)
    performWithDelay(self.m_scWaitNode, function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectPlay_Over)
    end, 110/60)
end

function PudgyPandaChooseView:choosePlayIndex()
    self.m_isClick = false
    self.m_clickCaidaiSpine:setVisible(true)
    util_spinePlay(self.m_clickCaidaiSpine, "actionframe_play", false)
    self:selectAndCloseSound()
    self:runCsbAction("actionframe_play",false, function()
        -- self:runCsbAction("idle",true)
        self:sendData(self.m_selectIndex)
    end)
end

function PudgyPandaChooseView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    -- local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = selectIndex}
    local messageData={msg=MessageDataType.MSG_BONUS_SPECIAL, choose = selectIndex}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function PudgyPandaChooseView:receiveData()
    self.m_machine:addPlayEffect()
    self:hideSelf()
end

function PudgyPandaChooseView:featureResultCallFun(param)
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

function PudgyPandaChooseView:isCanTouch()
    return self.m_isClick
end

function PudgyPandaChooseView:hideSelf()
    if self.callFunc then
        self.callFunc()
        self.callFunc = nil
    end
    self:setVisible(false)
end

return PudgyPandaChooseView
