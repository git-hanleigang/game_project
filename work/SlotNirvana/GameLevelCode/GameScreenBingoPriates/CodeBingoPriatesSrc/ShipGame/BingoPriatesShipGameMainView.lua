---
--xcyy
--2018年5月23日
--BingoPriatesShipGameMainView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local BingoPriatesShipGameMainView = class("BingoPriatesShipGameMainView",BaseGame )

BingoPriatesShipGameMainView.m_machine = nil
BingoPriatesShipGameMainView.m_bonusEndCall = nil

BingoPriatesShipGameMainView.m_MaxShipNum = 12
BingoPriatesShipGameMainView.m_BonusWinCoins = 0


function BingoPriatesShipGameMainView:initUI(data)

    self.m_machine = data.machine


    self.p_choose = data.choose or {}
    self.p_bonusExtra = data.bonusExtr or {}
    self.p_status =  "OPEN"
    self.m_BonusWinCoins = 0
    self.m_OldCoins = 0

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("BingoPriates/GameScreenBingoPriates_shipGame.csb")



    self.m_shipTipView = util_createAnimation("BingoPriates_shipGame_TipView.csb")
    self:findChild("tipNode"):addChild(self.m_shipTipView)

    self.m_Multiple = util_createView("CodeBingoPriatesSrc.ShipGame.BingoPriatesShipGameMultipleView")
    self:findChild("hudiej"):addChild(self.m_Multiple)
    local bonusExtra = self.p_bonusExtra 
    local multiple = bonusExtra.multiple or 0
    self.m_Multiple:updateMultipleUI( multiple )

    self.m_CaptainMan = util_spineCreate("BingoPriates_bonus_juese",true,true)
    self:findChild("man"):addChild(self.m_CaptainMan)
    util_spinePlay(self.m_CaptainMan,"idleframe",true)
    self.m_CaptainMan:setPosition(15,-10)
    self.m_CaptainMan:setScale(1.7)

    local bonusExtra = self.p_bonusExtra 
    local coinsTotal = bonusExtra.coinsTotal or 0
    self:updateWinCoins( coinsTotal )

    self:initShip( )

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)
  
end


function BingoPriatesShipGameMainView:initShip( )

    
    
    for i=1,self.m_MaxShipNum do

        local data = {}
        data.index = i - 1 
        data.machine = self
        
        local parShipNode = util_createAnimation("BingoPriates_shipGame_ShipNode_"..i..".csb")
        self:findChild("chuan"):addChild(parShipNode,i)
        local ship = util_createView("CodeBingoPriatesSrc.ShipGame.BingoPriatesShipClickView",data)   
        parShipNode:findChild("shipNode"):addChild(ship)
        ship.parShipNode = parShipNode
        self["Ship_" .. i] = ship
        parShipNode:runCsbAction("actionframe",true)

       
    end

end

function BingoPriatesShipGameMainView:initShipStates( )
    
    local choose = self.p_choose or {}
    local bonusExtra = self.p_bonusExtra or {}
    
    
    for i=1,self.m_MaxShipNum do

        local ship = self["Ship_" .. i]

        local clientPositions = choose or {}
        local rewards = bonusExtra.rewards or {}
        if self:isInArray( clientPositions,i - 1 ) then --如果已经点击过
            local clickPos = i 
            local isChest = false
           
            local rewardData = rewards[clickPos ] or {}
            local coins = rewardData.coins
    
            self:updateShipUI(ship,isChest,coins )
            ship:findChild("click"):setVisible(false)
            ship:runCsbAction("over")
            local parShipNode = ship.parShipNode
            if parShipNode then
                parShipNode:runCsbAction("idleframe")
            end
            
        end
       
    end
end

function BingoPriatesShipGameMainView:isCanTouch( )
    
    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
    
end

function BingoPriatesShipGameMainView:setClickData( pos )
    
    -- gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Jp_Choose_Click_Baozhu.mp3")

    self:sendData(pos)
end

function BingoPriatesShipGameMainView:onEnter()
    BaseGame.onEnter(self)
