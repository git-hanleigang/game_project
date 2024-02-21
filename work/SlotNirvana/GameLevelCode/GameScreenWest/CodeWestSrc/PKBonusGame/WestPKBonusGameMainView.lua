---
--xcyy
--2018年5月23日
--WestPKBonusGameMainView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local WestPKBonusGameMainView = class("WestPKBonusGameMainView",BaseGame )

WestPKBonusGameMainView.m_machine = nil
WestPKBonusGameMainView.m_bonusEndCall = nil

WestPKBonusGameMainView.m_MaxdoorNum = 18
WestPKBonusGameMainView.m_PlayerClicked = 0

WestPKBonusGameMainView.ADW = "ADW" -- 玩家减生命
WestPKBonusGameMainView.BDW = "BDW" -- 敌人减生命
WestPKBonusGameMainView.RWD = "RWD" -- 奖励
WestPKBonusGameMainView.AUP = "AUP" -- 玩家加生命

WestPKBonusGameMainView.m_GamePlayStates = 0 -- 本地存储的游戏状态
WestPKBonusGameMainView.m_GamePlayStates_PK = 0
WestPKBonusGameMainView.m_GamePlayStates_REWORD = 1

WestPKBonusGameMainView.win2 = "win2" -- 奖励界面 x2
WestPKBonusGameMainView.win3 = "win3" -- 奖励界面 x3
WestPKBonusGameMainView.again = "again" -- 奖励界面 在玩一次
WestPKBonusGameMainView.over = "over" -- 奖励界面 游戏结束

WestPKBonusGameMainView.m_CLickTimes = 0
WestPKBonusGameMainView.m_oldWinCoins = 0
WestPKBonusGameMainView.m_fsWinCoin = 0

function WestPKBonusGameMainView:initUI(data)

    self.m_machine = data.machine

    local bonusData = data.bonusData
    self.p_choose =  {}
    for i=1,#bonusData.cells do
        local openChoose = bonusData.cells[i]
        if openChoose.status and openChoose.status == 1 then
            table.insert( self.p_choose, i - 1 )
        end
    end

    self.m_GamePlayStates = self.m_GamePlayStates_PK
    self.m_PlayerClicked = 0
    self.p_bonusExtra = bonusData or {}
    self.p_status =  "OPEN"

    self.m_oldWinCoins = 0

    self.m_fsWinCoin = self.m_machine.m_runSpinResultData.p_fsWinCoins or 0




    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("West/BonusGame.csb")


    self.m_actWaitNode = cc.Node:create()
    self:addChild(self.m_actWaitNode)
    
    self:findChild("Node_TotalWin"):setLocalZOrder(2)

    self.m_BonusLoseView =  util_createView("CodeWestSrc.PKBonusGame.WestPKBonusLoseView",self)  
    self:addChild(self.m_BonusLoseView,1)
    self.m_BonusLoseView:setVisible(false)
    self.m_BonusLoseView:setPositionX(-4)

    self.m_BonusWinView =  util_createView("CodeWestSrc.PKBonusGame.WestPKBonusWinView",self)  
    self:addChild(self.m_BonusWinView,1)
    self.m_BonusWinView:setVisible(false)
    self.m_BonusWinView:setPositionX(-4)

    self.m_HeroMan =  util_createView("CodeWestSrc.PKBonusGame.WestPKBonusHeroView")  
    self:findChild("bonusgame_hp1"):addChild(self.m_HeroMan)
    self.m_HeroMan:updateHealthValue( self.p_bonusExtra.hp1 )

    self.m_CriminalMan =  util_createView("CodeWestSrc.PKBonusGame.WestPKBonusCriminalView")  
    self:findChild("bonusgame_hp2"):addChild(self.m_CriminalMan)
    self.m_CriminalMan:updateHealthValue( self.p_bonusExtra.hp2 )
    
    local lineBet = self.p_bonusExtra.lineBet or 1

    self.m_machine.m_bottomUI:resetWinLabel()
    local coins = (lineBet * self.p_bonusExtra.points) + self.m_fsWinCoin
    if coins > 0 then
        self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(coins))
        self.m_oldWinCoins = coins
    else
        self.m_machine.m_bottomUI:updateWinCount("")
    end
    
    self.m_GuoChang = util_createAnimation("West_bounsGame_guochang.csb")
    self:addChild(self.m_GuoChang,2)
    self.m_GuoChang:setVisible(false)

    self:findChild("man_Hero"):setLocalZOrder(1)
    self:findChild("man_Criminal"):setLocalZOrder(1)

    self.m_ManHeroSpine = util_spineCreate("West_HeroMan",true,true)
    self:findChild("man_Hero"):addChild(self.m_ManHeroSpine)
    util_spinePlay(self.m_ManHeroSpine,"idleframe",true)
    self.m_ManHeroSpine:setPositionY(-60)
    self:findChild("man_Hero"):setScale(0.8)

    self.m_ManCriminalSpine = util_spineCreate("West_CriminalMan",true,true)
    self:findChild("man_Criminal"):addChild(self.m_ManCriminalSpine)
    util_spinePlay(self.m_ManCriminalSpine,"idleframe",true)
    self.m_ManCriminalSpine:setPositionY(-60)
    self:findChild("man_Criminal"):setScale(0.8)

    self:initdoor( )

    self:commingDeathTip( true )

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)


