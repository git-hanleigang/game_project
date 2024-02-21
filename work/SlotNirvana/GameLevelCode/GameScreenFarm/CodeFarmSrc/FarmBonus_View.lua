---
--xcyy
--2018年5月23日
--FarmBonus_View.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local FarmBonus_View = class("FarmBonus_View",BaseGame )

local RoadType = {
    row = 1,
    reel = 2,
    free = 3,
    money = 4,
    wildReel = 5,

}

local RoadTypeName = {
    row = "row",
    reel = "reel",
    free = "free",
    money = "money",
    wildReel = "wildReel",

}

local wildReelList = {reel9 = 1,reel13= 2,reel20= 3,reel26=4}

FarmBonus_View.m_roadCsbNameList = 
        {{"Farm_game_addarow"},{"Farm_game_addreels"},
            {"Farm_game_freegame1","Farm_game_freegame2","Farm_game_freegame3"},
                {"Farm_game_txt"},
                    {"Farm_game_wildreel1","Farm_game_wildreel2","Farm_game_wildreel3","Farm_game_wildreel4"}}

FarmBonus_View.m_roadNodeList = {}

FarmBonus_View.m_roadNetdata = {}
FarmBonus_View.m_MaxRoadNum = 29

FarmBonus_View.m_machine = nil
FarmBonus_View.m_bonusEndCall = nil

FarmBonus_View.m_nowIndex = nil

FarmBonus_View.m_selectType = nil
--[[ selectType对应类型： reel  money free wildReel row closed corn --]]

FarmBonus_View.m_IsAutoStates = nil

function FarmBonus_View:initBonusData( )

    self.m_roadNetdata = self.m_bonusRoadNetdata.road
    self.m_nowIndex = self.m_bonusRoadNetdata.index  or 0
    self.m_backIndex = self.m_bonusRoadNetdata.backIndex or {}
    self.m_bonusWinCoins = self.m_machine.m_runSpinResultData.p_bonusWinCoins or 0
    self.m_freeGames = self.m_bonusRoadNetdata.freeGames or 5
    self.m_nowRow = self.m_bonusRoadNetdata.row  or 3
    self.m_wildReels = self.m_bonusRoadNetdata.wildReels or {}
    self.m_reel = self.m_bonusRoadNetdata.reel or 1
    self.m_wheelData = self.m_bonusRoadNetdata.wheel or {}
    self.m_machine.m_localCornNum = self.m_machine.m_localCornNum or 0 -- bonus与主类公用一个玉米数量管理
    self.m_specialIndex = self.m_bonusRoadNetdata.specialIndex
    self.m_canBack = self.m_bonusRoadNetdata.canBack
    self.m_back = self.m_bonusRoadNetdata.back or false
    self.m_selectType = nil

    if self.m_nowIndex == 0 then
        self.m_bonusWinCoins = 0
    end

    -- 是否自动spin
    self.m_IsAutoStates = false
    
end

function FarmBonus_View:AutoSendDate( )
    self:sendData()

end

function FarmBonus_View:OpenAutoSpin( )

    
    gLobalSoundManager:playSound("FarmSounds/music_Farm_click_AutoSpin_Tip.mp3")
    
    self.m_IsAutoStates = true
    self.m_Wheel.m_spinBtn:findChild("click_CloseAuto"):setVisible(true)
    self.m_Wheel.m_spinBtn:findChild("Node_Click"):setVisible(false)
    self.m_Wheel.m_spinBtn:findChild("autoSpin"):setVisible(true)
    self.m_Wheel.m_spinBtn:findChild("spin"):setVisible(false)
end

function FarmBonus_View:CloseAutoSpin( )
    self.m_IsAutoStates = false
    self.m_Wheel.m_spinBtn:findChild("click_CloseAuto"):setVisible(false)
    self.m_Wheel.m_spinBtn:findChild("Node_Click"):setVisible(true)
    self.m_Wheel.m_spinBtn:findChild("autoSpin"):setVisible(false)
    self.m_Wheel.m_spinBtn:findChild("spin"):setVisible(true)
end

