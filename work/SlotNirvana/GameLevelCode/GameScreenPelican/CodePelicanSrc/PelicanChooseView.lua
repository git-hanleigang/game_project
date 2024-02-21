---
--xcyy
--2018年5月23日
--PelicanChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local PelicanChooseView = class("PelicanChooseView", BaseGame)

PelicanChooseView.m_ClickIndex = 1
PelicanChooseView.m_spinDataResult = {}

function PelicanChooseView:initUI(machine)

    self:createCsbNode("Pelican/FreeSpinChose_mark.csb")

    self.People = util_spineCreate("FreeSpinChose",true,true)
    self:findChild("Node_spine"):addChild(self.People)

    self.m_machine = machine

    self.m_Click = false

    self.m_isStart_Over_Action = true

    util_spinePlay(self.People,"start",false)
    util_spineEndCallFunc(self.People,"start",function (  )
        util_spinePlay(self.People,"idleframe",true)
        self:addClick(self:findChild("Button2")) -- free
        self:addClick(self:findChild("Button1")) -- respin

        self.m_isStart_Over_Action = false
    end)
end


function PelicanChooseView:onExit()
    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)
end

function PelicanChooseView:checkAllBtnClickStates()
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
function PelicanChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    self.m_Click = true
    local randomNum = math.random(1,2)
    if randomNum == 1 then
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_choose1.mp3")
    else
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_choose2.mp3")
    end
    if name == "Button2" then
        -- free
        
        self.m_ClickIndex = 2
        self:sendData(1)
  
    elseif name == "Button1" then
         -- respin
        
        self.m_ClickIndex = 1
        self:sendData(0)
    
    end
end

--数据接收
function PelicanChooseView:recvBaseData(featureData)
    self.m_isStart_Over_Action = true
    gLobalSoundManager:playSound("PelicanSounds/music_Pelican_chooseOver.mp3")
    if self.m_ClickIndex == 2 then
        util_spinePlay(self.People,"actionframe2",false)
    elseif self.m_ClickIndex == 1 then
        util_spinePlay(self.People,"actionframe1",false)
    end
    performWithDelay(
        self,
        function()
            self:showReward()
        end,
        89/30
    )
end

--数据发送
function PelicanChooseView:sendData(pos)
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = nil

    messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = pos}

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

function PelicanChooseView:featureResultCallFun(param)
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
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action" .. spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end

--弹出结算奖励
function PelicanChooseView:showReward()
    if self.m_bonusEndCall then
        self.m_bonusEndCall(self.m_ClickIndex)
    end
end

function PelicanChooseView:setEndCall(func)
    self.m_bonusEndCall = func
end

function PelicanChooseView:closeUi(func)
    if func then
        func()
    end
end

return PelicanChooseView
