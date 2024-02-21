---
--xcyy
--2018年5月23日
--ManicMonsterJackpotGameMainView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local ManicMonsterJackpotGameMainView = class("ManicMonsterJackpotGameMainView",BaseGame )

ManicMonsterJackpotGameMainView.m_machine = nil
ManicMonsterJackpotGameMainView.m_bonusEndCall = nil

ManicMonsterJackpotGameMainView.m_MaxJPChestNum = 12
ManicMonsterJackpotGameMainView.m_startAction = false

function ManicMonsterJackpotGameMainView:initUI(machine)

    
    self.m_machine = machine

    self:createCsbNode("ManicMonster/BonusGame.csb")

    self.m_jpGameBg = util_createAnimation("ManicMonster_bonus_bg.csb") 
    self:findChild("ManicMonster_bonus_bg"):addChild(self.m_jpGameBg)

    self.m_jpGameMan = util_spineCreate("ManicMonster_Jackpot_juese",true,true)
    self:findChild("ManicMonster_bonus_bg2"):addChild(self.m_jpGameMan)
    self.m_jpGameMan:setPositionY(-20)

    util_spinePlay(self.m_jpGameMan,"idleframe",true)

    self.m_tipView = util_createAnimation("ManicMonster_bonus_biaoti.csb") 
    self:findChild("ManicMonster_bonus_1"):addChild(self.m_tipView)
    
    self.m_bonusStartView = util_createAnimation("ManicMonster/BonusGameOver.csb") 
    self:findChild("Node_showClick"):addChild(self.m_bonusStartView)
    self.m_bonusStartView:setVisible(false)
    self.m_bonusStartView:setPosition(-display.width/2,-display.height / 2 )
    
    

    self:initJPChest( )

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)
  
end

function ManicMonsterJackpotGameMainView:setJPChestClickVisible( _isShow )

    for i=1,self.m_MaxJPChestNum do

        local JPChest = self["JPChest_" .. i] 
        JPChest:findChild("click"):setVisible(_isShow)

    end

end

function ManicMonsterJackpotGameMainView:initJPChest( )

    
    
    for i=1,self.m_MaxJPChestNum do

        local data = {}
        data.index = i - 1 
        data.machine = self
        
        local JPChest = util_createView("CodeManicMonsterSrc.ManicMonsterJackpotGameClickView",data)  
        self:findChild("Node_"..data.index):addChild(JPChest,i)
        self["JPChest_" .. i] = JPChest
        JPChest:findChild("click"):setVisible(false)
        JPChest:runCsbAction("idle")
        

       
    end

end
function ManicMonsterJackpotGameMainView:showStartAction( )
    
    


    for i=1,self.m_MaxJPChestNum do
        local JPChest = self["JPChest_" .. i]
        JPChest:runCsbAction("actionframe")
    end


    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        waitNode:removeFromParent()

        self:updateBulingAct()

        self.m_startAction = false

    end,42/30)
    
end

function ManicMonsterJackpotGameMainView:runTwoSameImgAct( clickJpType  )
    
    

    for i=1,self.m_MaxJPChestNum do
        local JPChest = self["JPChest_" .. i]
        if JPChest.m_clickJpType then
            if clickJpType == JPChest.m_clickJpType then
                if JPChest.m_ShowImg then
                    JPChest.m_ShowImg:runCsbAction("idle3",true)
                end
                
            end
        end
            
    end

end

function ManicMonsterJackpotGameMainView:showWinJpAct( clickJpType,func)

    -- 停掉背景音乐
    self.m_machine:clearCurMusicBg()
    
    gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_BonusGame_End.mp3")

    for i=1,self.m_MaxJPChestNum do
        local JPChest = self["JPChest_" .. i]
        local JPChest = self["JPChest_" .. i]
        if JPChest.m_clickJpType then
            if clickJpType == JPChest.m_clickJpType then
                if JPChest.m_ShowImg then
                    JPChest.m_ShowImg:runCsbAction("actionframe2")
                end
                
            end
        end
            
    end

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,(60 + 15 )/30)
end

function ManicMonsterJackpotGameMainView:stopTwoSameImgAct( )
    for i=1,self.m_MaxJPChestNum do
        local JPChest = self["JPChest_" .. i]
        if JPChest.m_ShowImg then
            JPChest.m_ShowImg:runCsbAction("idle4")
        end
            
    end