end
function BingoPriatesShipGameMainView:onExit()
    scheduler.unschedulesByTargetName("BingoPriatesShipGameMainView")
    BaseGame.onExit(self)

end

--数据发送
function BingoPriatesShipGameMainView:sendData(pos)

    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , clickPos= pos }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    
end


--数据接收
function BingoPriatesShipGameMainView:recvBaseData(featureData)

        local bonusdata =  featureData.p_bonus or {}
        self.p_choose = bonusdata.choose or {}
        self.p_bonusExtra = bonusdata.extra or {}
        self.p_status = bonusdata.status or "OPEN"


        local choose = self.p_choose or {}
        local bonusExtra = self.p_bonusExtra
        
        
        local clientPositions = choose or {}
        local clickPos = clientPositions[#clientPositions] or 0
        local ship = self["Ship_" .. clickPos + 1]
        local isChest = false
        local rewards = bonusExtra.rewards or {}
        local rewardData = rewards[clickPos + 1] or {}
        local coins = rewardData.coins


        if ship then

            self:openFire( ship , function(  )
                self:updateShipUI(ship,isChest,coins,self:checkIsOver( ))


                local parShipNode = ship.parShipNode
                if parShipNode then
                    parShipNode:runCsbAction("idleframe")
                end

                local multiple = bonusExtra.multiple
                self.m_Multiple:updateMultipleUI( multiple )
                
                local actname = "actionframe"
                if self:checkIsOver( ) then
                    actname = "actionframe2"
                end

                gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_ShipGame_ShowLab.mp3")
                ship:runCsbAction(actname,false,function(  )
    

                    self:runShipNextTurn( )
                    
                end)
            end)

           

        end



end

function BingoPriatesShipGameMainView:runShipNextTurn( )
    
    local bonusExtra = self.p_bonusExtra 
    local coinsTotal = bonusExtra.coinsTotal or 0
    self:updateWinCoins( coinsTotal , true )

    if self:checkIsOver() then
        
        performWithDelay(self,function(  )

            self:showOtherShip( )

        end,1)
        
    else
        self.m_action=self.ACTION_RECV
    end

end

function BingoPriatesShipGameMainView:checkIsOver( )
    local bonusStatus = self.p_status 

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end

function BingoPriatesShipGameMainView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end

function BingoPriatesShipGameMainView:updateShipUI(ship,isChest,coins , isOver )

    local str = ""
    if isOver then
        str = "+"
    end

    local lab = ship:findChild("BitmapFontLabel_1") 
    if lab then
        lab:setString(util_formatCoins(coins,3)..str)
    end

    local lab_1 = ship:findChild("BitmapFontLabel_1_Dark") 
    if lab_1 then
        lab_1:setString(util_formatCoins(coins,3)..str)
    end

end

function BingoPriatesShipGameMainView:showOtherShip( )


    local choose = self.p_choose or {}
    local bonusExtra = self.p_bonusExtra

    local clientPositions = choose or {}

    local rewards = bonusExtra.rewards or {}
    local showCollect = bonusExtra.showCollect or {}


    for i=1,#rewards do
        local rewardData = rewards[i] or {}
        local isChest = false
        if rewardData.box and  rewardData.box ~= 0 then
            isChest = true
        end
        if not self:isInArray( clientPositions,i - 1 ) then
            local ship =  self["Ship_" .. i] 
            if ship then

                local parShipNode = ship.parShipNode
                if parShipNode then
                    parShipNode:runCsbAction("idleframe")
                end
                
                local coins = rewardData.coins
                local isover = nil
                if  self:isInArray( showCollect,i - 1 ) then
                    isover = true
                end

                self:updateShipUI(ship,isChest,coins,isover )


                if isover then
                    ship:runCsbAction("bianhei2")
                else
                    ship:runCsbAction("bianhei")
                    
                end
                

                
            end
        end

    end

    -- 停掉背景音乐
    self.m_machine:clearCurMusicBg()

    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_ShipGame_End.mp3")

    performWithDelay(self,function(  )
        if self.m_bonusEndCall then
            self.m_bonusEndCall()
        end
    end,2.5)

end


--开始结束流程
function BingoPriatesShipGameMainView:gameOver(isContinue)

end

--弹出结算奖励
function BingoPriatesShipGameMainView:showReward()

   
end

function BingoPriatesShipGameMainView:setEndCall( func)
    self.m_bonusEndCall = function(  )
            
        self.m_machine:showBonusOverView( self.m_serverWinCoins, function(  )

            -- 通知bonus 结束， 以及赢钱多少
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_serverWinCoins, GameEffect.EFFECT_BONUS})

            

            -- 更新游戏内每日任务进度条
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,true,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin 

            if func then
                func()
            end 
            
         end )   

    end 