function FarmBonus_View:initUI(machine)

    self.m_MaxRoadNum = 29
    self.m_machine = machine
    self.m_bonusEndCall = nil
    self.m_ReelsTip = nil
    self.m_bonusRoadNetdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    self.m_roadNodeList = {}

    self:initBonusData( )



    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("FarmGame/Farm_game.csb",isAutoScale)

    local wheelData = {}
    wheelData.content = self.m_wheelData
                      
    wheelData.m_betlevel = self.m_machine.m_betlevel or 0
    wheelData.m_machine = self.m_machine
    wheelData.m_BonusWheel = self

    self.m_Wheel = util_createView("CodeFarmSrc.FarmBonus_WheelView",wheelData)
    self:findChild("zhuanpan"):addChild(self.m_Wheel)
    self:setWheelCanTouch(  )
    

    --22.08.05策划移除谷仓
    -- self.m_Bonus_Barn = util_createView("CodeFarmSrc.FarmBonus_BarnView")
    -- self:findChild("gucang"):addChild(self.m_Bonus_Barn)
    -- self.m_Bonus_Barn:initMachine(self)
    

    self.m_Bonus_Corn = util_createView("CodeFarmSrc.FarmBonus_CornView")
    self:findChild("yumi_zi"):addChild(self.m_Bonus_Corn)
    
    

    self.m_Bonus_Coins = util_createView("CodeFarmSrc.FarmBonus_WinCoinsView")
    self:findChild("win"):addChild(self.m_Bonus_Coins)

    self:createLocalAnimation( )
    

    self.m_Bonus_FreespinTimes = util_createView("CodeFarmSrc.FarmBonus_FreespinTimesView")
    self:findChild("freegames"):addChild(self.m_Bonus_FreespinTimes)
    self.m_Bonus_FreespinTimes:runCsbAction("idle",true)

    
    self.m_Bonus_BigRoad_Yello = util_createView("CodeFarmSrc.FarmBonus_BigRoadView","Farm_lu")
    self:findChild("lu_huang"):addChild(self.m_Bonus_BigRoad_Yello)
    self.m_Bonus_BigRoad_Yello:runCsbAction("huang")
    self.m_Bonus_BigRoad_Yello:setVisible(false)

    self.m_Bonus_BigRoad_Pink = util_createView("CodeFarmSrc.FarmBonus_BigRoadView","Farm_lu")
    self:findChild("lu_fen"):addChild(self.m_Bonus_BigRoad_Pink)
    self.m_Bonus_BigRoad_Pink:runCsbAction("fen")
    self.m_Bonus_BigRoad_Pink:setVisible(false)

    self.m_Cow = util_createView("CodeFarmSrc.FarmBonus_CowView")
    self:findChild("niu"):addChild(self.m_Cow)
    local endPos = cc.p(self:findChild("road_" .. (self.m_nowIndex + 1)):getPosition()) 
    self:findChild("niu"):setPosition(endPos)
    local endIndex = self.m_nowIndex + 1
    if endIndex>=8 and endIndex <= 21 then
        self.m_Cow:setScaleX(-1)
    else
        self.m_Cow:setScaleX(1)
    end

    
    self:updateBonusView( true)
end

function FarmBonus_View:updateBonusData( )

    local result = self.m_spinDataResult

    self.m_roadNetdata = result.selfData.road
    self.m_nowNetIndex = result.selfData.index  or 0
    self.m_bonusWinCoins = result.bonus.bsWinCoins or 0
    self.m_freeGames = result.selfData.freeGames or 5
    self.m_nowRow = result.selfData.row  or 3
    self.m_wildReels = result.selfData.wildReels or {}
    self.m_reel = result.selfData.reel or 1
    self.m_wheelData = result.bonus.content or {}
    self.m_machine.m_localCornNum = result.selfData.collectScore or 0 -- bonus与主类公用一个玉米数量管理

    self.m_canBack = result.selfData.canBack
    self.m_back = result.selfData.back or false
    self.m_backIndex = result.selfData.backIndex or {}
    self.m_specialIndex = result.selfData.specialIndex

    self.p_contents = result.bonus.content
    self.p_chose = result.bonus.choose[1]
    self.p_status = result.bonus.status

    self.m_selectType = result.selfData.selectType

end


function FarmBonus_View:updateBonusView( isinit )
    self.m_Bonus_Corn:findChild("m_lb_coins"):setString(util_formatCoins(self.m_machine.m_localCornNum,6,nil,nil,true))
    self.m_Bonus_Coins:findChild("m_lb_coins"):setString( util_formatCoins(self.m_bonusWinCoins,9,nil,nil,true) )
    self.m_Bonus_Coins.coins = self.m_bonusWinCoins
    
    self.m_Bonus_Corn:updateLabelSize({label=self.m_Bonus_Corn:findChild("m_lb_coins"),sx=0.5,sy=0.5},297)
    self.m_Bonus_Coins:updateLabelSize({label=self.m_Bonus_Coins:findChild("m_lb_coins"),sx=0.75,sy=0.75},456)

    local labFreeTimes = self.m_Bonus_FreespinTimes:findChild("font")
    labFreeTimes:setString(self.m_freeGames)
    self:updateLabelSize({label=labFreeTimes,sx=0.9,sy=0.9}, 97)
    self:updateReelsTip(self.m_reel,self.m_nowRow ,self.m_wildReels)

    self:removeAllRoadNode( )
    self:initRoadNode( )
    self:updateBigRoad( isinit)

    self.m_Wheel.m_WinTip:setVisible(false)  
    self.m_Wheel.m_WinTip:runCsbAction("idleframe")
    
 
