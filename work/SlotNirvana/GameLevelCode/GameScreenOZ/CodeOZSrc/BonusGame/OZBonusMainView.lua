---
--xcyy
--2018年5月23日
--OZBonusMainView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local OZBonusMainView = class("OZBonusMainView",BaseGame )

OZBonusMainView.m_machine = nil
OZBonusMainView.m_bonusEndCall = nil

OZBonusMainView.m_MaxChestNum = 12

function OZBonusMainView:initUI(machine,isAct,isWait)

    self.m_machine = machine

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end

    self:createCsbNode("OZ/GameScreenOZ_baoxiang.csb")


    

    self.m_BetIcon = util_createView("CodeOZSrc.BonusGame.OZBonusBetIconView",self)
    self.m_BetIcon:runCsbAction("idle")
    
    self:findChild("Node_Bet"):addChild(self.m_BetIcon)
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local clientMultiply = selfdata.clientMultiply
    if clientMultiply then
        self.m_BetIcon:findChild("BitmapFontLabel_1"):setString( clientMultiply .."x")
    end

    
    local initUICallFunc = function( isShow )
        self:initChestView( isShow )
        self.m_BonusJPView = util_createView("CodeOZSrc.JackpotGame.OZJPtMainView")
        self:findChild("lvdiban"):addChild(self.m_BonusJPView)
        self.m_BonusJPView:runCsbAction("idle2",true)

        self:initJackpotData( )
        -- 按钮可以点击
        self:startGameCallFunc()
    end

    if isAct then
        self.m_BetIcon:setPosition(cc.p(-426,-192))

        local actLsit = {}
        actLsit[#actLsit + 1] = cc.CallFunc:create(function(  )
            self.m_BetIcon:runCsbAction("actionframe2")
            self.m_BetIcon:findChild("Particle_1"):setVisible(true)
            self.m_BetIcon:findChild("Particle_1"):resetSystem()
        end)
        actLsit[#actLsit + 1] = cc.DelayTime:create(35/30)
        actLsit[#actLsit + 1] = cc.MoveTo:create(0.5,cc.p(0,0))
        actLsit[#actLsit + 1] = cc.CallFunc:create(function(  )
            initUICallFunc( true)
        end)
        local sq = cc.Sequence:create(actLsit)
        self.m_BetIcon:runAction(sq)

    else
        initUICallFunc()
    end

    


    
    

    

end

function OZBonusMainView:getBonusJackpotCounts( )
    
    local jackpotCounts = { Mini = 0,Major = 0,Minor = 0}

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local icons = selfdata.icons
    if icons then
        for i=1,#icons do
            local chestType = icons[i]
            if chestType == "Major" then
                jackpotCounts["Major"] = jackpotCounts["Major"] + 1
            elseif chestType == "Minor" then
                jackpotCounts["Minor"] = jackpotCounts["Minor"] + 1
            elseif chestType == "Mini" then
                jackpotCounts["Mini"] = jackpotCounts["Mini"] + 1
            end
        end
        
    end

    return jackpotCounts

end

function OZBonusMainView:initJackpotData( )
    
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local collectBetCoins = selfdata.collectBetCoins or {Mini = 0,Major = 0,Minor = 0}
    local jackpotCounts = self:getBonusJackpotCounts( )

    for k,v in pairs(collectBetCoins) do
        local coins = v
        local labname = k .. "_coins" 
        local lab =  self.m_BonusJPView:findChild(labname)
        if lab then
            lab:setString(util_formatCoins(coins,50) )
            self.m_BonusJPView:updateLabelSize({label=lab,sx=1,sy=1},208)
        end
    end

    for k,v in pairs(jackpotCounts) do
        local num = v
        for i=1,3 do

            local nodename = k .. "_node_" .. i .. "_Diamond" 
            local diamond =  self.m_BonusJPView[nodename]
            if diamond then
                diamond:setVisible(false)
                if num >= i then
                    diamond:setVisible(true)            
                end 

            end
        end
    end

end

function OZBonusMainView:checkChestClicked( pos )

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local icons = selfdata.icons

    if icons then
        local chestType = icons[pos + 1]
            
        if chestType ~= "-1" then
            return true
        end

    end

end

function OZBonusMainView:initChestView( isinit)
    
    for i=1,self.m_MaxChestNum do
        local netPos = i - 1

        self["Chest"..i] = util_createView("CodeOZSrc.BonusGame.OZBonusChestView",self)
        self:findChild("Node_"..i):addChild(self["Chest"..i])
        self:findChild("Node_"..i):setLocalZOrder(i)
        self["Chest"..i]:setChestViewStates( true)

        self:updateOneChestView( netPos )

        if not self:checkChestClicked( netPos ) then
            self["Chest"..i]:setClickCall(function(  )
                self["Chest"..i]:runCsbAction("chufa",false) 
                self:sendData(netPos)
            end)
            self["Chest"..i]:setChestViewStates( true)
        else
            self["Chest"..i]:setChestViewStates( false)
        end
        
        if isinit then
            self["Chest"..i]:runCsbAction("chuxian")
        end
    end
end

function OZBonusMainView:updateOneChestView( pos )

    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local icons = selfdata.icons

    if icons then
        local chestType = icons[pos + 1]
            
        if chestType ~= "-1" then
            self["Chest".. (pos + 1)]:runCsbAction("idle4")
            -- self:createOneChestGift( self["Chest".. (pos + 1)], chestType)

        else
            self["Chest".. (pos + 1)]:runCsbAction("idle3",true)
        end

    end
end

function OZBonusMainView:getCsbName( chestType )

    if chestType == "Major" then
        return "OZ_tb_zuan_h"
    elseif chestType == "Minor" then
        return "OZ_tb_zuan_z"
    elseif chestType == "Mini" then
        return "OZ_tb_zuan_l"
    else
        
        return "OZ_bx_5x",chestType

    end
end

function OZBonusMainView:createOneChestGift( node, chestType)
    
    local csb_path,betNum = self:getCsbName( chestType )
    local giftAct = util_createAnimation(csb_path..".csb")
    node:findChild("gift"):addChild(giftAct)
    giftAct:runCsbAction("idle")

    if betNum then
        giftAct:findChild("BitmapFontLabel_1"):setString(betNum.."x")
    end

    return giftAct
    
end


function OZBonusMainView:onEnter()
    BaseGame.onEnter(self)
end
function OZBonusMainView:onExit()
    scheduler.unschedulesByTargetName("OZBonusMainView")
    BaseGame.onExit(self)

end

--数据发送
function OZBonusMainView:sendData(pos)

    gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_clickChest.mp3")

    
    self.m_action=self.ACTION_SEND
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
            self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGame")
    else
        
        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= pos }
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end


--数据接收
function OZBonusMainView:recvBaseData(featureData)

    local a = self.m_spinDataResult
    
    local selects = self.m_spinDataResult.selfData.selects
    local icons = self.m_spinDataResult.selfData.icons
    local selectId = selects[#selects]
    local chestType = icons[selectId + 1]
    local clickNode = self["Chest".. (selectId + 1)]
    local betNum = self.m_spinDataResult.selfData.clientMultiply

    local giftShowNode = self:createOneChestGift( clickNode, chestType)
    giftShowNode:setVisible(false)

    gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_OpenChest.mp3")

    clickNode:runCsbAction("actionframe1",false,function(  )
        

        local giftNode = clickNode:findChild("gift") --self:createOneChestGift( clickNode, chestType)
        
        if chestType == "Major" or chestType == "Minor" or chestType == "Mini" then
            -- giftNode:runCsbAction("shouji")
            local time = 1
            local endNode = self:getNetShowDiamond( chestType )
            local csbName = self:getDiamondCsbName( chestType )
            local startNode = giftNode

            gLobalSoundManager:playSound("OZSounds/music_OZ_baoshi_shouji.mp3")

            local flyNode = self:runFlyWildActJumpTo(startNode,endNode,csbName,function(  )

                gLobalSoundManager:playSound("OZSounds/music_OZ_baoshi_za_ban.mp3")

                endNode:setVisible(true)
                endNode:runCsbAction("shouji")


                self:checkIsOver( )

            end,time,0.49848)

            local shoujilizi = "OZ_shoujilizi_tuowei_L.csb"
            if chestType == "Major" then
                shoujilizi = "OZ_shoujilizi_tuowei_L_R.csb"
            elseif chestType == "Minor" then
                shoujilizi = "OZ_shoujilizi_tuowei_L_P.csb"
            elseif chestType == "Mini"  then
                shoujilizi = "OZ_shoujilizi_tuowei_L_B.csb"
            end
            local Particle =  util_createAnimation( shoujilizi )
            flyNode:addChild(Particle,-1)
            Particle:findChild("Particle_1"):setPositionType(0)
            Particle:findChild("Particle_1"):setDuration(time)

        else

            
            -- giftNode:runCsbAction("actionframe1")
            local endNode = self:findChild("Node_Bet")
            local csbName = "OZ_bx_5x"
            local startNode = giftNode
            local flyNode =  self:runFlyWildAct(startNode,endNode,csbName,function(  )

                gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_symbol_Down.mp3")

                self.m_BetIcon:findChild("BitmapFontLabel_1"):setString( betNum .."x")

                self.m_BetIcon:runCsbAction("actionframe")
            
                self:checkIsOver( )
                
                

            end,nil,1)
            flyNode:runCsbAction("idle")
            flyNode:findChild("BitmapFontLabel_1"):setString(giftShowNode:findChild("BitmapFontLabel_1"):getString())
        end


        if giftShowNode then
            giftShowNode:removeFromParent()
            giftShowNode = nil
        end

        
    end) 

    performWithDelay(self,function(  )
        giftShowNode:setVisible(true)
    end,34/30)
    
end

function OZBonusMainView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end

function OZBonusMainView:showOtherChest( )
    
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local icons = selfdata.icons
    local selects = selfdata.selects

    for i=1,#icons do
        local netPos = i - 1
        local chestType = icons[i]
        if self:isInArray( selects, netPos ) then
        
            self["Chest"..i]:runCsbAction("idle4")
            self:createOneChestGift( self["Chest".. (netPos + 1)], chestType)
        else
            self["Chest"..i]:runCsbAction("actionframe2")
            local gift =  self:createOneChestGift( self["Chest".. (netPos + 1)], chestType)
            gift:runCsbAction("idle2")
            
        end

    end

end

function OZBonusMainView:getWInRewordType( )
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local icons = selfdata.icons
    local selects = selfdata.selects

    local MiniNum = 0
    local MinorNum = 0
    local MajorNum = 0
    local winList = {}
    for i=1,#selects do
        local id = selects[i] + 1
        local wintype = icons[id]
        if wintype == "Mini" then
            MiniNum = MiniNum + 1
        elseif wintype == "Minor" then
            MinorNum = MinorNum + 1
        elseif wintype == "Major" then
            MajorNum = MajorNum + 1
        end
    end

    if MajorNum >= 3 then
        return "Major"
    end

    if MinorNum >= 3 then
        return "Minor"
    end

    if MiniNum >= 3 then
        
        return "Mini"
    end

end

function OZBonusMainView:checkIsOver( )
    local status = self.m_spinDataResult.bonus.status

    if status == "CLOSED" then


        performWithDelay(self,function(  )

            self:showOtherChest( )

            performWithDelay(self,function(  )
                local rewordType = self:getWInRewordType()
                -- 走结束的逻辑
                self:showBonusWinView(rewordType ,self.m_BonusWinCoins,function(  )

                    self.m_machine.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_BonusWinCoins))

                    self.m_machine:showOverGuoChang( function(  )

                        self.m_machine.m_BonusChestOver = true

                        -- 更新游戏内每日任务进度条
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_BonusWinCoins,true,false})
                        -- 通知bonus 结束， 以及赢钱多少
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_BonusWinCoins, GameEffect.EFFECT_BONUS})
                
                        self.m_machine:initJackpotData( )
                        self.m_machine:updateGirlPos( )

                        -- if self.m_bonusEndCall then
                        --     self.m_bonusEndCall()
                        -- end 

                        self:setVisible(false)
                    end, function()
                        if self.m_bonusEndCall then
                            self.m_bonusEndCall()
                        end 

                        self:removeFromParent()
                    end )

                end )
            end,2)
        end,1.5)
        
        


        return
    end


    self.m_action=self.ACTION_RECV