end


function WestPKBonusGameMainView:checkShowPKView( func ,funcEnd )
    

    self:showGuoChang( function(  )

        if func then
            func()
        end

        self:findChild("root"):setVisible(true)
        -- 赢
        self.m_BonusWinView:setVisible(false)
        -- 输
        self.m_BonusLoseView:setVisible(false)
  

    end,function(  )
        if funcEnd then
            funcEnd()
        end
    end )




end

function WestPKBonusGameMainView:checkShowRewordView( func ,funcEnd )
    

        self:setAllDoorCantClick( )

        self:showGuoChang( function(  )

            if func then
                func()
            end

            self:findChild("root"):setVisible(false)
            if self.p_bonusExtra.hp1 > 0 then
                self.m_machine:resetMusicBg(nil,"WestSounds/music_West_bonusgame_Win.mp3")
                -- 赢
                self.m_BonusWinView:setVisible(true)
            else
                self.m_machine:resetMusicBg(nil,"WestSounds/music_West_bonusgame_Lose.mp3")
                -- 输
                self.m_BonusLoseView:setVisible(true)
            end

        end,function(  )
            if self.p_bonusExtra.hp1 > 0 then
                
                -- 赢
                gLobalSoundManager:playSound("WestSounds/music_West_EnterBonusWinView.mp3")
            else

                -- 输

            end
            

            if funcEnd then
                funcEnd()
            end
        end )


    

end

-- function WestPKBonusGameMainView:isInArray( array,value )
    
--     for k,v in pairs(array) do
--         if v == value then
--             return true
--         end
--     end

--     return false
-- end

function WestPKBonusGameMainView:restAllDoor( )
    
    for i=1,self.m_MaxdoorNum do
        local door =  self["door_" .. i]
        door:findChild("click"):setVisible(true)
        door:runCsbAction("idleframe")
    end

end

function WestPKBonusGameMainView:hideAllDoor( )
    for i=1,self.m_MaxdoorNum do
        local door =  self["door_" .. i]
        door:setVisible(false)
    end
end

function WestPKBonusGameMainView:showAllDoor( )
    for i=1,self.m_MaxdoorNum do
        local door =  self["door_" .. i]
        door:setVisible(true)
    end
end

function WestPKBonusGameMainView:initdoor( )
    

    for i=1,self.m_MaxdoorNum do
        local data = {}
        data.index = i - 1
        data.machine = self

        local door = util_createView("CodeWestSrc.PKBonusGame.WestPKBonusClickView",data)    

        local nodeName = "men_" .. i
        self:findChild(nodeName):addChild(door)
        self:findChild(nodeName):setLocalZOrder(1)
        self["door_" .. i] = door
        door:runCsbAction("idleframe")
        local isInChoose =  self:isInArray( self.p_choose,data.index )
        if isInChoose then

            local celldatas = self.p_bonusExtra.cells or {}
            local actCelldata = celldatas[data.index + 1] or {}
            local actList = {1,2,3,4}
            local actNameId = 1
            if actCelldata.type ==  self.ADW then-- 玩家减生命
                actNameId = 3
            elseif actCelldata.type ==  self.BDW then-- 敌人减生命
                actNameId = 1
            elseif actCelldata.type ==  self.RWD then-- 奖励
                actNameId = 2
            elseif actCelldata.type ==  self.AUP then-- 玩家加生命
                actNameId = 4
            end
            door:findChild("click"):setVisible(false)
            local door = self["door_" .. data.index + 1] 
            door:findChild("BitmapFontLabel_1"):setString(actCelldata.point)
            door:runCsbAction("idleframe"..actList[actNameId] )

        end

    end

end




function WestPKBonusGameMainView:isCanTouch( )
    
    if self.m_action ==self.ACTION_NONE then
        return false
    end

    if self.m_action == self.ACTION_SEND then
        
        return false
    end

    return true
    
end

