---
--xcyy
--2018年5月23日
--BeerGirlChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local BeerGirlChooseView = class("BeerGirlChooseView",BaseGame )

BeerGirlChooseView.m_ClickIndex = 1
BeerGirlChooseView.m_spinDataResult = {}

function BeerGirlChooseView:initUI(machine)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("BeerGirl/GameChose.csb",isAutoScale)

    self.m_machine = machine


    self:updateChooseData( )
    self:updateLable( )

    self.m_Click = false

    self.m_isStart_Over_Action = true


    self:runCsbAction("start",false,function(  )

        self.m_isStart_Over_Action = false

        self:runCsbAction("idle",true)
    end)

    performWithDelay(self,function(  )

        gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_ChooseShow.mp3")
        
        self:findChild("Particle_2"):resetSystem()
        self:findChild("Particle_2_0_0"):resetSystem()
        self:findChild("Particle_2_0"):resetSystem()
    end,0.3)
    

end

function BeerGirlChooseView:updateChooseData( )
    self.m_wildTotalCounts = {5,7,10}
    self.m_freespinTimes = { 15,10,5}

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfdata then
        if selfdata.wildTotalCounts then
            self.m_wildTotalCounts = selfdata.wildTotalCounts
        end

        if selfdata.freespinTimes then
            self.m_freespinTimes = selfdata.freespinTimes
        end
    end
end

function BeerGirlChooseView:updateLable( )
    
    for i=1,3 do
        
        local fsNum = self:findChild("choose_lab_"..i)
        if fsNum then
            local fsStr = self.m_freespinTimes[i]
            fsNum:setString(fsStr)
        end

        local wildNum = self:findChild("choose_wild_"..i)
        if wildNum then
            local wildStr = self.m_wildTotalCounts[i]
            wildNum:setString(wildStr)
        end

    end
end

function BeerGirlChooseView:onEnter()

    gLobalNoticManager:addObserver(self,function(self,params)
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
    
end


function BeerGirlChooseView:onExit()

    self:clearBaseData()
    gLobalNoticManager:removeAllObservers(self)

end

function BeerGirlChooseView:checkAllBtnClickStates( )
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
function BeerGirlChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()


    if self:checkAllBtnClickStates( ) then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end


    self.m_Click = true

    self:findChild("Particle_5"):stopSystem()

    gLobalSoundManager:playSound("BeerGirlSounds/BeerGirl_ChooseClickd.mp3")
    
    if name ==  "Button_1" then
        self.m_ClickIndex = 1
        local clickActName = "choose" .. self.m_ClickIndex
    
        self:runCsbAction(clickActName,false,function(  )
            self:sendData(0)
        end)
        

    elseif name ==  "Button_2" then 
        self.m_ClickIndex = 2
        local clickActName = "choose" .. self.m_ClickIndex
        self:runCsbAction(clickActName,false,function(  )
            self:sendData(1)
        end)
        
    elseif name ==  "Button_3" then 
        self.m_ClickIndex = 3
        local clickActName = "choose" .. self.m_ClickIndex
        self:runCsbAction(clickActName,false,function(  )
            self:sendData(2)
        end)
    end

end





--数据接收
function BeerGirlChooseView:recvBaseData(featureData)


    self.m_isStart_Over_Action = true

    self:closeUi( function(  )
        self:showReward()
    end )

    

end

--数据发送
function BeerGirlChooseView:sendData(pos)
    self.m_action=self.ACTION_SEND

    
 
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil

    messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= pos }

    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)

end

function BeerGirlChooseView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self.m_spinDataResult = spinData.result

            self.m_machine.m_runSpinResultData:parseResultData(spinData.result,self.m_machine.m_lineDataPool)

            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end


--弹出结算奖励
function BeerGirlChooseView:showReward()

   if self.m_bonusEndCall then
        self.m_bonusEndCall()
   end 
end

function BeerGirlChooseView:setEndCall( func)
    self.m_bonusEndCall = func
end

function BeerGirlChooseView:closeUi( func )

    
    -- self:runCsbAction("over",false,function(  )
        
    --     if func then
    --         func()
    --     end
    -- end)

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,1)
end




return BeerGirlChooseView