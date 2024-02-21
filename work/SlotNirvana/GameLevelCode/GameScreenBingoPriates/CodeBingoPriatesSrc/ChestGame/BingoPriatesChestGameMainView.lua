---
--xcyy
--2018年5月23日
--BingoPriatesChestGameMainView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local BingoPriatesChestGameMainView = class("BingoPriatesChestGameMainView",BaseGame )

BingoPriatesChestGameMainView.m_machine = nil
BingoPriatesChestGameMainView.m_bonusEndCall = nil
BingoPriatesChestGameMainView.p_bonusExtra = nil

BingoPriatesChestGameMainView.m_MaxChestNum = 9
BingoPriatesChestGameMainView.m_BonusWinCoins = 0
BingoPriatesChestGameMainView.m_GrandIndex = {4,5,6}
BingoPriatesChestGameMainView.m_MajorIndex = {1,2,3}
BingoPriatesChestGameMainView.m_MinorIndex = {7,8,9}

function BingoPriatesChestGameMainView:initUI(data)

    self.m_machine = data.machine


    self.p_choose = data.choose or {}
    self.p_content = data.content or {}
    self.p_bonusExtra = {}
    self.p_status =  "OPEN"
    self.m_BonusWinCoins = 0
    self.m_OldCoins = 0
   

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("BingoPriates/GameScreenBingoPriates_chestGame.csb")


    self.m_CaptainMan = util_spineCreate("BingoPriates_bonus_juese",true,true)
    self:findChild("man"):addChild(self.m_CaptainMan)
    util_spinePlay(self.m_CaptainMan,"idleframe",true)
    self.m_CaptainMan:setPosition(0,140)
    self.m_CaptainMan:setScale(1.8)

    self.m_ChestViewJPBar = util_createView("CodeBingoPriatesSrc.ChestGame.BingoPriatesChestGameJackPotBarView")
    self:findChild("jackpot_1"):addChild(self.m_ChestViewJPBar)
    self.m_ChestViewJPBar:initMachine(self.m_machine)
        
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local jackpotData = selfdata.jackpotData 
    if jackpotData  then
        self.m_ChestViewJPBar:updateJackpotInfo(jackpotData)
    end

    self:initChest( )

    self:initChesZuan()
    

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

    local GrandNum,MajorNum,MinorNum = self:getJpNum()
    self:updateDiamonds( GrandNum,MajorNum,MinorNum)

end

function BingoPriatesChestGameMainView:getJpNum( )
    
    local GrandNum,MajorNum,MinorNum = 0,0,0

    for i=1,#self.p_content do
        local jpType = self.p_content[i]
        if jpType == "Grand" then
            GrandNum = GrandNum + 1
        
        elseif jpType == "Major" then
            MajorNum = MajorNum + 1
        elseif jpType == "Minor" then
            MinorNum = MinorNum + 1
        end
    end
    
    return GrandNum,MajorNum,MinorNum
end

function BingoPriatesChestGameMainView:getContentPos( pos )
    
    for i=1,#self.p_choose do
        local index = self.p_choose[i]
        if index ==  pos then
            return i
        end
    end
end

function BingoPriatesChestGameMainView:initChest( )
    

    for i=1,self.m_MaxChestNum do
        local data = {}
        data.index = i - 1
        data.machine = self

        local Chest = util_createView("CodeBingoPriatesSrc.ChestGame.BingoPriatesChestClickView",data)    

        local nodeName = "baoxiang_" .. i
        self:findChild(nodeName):addChild(Chest)
        self["Chest_" .. i] = Chest

        if not self:isInArray( self.p_choose,data.index ) then
            Chest:runCsbAction("idle1",true)
        else
            Chest:runCsbAction("open")
            local currPos = self:getContentPos( data.index ) or 1
            local jpType = self.p_content[currPos]
            self:updateChestUI(Chest , jpType )
        end

        

    end

end

function BingoPriatesChestGameMainView:initChesZuan( )
    
    

    for i=1,self.m_MaxChestNum do
        local data = {}
        local diamond = util_createAnimation("BingoPriates_chestGame_zuan.csb") 

        local nodeName = "BingoPriates_zuan_" .. i
        self.m_ChestViewJPBar:findChild(nodeName):addChild(diamond)
        self["diamond_" .. i] = diamond
        diamond:runCsbAction("idleframe")
        
    end

end


function BingoPriatesChestGameMainView:isCanTouch( )
    
    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
    
end

function BingoPriatesChestGameMainView:setClickData( pos )
    
    -- gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_Jp_Choose_Click_Baozhu.mp3")

    self:sendData(pos)
end

function BingoPriatesChestGameMainView:onEnter()
    BaseGame.onEnter(self)