function WestPKBonusGameMainView:setClickData( pos )
    
    -- gLobalSoundManager:playSound("WestSounds/music_West_Jp_Choose_Click_Baozhu.mp3")
    
    self.m_CLickTimes = self.m_CLickTimes + 1
    print("dadadadada    "..self.m_CLickTimes)

    self:sendData(pos)
end


function WestPKBonusGameMainView:onEnter()
    BaseGame.onEnter(self)
end
function WestPKBonusGameMainView:onExit()
    scheduler.unschedulesByTargetName("WestPKBonusGameMainView")
    BaseGame.onExit(self)

end

--数据发送
function WestPKBonusGameMainView:sendData(pos)

    self.m_action=self.ACTION_SEND

    self.m_PlayerClicked = pos

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data = pos }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    
end

function WestPKBonusGameMainView:pkGameRecvBaseData( featureData )
    local bonus = featureData.p_bonus or {}
    self.p_status = bonus.status or "OPEN"

    local oldHp1 = self.p_bonusExtra.hp1

    local data = featureData.p_data or {}
    local selfdata = data.selfData or {}
    local bonusdata =  selfdata.bonusData or {}
    table.insert(self.p_choose,self.m_PlayerClicked)
    self.p_bonusExtra = bonusdata or {}
    


    local celldatas = self.p_bonusExtra.cells or {}
    local actCelldata = celldatas[self.m_PlayerClicked + 1] or {}
    local actList = {1,2,3,4}
    local actNameId = 1
    if actCelldata.type ==  self.ADW then-- 玩家减生命
        actNameId = 3
    elseif actCelldata.type ==  self.BDW then-- 敌人减生命
        actNameId = 1
    elseif actCelldata.type ==  self.RWD then-- 奖励
        actNameId = 2
    elseif actCelldata.type ==  self.AUP then-- 玩家加生命
        actNameId = 4
    end
  
    
    local nodeName = "men_" .. self.m_PlayerClicked + 1
    self:findChild(nodeName):setLocalZOrder(10)


    local updateFunc = function(  )
        self:findChild(nodeName):setLocalZOrder(1)
     
        self:beginNextTurn( )
    end

    local updateViewUI = function(  )

        self.m_HeroMan:updateHealthValue( self.p_bonusExtra.hp1 )
        self.m_CriminalMan:updateHealthValue( self.p_bonusExtra.hp2 )

        self:commingDeathTip( )

    end



    -- gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_MenOpen.mp3")

    local door = self["door_" .. self.m_PlayerClicked + 1] 
    door:findChild("BitmapFontLabel_1"):setString(actCelldata.point)
    door:runCsbAction("actionframe"..actList[actNameId] ,false ,function(  )

    
    end)

    self:updateWinCoins( self.p_bonusExtra.points,1.5 )
    
    performWithDelay(self,function(  )
        if actCelldata.type ==  self.ADW then-- 玩家减生命

            local worldXinFlyStartPos = door:findChild("Node_XinFly"):getParent():convertToWorldSpace(cc.p(door:findChild("Node_XinFly"):getPosition()))
            local xinFlyStartPos = self.m_machine:convertToNodeSpace(worldXinFlyStartPos)
            local man_CriminalSpine_pos = cc.p(self:findChild("man_Criminal"):getPosition())
            local worldxinFlyEndPos = self:findChild("man_Criminal"):getParent():convertToWorldSpace(cc.p(man_CriminalSpine_pos.x,man_CriminalSpine_pos.y + 75))
            local xinFlyEndPos = self.m_machine:convertToNodeSpace(worldxinFlyEndPos)
            local time = 0.7
            self.m_machine:createBonusPkSkeletonFly( xinFlyStartPos,xinFlyEndPos ,time,function(  )
    
                gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_CriminalShut.mp3")
    
                if self.p_bonusExtra.hp1 == 0 then
                    self.m_machine:CreateBonusMusicBgSoundGlobal()
                    self:CriminalShootHeroDeath(function(  )
                        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeroDeath.mp3")
                        updateFunc()
                    end,function(  )
                        
                        updateViewUI()
                    end)
    
                else
                    self:CriminalShootIn(function(  )
                        
                        
                        util_spinePlay(self.m_ManHeroSpine,"idleframe",true)
                        util_spinePlay(self.m_ManCriminalSpine,"idleframe",true)
        
                        updateFunc()
                    end,function(  )
                        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeroHurt_RenSheng.mp3")
                        -- gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeroHurt.mp3")
                        updateViewUI()
                    end)
                end
    
            end)
    
            
    
            
        elseif actCelldata.type ==  self.BDW then-- 敌人减生命
    
            local worldXinFlyStartPos = door:findChild("Node_XinFly"):getParent():convertToWorldSpace(cc.p(door:findChild("Node_XinFly"):getPosition()))
            local xinFlyStartPos = self.m_machine:convertToNodeSpace(worldXinFlyStartPos)
            local man_HeroSpine_pos = cc.p(self:findChild("man_Hero"):getPosition())
            local worldxinFlyEndPos = self:findChild("man_Hero"):getParent():convertToWorldSpace(cc.p(man_HeroSpine_pos.x,man_HeroSpine_pos.y + 75))
            local xinFlyEndPos = self.m_machine:convertToNodeSpace(worldxinFlyEndPos)
            local time = 0.7
            self.m_machine:createBonusPkPistolFly( xinFlyStartPos,xinFlyEndPos ,time,function(  )
    
                gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_CowBoyShut.mp3")
    
                if self.p_bonusExtra.hp2 == 0 then
    
                    self.m_machine:CreateBonusMusicBgSoundGlobal()

                    self:HeroShootCriminalDeath(function(  )
                        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_CriminalDeath.mp3")
                        updateFunc()
                    end,function(  )
                        
                        updateViewUI()
                    end)
                    
                else
                    self:HeroShootIn(function(  )
                        util_spinePlay(self.m_ManHeroSpine,"idleframe",true)
                        util_spinePlay(self.m_ManCriminalSpine,"idleframe",true)
                        
                        updateFunc()
                    end,function(  )
                        
                        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_CriminalHurt_RenSheng.mp3")
                        -- gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_CriminalHurt.mp3")
                        updateViewUI()
                    end)
                end
    
            end)
    
            
    
           
        elseif actCelldata.type ==  self.RWD then-- 奖励
            
            gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_AddCoins.mp3")

            local num = math.random(1,2)
            if num == 1 then
                self:HeroShootMiss(function(  )
    
                    updateFunc()
    
                end,function(  )
                    updateViewUI()
                end)
            else
                self:CriminalShootMiss( function(  )
    
                    updateFunc()
    
                end,function(  )
                    updateViewUI()
                end)
            end
            
            
            
        elseif actCelldata.type ==  self.AUP then-- 玩家加生命
    
            if oldHp1 == 3 then
                -- 如果之前玩家的血量就是最大 那么就不播加血动画
                updateFunc()
            else
                --加血动画在门播放的同时播
                local actHeart = self.m_HeroMan["HealthValue_1"]
                    if oldHp1 == 1 then
                        actHeart = self.m_HeroMan["HealthValue_2"]
                    elseif oldHp1 == 2 then
                        actHeart = self.m_HeroMan["HealthValue_3"]
                    end
                
        
                    local worldXinFlyStartPos = door:findChild("Node_XinFly"):getParent():convertToWorldSpace(cc.p(door:findChild("Node_XinFly"):getPosition()))
                    local xinFlyStartPos = self.m_machine:convertToNodeSpace(worldXinFlyStartPos)
                    local man_HeroSpine_pos = cc.p(self:findChild("man_Hero"):getPosition())
                    local worldxinFlyEndPos = self:findChild("man_Hero"):getParent():convertToWorldSpace(cc.p(man_HeroSpine_pos.x,man_HeroSpine_pos.y + 75))
                    local xinFlyEndPos = self.m_machine:convertToNodeSpace(worldxinFlyEndPos)
                    local time = 0.7
                    self.m_machine:createBonusPkHeartFly( xinFlyStartPos,xinFlyEndPos ,time,function(  )
                        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeroAddBlood.mp3")
                        self:HeroAddBlood(function(  )
        
                            updateFunc()
                            updateViewUI()
        
                            for i=3,1,-1 do
    
                                if self.m_HeroMan["HealthValue_" .. i]:isVisible() then
                                    self.m_HeroMan["HealthValue_" .. i]:runCsbAction("actionframe_jiaxue")
                                    break
                                end
                            end
                            
                            
                            self.m_HeroMan["HealthValue_1"]:runCsbAction("idleframe_1")
                            self.m_HeroMan:runCsbAction("idleframe")
                            self.m_HeroMan.lastHp = false
        
                            
        
                            
        
                            
                        end) 
        
                    end )
            end
           
        end
    end,9/30)
    
   