end

--开始结束流程
function OZBonusMainView:gameOver(isContinue)

end

--弹出结算奖励
function OZBonusMainView:showReward()

   
end

function OZBonusMainView:setEndCall( func)
    self.m_bonusEndCall = func
end



function OZBonusMainView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_BonusWinCoins = spinData.result.bonus.bsWinCoins

        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if spinData.action == "FEATURE" then
            self.m_featureData:parseFeatureData(spinData.result)
            self.m_spinDataResult = spinData.result

            self.m_machine:SpinResultParseResultData( spinData)
            performWithDelay(self,function(  )
                self:recvBaseData(self.m_featureData)
            end,1)
            
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

 
function OZBonusMainView:getDiamondCsbName( rewordType )
    local csbType = nil
    if rewordType == "Mini" then
        csbType = "l"
    elseif rewordType == "Minor" then
        csbType = "z"
    else
        csbType = "h"
    end
    local csbname = "OZ_tb_zuan_" .. csbType

    return csbname
end

function OZBonusMainView:getNetShowDiamond( rewordType )

    local jackpotCounts = { Mini = 0,Major = 0,Minor = 0}

    for k,v in pairs(jackpotCounts) do
        local num = v
        if rewordType == tostring(k) then
            for i=1,3 do
                local nodename = k .. "_node_" .. i .. "_Diamond" 
                local diamond =  self.m_BonusJPView[nodename]
                if diamond then
                    if not diamond:isVisible() then
                        return diamond
                    end
                end
            end
        end
        
    end
