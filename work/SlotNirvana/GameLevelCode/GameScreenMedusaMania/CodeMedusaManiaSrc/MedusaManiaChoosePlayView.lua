---
--xcyy
--MedusaManiaChoosePlayView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "MedusaManiaPublicConfig"
local MedusaManiaChoosePlayView = class("MedusaManiaChoosePlayView",BaseGame)

MedusaManiaChoosePlayView.m_isClick = false
MedusaManiaChoosePlayView.m_selectIndex = 0

function MedusaManiaChoosePlayView:initUI(machine)

    self:createCsbNode("MedusaMania/FreeSpinchoose.csb")

    self.m_machine = machine

    self:initData()

    self.m_tblClickPanel = {}
    self.m_tblChooseSpine = {}
    self.m_rootChooseNode = {}
    for i=1, self.m_totalCount do
        local chooseNode = util_createAnimation("MedusaMania_Freechoose.csb")
        self.m_tblClickPanel[i] = chooseNode:findChild("click_Panel")
        self.m_tblChooseSpine[i] = util_spineCreate("MedusaMania_Freechoose",true,true)
        self.m_rootChooseNode[i] = self:findChild("choose_"..i)
        chooseNode:findChild("Node_bg"):addChild(self.m_tblChooseSpine[i])
        self.m_rootChooseNode[i]:addChild(chooseNode)

        if i == 1 then
            self.m_tblChooseSpine[i]:setSkin("twelve")
        elseif i == 2 then
            self.m_tblChooseSpine[i]:setSkin("six")
        elseif i == 3 then
            self.m_tblChooseSpine[i]:setSkin("four")
        end
    end
    

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    util_setCascadeOpacityEnabledRescursion(self, true)

    for i=1, self.m_totalCount do
        self.m_tblClickPanel[i]:setTag(i)
        self:addClick(self.m_tblClickPanel[i])
    end
end

function MedusaManiaChoosePlayView:initData()
    self.m_totalCount = 3
    self.m_initChoosePos = {cc.p(-400, -19), cc.p(0, -19), cc.p(400, -19)}
end

function MedusaManiaChoosePlayView:onEnter()
    MedusaManiaChoosePlayView.super.onEnter(self)
end

function MedusaManiaChoosePlayView:onExit()
    MedusaManiaChoosePlayView.super.onExit(self)
end

function MedusaManiaChoosePlayView:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
end

function MedusaManiaChoosePlayView:playSpineStart()
    for i=1, self.m_totalCount do
        self.m_rootChooseNode[i]:setPosition(self.m_initChoosePos[i])
        util_spinePlay(self.m_tblChooseSpine[i],"start",false)
    end
    util_spineEndCallFunc(self.m_tblChooseSpine[self.m_totalCount], "start", function()
        self:playSpineIdle()
    end)
end

function MedusaManiaChoosePlayView:playSpineIdle()
    for i=1, self.m_totalCount do
        util_spinePlay(self.m_tblChooseSpine[i],"idle",true)
    end
end

function MedusaManiaChoosePlayView:refreshData(_callFunc)
    self.callFunc = _callFunc
    self.m_isClick = true
end

--默认按钮监听回调
function MedusaManiaChoosePlayView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_Panel" and self:isCanTouch() then
        self:choosePlayIndex(tag)
    end
end

function MedusaManiaChoosePlayView:choosePlayIndex(_index)
    self.m_isClick = false
    self.m_selectIndex = _index
    for i=1, self.m_totalCount do
        if i == _index then
            util_spinePlay(self.m_tblChooseSpine[i],"actionframe",false)
        else
            util_spinePlay(self.m_tblChooseSpine[i],"over",false)
        end
    end
    gLobalSoundManager:playSound(PublicConfig.Music_Choose_FeedBack)
    util_spineEndCallFunc(self.m_tblChooseSpine[_index], "actionframe", function()
        self:moveChooseNodeToMiddle(_index)
    end)
end

function MedusaManiaChoosePlayView:moveChooseNodeToMiddle(_index)
    local delayTime = 0.5
    local endPos = cc.p(0, -19)
    if _index ~= 2 then
        gLobalSoundManager:playSound(PublicConfig.Music_Choose_Move_Mid)
        util_playMoveToAction(self.m_rootChooseNode[_index], delayTime, endPos,function()
            --选择播放完成后
            self.m_machine:setFreeSelectType(_index)
            self:sendData(_index)
        end)
    else
        --选择播放完成后
        self.m_machine:setFreeSelectType(_index)
        self:sendData(_index)
    end
end

function MedusaManiaChoosePlayView:sendData(_selectIndex)
    local selectIndex = _selectIndex
    local httpSendMgr = SendDataManager:getInstance()
    print("发送的类型索引是-" .. selectIndex)
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT, data = selectIndex}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function MedusaManiaChoosePlayView:receiveData()
    self.m_machine:addPlayEffect()
    local endCallFunc = function()
        if self.callFunc then
            self.callFunc()
            self.callFunc = nil
        end
        -- self:hideSelf()
    end
    self:runCsbAction("over")
    self.m_machine:playBgCutSpine()
    performWithDelay(self.m_scWaitNode, function()
        gLobalSoundManager:playSound(PublicConfig.Music_Fg_startOver)
    end, 30/30)
    performWithDelay(self.m_scWaitNode, function()
        gLobalSoundManager:playSound(PublicConfig.Music_Fg_CutScene)
        gLobalSoundManager:fadeOutBgMusic(1.0)
    end, 40/30)
    
    util_spinePlay(self.m_tblChooseSpine[self.m_selectIndex],"actionframe3",false)
    util_spineEndCallFunc(self.m_tblChooseSpine[self.m_selectIndex],"actionframe3", function()
        self.m_machine:playChooseCutScene(endCallFunc)
        self:hideSelf()
    end)
end

function MedusaManiaChoosePlayView:featureResultCallFun(param)
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

function MedusaManiaChoosePlayView:isCanTouch()
    return self.m_isClick
end

function MedusaManiaChoosePlayView:hideSelf()
    self:setVisible(false)
end

return MedusaManiaChoosePlayView