end

function WestPKBonusGameMainView:commingDeathTip( isInit)
    
    

    local hp1 = self.p_bonusExtra.hp1 or 0
    if hp1 == 1 then
        
        if not self.m_HeroMan.lastHp then
            if not isInit then
                gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_lastHp.mp3")
            end
            
            self.m_HeroMan:runCsbAction("actionframe",true)
            self.m_HeroMan["HealthValue_1"]:runCsbAction("actionframe_canxue",true)
        end
        
        self.m_HeroMan.lastHp = true
    end

    local hp2 = self.p_bonusExtra.hp2 or 0
    if hp2 == 1 then

        if not self.m_CriminalMan.lastHp then
            if not isInit then
                gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_lastHp.mp3")
            end
            self.m_CriminalMan["HealthValue_1"]:runCsbAction("actionframe_canxue",true)
            self.m_CriminalMan:runCsbAction("actionframe",true)
        end
        self.m_CriminalMan.lastHp = true
    end

    
    

end


function WestPKBonusGameMainView:WinRewordGameView( bonusdata )
    local selected = bonusdata.selected + 1 or 1
    local rewordChoose = bonusdata.rewordChoose or {}
    local selectData = rewordChoose[selected ]
    table.remove( rewordChoose, selected  )

    local clickPos = self.m_PlayerClicked + 1

    if clickPos > 3 or clickPos < 1  then
        clickPos = 1
    end

    local actNode = self.m_BonusWinView["chest_" .. clickPos ]
    actNode:runCsbAction("actionframe",false,function(  )
        actNode:runCsbAction("idleframe_2",true) 

    end)
    actNode.m_lab:setVisible(true)
    if selectData == self.win2 then -- 奖励界面 x2
        actNode.m_lab:runCsbAction("actionframe_2")
    elseif selectData == self.win3 then -- 奖励界面 x3
        actNode.m_lab:runCsbAction("actionframe_3")
    elseif selectData == self.again then -- 奖励界面 在玩一次
        actNode.m_lab:runCsbAction("actionframe_1")

    end



    performWithDelay(self,function(  )
        local index = 0
        for i=1,3 do
            
            if i ~=  clickPos  then
                index = index + 1
                local otherNode_1 = self.m_BonusWinView["chest_" ..i]
                local otherData= rewordChoose[index]
                otherNode_1:runCsbAction("actionframe_1")
                otherNode_1.m_lab:setVisible(true)
                

                if otherData == self.win2 then -- 奖励界面 x2
                    otherNode_1.m_lab:runCsbAction("actionframe_2")
                elseif otherData == self.win3 then -- 奖励界面 x3
                    otherNode_1.m_lab:runCsbAction("actionframe_3")
                elseif otherData == self.again then -- 奖励界面 在玩一次
                    otherNode_1.m_lab:runCsbAction("actionframe_1")
            
                end

            end

        end

        performWithDelay(self,function(  )
            self:beginNextTurn( )
    
        end,1.5)
    end,1)
        
    