end

function ManicMonsterJackpotGameMainView:restJackpotGameShowUI(  )

    self:runCsbAction("idle")

    util_spinePlay(self.m_jpGameMan,"idleframe",true)
    
    for i=1,self.m_MaxJPChestNum do
        local JPChest = self["JPChest_" .. i]
        self["JPChest_" .. i].m_clickJpType = nil
        self["JPChest_" .. i].m_ShowImg = nil
        JPChest:runCsbAction("idle")
        JPChest:findChild("jp_actNode"):removeAllChildren()
        
    end

    self:setJPChestClickVisible( false )

end


function ManicMonsterJackpotGameMainView:addJpShowImg(jpIdleNode,jpType )
    

    local csbName = nil
    if jpType == "GRAND" then
        csbName = "grand"
    elseif jpType == "MAJOR" then
        csbName = "major"
    elseif jpType == "MINOR" then
        csbName = "minor"
    elseif jpType == "MINI" then
        csbName = "mini"

    end

    local showImg = util_createAnimation("ManicMonster_bonus_"..csbName .. ".csb")
    jpIdleNode:findChild("jp_actNode"):addChild(showImg)
    

    return showImg
end


function ManicMonsterJackpotGameMainView:isCanTouch( )
    
    if self.m_startAction then
        return false
    end

    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
    
end

function ManicMonsterJackpotGameMainView:setClickData( pos )
    

    self:stopAllBulingNode()

    gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_Click_DianZha.mp3")

    table.insert( self.p_choose , pos )

    self.m_action = self.ACTION_SEND

    self:recvLocalBaseData()

end

function ManicMonsterJackpotGameMainView:onEnter()
    BaseGame.onEnter(self)
end
function ManicMonsterJackpotGameMainView:onExit()
    scheduler.unschedulesByTargetName("ManicMonsterJackpotGameMainView")
    BaseGame.onExit(self)

end

--数据发送
function ManicMonsterJackpotGameMainView:sendData(pos)

    
    self.m_action = self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        messageData={msg=MessageDataType.MSG_BONUS_COLLECT , data= self.m_collectDataList}
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)

end

function ManicMonsterJackpotGameMainView:changeActImg(clickJpType )
    
    local shouJiName = {"Grand_shouji","Major_shouji" , "Minor_shouji","Mini_shouji"}
    for i=1,#shouJiName do
        local img = self:findChild(shouJiName[i]) 
        if img then

            img:setVisible(false)   

            if clickJpType == "GRAND" then
                if i == 1 then
                    img:setVisible(true) 
                end    
            elseif clickJpType == "MAJOR" then
                if i == 2 then
                    img:setVisible(true) 
                end
            elseif clickJpType == "MINOR" then
                if i == 3 then
                    img:setVisible(true) 
                end
            elseif clickJpType == "MINI" then
                if i == 4 then
                    img:setVisible(true) 
                end
            end

                     
        end
    end

end

function ManicMonsterJackpotGameMainView:getJpPointNode( clickJpType)
   
    local GrandNum,MajorNum,MinorNum,MiniNum = self:getJpNum( )

    if clickJpType then
        if clickJpType == "GRAND" then

            return self.m_machine.m_jackpotBar.m_grandBan["jp_dian_"..GrandNum],GrandNum,self.m_machine.m_jackpotBar.m_grandBan
            
        elseif clickJpType == "MAJOR" then

            return self.m_machine.m_jackpotBar.m_majorBan["jp_dian_"..MajorNum],MajorNum,self.m_machine.m_jackpotBar.m_majorBan

        elseif clickJpType == "MINOR" then

            return self.m_machine.m_jackpotBar.m_minorBan["jp_dian_"..MinorNum],MinorNum,self.m_machine.m_jackpotBar.m_minorBan

        elseif clickJpType == "MINI" then

            return self.m_machine.m_jackpotBar.m_miniBan["jp_dian_"..MiniNum],MiniNum,self.m_machine.m_jackpotBar.m_miniBan

        end
    end

end