end
function BingoPriatesChestGameMainView:onExit()
    scheduler.unschedulesByTargetName("BingoPriatesChestGameMainView")
    BaseGame.onExit(self)

end

--数据发送
function BingoPriatesChestGameMainView:sendData(pos)



    
    self.m_action=self.ACTION_SEND
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
            self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGame")
    else
        
        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData={msg=MessageDataType.MSG_BONUS_SELECT , clickPos= pos }
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end


--数据接收
function BingoPriatesChestGameMainView:recvBaseData(featureData)

    local bonusdata =  featureData.p_bonus or {}
    self.p_choose = bonusdata.choose or {}
    self.p_content = bonusdata.content or {}
    self.p_status = bonusdata.status or "OPEN"
    self.p_bonusExtra = bonusdata.extra
  
    local choose = self.p_choose or {}

    

    local clientPositions = choose or {}
    local clickPos = clientPositions[#clientPositions] or 0
    local chest = self["Chest_" .. clickPos + 1]

    local currPos = self:getContentPos( clickPos ) or 1
    local rewardData = self.p_content[currPos]



    if chest then
        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_ChestGame_ChestOpen.mp3")
        self:updateChestUI(chest ,rewardData)
        chest:runCsbAction("open",false,function(  )

            local GrandNum,MajorNum,MinorNum = self:getJpNum()
            
            local beginNode = chest
            local endNode = nil
            if rewardData == "Grand" then
                endNode = self.m_ChestViewJPBar:findChild("BingoPriates_zuan_" .. self.m_GrandIndex[GrandNum])

            elseif rewardData == "Major" then
                endNode = self.m_ChestViewJPBar:findChild("BingoPriates_zuan_" .. self.m_MajorIndex[MajorNum])

            elseif rewardData == "Minor" then
                endNode = self.m_ChestViewJPBar:findChild("BingoPriates_zuan_" .. self.m_MinorIndex[MinorNum])

            end
            
            self:flyDiamondNode(beginNode , endNode,function(  )

                
                self:updateDiamonds( GrandNum,MajorNum,MinorNum)

                self:beginNextTurn( )
            end )
            
    
        end)

    end

end

function BingoPriatesChestGameMainView:beginNextTurn( )
    

        if self:checkIsOver() then
            
            self:showOtherchest( function(  )

                performWithDelay(self.m_actNode,function( )
                
                    -- 停掉背景音乐
                    self.m_machine:clearCurMusicBg()
    
                    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_ChestGame_Over.mp3")
                    
                    performWithDelay(self,function(  )
                        if self.m_bonusEndCall then
                            self.m_bonusEndCall()
                        end
                    end,2)
    
                end,12/30)

            end )

            
            

        else
            

            self.m_action=self.ACTION_RECV
          
        end
    
end

function BingoPriatesChestGameMainView:restChest( )


    for i=1,self.m_MaxChestNum do
        local Chest = self["Chest_" .. i]
        if Chest then
            Chest:runCsbAction("idle1",true)
            Chest:findChild("click"):setVisible(true)
        end

    end
end

function BingoPriatesChestGameMainView:showOtheChest( )
   
end

function BingoPriatesChestGameMainView:checkIsOver( )
    local bonusStatus = self.p_status

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end

function BingoPriatesChestGameMainView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end




--开始结束流程
function BingoPriatesChestGameMainView:gameOver(isContinue)

end

--弹出结算奖励
function BingoPriatesChestGameMainView:showReward()

   
end

function BingoPriatesChestGameMainView:setEndCall( func)
    self.m_bonusEndCall = function(  )
           
        local selfdate = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
        self.m_BonusWinCoins = self.m_serverWinCoins or 0
        local jpIndex = 1
        local jpCoins = selfdate.jackpotWinAmount or 0
        local diamondCount = self.p_bonusExtra.diamondCount or 0

        local GrandNum,MajorNum,MinorNum = self:getJpNum()
 
        if MinorNum == 3 then
            jpIndex = 3
            self.m_ChestViewJPBar:runCsbAction("minor") 
        elseif MajorNum == 3 then
            jpIndex = 2
            self.m_ChestViewJPBar:runCsbAction("major")
        elseif GrandNum == 3 then
            jpIndex = 1
            self.m_ChestViewJPBar:runCsbAction("grand")
            
        end

        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_ChestGame_WinJp.mp3")

        performWithDelay(self.m_actNode,function(  )


                self.m_machine:showChestBonusOverView( self.m_BonusWinCoins,jpIndex , jpCoins ,  function(  )

                    -- 通知bonus 结束， 以及赢钱多少
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_BonusWinCoins, GameEffect.EFFECT_BONUS})

                    

                    -- 更新游戏内每日任务进度条
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

                    local lastWinCoin = globalData.slotRunData.lastWinCoin
                    globalData.slotRunData.lastWinCoin = 0
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_BonusWinCoins,true,true})
                    globalData.slotRunData.lastWinCoin = lastWinCoin  

                    if func then
                        func()
                    end 
                        
                end )



        end,3)


    end 
