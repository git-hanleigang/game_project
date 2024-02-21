---
--xcyy
--2018年5月23日
--FortuneGodChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local FortuneGodChooseView = class("FortuneGodChooseView", BaseGame)

FortuneGodChooseView.m_ClickIndex = 1
FortuneGodChooseView.m_spinDataResult = {}

function FortuneGodChooseView:initUI(machine)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("FortuneGod/GameChoose.csb", isAutoScale)

    self.m_machine = machine
    self:addClick(self:findChild("Panel_zuo"))
    self:addClick(self:findChild("Panel_you"))

    self:addBaoToNode()

    local freeTimes = self.m_machine.m_runSpinResultData.p_selfMakeData.freeTimes or 8
    local numView = util_createAnimation("Socre_FortuneGod_font_6.csb")
    numView:findChild("m_lb_coins"):setString(freeTimes)
    self:updateLabelSize({label=numView:findChild("m_lb_coins"),sx=0.9,sy=0.9},553)

    self.m_Click = false

    self.m_isStart_Over_Action = true
    self.peopleShow = util_spineCreate("Socre_xuanze_tanban",true,true)
    util_spinePushBindNode(self.peopleShow,"guadian8",numView)
    self:findChild("Node_1"):addChild(self.peopleShow)
    util_spinePlay(self.peopleShow,"start",false)
    performWithDelay(self,function (  )
        self.m_isStart_Over_Action = false

        util_spinePlay(self.peopleShow,"idle",true)
    end,1)
        
end


function FortuneGodChooseView:addBaoToNode( )
    self.baoDian1 = util_spineCreate("Socre_FortuneGod_Tongyongbaodian",true,true)
    self:findChild("Node_27"):addChild(self.baoDian1)
    self.baoDian2 = util_spineCreate("Socre_FortuneGod_Tongyongbaodian",true,true)
    self:findChild("Node_28"):addChild(self.baoDian2)
end

function FortuneGodChooseView:onEnter()
    FortuneGodChooseView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:featureResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

function FortuneGodChooseView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function FortuneGodChooseView:checkAllBtnClickStates()
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
function FortuneGodChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() or self.m_Click then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    self.m_Click = true

    if name == "Panel_zuo" then     --respin
        self.m_ClickIndex = 0
        self:sendData(0)
    elseif name == "Panel_you" then     --free
        self.m_ClickIndex = 1
        self:sendData(1)
    end
end

--数据接收
function FortuneGodChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true
    local node = cc.Node:create()
    self:addChild(node)
    local actList = {}
    if self.m_ClickIndex == 0 then
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_ChooseOverShow.mp3")
            --爆点播放
            util_spinePlay(self.baoDian1,"actionframe2",false)
        end)
        actList[#actList + 1]  = cc.DelayTime:create(0.5)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            
            util_spinePlay(self.peopleShow,"actionframe1",false)
        end)
        actList[#actList + 1]  = cc.DelayTime:create(4/3)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            util_spinePlay(self.peopleShow,"xuanguang1",false)
        end)
        actList[#actList + 1]  = cc.DelayTime:create(2/3)
    elseif self.m_ClickIndex == 1 then
        --爆点播放
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_ChooseOverShow.mp3")
            --爆点播放
            util_spinePlay(self.baoDian2,"actionframe2",false)
        end)
        actList[#actList + 1]  = cc.DelayTime:create(0.5)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            
            util_spinePlay(self.peopleShow,"actionframe2",false)
        end)
        actList[#actList + 1]  = cc.DelayTime:create(4/3)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            util_spinePlay(self.peopleShow,"xuanguang2",false)
        end)
        actList[#actList + 1]  = cc.DelayTime:create(2/3)
    end
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        self:showReward()
        
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        node:removeFromParent()
        
    end)
    node:runAction(cc.Sequence:create(actList))
end

--数据发送
function FortuneGodChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function FortuneGodChooseView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        -- print("赢取的总钱数为=" .. self.m_totleWimnCoins)
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
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function FortuneGodChooseView:showReward()
    gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_ChooseOver.mp3")
    if self.m_ClickIndex == 0 then
        util_spinePlay(self.peopleShow,"actionframe1_out",false)
    else
        util_spinePlay(self.peopleShow,"actionframe2_out",false)
    end
    performWithDelay(self,function (  )
        if self.m_bonusEndCall then
            self.m_bonusEndCall(self.m_ClickIndex)
        end
    end,20/30)
    
end

function FortuneGodChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

return FortuneGodChooseView