end

function WestPKBonusGameMainView:LoseRewordGameView( bonusdata  )
    local selected = bonusdata.selected + 1  or 1
    local rewordChoose = bonusdata.rewordChoose or {}
    local selectData = rewordChoose[selected ]
    table.remove( rewordChoose, selected  )

    local clickPos = self.m_PlayerClicked + 1

    if clickPos > 3 or clickPos < 1  then
        clickPos = 1
    end

    self.m_BonusLoseView:runCsbAction("idle_xuanzhong")

    self.m_BonusLoseView["m_Ma"..clickPos]:runCsbAction("idle_xuanzhong")
 

    local actNodeZi = self.m_BonusLoseView["rewordlab" .. clickPos ]
    actNodeZi:setVisible(true)
    if selectData == self.over then -- 奖励界面 游戏结束
        actNodeZi:runCsbAction("actionframe_1")
    elseif selectData == self.win2 then -- 奖励界面 x2
        actNodeZi:runCsbAction("actionframe_2")
    elseif selectData == self.again then -- 奖励界面 在玩一次
        actNodeZi:runCsbAction("actionframe_3")

    end

    local mask = self.m_BonusLoseView["m_Ma"..clickPos]:findChild("ma".. clickPos .."_ma_hei")
    mask:setVisible(false)


    performWithDelay(self,function(  )
        local index = 0
        for i=1,3 do
            
            if i ~=  clickPos  then
                index = index + 1
    
                self.m_BonusLoseView["m_Ma"..i]:runCsbAction("idle_xuanzhong")
    
                local otherNodeZi = self.m_BonusLoseView["rewordlab" .. i ]
                local otherData = rewordChoose[index]
                otherNodeZi:setVisible(true)
    
                local guang1 = self.m_BonusLoseView["m_Ma"..i]:findChild("Socre_West_ma_".. i .."_Guang_1")
                guang1:setVisible(false)
    
                local guang2 = self.m_BonusLoseView["m_Ma"..i]:findChild("Socre_West_ma_".. i .."_Guang_2")
                guang2:setVisible(false)
                
                if otherData == self.over then -- 奖励界面 游戏结束
                    otherNodeZi:runCsbAction("actionframe_1")
                elseif otherData == self.win2 then -- 奖励界面 x2
                    otherNodeZi:runCsbAction("actionframe_2")
                elseif otherData == self.again then -- 奖励界面 在玩一次
                    otherNodeZi:runCsbAction("actionframe_3")
            
                end
    
                
        
            end
    
        end

        performWithDelay(self,function(  )

            self:beginNextTurn( )
    
        end,1.5)
        
    end,1)
   

    

    