end

function OZBonusMainView:runFlyWildActJumpTo(startNode,endNode,csbName,func,times,scale)


    local flytime = times or 0.5
    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self.m_machine:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = util_getConvertNodePos(endNode,flyNode)

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local actList_1 = {}
        actList_1[#actList_1 + 1] = cc.ScaleTo:create(flytime,scale or 1)
        local sq_1 = cc.Sequence:create(actList_1)
        flyNode:runAction(sq_1)
     end)
    actList[#actList + 1] = cc.JumpTo:create(flytime,cc.p(endPos),-80,1)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end

        local actNode =  flyNode:findChild("Node_show")
        if actNode then
            actNode:setVisible(false)
        end
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(flytime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)

    return flyNode

end

function OZBonusMainView:runFlyWildAct(startNode,endNode,csbName,func,str,scale)

    local flytime = 0.5
    -- 创建粒子
    local flyNode =  util_createAnimation( csbName ..".csb")
    self:findChild("root"):addChild(flyNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 501)

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = util_getConvertNodePos(endNode,flyNode)

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
       local actList_1 = {}
       actList_1[#actList_1 + 1] = cc.ScaleTo:create(flytime,scale or 1)
       local sq_1 = cc.Sequence:create(actList_1)
       flyNode:runAction(sq_1)
    end)
    actList[#actList + 1] = cc.MoveTo:create(flytime,cc.p(endPos))
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        local actNode =  flyNode:findChild("Node_show")
        if actNode then
            actNode:setVisible(false)
        end

        if func then
            func()
        end
        

    end)

    actList[#actList + 1] = cc.DelayTime:create(flytime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:stopAllActions()
        flyNode:removeFromParent()
    end)

    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)

    return flyNode

