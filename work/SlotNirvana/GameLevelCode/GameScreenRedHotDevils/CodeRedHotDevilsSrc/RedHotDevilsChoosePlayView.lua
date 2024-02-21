---
--xcyy
--RedHotDevilsChoosePlayView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "RedHotDevilsPublicConfig"
local RedHotDevilsChoosePlayView = class("RedHotDevilsChoosePlayView",BaseGame)

RedHotDevilsChoosePlayView.m_isClick = false
RedHotDevilsChoosePlayView.m_selectIndex = 0

function RedHotDevilsChoosePlayView:initUI()

    self:createCsbNode("RedHotDevils/Choose.csb")

    self.m_leftSpine = util_spineCreate("Socre_RedHotDevils_7",true,true)
    self:findChild("spine_1"):addChild(self.m_leftSpine)
    self.m_leftSpine:setSkin("cai")

    self.m_middleSpine = util_spineCreate("Socre_RedHotDevils_8",true,true)
    self:findChild("spine_2"):addChild(self.m_middleSpine)
    self.m_middleSpine:setSkin("cai")

    self.m_rightSpine = util_spineCreate("Socre_RedHotDevils_9",true,true)
    self:findChild("spine_3"):addChild(self.m_rightSpine)
    self.m_rightSpine:setSkin("cai")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:addClick(self:findChild("click_left"))
    self:addClick(self:findChild("click_middle"))
    self:addClick(self:findChild("click_right"))
end

function RedHotDevilsChoosePlayView:onEnter()
    RedHotDevilsChoosePlayView.super.onEnter(self)
end

function RedHotDevilsChoosePlayView:onExit()
    RedHotDevilsChoosePlayView.super.onExit(self)
end

function RedHotDevilsChoosePlayView:initMachine(machine)
    self.m_machine = machine
end

function RedHotDevilsChoosePlayView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function RedHotDevilsChoosePlayView:playSpineIdle()
    util_spinePlay(self.m_leftSpine,"idleframe4",true)
    util_spinePlay(self.m_middleSpine,"idleframe4",true)
    util_spinePlay(self.m_rightSpine,"idleframe4",true)
end

function RedHotDevilsChoosePlayView:refreshData(_callFunc)
    self.callFunc = _callFunc
    self.m_isClick = true
end

--默认按钮监听回调
function RedHotDevilsChoosePlayView:clickFunc(sender)
    local name = sender:getName()

    if name == "click_left" and self:isCanTouch() then
        self:choosePlayIndex(0)
    elseif name == "click_middle" and self:isCanTouch() then
        self:choosePlayIndex(1)
    elseif name == "click_right" and self:isCanTouch() then
        self:choosePlayIndex(2)
    end
end

function RedHotDevilsChoosePlayView:choosePlayIndex(_index)
    self.m_isClick = false
    local randomNum = math.random(1, 2)
    local soundName = "RedHotDevilsSounds/RedHotDevils_freeGame_choose_"..randomNum..".mp3"
    gLobalSoundManager:playSound(soundName)
    self:playRoleSpine(_index)
    self.m_selectIndex = _index
    local particleName = "Particle_".._index+1
    local particle = self:findChild(particleName)
    particle:resetSystem()
    local actionFrameName = "actionframe" .. self.m_selectIndex+1
    self:runCsbAction(actionFrameName, false, function()
        particle:stopSystem()
    end)
    --选择播放完成后
    performWithDelay(self.m_scWaitNode, function()
        self:sendData(self.m_selectIndex)
    end, 60/30)
end

function RedHotDevilsChoosePlayView:playRoleSpine(_index)
    if _index == 0 then
        util_spinePlay(self.m_leftSpine,"actionframe4",false)
        util_spinePlay(self.m_middleSpine,"idleframe5",false)
        util_spinePlay(self.m_rightSpine,"idleframe5",false)
    elseif _index == 1 then
        util_spinePlay(self.m_leftSpine,"idleframe5",false)
        util_spinePlay(self.m_middleSpine,"actionframe4",false)
        util_spinePlay(self.m_rightSpine,"idleframe5",false)
    elseif _index == 2 then
        util_spinePlay(self.m_leftSpine,"idleframe5",false)
        util_spinePlay(self.m_middleSpine,"idleframe5",false)
        util_spinePlay(self.m_rightSpine,"actionframe4",false)
    end
end

function RedHotDevilsChoosePlayView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = selectIndex}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function RedHotDevilsChoosePlayView:receiveData()
    self.m_machine:addPlayEffect()
    if self.callFunc then
        self.callFunc()
        self.callFunc = nil
    end
    self:hideSelf()
end

function RedHotDevilsChoosePlayView:featureResultCallFun(param)
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

function RedHotDevilsChoosePlayView:isCanTouch()
    return self.m_isClick
end

function RedHotDevilsChoosePlayView:hideSelf()
    local overName = "over" .. self.m_selectIndex+1
    gLobalSoundManager:playSound(PublicConfig.Music_FreeGame_ChooseOver)
    self:runCsbAction(overName,false, function()
        self:setVisible(false)
    end)
end

return RedHotDevilsChoosePlayView