end

function WestPKBonusGameMainView:rewordGameRecvBaseData( featureData )
    
    local oldHp1 = self.p_bonusExtra.hp1

    local bonus = featureData.p_bonus or {}
    self.p_status = bonus.status or "OPEN"

    local data = featureData.p_data or {}
    local selfdata = data.selfData or {}
    local bonusdata =  selfdata.bonusData or {}
    self.p_bonusExtra = bonusdata or {}

    if oldHp1 > 0 then

        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_ChestOpen.mp3")

        -- 赢
        self:WinRewordGameView( bonusdata )
    else

        -- 输
        self:LoseRewordGameView(  bonusdata )
    end

    
    

end

--数据接收
function WestPKBonusGameMainView:recvBaseData(featureData)

    if self.m_GamePlayStates == self.m_GamePlayStates_PK then
        self:pkGameRecvBaseData( featureData )
    else
        self:rewordGameRecvBaseData( featureData )
    end
    

end


function WestPKBonusGameMainView:beginNextTurn( )

    if self:checkIsOver() then -- 直接结束

            local multiple = self.p_bonusExtra.multiple or 1
            local points = self.p_bonusExtra.points or 1

            self:updateWinCoins( points * multiple ,2 )

            -- 停掉背景音乐
            self.m_machine:clearCurMusicBg()

            -- gLobalSoundManager:playSound("WestSounds/sound_West_doorGame_Over.mp3")
            
            performWithDelay(self,function(  )
                if self.m_bonusEndCall then
                    self.m_bonusEndCall()
                end
            end,3)
   
        
    else
        if self.p_bonusExtra.phase == 1 then --1 :送奖

            if self.m_GamePlayStates == self.m_GamePlayStates_PK then
               -- 这种状态说明 由PK界面 转到 奖励页面 
               self:setAllDoorCantClick( )
               
                -- 停掉背景音乐
                self.m_machine:clearCurMusicBg()

               performWithDelay(self,function(  )
                    self:checkShowRewordView( function(  )
                        self.m_BonusLoseView:restAllClickBtn( )
                        self.m_BonusWinView:restAllChest()
                    end ,function(  )

                        local oldHp1 = self.p_bonusExtra.hp1
                        if oldHp1 > 0 then
                            -- 赢
                            self.m_BonusWinView:showBeginAct( function(  )
                                self.m_action=self.ACTION_RECV
                            end)
                        else
                            -- 输
                            self.m_BonusLoseView:showBeginAct( function(  )
                                self.m_action=self.ACTION_RECV
                            end)
                        end

                       
                        
                        
                    end )
               end,2.5)
               
    
    
            elseif self.m_GamePlayStates == self.m_GamePlayStates_REWORD then
                --这种情况基本不会出现，这种状态就是结束了
                print("---------------------- m_GamePlayStates_REWOR 出错了")
            end
            self.m_GamePlayStates = self.m_GamePlayStates_REWORD

        else -- 当前阶段 0:PK 
    
            

            if self.m_GamePlayStates == self.m_GamePlayStates_PK then
               -- 这种状态说明正在pk
               self.m_action=self.ACTION_RECV
    
    
            elseif self.m_GamePlayStates == self.m_GamePlayStates_REWORD then

                -- 这种状态说明 由获得界面 转到 pk 又获得了一轮游戏

                -- 停掉背景音乐
                self.m_machine:clearCurMusicBg()
                
                performWithDelay(self,function(  )
                    self:checkShowPKView( function(  )
                    
                        self:restMainView( )

                    end ,function(  )
    
                        self.m_action=self.ACTION_RECV
    
                    end )
                end,2.5)

            end

            self.m_GamePlayStates = self.m_GamePlayStates_PK
    
        end

    end
    
end

function WestPKBonusGameMainView:setAllDoorCantClick( )
    for i=1,self.m_MaxdoorNum do
        local door = self["door_" .. i]
        if door then
            door:findChild("click"):setVisible(false)
        end

    end
end

function WestPKBonusGameMainView:restdoor( )


    for i=1,self.m_MaxdoorNum do
        local door = self["door_" .. i]
        if door then
            door:runCsbAction("idleframe")
            door:findChild("click"):setVisible(true)
        end

    end
end


function WestPKBonusGameMainView:checkIsOver( )
    local bonusStatus = self.p_status

    if bonusStatus == "CLOSED" then
        return true
    end

    return false
    