end

function FarmBonus_View:updateBigRoad( isinit )

    

    if isinit then
        self.m_Bonus_BigRoad_Pink:setVisible(false)
        self.m_Bonus_BigRoad_Yello:setVisible(false)

        for i=1,#self.m_canBack do
            local id = self.m_canBack[i]
            if id == self.m_specialIndex[1] then
                self.m_Bonus_BigRoad_Yello:setVisible(true) 
            else
                self.m_Bonus_BigRoad_Pink:setVisible(true)
            end
        end
    else
        if self.m_canBack  then
            if #self.m_canBack == 1  then
                if self.m_canBack[1] == self.m_specialIndex[1] then
                    if self.m_Bonus_BigRoad_Pink:isVisible() then
                        self.m_Bonus_BigRoad_Pink:runCsbAction("fenHide",false,function(  )
                            self.m_Bonus_BigRoad_Pink:setVisible(false)
                        end)
                    end
                else
                    if self.m_Bonus_BigRoad_Yello:isVisible() then
                        self.m_Bonus_BigRoad_Yello:runCsbAction("huangHide",false,function(  )
                            self.m_Bonus_BigRoad_Yello:setVisible(false)
                        end)
                    end
                    
                end
               
            elseif #self.m_canBack == 0 then

                if self.m_Bonus_BigRoad_Pink:isVisible() then
                    self.m_Bonus_BigRoad_Pink:runCsbAction("fenHide",false,function(  )
                        self.m_Bonus_BigRoad_Pink:setVisible(false)
                    end)
                end
                if self.m_Bonus_BigRoad_Yello:isVisible() then
                    self.m_Bonus_BigRoad_Yello:runCsbAction("huangHide",false,function(  )
                        self.m_Bonus_BigRoad_Yello:setVisible(false)
                    end)
                end
            else

            end
        end
    end
    

end

function FarmBonus_View:updateReelsTip(reelNum,reelRow,wildCols)

    if self.m_ReelsTip then
        self.m_ReelsTip:removeFromParent() 
        self.m_ReelsTip = nil
    end
    local data = {}
    data.m_reelNum = reelNum
    data.m_reelRow = reelRow
    data.m_wildCols = wildCols

    self.m_ReelsTip = util_createView("CodeFarmSrc.FarmBonus_ReelsTipView",data)
    self:findChild("lunpan_tip_end"):addChild(self.m_ReelsTip)

end

function FarmBonus_View:onEnter()
    BaseGame.onEnter(self)
end
function FarmBonus_View:onExit()
    scheduler.unschedulesByTargetName("FarmBonus_View")
    BaseGame.onExit(self)

end


--数据发送
function FarmBonus_View:sendData(pos)

    gLobalSoundManager:playSound("FarmSounds/music_Farm_Bonus_View_click.mp3")
    

    

    BaseGame.sendData(self,pos)

end

--数据接收
function FarmBonus_View:recvBaseData(featureData)

    self.m_action=self.ACTION_RECV

    --数据赋值
    self:updateBonusData( )
    
    self:netBackBeginWheelRun( )

end



--开始结束流程
function FarmBonus_View:gameOver(isContinue)


    if self.p_status=="CLOSED" then

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{nil, GameEffect.EFFECT_BONUS})
    end

    gLobalSoundManager:playSound("FarmSounds/music_Farm_Bonus_end.mp3")

    --默认3秒后弹出结算面板，子类实现
    performWithDelay(self,function(  )
        self:showReward(isContinue)
    end,1.5)

end





--弹出结算奖励
function FarmBonus_View:showReward()

   if self.m_bonusEndCall then
        self.m_bonusEndCall()
   end 
end

function FarmBonus_View:setEndCall( func)
    self.m_bonusEndCall = func
end



function FarmBonus_View:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if self.m_machine then
            self.m_machine:updateResultData(spinData )
        end

        if spinData.action == "FEATURE" then
            self.m_featureData:parseFeatureData(spinData.result)
            self.m_spinDataResult = spinData.result
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



function FarmBonus_View:getMoneyCoins( uiIndex)
    local netindex = uiIndex - 1
    local coins = self.m_roadNetdata[netindex].coins or "000"

    return util_formatCoins(coins,3,nil,nil,true) 

end