end

function OZBonusMainView:isTouch()
    -- print(self.ACTION_NONE.."jkjkjkjkj  "..self.ACTION_OVER.."  "..self.m_action)
    if self.m_action == self.ACTION_SEND then
        return true
    end
      
end


function OZBonusMainView:showBonusWinView( rewordType,coins,func )
    
    -- 停止播放背景音乐
    self.m_machine:clearCurMusicBg()

    self:findChild("Node_Bet"):setLocalZOrder(10)

    gLobalSoundManager:playSound("OZSounds/music_OZ_Jp_view_sound.mp3")

    local name = "OZ/FreeSpinOver_0"
    self.m_BonusWheelWin = util_createView("CodeOZSrc.BonusGame.OZBonusWinView",name)   
    self:findChild("WinView"):addChild(self.m_BonusWheelWin)
    self.m_BonusWheelWin:setPosition(-display.width/2,-display.height/2)

    local bet = 1
    local selfdata = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local clientMultiply = selfdata.clientMultiply or 1
    local wheelAllCoins = selfdata.wheelAllCoins or 0

    if clientMultiply then
        bet = clientMultiply
    end

    local oldCoins = (coins - wheelAllCoins)/bet

    local lb = self.m_BonusWheelWin:findChild("m_lb_coins")
    if lb then
        lb:setString(util_formatCoins(oldCoins,50))
        self.m_BonusWheelWin:updateLabelSize({label=lb,sx=0.76,sy=0.76},806)
    end

    
    local lb1 = self.m_BonusWheelWin:findChild("m_lb_coins_0")
    if wheelAllCoins then
        if lb1 then
            lb1:setString(util_formatCoins(wheelAllCoins,50))
            self.m_BonusWheelWin:updateLabelSize({label=lb1,sx=0.76,sy=0.76},806)
        end
    end
    

    local csbname = self:getDiamondCsbName( rewordType )
    local Diamond  = util_createView("CodeOZSrc.JackpotGame.OZJPDiamonds",csbname)
    self.m_BonusWheelWin:findChild("zuan"):addChild(Diamond)


    self.m_BonusWheelWin:setEndCalFunc(function(  )
        

        scheduler.performWithDelayGlobal(function (  )
            
            self.m_machine:resetMusicBg(true)

        
        end,0.3,self.m_machine:getModuleName())


        if func then
            func()
        end

    end) 


    local endpos = cc.p(util_getConvertNodePos(self.m_BonusWheelWin:findChild("Node_fly_pos"),self:findChild("Node_Bet"))) 

    local tuoweiCsb = "OZ_bx_tuowei"
    local tuowei  = util_createView("CodeOZSrc.JackpotGame.OZJPDiamonds",tuoweiCsb)
    self:findChild("Node_Bet"):addChild(tuowei,-1)
    tuowei:findChild("Particle_1"):setDuration(0.5)
    tuowei:findChild("Particle_1"):setPositionType(0)
    tuowei:findChild("Particle_1_0"):setPositionType(0)
    tuowei:findChild("Particle_1_0"):setDuration(0.5)


    
    
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(1)
    actList[#actList + 1] = cc.MoveTo:create(0.5,cc.p(endpos.x,endpos.y - 140 ))
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("OZSounds/music_OZ_Bonu_OverView_baoshi_za.mp3")

        self.m_BonusWheelWin:runCsbAction("actionframe",false,function(  )
            self.m_BonusWheelWin:runCsbAction("idle",true)
        end)

        self.m_BonusWheelWin:findChild("Button_1"):setTouchEnabled(true) 
        self:findChild("Node_Bet"):setVisible(false)


        

        local oldCoinsNew = coins - wheelAllCoins
        local lb2 = self.m_BonusWheelWin:findChild("m_lb_coins")
        if lb2 then

            local startValue = oldCoinsNew/bet
            local addValue = (oldCoinsNew - startValue) /35
            util_jumpNum(lb2,startValue,oldCoinsNew,addValue,0.02,{50},nil,nil,function(  )

                self.m_BonusWheelWin:updateLabelSize({label=lb2,sx=0.76,sy=0.76},806)

            end)

            -- lb2:setString(util_formatCoins(oldCoinsNew,50))
            
        end

    end)
    local sq = cc.Sequence:create(actList)
    self:findChild("Node_Bet"):runAction(sq)

    
end

return OZBonusMainView