end

function WestPKBonusGameMainView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end




--开始结束流程
function WestPKBonusGameMainView:gameOver(isContinue)

end

--弹出结算奖励
function WestPKBonusGameMainView:showReward()

   
end

function WestPKBonusGameMainView:setEndCall( func)
    self.m_bonusEndCall = function(  )
             
            local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
            local winLinesAmount = selfdata.winLinesAmount or 0
            local avgBet = selfdata.avgBet or 1
            local lineBet = self.p_bonusExtra.lineBet or 1
            local multiple = self.p_bonusExtra.multiple or 1
            local points = self.p_bonusExtra.points or 1
            local detailedWin = util_formatCoins(points, 30)   .. " X " ..util_formatCoins(lineBet, 30)  .. " X " .. multiple .. " = " .. util_formatCoins(self.m_serverWinCoins - winLinesAmount, 30) 
            self.m_machine:showPKBonusOverView( self.m_serverWinCoins - winLinesAmount , detailedWin ,function(  )


                if func then
                    func()
                end

             end )

        
    end 
end



function WestPKBonusGameMainView:featureResultCallFun(param)

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


function WestPKBonusGameMainView:showOtherdoor( func )


    if func then
        func()
    end


end

function WestPKBonusGameMainView:updateWinCoins( coins,time )
    
    local lineBet = self.p_bonusExtra.lineBet or 1
    local beiginCoins = self.m_oldWinCoins
    local endCoins = (lineBet * coins) + self.m_fsWinCoin
    self.m_machine:updateBonusWinCoins( beiginCoins, endCoins,time  )
    self.m_oldWinCoins = endCoins
end

function WestPKBonusGameMainView:showGuoChang( func,funcEnd )

    gLobalSoundManager:playSound("WestSounds/music_West_Guochang.mp3")

    local actNode = cc.Node:create()
    self:addChild(actNode)
    self.m_GuoChang:setVisible(true)
    
    self.m_GuoChang:runCsbAction("actionframe",false)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(15/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()

        if func then
            func()
        end


    end)
    actionList[#actionList + 1] = cc.DelayTime:create(15/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()
        self.m_GuoChang:setVisible(false)
        if funcEnd then
            funcEnd()
        end

        actNode:removeFromParent()
    end)

    local seq = cc.Sequence:create(actionList)
    actNode:runAction(seq)

end

function WestPKBonusGameMainView:restMainView( )
    

    self.m_machine:resetMusicBg(nil,"WestSounds/music_West_bonusgame.mp3")

    self.m_CLickTimes = 0

    util_spinePlay(self.m_ManHeroSpine,"idleframe",true)
    util_spinePlay(self.m_ManCriminalSpine,"idleframe",true)

    self.m_CriminalMan:runCsbAction("idleframe")
    self.m_HeroMan:runCsbAction("idleframe")

    self.m_CriminalMan["HealthValue_1"]:runCsbAction("idleframe_1")
    self.m_HeroMan["HealthValue_1"]:runCsbAction("idleframe_1")

    self.m_CriminalMan.lastHp = false
    self.m_HeroMan.lastHp = false

    self.p_choose =  {}
    self.m_CriminalMan:updateHealthValue( self.p_bonusExtra.hp2 )
    self.m_HeroMan:updateHealthValue( self.p_bonusExtra.hp1 )


    self:restdoor( )

    self:updateBulingAct( )

end

-- 牛仔开枪 罪犯未中弹
function WestPKBonusGameMainView:HeroShootMiss( func ,funcCur  )


    performWithDelay(self,function(  )
        if funcCur then
            funcCur()
        end
    
        if func then
            func()
        end 
    end,0.5)
    
end

-- 牛仔开枪 罪犯中弹
function WestPKBonusGameMainView:HeroShootIn( func ,funcCur  )

    self:findChild("man_Hero"):setLocalZOrder(10)
    self:findChild("man_Criminal"):setLocalZOrder(1)

    util_spinePlay(self.m_ManHeroSpine,"actionframe")

    performWithDelay(self,function(  )
        

        self.m_CriminalMan:runCsbAction("actionframe")

        if funcCur then
            funcCur()
        end

        

        util_spinePlay(self.m_ManCriminalSpine,"actionframe2")
        util_spineEndCallFunc(self.m_ManCriminalSpine,"actionframe2",function(  )
            if func then
                func()
            end
        end)

    end,18/30)



end