end



function BingoPriatesShipGameMainView:featureResultCallFun(param)

    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            print("=========" .. cjson.encode(spinData.result) )
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
    
            self.m_totleWimnCoins = spinData.result.winAmount
            print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
    
            if spinData.action == "FEATURE" then
                self.m_featureData:parseFeatureData(spinData.result)
                self.m_spinDataResult = spinData.result
    
                self.m_machine:SpinResultParseResultData( spinData)
                self:recvBaseData(self.m_featureData)
    
            elseif self.m_isBonusCollect then
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            else
                dump(spinData.result, "featureResult action"..spinData.action, 3)
            end
        else
            -- 处理消息请求错误情况
    
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
    
        end
    end
    
end


function BingoPriatesShipGameMainView:updateWinCoins( coins , playSound )
    self.m_BonusWinCoins = coins
    local lab = self:findChild("lab_winCoins")
    if lab then

        local soundId = nil
        if playSound then
            soundId = gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Coins_Jump.mp3")
        end
        
        local startValue = self.m_OldCoins
        local addValue = (coins - startValue) /30
        util_jumpNum(lab,startValue,coins,addValue,0.02,{50},nil,nil,function(  )

            if soundId then
                gLobalSoundManager:stopAudio(soundId)
                gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Coins_JumpOver.mp3")
            end
        end,function(  )

            self:updateLabelSize({label=lab,sx=1,sy=1},304)

        end)

    end
    self.m_OldCoins = coins
    
end

function BingoPriatesShipGameMainView:openFire( endNode , func)
    

    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_ShipGame_openFire.mp3")
    self:runCsbAction("kaipao",false,function(  )
        
    end)

    performWithDelay(self.m_actNode,function(  )
        local beginNode = self:findChild("Node_actPos") 
        self:flyBombNode(beginNode , endNode,function(  )
            if func then
                func()
            end
        end )
    end,6/30)
    
end

function BingoPriatesShipGameMainView:flyBombNode(beginNode , endNode,func )
    
    local actNode = cc.Node:create()
    self:findChild("Node_FireBombLayer"):addChild(actNode)

    local node = util_createAnimation("Socre_BingoPriates_Linghting.csb")
    node:findChild("m_lb_score"):setString("")
    actNode:addChild(node)
    node:setVisible(false)

    local BoomAct = util_createAnimation("Socre_BingoPriates_Boom.csb")
    actNode:addChild(BoomAct)
    BoomAct:setVisible(false)


    local time = 0.5
    local endPos = cc.p(util_getConvertNodePos(endNode,actNode))
    local beginPos = cc.p(endPos.x,endPos.y + 500) --cc.p(util_getConvertNodePos(beginNode,actNode))
    actNode:setPosition(beginPos)
    
    local actionList={}
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
 
        node:runCsbAction("small")
        
        
    end)
    actionList[#actionList+1]=cc.MoveTo:create(time,endPos);
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        
        gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_ShipGame_BoomZha.mp3")

        BoomAct:setVisible(true) 
        node:setVisible(false)
        local BoomAct_1 = BoomAct
        BoomAct:runCsbAction("actionframe",false,function(  )
            BoomAct_1:setVisible(false)
        end)
        
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(9/30) -- BoomAct 炸到最大时
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        if func then
            func()
        end

    end)
    local seq=cc.Sequence:create(actionList)
    actNode:runAction(seq)

end



return BingoPriatesShipGameMainView