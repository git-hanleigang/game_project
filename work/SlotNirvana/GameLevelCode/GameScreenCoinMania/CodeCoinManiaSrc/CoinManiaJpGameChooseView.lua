---
--xcyy
--2018年5月23日
--CoinManiaJpGameChooseView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local CoinManiaJpGameChooseView = class("CoinManiaJpGameChooseView",BaseGame )

CoinManiaJpGameChooseView.m_machine = nil
CoinManiaJpGameChooseView.m_bonusEndCall = nil
CoinManiaJpGameChooseView.m_JpMultiply = 1
CoinManiaJpGameChooseView.m_MaxChestNum = 18
CoinManiaJpGameChooseView.m_pigNum = 0
CoinManiaJpGameChooseView.m_JpSymbolNumList = {0,0,0,0}

local PigType = "Mega"
local ManType = "Grand"
local WuShiType = "Major"
local GuShiType = "Minor"
local LuoType = "Mini"

local CaiType = "None"

function CoinManiaJpGameChooseView:initUI(machine)

    
    self.m_machine = machine
    

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("CoinMania/GameScreenCoinMania_jackpot_wanfa.csb")


    
    self:initJpSymbol( )


    self.m_JackPotBar = util_createView("CodeCoinManiaSrc.CoinManiaJpGameJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotBar)
    self.m_JackPotBar:initMachine(self.m_machine)


    self.m_loadingBar = util_createView("CodeCoinManiaSrc.CoinManiaJpGameLoadingBarView",self)
    self.m_JackPotBar:findChild("Node_Loading"):addChild(self.m_loadingBar)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

    self.m_JackPotBar:findChild("Node_Loading"):setLocalZOrder(1)
    self.m_JackPotBar:findChild("Node_down"):setLocalZOrder(2)
    
    self.m_JackPotBar:findChild("Node_baozhu"):setLocalZOrder(3)
    
    self.m_bulingPos = 1000

    self:findChild("jp_choose_click"):setVisible(false)
    self:addClick(self:findChild("jp_choose_click"))

    self.m_Jp_LevelUp_Func = nil
    
end

function CoinManiaJpGameChooseView:getNextBulingNode( )

    local actList = {}
    local currNode = {}

    for i=1,self.m_MaxChestNum do
       
        local node =  self["Chest"..i]

        if node.m_gameType == CaiType then
            table.insert(actList,i)
        end
      
    end

    if #actList  > 0 then
        if #actList >= 6 then
            local roadNum = math.random(3,5)

            for i=1,roadNum do
                local index_1 = math.random(1,#actList) 
                currNode[#currNode + 1] = self["Chest"..actList[index_1]]
                table.remove(actList,index_1)
            end

        elseif #actList >= 4 then
            local roadNum = math.random(2,3)
        
            for i=1,roadNum do
                local index_1 = math.random(1,#actList) 
                currNode[#currNode + 1] = self["Chest"..actList[index_1]]
                table.remove(actList,index_1)
            end
        else
            local index_1 = math.random(1,#actList) 
            currNode[#currNode + 1] = self["Chest"..actList[index_1]]
        end
        
    end
    

    return currNode
end

function CoinManiaJpGameChooseView:beginBulingAct( )
    
    self.m_actNode:stopAllActions()
    self.m_bulingPos = 1000

    util_schedule(self.m_actNode, function(  )
        local actNode = self:getNextBulingNode( )  
        for i=1,#actNode do
            if actNode[i] then
                actNode[i]:runCsbAction("idleframe")
            end
        end      
        

    end, 2)

end



function CoinManiaJpGameChooseView:getGameType( index )
    
    local value = self.m_ClickData[index] 

    return value or "None"  
end

function CoinManiaJpGameChooseView:getCsbFromType( gameType )
    
    if gameType == PigType then
        return "CoinMania_JackPot_wanfa_zhu.csb"
    elseif gameType == ManType then
        return "CoinMania_JackPot_wanfa_hong.csb"
    elseif gameType == WuShiType then
        return "CoinMania_JackPot_wanfa_wushi.csb"
    elseif gameType == GuShiType then
        return "CoinMania_JackPot_wanfa_gu.csb"
    elseif gameType == LuoType then
        return "CoinMania_JackPot_wanfa_luo.csb"
    elseif gameType == CaiType then
        return "CoinMania_JackPot_wanfa_cai.csb"
    end

end

function CoinManiaJpGameChooseView:updateUI(machine  )


    self:findChild("jp_choose_click"):setVisible(false)
    self.m_Jp_LevelUp_Func = nil

    self:findChild("hong_1"):setVisible(false)
    self:findChild("zi_2"):setVisible(false)
    self:findChild("lan_3"):setVisible(false)
    self:findChild("lv_4"):setVisible(false)

    self.m_machine = machine

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    self.m_ClickData = selfdata.jackpots or {"None","None","None","None","None","None","None","None","None","None","None","None","None","None","None","None","None","None"}

    self.m_JpMultiply = selfdata.megaMultiply or 1
    self.m_pigNum = 0
    self.m_JpSymbolNumList = {0,0,0,0}
    self.m_JackPotBar:runCsbAction("idleframe",true)
    self.m_JackPotBar.m_JackPotBarMultiply = self.m_JpMultiply
    self.m_JackPotBar.m_OldJPBarMultiply  = self.m_JackPotBar.m_JackPotBarMultiply

    self:initChest( )
    self:updateJpSymbolActStates( )
    self.m_loadingBar:updateLoadingTipActStates( )
    self.m_loadingBar:runCsbAction("idleframe",true)
    self:showAllTwoSameChest( )
    self:beginBulingAct( )
end

function CoinManiaJpGameChooseView:removeAllChest( )
    for i=1,self.m_MaxChestNum do
        if self:findChild("tubiao_"..i) then
            self:findChild("tubiao_"..i):removeAllChildren()
        end
        self["Chest"..i] = nil
    end
end

function CoinManiaJpGameChooseView:initChest( )
    
    for i=1,self.m_MaxChestNum do
        local data = {}
        data.machine = self
        data.index = i - 1
        local gameType = self:getGameType( i )
        data.csbname = self:getCsbFromType( gameType )

        self:findChild("tubiao_"..i ):setLocalZOrder(i)
        self["Chest"..i] = util_createView("CodeCoinManiaSrc.CoinManiaCaiView",data) 
        self:findChild("tubiao_"..i ):addChild(self["Chest"..i])
        self["Chest"..i].m_gameType = gameType

        

        local group = self:getJpGroupFromGameType(gameType )
        if group then
            self.m_JpSymbolNumList[group] = self.m_JpSymbolNumList[group] + 1
        end

        if gameType == PigType then
            self.m_pigNum = self.m_pigNum + 1

            -- local spinPig = util_spineCreate("Socre_CoinMania_Bonus",true,true)
            -- self["Chest"..i]:findChild("Node_3_0"):addChild(spinPig)
    
            -- util_spinePlay(spinPig,"idleframe2",true)
        end

        if gameType ~= CaiType then
            self["Chest"..i]:runCsbAction("idleframe")
        end
        
        
        
        

        

    end
end



function CoinManiaJpGameChooseView:getJpSymbolNameFromGroup( group )
    
    if group == 1 then
        return "CoinMania_JackPot_wanfa_H1.csb"
    elseif group == 2 then
        return "CoinMania_JackPot_wanfa_H2.csb"
    elseif group == 3 then
        return "CoinMania_JackPot_wanfa_H3.csb"
    elseif group == 4 then
        return "CoinMania_JackPot_wanfa_H4.csb"
    end

end

function CoinManiaJpGameChooseView:initJpSymbol( )
    

    for group = 1 , 4 do
       
        local curNum = 0
        for index = 3 , 1 , -1 do
            local addName =  "h" .. group .. "_" .. index
            self[ group .."JpSymbol" .. index] = util_createAnimation(self:getJpSymbolNameFromGroup( group ))
            self:findChild(addName):addChild(self[ group .."JpSymbol" .. index])

            curNum = curNum + 1
            self[ group .."JpSymbol" .. index]:runCsbAction("idleframe")

            
        end
        
    end
    

end

function CoinManiaJpGameChooseView:updateJpSymbolActStates( )
    for group = 1 , 4 do
       
        local allShowIndex =  self.m_JpSymbolNumList[group]
        local curNum = 0
        for index = 3 , 1 , -1 do

            curNum = curNum + 1

            if self[ group .."JpSymbol" .. index] then
                if curNum <= allShowIndex then
                    self[ group .."JpSymbol" .. index].m_isAdd = true
                    self[ group .."JpSymbol" .. index]:runCsbAction("idleframe1")
                else
                    self[ group .."JpSymbol" .. index].m_isAdd = nil
                    self[ group .."JpSymbol" .. index]:runCsbAction("idleframe")
                end
            end
            
            
        end
        
    end
end

function CoinManiaJpGameChooseView:getActJpSymbol(group )
    
    for index = 3 ,1,-1 do
        if self[ group .."JpSymbol" .. index] and not self[ group .."JpSymbol" .. index].m_isAdd then
            return self[ group .."JpSymbol" .. index]
        end
        
    end
end


function CoinManiaJpGameChooseView:onEnter()
    BaseGame.onEnter(self)
end
function CoinManiaJpGameChooseView:onExit()
    scheduler.unschedulesByTargetName("CoinManiaJpGameChooseView")
    BaseGame.onExit(self)

end

function CoinManiaJpGameChooseView:isCanTouch( )
    
    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
end

function CoinManiaJpGameChooseView:setClickData( pos )
    
    

    self:sendData(pos)
end

--数据发送
function CoinManiaJpGameChooseView:sendData(pos)



    
    self.m_action=self.ACTION_SEND
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
            self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGame")
    else

        self.m_machine:updateJackpotList()

        local jackpotList = {}

        for i=1,#self.m_machine.m_jackpotList do
            local jp = self.m_machine.m_jackpotList[i]
            local coins =  self.m_machine:BaseMania_getJackpotScore(i)

            if i == 1 then
                table.insert(jackpotList,jp  )
                print("totalCoins   "  .. i .. "  "..coins  )
            else
                table.insert(jackpotList,jp * self.m_JpMultiply )  
                print("totalCoins   ".. i .. "  " ..coins * self.m_JpMultiply )
            end
            
            
            
        end

        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData={msg=MessageDataType.MSG_BONUS_SELECT , clickPos= pos , jackpot = jackpotList }
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end

function CoinManiaJpGameChooseView:getJpGroupFromGameType(gameType )
    
    if gameType == ManType then
        return 1
    elseif gameType == WuShiType then
        return 2
    elseif gameType == GuShiType then
        return 3
    elseif gameType == LuoType then

        return 4
    end

end

--数据接收
function CoinManiaJpGameChooseView:recvBaseData(featureData)


    

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    self.m_ClickData = selfdata.jackpots or {"None","None","None","None","None","None","None","None","None","None","None","None","None","None","None","None","None","None"}
    self.m_JpMultiply = selfdata.megaMultiply or 1

    local clientPositions = selfdata.clientPositions or {}
    local clickPos = clientPositions[#clientPositions] or 0

    local index = clickPos + 1
    local actNode = self["Chest".. index]
    actNode:setVisible(false)

    local data = {}
    local gameType = self:getGameType( index )
    data.csbname = self:getCsbFromType( gameType )
    self["Chest"..index] = util_createView("CodeCoinManiaSrc.CoinManiaCaiView",data) 
    self["Chest"..index].m_gameType = gameType
    self:findChild("tubiao_"..index ):addChild(self["Chest"..index])

    if gameType == PigType then
        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Collect_Pig.mp3")
    else
        gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Collect_Jp.mp3")
    end
    
    self:findChild("tubiao_"..index ):stopAllActions()

    self["Chest"..index]:runCsbAction("actionframe",false,function(  )

        if gameType == PigType then
            local spinPig = util_spineCreate("Socre_CoinMania_Bonus",true,true)
            self["Chest"..index]:findChild("Node_3_0"):addChild(spinPig)
            
            self:findChild("tubiao_"..index ):setLocalZOrder(self.m_MaxChestNum + 1)

            util_spinePlay(spinPig,"actionframe10",false)

            util_spineEndCallFunc(spinPig,"actionframe10",function(  )
                util_spinePlay(spinPig,"actionframe7",false)
                util_spineFrameCallFunc(spinPig, "actionframe7", "Gush2", function(  )

                    local startNodePos = cc.p(self:findChild("tubiao_"..index ):getPosition()) 

                    local actBarNode , actBarNodeIndex =  self.m_loadingBar:getActBarNode()

                   if actBarNodeIndex == 6 then
                        self.m_loadingBar:runCsbAction("actionframe3",false,function(  )
                            self.m_loadingBar:runCsbAction("animation3",false,function(  )
                                self.m_loadingBar:runCsbAction("idleframe",true)
                            end)
                        end)
                    end

                    local endNodePos = cc.p(util_getConvertNodePos(actBarNode,self:findChild("tubiao_"..index )) ) 
                    

                    self:playCoinsFly(cc.p(startNodePos.x- 17,startNodePos.y + 145), endNodePos,function(  )

                    end)
                    
                    
                    self.m_loadingBar:getActBarNode():runCsbAction("actionframe",false,function(  )
                        self.m_loadingBar:getActBarNode().m_isAdd = true

                        if self.m_JackPotBar.m_JackPotBarMultiply ~= self.m_JpMultiply then
                            

                            if actBarNodeIndex == 1 then 

                                gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Boost_Baozhu_zha.mp3")
                                self.m_loadingBar:runBaoZhuZha( 1 )
                            elseif actBarNodeIndex == 3 then 
                                gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Boost_Baozhu_zha.mp3")
                                self.m_loadingBar:runBaoZhuZha( 2 )

                            end

                            local waitTimes = 0
                            if actBarNodeIndex == 1 then 

                                waitTimes = 2.7
                            elseif actBarNodeIndex == 3 then 
        
                                waitTimes = 2.7
                            end
                            
                            
                            performWithDelay(self,function(  )
                                -- gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_LevelUp_Tip.mp3")

                                self.m_JackPotBar.m_JackPotBarMultiply = self.m_JpMultiply
                                
                                self.m_Jp_Sound_Coins_Jump =  gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Coins_Jump.mp3",true)
                                self.m_JackPotBar:jpLabAction( 3 )

                                self.m_JackPotBar.m_OldJPBarMultiply  = self.m_JackPotBar.m_JackPotBarMultiply

                                self.m_JackPotBar:findChild("Node_down"):setLocalZOrder(4)

                                self.m_Jp_LevelUp_Func = function(  )
                                    self.m_JackPotBar:runCsbAction("idle",true)

                                    if self.m_Jp_Sound_Coins_Jump then
                                        gLobalSoundManager:stopAudio(self.m_Jp_Sound_Coins_Jump)
                                        self.m_Jp_Sound_Coins_Jump = nil
                                    end

                                    gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_JPCoinsJump_Over.mp3")

                                    performWithDelay(self,function(  )
                                        self.m_JackPotBar:runCsbAction("over",false,function(  )
                                
                                            self.m_JackPotBar:findChild("Node_down"):setLocalZOrder(2)
    
                                           
                                            
                                            if self:checkIsOver( ) then
        
                                                self:changeJpWinTip(gameType )
        
                                                self:showOtheChest_One( )
        
                                            else
                                    
                                                self:showTwoSameChest( gameType)
                                                self.m_action=self.ACTION_RECV
                                            end
    
                                        end)
                                    end,0.5)
                                    
                                    
                                end

                                

                                self.m_JackPotBar:runCsbAction("show",false,function(  )
                                    
                                    self:findChild("jp_choose_click"):setVisible(true)
                                    self.m_JackPotBar:runCsbAction("idle",true)

                                end)

                                performWithDelay(self,function(  )
                                    
                                  
                                    self:findChild("jp_choose_click"):setVisible(false)

                                    if self.m_Jp_LevelUp_Func then
                                        self.m_Jp_LevelUp_Func()
                                        self.m_Jp_LevelUp_Func = nil
                                    end

                                end,3)

                                
                            end,waitTimes)
                            

                        else

                            

                            if self:checkIsOver( ) then

                                self:changeJpWinTip(gameType )

                                self:showOtheChest_One( )
    
                            else
                                self:showTwoSameChest( gameType)
                                self.m_action=self.ACTION_RECV
                            end
                            
                        end
                        
                    end)


                end,function(  )
                    

                    self["Chest"..index]:runCsbAction("animation0",false,function(  )
                        -- util_spinePlay(spinPig,"idleframe2",true)
                        self:findChild("tubiao_"..index ):setLocalZOrder(index)

                    end)
                    
                    util_spinePlay(spinPig,"actionframe9",false)
                end)
            end)

            

        else
            
            local startNode = self:findChild("tubiao_"..index )
            local group = self:getJpGroupFromGameType(gameType )
            local endNode = self:getActJpSymbol(group )
            local csbName = self:getLineActCsb( gameType )

            self["Chest"..index]:runCsbAction("actionframe2",false,function(  )

                self["Chest"..index]:runCsbAction("actionframe1")

                self:runFlyLineAct(startNode,endNode,csbName,function(  )
                    
                end)

                endNode:runCsbAction("actionframe",false,function(  )

                    self:getActJpSymbol(group ).m_isAdd = true
                    
                    if self:checkIsOver( ) then


                        self:changeJpWinTip(gameType )

                        self:showOtheChest_One( )
                    else
            
                        self:showTwoSameChest( gameType)
                        self.m_action=self.ACTION_RECV
                    end 
                end)        
                
            end)
        end

    end)

end

function CoinManiaJpGameChooseView:changeJpWinTip(gameType )
    
    self:findChild("hong_1"):setVisible(false)
    self:findChild("zi_2"):setVisible(false)
    self:findChild("lan_3"):setVisible(false)
    self:findChild("lv_4"):setVisible(false)

    if gameType == ManType then
        self:findChild("hong_1"):setVisible(true)
    elseif gameType == WuShiType then
        self:findChild("zi_2"):setVisible(true)
    elseif gameType == GuShiType then
        self:findChild("lv_4"):setVisible(true)
    elseif gameType == LuoType then
        self:findChild("lan_3"):setVisible(true)
        
    end

end

function CoinManiaJpGameChooseView:showAllTwoSameChest(  )

    local PigTypeNum = {}
    local ManTypeNum = {}
    local WuShiTypeNum = {}
    local GuShiTypeNum = {}
    local LuoTypeNum = {}

    for index=1,18 do

        local gameType = self["Chest"..index].m_gameType

        if gameType == PigType then
            table.insert(PigTypeNum,index)
        elseif gameType == ManType then
            table.insert(ManTypeNum,index)
        elseif gameType == WuShiType then
            table.insert(WuShiTypeNum,index)
        elseif gameType == GuShiType then
            table.insert(GuShiTypeNum,index)
        elseif gameType == LuoType then
            table.insert(LuoTypeNum,index)
        end
    end

    self:playTwoShowAct(PigTypeNum,ManTypeNum,WuShiTypeNum,GuShiTypeNum,LuoTypeNum )
    
    
end

function CoinManiaJpGameChooseView:playTwoShowAct(PigTypeNum,ManTypeNum,WuShiTypeNum,GuShiTypeNum,LuoTypeNum )
    if #PigTypeNum == 5 then

        for i=1,#PigTypeNum do
            local index =  PigTypeNum[i]
            self["Chest"..index]:runCsbAction("idleframe1",true,nil,10)
        end

    elseif #ManTypeNum == 2 then
        self:findChild("hong_1"):setVisible(true)
        for i=1,#ManTypeNum do
            local index =  ManTypeNum[i]
            self["Chest"..index]:runCsbAction("idleframe1",true,nil,10)
        end
    elseif #WuShiTypeNum == 2 then
        self:findChild("zi_2"):setVisible(true)
        for i=1,#WuShiTypeNum do
            local index =  WuShiTypeNum[i]
            self["Chest"..index]:runCsbAction("idleframe1",true,nil,10)
        end
    elseif #GuShiTypeNum == 2 then
        self:findChild("lv_4"):setVisible(true)
        for i=1,#GuShiTypeNum do
            local index =  GuShiTypeNum[i]
            self["Chest"..index]:runCsbAction("idleframe1",true,nil,10)
        end
    elseif #LuoTypeNum == 2 then
        self:findChild("lan_3"):setVisible(true)
        for i=1,#LuoTypeNum do
            local index =  LuoTypeNum[i]
            self["Chest"..index]:runCsbAction("idleframe1",true,nil,10)
        end
    end

    
    
    
    
end

function CoinManiaJpGameChooseView:showTwoSameChest( Gtype )




    local PigTypeNum = {}
    local ManTypeNum = {}
    local WuShiTypeNum = {}
    local GuShiTypeNum = {}
    local LuoTypeNum = {}

    for index=1,18 do

        local gameType = self["Chest"..index].m_gameType

        if gameType == Gtype then
            if gameType == PigType then
                table.insert(PigTypeNum,index)
            elseif gameType == ManType then
                table.insert(ManTypeNum,index)
            elseif gameType == WuShiType then
                table.insert(WuShiTypeNum,index)
            elseif gameType == GuShiType then
                table.insert(GuShiTypeNum,index)
            elseif gameType == LuoType then
                table.insert(LuoTypeNum,index)
            end
        end
        
    end


    self:playTwoShowAct(PigTypeNum,ManTypeNum,WuShiTypeNum,GuShiTypeNum,LuoTypeNum )
    
end

function CoinManiaJpGameChooseView:getEndGameType( )
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local clientPositions = selfdata.clientPositions or {}
    local clickPos = clientPositions[#clientPositions] or 0


    return self.m_ClickData[clickPos + 1] 
end

function CoinManiaJpGameChooseView:updateChestForOverShow( )
    for i=1,self.m_MaxChestNum do

        self["Chest"..i]:runCsbAction("idleframe",true)

        if self["Chest"..i].m_gameType == CaiType then
            self["Chest"..i]:setVisible(false)
            
            local data = {}
            data.machine = self
            data.index = i - 1
            local gameType = self:getGameType( i )
            data.csbname = self:getCsbFromType( gameType )

            self["Chest"..i] = util_createView("CodeCoinManiaSrc.CoinManiaCaiView",data) 
            self:findChild("tubiao_"..i ):addChild(self["Chest"..i])
            self["Chest"..i].m_gameType = gameType

            self["Chest"..i]:runCsbAction("idleframe",true)

            if gameType == PigType then
                local spinPig = util_spineCreate("Socre_CoinMania_Bonus",true,true)
                self["Chest"..i]:findChild("Node_3_0"):addChild(spinPig)
        
                util_spinePlay(spinPig,"idleframe2",true)
            end
        end


    end
end

function CoinManiaJpGameChooseView:showOtheChest_One( )


    self:updateChestForOverShow( )

    if  PigType ==  self:getEndGameType( ) then
        
        self.m_JackPotBar:findChild("Node_Loading"):setLocalZOrder(-1)
        self.m_JackPotBar:runCsbAction("mega",false,function(  )
            self.m_JackPotBar:runCsbAction("megaidle",true)
        end)
    elseif  ManType ==  self:getEndGameType( ) then
        self.m_JackPotBar:runCsbAction("grand",false,function(  )
            self.m_JackPotBar:runCsbAction("grandidle",true)
        end)
    elseif  WuShiType ==  self:getEndGameType( ) then  
        self.m_JackPotBar:runCsbAction("major",false,function(  )
            self.m_JackPotBar:runCsbAction("majoridle",true)
        end)
    elseif  GuShiType ==  self:getEndGameType( ) then 
        self.m_JackPotBar:runCsbAction("minor",false,function(  )
            self.m_JackPotBar:runCsbAction("minoridle",true)
        end)
    elseif  LuoType ==  self:getEndGameType( ) then 
        self.m_JackPotBar:runCsbAction("mini",false,function(  )
            self.m_JackPotBar:runCsbAction("miniidle",true)
        end)
    end


    local index = 0
    for i=1,self.m_MaxChestNum do
        
        self:findChild("tubiao_"..i ):stopAllActions()

        if self["Chest"..i]  then
            local gameType = self:getGameType( i )

            if gameType == self:getEndGameType( )then

            else
                
                index = index + 1

                local index_1 = index
                self["Chest"..i]:runCsbAction("dark",false,function(  )
                    if index_1 == 1 then
                        
                        performWithDelay(self,function(  )
                            
                            self.m_machine:clearCurMusicBg()
                            gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_Jp_Choose_Three_Wins.mp3")

                            self:showOtheChest_Two( function(  )
                                self:showOtheChest_Two( function(  )
                                    self:showOtheChest_Two( function(  )
                                        self:showOtheChest_Two( function(  )
                                
                                            self:showOtheChest_Two_end( function( )
                                                performWithDelay(self,function(  )

                                                    self.m_JackPotBar:findChild("Node_Loading"):setLocalZOrder(1)
                                                    -- 在这个函数销毁此类
                                                    if self.m_bonusEndCall then
                                                        self.m_bonusEndCall()
                                                    end
                                                end,0.5)
                                            end )

                                        end )
                                    end )
                                end )
                            end )

                            

                        end,0.5)
                        
                    end
                end)
            end

        
            
        end
        

    end


    

end

function CoinManiaJpGameChooseView:showOtheChest_Two_end( func )

    local index = 0
    for i=1,self.m_MaxChestNum do
        
        local actNdoe = self["Chest"..i]
        if actNdoe  then
            local gameType = self:getGameType( i )

            if gameType == self:getEndGameType( ) then

                index = index + 1

                local index_1 = index
                actNdoe:runCsbAction("actionframe2",false,function(  )
                    local index_2 = index_1
                    if index_2 == 1 then
                    
                        if func then
                            func()
                        end

                    end

                    
                end)
            end

           
            
        end
        

    end

end

function CoinManiaJpGameChooseView:showOtheChest_Two( func )

    local index = 0
    for i=1,self.m_MaxChestNum do
        
        local actNdoe = self["Chest"..i]
        if actNdoe  then
            local gameType = self:getGameType( i )

            if gameType == self:getEndGameType( ) then

                index = index + 1

                local index_1 = index
                actNdoe:runCsbAction("actionframe2",false,function(  )
                    local index_2 = index_1
                    actNdoe:runCsbAction("actionframe1",false,function(  )
                        if index_2 == 1 then
                        
                            if func then
                                func()
                            end

                        end
                    end)
                    
                end)
            end

           
            
        end
        

    end

end

function CoinManiaJpGameChooseView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end

function CoinManiaJpGameChooseView:showOtherChest( )
    
    

end


--开始结束流程
function CoinManiaJpGameChooseView:gameOver(isContinue)

end

--弹出结算奖励
function CoinManiaJpGameChooseView:showReward()

   
end

function CoinManiaJpGameChooseView:getJackPotIndex(  )
    

    if self:getEndGameType( ) ==  PigType  then
        return 1
    elseif self:getEndGameType( ) ==  ManType  then
        return 2
    elseif self:getEndGameType( ) ==  WuShiType  then
        return 3
    elseif self:getEndGameType( ) ==  GuShiType  then
        return 4
    elseif self:getEndGameType( ) ==  LuoType  then
        return 5
        
    end

end

function CoinManiaJpGameChooseView:setEndCall( func)
    self.m_bonusEndCall = function(  )

        local coins = self.m_serverWinCoins 
        local index = self:getJackPotIndex(  )
        self.m_machine:showJackpotWinView(index,coins,function(  )
            
            
            self.m_machine:showGuoChang( function(  )

                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                local isUpdateTopUI = true     
                self.m_machine:checkFeatureOverTriggerBigWin( self.m_serverWinCoins ,GameEffect.EFFECT_BONUS)
                
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isUpdateTopUI,true})
                -- self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(coins))
                globalData.slotRunData.lastWinCoin = lastWinCoin 
                    
                self.m_machine:resetMusicBg()

                if func then
                    func()
                end 
                    
            end)

            

        end)

        


    end 
end



function CoinManiaJpGameChooseView:featureResultCallFun(param)

    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            -- dump(spinData.result, "featureResultCallFun data", 3)
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


function CoinManiaJpGameChooseView:checkIsOver( )
    local bonusStatus = self.m_machine.m_runSpinResultData.p_bonusStatus 

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end


function CoinManiaJpGameChooseView:isTouch()
    -- print(self.ACTION_NONE.."jkjkjkjkj  "..self.ACTION_OVER.."  "..self.m_action)
    if self.m_action == self.ACTION_SEND then
        return true
    end
      
end

function CoinManiaJpGameChooseView:getLineActCsb( gameType )
    
    if gameType == ManType then
        return "CoinMania_JackPot_wanfa_hong_shoujixian.csb"
    elseif gameType == WuShiType then
        return "CoinMania_JackPot_wanfa_wushi_shoujixian.csb"
    elseif gameType == GuShiType then
        return "CoinMania_JackPot_wanfa_gu_shoujixian.csb"
    elseif gameType == LuoType then
        return "CoinMania_JackPot_wanfa_luo_shoujixian.csb"
    end

end

function CoinManiaJpGameChooseView:runFlyLineAct(startNode,endNode,csbName,func)

    -- 创建粒子
    local flyNode =  util_createAnimation( csbName )
    self:findChild("root"):addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 501)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = cc.p(util_getConvertNodePos(endNode,flyNode))

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:findChild("Node_5"):setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:findChild("Node_5"):setScaleX(scaleSize / 800 )

    flyNode:runCsbAction("actionframe",false,function(  )

            if func then
                func()
            end

            flyNode:stopAllActions()
            flyNode:removeFromParent()
    end)

    return flyNode

end


function CoinManiaJpGameChooseView:playMoveToAction(node,time,pos,callback,type,isHide)
    local actionList={}
    local flyTime = 1
    local waitTimes = time - flyTime

    if isHide then
        node:setVisible(false)
    end
    

    actionList[#actionList + 1] = cc.DelayTime:create(waitTimes)
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
         local curNode = node
         node:setVisible(true)
        local seq_1 =cc.Sequence:create(cc.CallFunc:create(function(  )
            if curNode:getParent() then
                curNode:runCsbAction("animation0")
            end
            
        end))
        curNode:runAction(seq_1)
        
     end)

    if type == "easyInOut" then
        actionList[#actionList + 1] = cc.EaseOut:create(cc.JumpTo:create(flyTime,pos,100,1),1)
        -- actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveTo:create(flyTime,pos),1)
    else
        -- actionList[#actionList + 1 ] = cc.MoveTo:create(flyTime,pos);
        actionList[#actionList + 1 ] = cc.JumpTo:create(flyTime,pos,100,1)
    end
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
       if callback then
            callback()
       end
    end)
    local seq=cc.Sequence:create(actionList)
    node:runAction(seq)
end

function CoinManiaJpGameChooseView:playCoinsFly(startNodePos, endNodePos,func)
    
    local coinsNum = 5
    local flyTimesPool = {100,100}
    local ActInfo = {}
    for i=1,coinsNum do

        local acttionTime = math.random(flyTimesPool[1],flyTimesPool[2]) / 100
        if i == 1 then
            acttionTime = flyTimesPool[1] / 100
        end
        local info = {}
        info.time = acttionTime + (i-1)*0.15
        table.insert(ActInfo,info)
    end


    table.sort(ActInfo,function( a,b )
        return a.time < b.time
    end)

    for i=1,#ActInfo do
        local info = ActInfo[i]
        local CsbName = "CoinMania_jinbi_fanzhuan"

        local node = util_createAnimation(CsbName .. ".csb")
        self:findChild("root"):addChild(node,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER   )

        node:setPosition(cc.p(startNodePos))

        local endPos = cc.p(endNodePos)

        local angle = util_getAngleByPos(cc.p(node:getPosition()),endPos) + 270
        node:findChild("root"):setRotation( -angle)
    
        local endCallIndex = 1

        if i == endCallIndex then
            
            self:playMoveToAction(node,info.time,endPos,function(  )

                node:setVisible(false)

                if func then
                    func()
                end
               

            end,"easyInOut",true)
        else
            self:playMoveToAction(node,info.time,endPos,function(  )
                node:setVisible(false)
            end,"easyInOut",true)
        end

    end

end

function CoinManiaJpGameChooseView:playStartMoveToAction(node,pos,callback,type,waitTimes)
    local actionList={}
    local flyTime = 1.1

    actionList[#actionList + 1] = cc.DelayTime:create(0.1)
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
         local curNode = node
         node:setVisible(true)
        local seq_1 =cc.Sequence:create(cc.CallFunc:create(function(  )
            if curNode:getParent() then
                curNode:runCsbAction("idleframe")
            end
            
        end))
        curNode:runAction(seq_1)
        
     end)

    if type == "easyInOut" then
        actionList[#actionList + 1] = cc.EaseOut:create(cc.MoveTo:create(flyTime,pos),1)
    else
        actionList[#actionList+1]=cc.MoveTo:create(flyTime,pos);
    end
    actionList[#actionList + 1] = cc.DelayTime:create(waitTimes)
    actionList[#actionList+1]=cc.CallFunc:create(function(  )
       if callback then
            callback()
       end

    end)
    local seq=cc.Sequence:create(actionList)
    node:runAction(seq)
end

--默认按钮监听回调
function CoinManiaJpGameChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "jp_choose_click" then

        self:findChild("jp_choose_click"):setVisible(false)

        if self.m_Jp_LevelUp_Func then
            self.m_JackPotBar:stopJumplab( )
            self.m_Jp_LevelUp_Func()
            self.m_Jp_LevelUp_Func = nil
        end
    end

end
return CoinManiaJpGameChooseView