function ManicMonsterJackpotGameMainView:showWinJpBan( clickJpType )
    if clickJpType then
        if clickJpType == "GRAND" then

            self.m_machine.m_jackpotBar.m_grandBan:runCsbAction("shouji")
            
        elseif clickJpType == "MAJOR" then

            self.m_machine.m_jackpotBar.m_majorBan:runCsbAction("shouji")

        elseif clickJpType == "MINOR" then

            self.m_machine.m_jackpotBar.m_minorBan:runCsbAction("shouji")

        elseif clickJpType == "MINI" then

            self.m_machine.m_jackpotBar.m_miniBan:runCsbAction("shouji")

        end
    end
end

-- 本地数据处理
function ManicMonsterJackpotGameMainView:recvLocalBaseData()
    
    local clickPos = self.p_choose[#self.p_choose]
    local clickJpType = self.p_content[#self.p_choose] or "MINI"
    release_print("暂时屏蔽")

    local jpPointNode,jpPointNum,jpBan = self:getJpPointNode( clickJpType)
    
    local JPchest =  self["JPChest_" .. clickPos + 1] 
    JPchest.m_ShowImg = self:addJpShowImg(JPchest,clickJpType )
    JPchest.m_ShowImg:findChild("Node_dark"):setVisible(false)
    JPchest.m_ShowImg:runCsbAction("switch")
    JPchest.m_clickJpType = clickJpType
    JPchest:runCsbAction("switch")

    self:changeActImg(clickJpType )
    
    local choose = clone(self.p_choose) 
    local content = clone(self.p_content) 

    if #choose == #content then

    else
        self.m_action = self.ACTION_RECV
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        self:runCsbAction("idle2",false,function(  )
            
            


            
            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_JpMan_ChanDou.mp3")

            util_spinePlay(self.m_jpGameMan,"actionframe",true)

            self:runCsbAction("actionframe",false,function(  )
            
                self:showWinJpBan( clickJpType )

                
                
                gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_JpMan_DianLiu_ShouDao_jackpotBar.mp3")

                self:runCsbAction("over2",false,function(  )

                    self:runCsbAction("over")

                    performWithDelay(waitNode,function(  )
                        waitNode:removeFromParent()
                        
                        if clickJpType == "GRAND" then

                            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_jpPointNode_Grand.mp3")
                            
                        elseif clickJpType == "MAJOR" then
                
                            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_jpPointNode_Major.mp3")
                
                        elseif clickJpType == "MINOR" then
                
                            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_jpPointNode_Minor.mp3")
                
                        elseif clickJpType == "MINI" then
                
                            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_jpPointNode_Mini.mp3")
                
                        end
                       
                        jpPointNode:setVisible(true)
                        jpPointNode:runCsbAction("start",false,function(  )
                            
                            if jpPointNum == 2 then
                                jpBan:runCsbAction("idle2",true)
                                self:runTwoSameImgAct( clickJpType  )
                            end


                            if #choose== #content then

                                gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_JpMan_TuiFei.mp3")
            
                                util_spinePlay(self.m_jpGameMan,"actionframe2",false)
                                util_spineEndCallFunc(self.m_jpGameMan,"actionframe2",function(  )
                                    util_spinePlay(self.m_jpGameMan,"idleframe2",true)
                                end)
            

                                -- 结束游戏,显示其他未点击的
                                self:showOtherJPChest(clickJpType)
                            else
                  
                                util_spinePlay(self.m_jpGameMan,"idleframe",true)
                            end

                            
                            
                        end)

                    end,6/30)

                    

                end)

            end)

        end)

        
        

    end,24/30)

    

end

--数据接收 只用作一进bonus向服务器请求最终数据
function ManicMonsterJackpotGameMainView:recvBaseData(featureData)


    local bonusdata =  featureData.p_bonus or {}
    self.p_content = bonusdata.content or {}
    self.p_choose =  {}
    self.p_status = bonusdata.status or "OPEN"
    self.p_extra = bonusdata.extra or {}
    local p_data = featureData.p_data or {}
    local selfData = p_data.selfData or {}
    self.p_rewordJpType = selfData.jackpot

    self.m_action = self.ACTION_RECV

    self:setJPChestClickVisible( true )
    
end


function ManicMonsterJackpotGameMainView:checkIsOver( )
    local bonusStatus = self.p_status 

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end

function ManicMonsterJackpotGameMainView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end



function ManicMonsterJackpotGameMainView:showOtherJPChest(clickJpType )

    self:stopTwoSameImgAct( )

    self.m_machine.m_jackpotBar:hidAllJpBan( )
    
    self:runCsbAction("idle3")

    local displayData = self.p_extra.displayData
    
    local rewardNum = 0
    for i=1,self.m_MaxJPChestNum do
        local JPchest =  self["JPChest_" .. i] 

        local index = i -1
        if JPchest.m_clickJpType and JPchest.m_clickJpType ~= clickJpType then
            JPchest.m_ShowImg:findChild("Node_dark"):setVisible(true)
            JPchest:runCsbAction("over")
        end

        if not self:isInArray( self.p_choose,index ) then
            rewardNum = rewardNum + 1
            local rewardtype = displayData[rewardNum] 
            
            
            JPchest.m_ShowImg = self:addJpShowImg(JPchest,rewardtype )
            JPchest.m_ShowImg:runCsbAction("over")
            JPchest:runCsbAction("over")
        end

    end

    
    self:showWinJpAct( clickJpType,function(  )
        if self.m_bonusEndCall then
            self.m_bonusEndCall()
            self.m_bonusEndCall = nil
        end
    end)

    

    


end


--开始结束流程
function ManicMonsterJackpotGameMainView:gameOver(isContinue)

end

--弹出结算奖励
function ManicMonsterJackpotGameMainView:showReward()

   
end

function ManicMonsterJackpotGameMainView:setEndCall( func)
    self.m_bonusEndCall = function(  )
            
        self.m_machine:showBonusOverView( self.m_serverWinCoins,self.p_rewordJpType , function(  )

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



function ManicMonsterJackpotGameMainView:featureResultCallFun(param)

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


function ManicMonsterJackpotGameMainView:showBonusStartView(func )


    self.m_bonusStartView:setVisible(true)
    self.m_bonusStartView:runCsbAction("auto",false,function(  )
        self.m_bonusStartView:setVisible(false)
        if func then
            func()
        end
    end)

end

function ManicMonsterJackpotGameMainView:getJpNum( )
    
    local GrandNum,MajorNum,MinorNum,MiniNum = 0,0,0,0


    for i=1,#self.p_content do
        if i <= #self.p_choose then
            local jpType = self.p_content[i]
            if jpType == "GRAND" then
                GrandNum = GrandNum + 1
            
            elseif jpType == "MAJOR" then
                MajorNum = MajorNum + 1
            elseif jpType == "MINOR" then
                MinorNum = MinorNum + 1
            elseif jpType == "MINI" then
                MiniNum = MiniNum + 1
            end
        end
        
    end
    
    return GrandNum,MajorNum,MinorNum,MiniNum
end

function ManicMonsterJackpotGameMainView:updateBulingAct( )
    self.m_actNode:stopAllActions()

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    waitNode:removeFromParent()

    

    self:beginBulingAct( )

    util_schedule(self.m_actNode, function(  )
        self:beginBulingAct( )

    end, 2)
end

function ManicMonsterJackpotGameMainView:stopAllBulingNode( )
    
    self.m_actNode:stopAllActions()

    for i=1,self.m_MaxJPChestNum do
       
        local node =  self["JPChest_"..i]

        if node.m_falsh then
            node.m_falsh:setVisible(false)
        end

    end

end

function ManicMonsterJackpotGameMainView:beginBulingAct( )
    
 
    local actNode = self:getNextBulingNode( )  
    for i=1,#actNode do
        if actNode[i] then
            local node = actNode[i]
            if node.m_falsh then
                node.m_falsh:setVisible(true)
                node.m_falsh:runCsbAction("animation0",false,function(  )
                    node.m_falsh:setVisible(false)
                end)
            end
            
        end
    end      
        


end

function ManicMonsterJackpotGameMainView:getNextBulingNode( )

    local actList = {}
    local currNode = {}

    for i=1,self.m_MaxJPChestNum do
       
        local node =  self["JPChest_"..i]

        table.insert(actList,i)

    end


    local roadNum = math.random(1,3)

    for i=1,roadNum do
        local index_1 = math.random(1,#actList) 
        currNode[#currNode + 1] = self["JPChest_"..actList[index_1]]
        table.remove(actList,index_1)
    end


    

    return currNode
end

return ManicMonsterJackpotGameMainView