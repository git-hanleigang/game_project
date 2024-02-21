---
--xcyy
--WickedWinschoosePlayView.lua

local WickedWinsMusicConfig = require "WickedWinsPublicConfig"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local WickedWinschoosePlayView = class("WickedWinschoosePlayView",BaseGame)

WickedWinschoosePlayView.m_isClick = false
WickedWinschoosePlayView.m_selectIndex = 0

function WickedWinschoosePlayView:initUI()

    self:createCsbNode("WickedWins/FeatureChoice.csb")

    self.m_FGLeft = util_createAnimation("WickedWins_FGchoice.csb")
    self:findChild("Node_FG"):addChild(self.m_FGLeft)
    self.m_textFreeSpinCount = self.m_FGLeft:findChild("m_lb_num")

    self.m_FGRight = util_createAnimation("WickedWins_Respinchoice.csb")
    self:findChild("Node_Respin"):addChild(self.m_FGRight)

    self.m_FGSpine = util_spineCreate("Socre_WickedWins_Wild2",true,true)
    self.m_FGLeft:findChild("Node_spine"):addChild(self.m_FGSpine)

    self.m_RGSpine = util_spineCreate("Socre_WickedWins_Bonus",true,true)
    self.m_FGRight:findChild("Node_spine"):addChild(self.m_RGSpine)

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:addClick(self.m_FGLeft:findChild("click_left"))
    self:addClick(self.m_FGRight:findChild("click_right"))
end

function WickedWinschoosePlayView:onEnter()
    WickedWinschoosePlayView.super.onEnter(self)
end

function WickedWinschoosePlayView:onExit()
    WickedWinschoosePlayView.super.onExit(self)
end

function WickedWinschoosePlayView:initMachine(machine)
    self.m_machine = machine
end

function WickedWinschoosePlayView:refreshAni()
    self.m_FGLeft:runCsbAction("idle", true)
    self.m_FGRight:runCsbAction("idle", true)
    util_spinePlay(self.m_RGSpine,"idleframe3",true)
    util_spinePlay(self.m_FGSpine,"idle",true)
end

function WickedWinschoosePlayView:refreshData(_callFunc)
    self.callFunc = _callFunc
    self.m_isClick = true
end

--默认按钮监听回调
function WickedWinschoosePlayView:clickFunc(sender)
    local name = sender:getName()

    if name == "click_left" and self:isCanTouch() then
        self:choosePlayIndex(1)
    elseif name == "click_right" and self:isCanTouch() then
        self:choosePlayIndex(0)
    end
end

function WickedWinschoosePlayView:choosePlayIndex(_index)
    gLobalSoundManager:playSound(WickedWinsMusicConfig.Music_Click_Choose_Sure)
    self.m_selectIndex = _index
    self.m_isClick = false
    if _index == 1 then
        local particle = self.m_FGLeft:findChild("Particle_1")
        particle:resetSystem()
        self.m_FGLeft:runCsbAction("actionframe", false, function()
            particle:stopSystem()
        end)
        self.m_FGRight:runCsbAction("dark")
    else
        local particle = self.m_FGRight:findChild("Particle_1")
        particle:resetSystem()
        self.m_FGRight:runCsbAction("actionframe", false, function()
            particle:stopSystem()
        end)
        self.m_FGLeft:runCsbAction("dark")
    end
    self:sendData(self.m_selectIndex)
end

function WickedWinschoosePlayView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    local data = {["select"] = selectIndex}
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = data}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function WickedWinschoosePlayView:receiveData()
    self.m_machine:addPlayEffect()
    if self.callFunc then
        self.callFunc()
        self.callFunc = nil
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    self:hideSelf()
end

function WickedWinschoosePlayView:featureResultCallFun(param)
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

function WickedWinschoosePlayView:isCanTouch()
    return self.m_isClick
end

function WickedWinschoosePlayView:hideSelf()
    self:runCsbAction("over",false, function()
        self:setVisible(false)
    end)
end

return WickedWinschoosePlayView
