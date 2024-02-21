---
--xcyy
--SpacePupChoosePlayView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "SpacePupPublicConfig"
local SpacePupChoosePlayView = class("SpacePupChoosePlayView",BaseGame)

SpacePupChoosePlayView.m_isClick = false
SpacePupChoosePlayView.m_selectIndex = 0

function SpacePupChoosePlayView:initUI()

    self:createCsbNode("SpacePup/Choose.csb")

    self.m_FGLeft = util_createAnimation("SpacePup_chooseFreespin.csb")
    self:findChild("Node_free"):addChild(self.m_FGLeft)

    self.m_RespinRight = util_createAnimation("SpacePup_chooseRespin.csb")
    self:findChild("Node_respin"):addChild(self.m_RespinRight)

    self.m_FGLeftSpine = util_spineCreate("Socre_SpacePup_Wild",true,true)
    self.m_FGLeft:findChild("spine"):addChild(self.m_FGLeftSpine)
    util_spinePlay(self.m_FGLeftSpine,"idleframe_tanban",true)

    self.m_RespinRightSpine = util_spineCreate("Socre_SpacePup_Bonus",true,true)
    self.m_RespinRight:findChild("spine"):addChild(self.m_RespinRightSpine)
    util_spinePlay(self.m_RespinRightSpine,"idleframe_tanban",true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:addClick(self:findChild("click_left"))
    self:addClick(self:findChild("click_right"))
end

function SpacePupChoosePlayView:onEnter()
    SpacePupChoosePlayView.super.onEnter(self)
end

function SpacePupChoosePlayView:onExit()
    SpacePupChoosePlayView.super.onExit(self)
end

function SpacePupChoosePlayView:initMachine(machine)
    self.m_machine = machine
end

function SpacePupChoosePlayView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function SpacePupChoosePlayView:refreshView()
    self.m_FGLeft:runCsbAction("start",false)
    self.m_RespinRight:runCsbAction("start",false)
    util_spinePlay(self.m_FGLeftSpine,"idleframe_tanban",true)
    util_spinePlay(self.m_RespinRightSpine,"idleframe_tanban",true)
end

function SpacePupChoosePlayView:refreshData(_callFunc)
    self.callFunc = _callFunc
    self.m_isClick = true
end

--默认按钮监听回调
function SpacePupChoosePlayView:clickFunc(sender)
    local name = sender:getName()

    if name == "click_left" and self:isCanTouch() then
        self:choosePlayIndex(0)
    elseif name == "click_right" and self:isCanTouch() then
        self:choosePlayIndex(1)
    end
end

function SpacePupChoosePlayView:choosePlayIndex(_index)
    self.m_isClick = false
    self.m_selectIndex = _index

    --选择播放完成后
    if _index == 0 then
        gLobalSoundManager:playSound(PublicConfig.Music_Choose_Free)
        self.m_FGLeft:runCsbAction("actionframe", false, function()
            self.m_FGLeft:runCsbAction("idleframe", true)
        end)
        util_spinePlay(self.m_FGLeftSpine,"actionframe_tanban",false)
        util_spineEndCallFunc(self.m_FGLeftSpine, "actionframe_tanban", function()
            self:sendData(self.m_selectIndex)
        end)

        self.m_RespinRight:runCsbAction("yaan", false)
        util_spinePlay(self.m_RespinRightSpine,"dark2",false)
    else
        gLobalSoundManager:playSound(PublicConfig.Music_Choose_Respin)
        self.m_RespinRight:runCsbAction("actionframe", false, function()
            self.m_RespinRight:runCsbAction("idleframe", true)
        end)
        util_spinePlay(self.m_RespinRightSpine,"actionframe2",false)
        util_spineEndCallFunc(self.m_RespinRightSpine, "actionframe2", function()
            self:sendData(self.m_selectIndex)
        end)

        self.m_FGLeft:runCsbAction("yaan", false)
        util_spinePlay(self.m_FGLeftSpine,"yaan_tanban",false)
    end
end

function SpacePupChoosePlayView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = selectIndex}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function SpacePupChoosePlayView:receiveData()
    self.m_machine:addPlayEffect()
    if self.callFunc then
        self.callFunc()
        self.callFunc = nil
    end
    self:hideSelf()
end

function SpacePupChoosePlayView:featureResultCallFun(param)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if self:isVisible() and param[1] == true and selfData and selfData.bonusType and selfData.bonusType == "select" then
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

function SpacePupChoosePlayView:isCanTouch()
    return self.m_isClick
end

function SpacePupChoosePlayView:hideSelf()
    gLobalSoundManager:playSound(PublicConfig.Music_Choose_startOver)
    self:runCsbAction("over",false, function()
        self:setVisible(false)
    end)
end

return SpacePupChoosePlayView