-- 牛仔开枪 罪犯中弹死亡
function WestPKBonusGameMainView:HeroShootCriminalDeath( func ,funcCur  )
    
    self:findChild("man_Hero"):setLocalZOrder(10)
    self:findChild("man_Criminal"):setLocalZOrder(1)

    util_spinePlay(self.m_ManHeroSpine,"actionframe")

    performWithDelay(self,function(  )


        self.m_CriminalMan:runCsbAction("actionframe")

        if funcCur then
            funcCur()
        end
  
        util_spinePlay(self.m_ManCriminalSpine,"actionframe4")
        util_spineEndCallFunc(self.m_ManCriminalSpine,"actionframe4",function(  )
            if func then
                func()
            end
        end)

    end,18/30)

end

-- 牛仔回血
function WestPKBonusGameMainView:HeroAddBlood( func ,funcCur  )
    
    self:findChild("man_Hero"):setLocalZOrder(10)
    self:findChild("man_Criminal"):setLocalZOrder(1)

    util_spinePlay(self.m_ManHeroSpine,"actionframe3")
    util_spineEndCallFunc(self.m_ManHeroSpine,"actionframe3",function(  )
        
        if funcCur then
            funcCur()
        end

        if func then
            func()
        end
        
    end)
    

end


-- 罪犯开枪 牛仔未中弹
function WestPKBonusGameMainView:CriminalShootMiss( func ,funcCur  )


    performWithDelay(self,function(  )
        if funcCur then
            funcCur()
        end
    
        if func then
            func()
        end 
    end,0.5)

end

-- 罪犯开枪 牛仔中弹
function WestPKBonusGameMainView:CriminalShootIn( func , funcCur  )
    
    
    self:findChild("man_Hero"):setLocalZOrder(1)
    self:findChild("man_Criminal"):setLocalZOrder(10)

    util_spinePlay(self.m_ManCriminalSpine,"actionframe")

    performWithDelay(self,function(  )


        self.m_HeroMan:runCsbAction("actionframe")

        if funcCur then
            funcCur()
        end

        
        util_spinePlay(self.m_ManHeroSpine,"actionframe2")
        util_spineEndCallFunc(self.m_ManHeroSpine,"actionframe2",function(  )
            if func then
                func()
            end
        end)


    end,42/30)

end

-- 罪犯开枪 牛仔中弹死亡
function WestPKBonusGameMainView:CriminalShootHeroDeath( func ,funcCur  )
    
    
    self:findChild("man_Hero"):setLocalZOrder(1)
    self:findChild("man_Criminal"):setLocalZOrder(10)


    util_spinePlay(self.m_ManCriminalSpine,"actionframe")

    performWithDelay(self,function(  )

        self.m_HeroMan:runCsbAction("actionframe")
        
        if funcCur then
            funcCur()
        end

        
        util_spinePlay(self.m_ManHeroSpine,"actionframe4")
        util_spineEndCallFunc(self.m_ManHeroSpine,"actionframe4",function(  )
            if func then
                func()
            end
        end)



    end,42/30)

end


function WestPKBonusGameMainView:updateBulingAct( )
    self.m_actNode:stopAllActions()

    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    for i=1,self.m_MaxdoorNum do
    
        local node =  self["door_"..i]
        local isInChoose =  self:isInArray( self.p_choose ,node.m_index )
        if not isInChoose then
            node:runCsbAction("idleframe5")
        end
        
    end
    waitNode:removeFromParent()

    

    self:beginBulingAct( )

    util_schedule(self.m_actNode, function(  )
        self:beginBulingAct( )

    end, 2)
end

function WestPKBonusGameMainView:beginBulingAct( )
    
 
    local actNode = self:getNextBulingNode( )  
    for i=1,#actNode do
        if actNode[i] then
            actNode[i]:runCsbAction("idleframe5")
        end
    end      
        


end

function WestPKBonusGameMainView:getNextBulingNode( )

    local actList = {}
    local currNode = {}

    for i=1,self.m_MaxdoorNum do
       
        local node =  self["door_"..i]
        local isInChoose =  self:isInArray( self.p_choose ,node.m_index )
        if not isInChoose then
            table.insert(actList,i)
        end
      
    end

    if #actList  > 0 then
        if #actList >= 6 then
            local roadNum = math.random(3,5)

            for i=1,roadNum do
                local index_1 = math.random(1,#actList) 
                currNode[#currNode + 1] = self["door_"..actList[index_1]]
                table.remove(actList,index_1)
            end

        elseif #actList >= 4 then
            local roadNum = math.random(2,3)
        
            for i=1,roadNum do
                local index_1 = math.random(1,#actList) 
                currNode[#currNode + 1] = self["door_"..actList[index_1]]
                table.remove(actList,index_1)
            end
        else
            local index_1 = math.random(1,#actList) 
            currNode[#currNode + 1] = self["door_"..actList[index_1]]
        end
        
    end
    

    return currNode
end

return WestPKBonusGameMainView