function FarmBonus_View:getRoadCsbName(uiIndex )
    local csbPath = nil
    local netindex = uiIndex - 1

    local netRoadType = self.m_roadNetdata[netindex].type
    local nameListIndex = RoadType[netRoadType]
    if netRoadType ==  RoadTypeName.row then
        
        csbPath = self.m_roadCsbNameList[nameListIndex][1]

    elseif netRoadType ==  RoadTypeName.reel then
        csbPath = self.m_roadCsbNameList[nameListIndex][1]

    elseif  netRoadType ==  RoadTypeName.free then
        local netRoadTypeIndex = self.m_roadNetdata[netindex].param
        csbPath =  self.m_roadCsbNameList[nameListIndex][netRoadTypeIndex]

    elseif netRoadType ==  RoadTypeName.money then
        csbPath = self.m_roadCsbNameList[nameListIndex][1]

    elseif netRoadType ==  RoadTypeName.wildReel then
        local wildIndex =  "reel"..uiIndex -- 写死位置 有问题就是服务器的锅
        local netRoadLittleType = wildReelList[wildIndex]
        csbPath = self.m_roadCsbNameList[nameListIndex][netRoadLittleType]

    end



    return csbPath,netRoadType
end

function FarmBonus_View:removeAllRoadNode( )
    for i=1,#self.m_roadNodeList do
        local road =  self.m_roadNodeList[i]
        if road then
            road:removeFromParent()
        end
    end

    self.m_roadNodeList = {}

end


function FarmBonus_View:initRoadNode( )
    
    for i=2,self.m_MaxRoadNum do
        local parNode = self:findChild("road_"..i)
        local csbName,netRoadType = self:getRoadCsbName(i)
        local littleRoad =  util_createView("CodeFarmSrc.FarmBonus_Little_RoadView",csbName)
        parNode:addChild(littleRoad)

        if netRoadType == RoadTypeName.money then
            local coinsNum = littleRoad:findChild("coinsNum")
            if coinsNum then
                local money = self:getMoneyCoins( i)
                coinsNum:setString(money)
            end
        end
        
        table.insert( self.m_roadNodeList, littleRoad )
    end
    

end