end



function BingoPriatesChestGameMainView:featureResultCallFun(param)

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


 
function BingoPriatesChestGameMainView:updateChestUI(chest , jpType )

    local grandImg = chest:findChild("grand")
    local majorImg = chest:findChild("major")
    local minorImg = chest:findChild("minor")
    if grandImg then
        grandImg:setVisible(false)
    end
    if majorImg then
        majorImg:setVisible(false)
    end
    if minorImg then
        minorImg:setVisible(false)
    end

    if jpType == "Grand" then
        if grandImg then
            grandImg:setVisible(true)
        end
    
    elseif jpType == "Major" then
        if majorImg then
            majorImg:setVisible(true)
        end
    elseif jpType == "Minor" then
        if minorImg then
            minorImg:setVisible(true)
        end
    end

    local Node_Chest = chest:findChild("Node_Chest")
    Node_Chest:setVisible(true)
    
end

function BingoPriatesChestGameMainView:showOtherchest( func )

    local choose = self.p_choose or {}


    local clientPositions = choose or {}


    local  displayBox =  self.p_bonusExtra.displayBox or {}
    local index = 0
    for i=1,self.m_MaxChestNum do

        if not self:isInArray( clientPositions,i - 1 ) then
            index = index + 1
            local rewardData = displayBox[index]
            local chest =  self["Chest_" .. i] 
            if chest then

                self:updateChestUI(chest ,rewardData)
                chest:runCsbAction("bianhei")
            end
        end

    end


    performWithDelay(self.m_actNode,function(  )
        if func then
            func()
        end
    end,1)

end

function BingoPriatesChestGameMainView:updateDiamonds( GrandNum,MajorNum,MinorNum )
   
    

    for i=1,3 do
        
        local GrandDiamond = self.m_ChestViewJPBar:findChild("BingoPriates_zuan_" .. self.m_GrandIndex[i])
        local MajorDiamond = self.m_ChestViewJPBar:findChild("BingoPriates_zuan_" .. self.m_MajorIndex[i])
        local MinorDiamond = self.m_ChestViewJPBar:findChild("BingoPriates_zuan_" .. self.m_MinorIndex[i])
        if GrandDiamond then
            if i <= GrandNum  then
                GrandDiamond:setVisible(true)
            else
                GrandDiamond:setVisible(false)
            end
        end
        if MajorDiamond then
            if i <= MajorNum  then
                MajorDiamond:setVisible(true)
            else
                MajorDiamond:setVisible(false)
            end
        end
        if MinorDiamond then
            if i <= MinorNum  then
                MinorDiamond:setVisible(true)
            else
                MinorDiamond:setVisible(false)
            end
        end
    end

    
end

function BingoPriatesChestGameMainView:flyDiamondNode(beginNode , endNode,func )
    
    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_ChestGame_flyDiamond.mp3")

    endNode:setVisible(false)
    

    local actNode = util_createAnimation("BingoPriates_chestGame_zuan.csb")
    self:addChild(actNode)
    local beginPos = cc.p(util_getConvertNodePos(beginNode,actNode))
    actNode:setPosition(beginPos)
    actNode:setScale(1.72)
    local endPos = cc.p(util_getConvertNodePos(endNode,actNode))
    local time = 0.5
    local Particle =  actNode:findChild("Particle_1")
    if Particle then
        Particle:setPositionType(0)
        Particle:setDuration(time)
    end
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        actNode:runCsbAction("shouji")
    end)
    actList[#actList + 1] = cc.MoveTo:create(time,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        actNode:findChild("Node_UI"):setVisible(false)
        if func then
            func()
        end
        endNode:setVisible(false)
        actNode:runCsbAction("fankui")
        gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_ChestGame_flyDiamond_Fankui.mp3")
    end)
    actList[#actList + 1] = cc.DelayTime:create(time)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        endNode:setVisible(true)
        actNode:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    actNode:runAction(sq)

end

function BingoPriatesChestGameMainView:updateLeftClickTimes( time,isInit )
    
    if time == 5 then
        return
    end

    if time == 4 then

        
        self:findChild("lab_pinkNum"):setVisible(false)

        self:findChild("BingoPriates_MoreRound"):setVisible(false)
   
    else

        self:findChild("lab_pinkNum"):setVisible(true)

        self:findChild("BingoPriates_MoreRound"):setVisible(true)

    end
    
end

return BingoPriatesChestGameMainView