function FarmBonus_View:cowRunAct(endIndex,time,beginFunc,endFunc,notTurn )
   if self.m_Cow == nil then
       return
   end 

   if notTurn then
       
   else
        if endIndex >=8 and endIndex <= 21 then
            self.m_Cow:setScaleX(-1)
        else

            self.m_Cow:setScaleX(1)
        end
   end
   
   
   local moveTimes = time


   local roadNodeName = "road_" .. endIndex
   if endIndex == 30 then
        roadNodeName = "lunpan_tip_end"
   end
   local endPos = cc.p(self:findChild(roadNodeName):getPosition()) 

   local actionList = {}
   actionList[#actionList + 1] = cc.CallFunc:create(function(  )

        if beginFunc then
            beginFunc()
        end
   end)
   actionList[#actionList + 1] = cc.MoveTo:create(moveTimes,endPos)
   actionList[#actionList + 1] = cc.CallFunc:create(function(  )

        if endFunc then
            endFunc()
        end
    end)
    
    local sq = cc.Sequence:create(actionList)
    self:findChild("niu"):runAction(sq) 

end

function FarmBonus_View:backCowbeginRun(endindex,func )

    gLobalSoundManager:playSound("FarmSounds/music_Farm_Bonus_cow_backRun.mp3")

    
    -- 牛移动
    local time = 1
    self.m_nowIndex = endindex

    util_spinePlay(self.m_Cow.m_CowSpineNode,"actionframe",true)

    local runEndFunc = function(  )
        util_spinePlay(self.m_Cow.m_CowSpineNode,"idleframe",true)
        print("走完了 hui 回调")
        if func then
            func()
        end
    end

    if self.m_nowNetIndex == self.m_backIndex[1]  then
        self.m_Cow:setScaleX(1)
    end
    



    self:cowRunAct((endindex + 1),time,nil,function(  )
        if self.m_nowNetIndex ~= self.m_backIndex[1] then
            self.m_Cow:setScaleX(-1)
        end

        if runEndFunc then
            runEndFunc()
        end
    end,true)

        

end

function FarmBonus_View:backCowbeginRunToOnePos( endpos, func )

   local Cowrun =  gLobalSoundManager:playSound("FarmSounds/music_Farm_Bonus_cow_Run.mp3",true)

    -- 牛移动
    local time = 0.5
    local endindex = endpos + 1
    local beginindex = self.m_nowIndex + 1

    if beginindex == endindex then

        if Cowrun then
            gLobalSoundManager:stopAudio(Cowrun)
            Cowrun = nil
        end

        if func then
           func()
        end

        return
    end

    util_spinePlay(self.m_Cow.m_CowSpineNode,"actionframe",true)

    for i = beginindex ,endindex do
        local runEndFunc = nil
        if i == endindex then
            runEndFunc = function(  )
                util_spinePlay(self.m_Cow.m_CowSpineNode,"idleframe",true)
                print("走完了 hui 回调")
                if Cowrun then
                    gLobalSoundManager:stopAudio(Cowrun)
                    Cowrun = nil
                end

                if func then
                   func()
                end
            end
        end
        performWithDelay(self,function(  )
            self:cowRunAct(i,time,nil,function(  )
                if runEndFunc then
                    runEndFunc()
                end
            end)
        end,(i - beginindex)*time)
        
    end
end


function FarmBonus_View:cowbeginRun( func )

    local Cowrun =  gLobalSoundManager:playSound("FarmSounds/music_Farm_Bonus_cow_Run.mp3",true)

     -- 牛移动
     local time = 0.5
     local endindex = self.m_nowNetIndex + 1
     local beginindex = self.m_nowIndex + 1
     self.m_nowIndex = self.m_nowNetIndex

     if beginindex == endindex then
        if Cowrun then
            gLobalSoundManager:stopAudio(Cowrun)
            Cowrun = nil
        end

         if func then
            func()
         end

         return
     end
 
     util_spinePlay(self.m_Cow.m_CowSpineNode,"actionframe",true)
 
     for i = beginindex ,endindex do
         local runEndFunc = nil
         if i == endindex then
             runEndFunc = function(  )
                 util_spinePlay(self.m_Cow.m_CowSpineNode,"idleframe",true)
                 print("走完了 hui 回调")

                if Cowrun then
                    gLobalSoundManager:stopAudio(Cowrun)
                    Cowrun = nil
                end

                 if func then
                    func()
                 end
             end
         end
         performWithDelay(self,function(  )
             self:cowRunAct(i,time,nil,function(  )
                 if runEndFunc then
                     runEndFunc()
                 end
             end)
         end,(i - beginindex)*time)
         
     end
end

function FarmBonus_View:setWheelCanTouch(  )

    if self.m_IsAutoStates then
        self:AutoSendDate( )
        self.m_Wheel:setSpinBtnCanTouch()
        self.m_Wheel:setSpinBtnClickCallFunc(function(  )
            print(" 啥也不干 ！！！！！  ")
        end )
    else
        self.m_Wheel:setSpinBtnCanTouch()
        self.m_Wheel:setSpinBtnClickCallFunc(function(  )
            print(" 发送网络信息 ！！！！！  ")
            self:sendData()
    
            self.m_Wheel:setSpinBtnNotCanTouch()
        end )
    end
 
end

function FarmBonus_View:cowRunThisTime( )
    
    if type(self.p_contents[self.p_chose + 1] ) ~= "number" then
        return true
    end

    return false
end

-- 网络消息回来之后开始转盘滚动
function FarmBonus_View:netBackBeginWheelRun( )

    

    local data = {}
    data.choose = self.p_chose
    data.endCallBack = function(  )
        print("滚完了   -- 开始滚完了的逻辑")

        if self:cowRunThisTime( ) then

            
            if self.m_back then
                -- 倒着牛走
                self:backCowRun( )
            else
               -- 正常 牛走
                self:normalCowRun( ) 
            end

            

        else
            self:AddCornFlyParticle( 
                self:findChild("zhuanpan"),
                self:findChild("yumi_zi"),
                function(  )
                    self:updateBonusView( )
                    self:setWheelCanTouch(  )
                end 
            )
        end
        

        
    end
    self.m_Wheel:beginWheel( data )
end

function FarmBonus_View:getbackPosCoins( pos )
    
end

function FarmBonus_View:backCowRun( )

    local backpos = nil
    if self.m_nowNetIndex == self.m_backIndex[1] then
        backpos = self.m_specialIndex[1]
    else
        backpos = self.m_specialIndex[2]
    end
    
    

    self:backCowbeginRunToOnePos( backpos,function(  )


        

        local oldCoins = self.m_Bonus_Coins.coins + self.m_roadNetdata[backpos].coins 

        self:AddMoneyFlyParticle( self:findChild("niu"),self:findChild("win"),function(  )
            self.m_CoinsEndActiom:showAct()
            
            self.m_Bonus_Coins:findChild("m_lb_coins"):setString( util_formatCoins(oldCoins,9,nil,nil,true) )
            self.m_Bonus_Coins.coins = oldCoins
            self.m_Bonus_Coins:updateLabelSize({label=self.m_Bonus_Coins:findChild("m_lb_coins"),sx=0.75,sy=0.75},456)

            performWithDelay(self,function(  )

                

                self:backCowbeginRun(self.m_nowNetIndex,function(  )
                    if self.m_selectType ==  "free" then
                        self:AddFsFlyParticle( self:findChild("niu"),self:findChild("freegames"),function(  )
                            self:updateBonusView( )
                            self:cowAlReadyRunEnd( )
                        end,self:getAddAngleNum( ) )
                        
                    elseif self.m_selectType ==  "wildReel" 
                    or self.m_selectType ==  "row" 
                        or self.m_selectType ==  "reel" then
                            
                            self:AddReelsTipFlyParticle( self:findChild("niu"),self:findChild("lunpan_tip_end"),function(  )
                                self:updateBonusView( )
                                self:cowAlReadyRunEnd( )
                            end,self:getAddAngleNum( ) ) 
            
                    elseif self.m_selectType ==  "money" then
                        self:AddMoneyFlyParticle( self:findChild("niu"),self:findChild("win"),function(  )
                            self.m_CoinsEndActiom:showAct()
                            self:updateBonusView( )
                            self:cowAlReadyRunEnd( )
                        end,self:getAddAngleNum( ) ) 
                        
                    else
                        self:updateBonusView( )
                        self:cowAlReadyRunEnd( )
                    end
                end )
            end,1)

        end,self:getAddAngleNum( ) ,true,backpos, util_formatCoins(self.m_roadNetdata[backpos].coins,3,nil,nil,true) ) 


        

    end )
end

function FarmBonus_View:getAddAngleNum( )
    local anglenum = 0
    if self.m_nowIndex then
        if self.m_nowIndex > 20 then
            anglenum = 10
        end
    end

    return anglenum
end


function FarmBonus_View:normalCowRun( )
    self:cowbeginRun( function(  )

        if self.m_selectType ==  "free" then
            self:AddFsFlyParticle( self:findChild("niu"),self:findChild("freegames"),function(  )
                self:updateBonusView( )
                self:cowAlReadyRunEnd( )
            end,self:getAddAngleNum( ) )

        elseif self.m_selectType ==  "wildReel" 
            or self.m_selectType ==  "row" 
                or self.m_selectType ==  "reel" then
                    
                    self:AddReelsTipFlyParticle( self:findChild("niu"),self:findChild("lunpan_tip_end"),function(  )
                        self:updateBonusView( )
                        self:cowAlReadyRunEnd( )
                    end,self:getAddAngleNum( ) )    

        elseif self.m_selectType ==  "money" then
            self:AddMoneyFlyParticle( self:findChild("niu"),self:findChild("win"),function(  )
                self.m_CoinsEndActiom:showAct()
                self:updateBonusView( )
                self:cowAlReadyRunEnd( )
            end,self:getAddAngleNum( ) ) 
        else
            self:updateBonusView( )
            self:cowAlReadyRunEnd( )
        end

        
    end )
end



function FarmBonus_View:cowAlReadyRunEnd( )

    if self.p_status == "CLOSED" then
        -- 最后一次 牛走 到结束
        self.m_nowNetIndex = 29

        self:cowbeginRun( function(  )
            self:gameOver()
        end )
    else
        self:setWheelCanTouch(  )
    end
  
end


function FarmBonus_View:AddMoneyFlyParticle( startNode,endNode,func,anglenum ,isback,index,str)

    gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_flying.mp3")

    local times = 0.7
    local flyParticle = util_createView("CodeFarmSrc.FarmBonus_AddFsPartacleView")   
    flyParticle:starFly(times)
    self:addChild(flyParticle,1)
    local startPos = cc.p(util_getConvertNodePos(startNode,flyParticle))
    flyParticle:setPosition(startPos)

    local roadInfoNode = cc.Node:create()
    if isback then
        self:createFlyRoadInfoNodeBack( roadInfoNode,index,str)
    else
        self:createFlyRoadInfoNode( roadInfoNode)
    end
    
    flyParticle:addChild(roadInfoNode)

    local endPos = cc.p(util_getConvertNodePos(endNode,flyParticle))

    local animation = {}
    -- animation[#animation + 1] = cc.MoveTo:create(times, cc.p(endPos))
    local angle = 85 + anglenum
    local height = 10
	local radian = angle*math.pi/180
	local q1x = startPos.x+(endPos.x - startPos.x)/4
      local q1 = cc.p(q1x, height + startPos.y+math.cos(radian)*q1x)
	local q2x = startPos.x + (endPos.x - startPos.x)/2.0
	local q2 = cc.p(q2x*1.2, height + startPos.y+math.cos(radian)*q2x)
    animation[#animation + 1] = cc.EaseInOut:create(cc.BezierTo:create(times,{q1,q2,endPos}),1)

    animation[#animation + 1] = cc.CallFunc:create(function(  )

            roadInfoNode:setVisible(false)

            gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_fly_end.mp3")
    
            if func then
                func()
            end
            
    end)
    animation[#animation + 1] = cc.DelayTime:create(times)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        flyParticle:removeFromParent()
        flyParticle = nil
    end)

    flyParticle:runAction(cc.Sequence:create(animation))

end

function FarmBonus_View:AddReelsTipFlyParticle( startNode,endNode,func,anglenum )
    gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_flying.mp3")

    local times = 0.7
    local flyParticle = util_createView("CodeFarmSrc.FarmBonus_AddFsPartacleView")   
    flyParticle:starFly(times)
    self:addChild(flyParticle,1)
    local startPos = cc.p(util_getConvertNodePos(startNode,flyParticle))
    flyParticle:setPosition(startPos)

    local roadInfoNode = cc.Node:create()
    self:createFlyRoadInfoNode( roadInfoNode)
    flyParticle:addChild(roadInfoNode)

    local endPos = cc.p(util_getConvertNodePos(endNode,flyParticle))

    local animation = {}
    -- animation[#animation + 1] = cc.MoveTo:create(times, cc.p(endPos))
    local angle = 85 + anglenum
    local height = 10
	local radian = angle*math.pi/180
	local q1x = startPos.x+(endPos.x - startPos.x)/4
      local q1 = cc.p(q1x, height + startPos.y+math.cos(radian)*q1x)
	local q2x = startPos.x + (endPos.x - startPos.x)/2.0
	local q2 = cc.p(q2x*1.2, height + startPos.y+math.cos(radian)*q2x)
    animation[#animation + 1] = cc.EaseInOut:create(cc.BezierTo:create(times,{q1,q2,endPos}),1)

    animation[#animation + 1] = cc.CallFunc:create(function(  )

            gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_fly_end.mp3")

            roadInfoNode:setVisible(false)
            -- 反馈
            local ReelsTip_FanKui = util_createView("CodeFarmSrc.FarmBonus_ReelsTip_FanKui_View")
            self:findChild("lunpan_tip_end"):addChild(ReelsTip_FanKui,10)
            ReelsTip_FanKui:runCsbAction("actionframe",false,function(  )
                ReelsTip_FanKui:findChild("Particle_1"):resetSystem()
                ReelsTip_FanKui:runCsbAction("actionframe1",false,function(  )

                    ReelsTip_FanKui:removeFromParent()
                end)
            end)
            

        

            if func then
                func()
            end
            
    end)
    animation[#animation + 1] = cc.DelayTime:create(times)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        flyParticle:removeFromParent()
        flyParticle = nil
    end)

    flyParticle:runAction(cc.Sequence:create(animation))

end

function FarmBonus_View:AddFsFlyParticle( startNode,endNode,func,anglenum)

    gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_flying.mp3")

    local times = 0.7
    local flyParticle = util_createView("CodeFarmSrc.FarmBonus_AddFsPartacleView")   
    flyParticle:starFly(times)
    self:addChild(flyParticle,1)
    local startPos = cc.p(util_getConvertNodePos(startNode,flyParticle))
    flyParticle:setPosition(startPos)

    local roadInfoNode = cc.Node:create()
    self:createFlyRoadInfoNode( roadInfoNode)
    flyParticle:addChild(roadInfoNode)
    -- endNode 都是 freegames节点
    local endPos = cc.p(util_getConvertNodePos(endNode,flyParticle))
    endPos.x = endPos.x -95
    local animation = {}
    -- animation[#animation + 1] = cc.MoveTo:create(times, cc.p(endPos))
    local angle = 85 + anglenum
    local height = 10
	local radian = angle*math.pi/180
	local q1x = startPos.x+(endPos.x - startPos.x)/4
      local q1 = cc.p(q1x, height + startPos.y+math.cos(radian)*q1x)
	local q2x = startPos.x + (endPos.x - startPos.x)/2.0
	local q2 = cc.p(q2x*1.2, height + startPos.y+math.cos(radian)*q2x)
    animation[#animation + 1] = cc.EaseInOut:create(cc.BezierTo:create(times,{q1,q2,endPos}),1)
    
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        roadInfoNode:setVisible(false)

        gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_fly_end.mp3")

        -- 反馈
        self.m_Bonus_FreespinTimes:runCsbAction("actionframe",false,function(  )
            self.m_Bonus_FreespinTimes:runCsbAction("idle",true)
        end)

            if func then
                func()
            end
            
    end)
    animation[#animation + 1] = cc.DelayTime:create(times)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        flyParticle:removeFromParent()
        flyParticle = nil
    end)

    flyParticle:runAction(cc.Sequence:create(animation))

end

function FarmBonus_View:AddCornFlyParticle( startNode,endNode,func)

    gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_flying.mp3")

    local times = 0.7
    local flyParticle = util_createView("CodeFarmSrc.FarmBonus_AddFsPartacleView")   
    flyParticle:starFly(times)
    self:addChild(flyParticle,1)
    local startPos = cc.p(util_getConvertNodePos(startNode,flyParticle))
    flyParticle:setPosition(startPos)

    local roadInfoNode = cc.Node:create()
    self:createFlyCornInfoNode( roadInfoNode)
    flyParticle:addChild(roadInfoNode)

    local endPos = cc.p(util_getConvertNodePos(endNode,flyParticle))
    endPos.y = endPos.y - 10
    local animation = {}
    -- animation[#animation + 1] = cc.MoveTo:create(times, cc.p(endPos))

    local angle = 75 
    local height = 10
	local radian = angle*math.pi/180
	local q1x = startPos.x+(endPos.x - startPos.x)/4
      local q1 = cc.p(q1x, height + startPos.y+math.cos(radian)*q1x)
	local q2x = startPos.x + (endPos.x - startPos.x)/2.0
	local q2 = cc.p(q2x*1.2, height + startPos.y+math.cos(radian)*q2x)
    animation[#animation + 1] = cc.EaseInOut:create(cc.BezierTo:create(times,{q1,q2,endPos}),1)

    animation[#animation + 1] = cc.CallFunc:create(function(  )
        roadInfoNode:setVisible(false)

        gLobalSoundManager:playSound("FarmSounds/music_Farm_Particle_fly_end.mp3")
            
        -- 谷仓跳 --22.08.05策划移除谷仓
        -- util_spinePlay(self.m_Bonus_Barn.m_BarnSpineNode,"actionframe",false)
        self.m_Bonus_Corn:runCsbAction("actionframe")

        if func then
            func()
        end
    end)

    animation[#animation + 1] = cc.DelayTime:create(times)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        flyParticle:removeFromParent()
        flyParticle = nil

        
    end)

    flyParticle:runAction(cc.Sequence:create(animation))

    

end



function FarmBonus_View:createLocalAnimation( )
    local pos = cc.p(self.m_Bonus_Coins:findChild("m_lb_coins"):getPosition()) 
    
    self.m_CoinsEndActiom =  util_createView("CodeFarmSrc.FarmViewWinCoinsAction")
    self.m_Bonus_Coins:findChild("m_lb_coins"):getParent():addChild(self.m_CoinsEndActiom,9999999)
    self.m_CoinsEndActiom:setPosition(cc.p(pos.x ,pos.y))

    self.m_CoinsEndActiom:setVisible(false)
end

function FarmBonus_View:createFlyCornInfoNode( roadInfoNode)
    local csbName = "Farm_yumi_geshu_0"
    local littleRoad =  util_createView("CodeFarmSrc.FarmBonus_Little_RoadView",csbName)
    roadInfoNode:addChild(littleRoad)


end

function FarmBonus_View:getOldRoadViewCsbName( index)
    local name = nil
    local coins = nil
    for i=1,#self.m_roadNodeList do
        local road = self.m_roadNodeList[i]
        if i == index then
            local coinsNum = road:findChild("coinsNum")
            if coinsNum then
                
                return road.m_oldCsbName,coinsNum:getString()
            else
                return road.m_oldCsbName
            end
            
        end
    end 

end

function FarmBonus_View:createFlyRoadInfoNode( roadInfoNode)

    local csbName,coinsNumStr = self:getOldRoadViewCsbName( self.m_nowNetIndex )
    local littleRoad =  util_createView("CodeFarmSrc.FarmBonus_Little_RoadView",csbName)
    roadInfoNode:addChild(littleRoad)

    if coinsNumStr then
        local coinsNum = littleRoad:findChild("coinsNum")
        if coinsNum then
            local money = coinsNumStr
            coinsNum:setString(money)
        end
    end

end

function FarmBonus_View:createFlyRoadInfoNodeBack( roadInfoNode,index,str)

    local csbName,coinsNumStr = self:getOldRoadViewCsbName( index )
    local littleRoad =  util_createView("CodeFarmSrc.FarmBonus_Little_RoadView",csbName)
    roadInfoNode:addChild(littleRoad)

    if coinsNumStr then
        local coinsNum = littleRoad:findChild("coinsNum")
        if coinsNum then
            local money = str or coinsNumStr
            coinsNum:setString(money)
        end
    end

end

return FarmBonus_View