---
--xcyy
--2018年5月23日
--MermaidBonusView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local MermaidBonusView = class("MermaidBonusView",BaseGame )

MermaidBonusView.m_machine = nil
MermaidBonusView.m_bonusEndCall = nil

MermaidBonusView.m_bonusStartStates = "timesPick"
MermaidBonusView.m_bonusPaoView = 1

function MermaidBonusView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("Mermaid/GameScreenMermaid_qipao.csb")

    self.m_BonusStartView = util_createView("CodeMermaidSrc.MermaidBonusStartView",self) 
    self:findChild("root_2"):addChild(self.m_BonusStartView)
    self.m_BonusStartView:setVisible(false)

    self.m_BonusPaoView = util_createView("CodeMermaidSrc.MermaidBonusPaoView",self) 
    self:findChild("root_1"):addChild(self.m_BonusPaoView)
    self.m_BonusPaoView:setVisible(false)

    self.m_BonusPaoView:startPaoPaoAction( )

    self.m_currBonusType = self.m_bonusStartStates -- multiplePick
    self.m_winCoins = 0
    self.m_clickTimes = 0
    self.m_picks = {}
    
    
    

end

function MermaidBonusView:showBonusStartView( )


    self.m_BonusStartView:runCsbAction("start",false,function(  )
        -- 按钮可以点击
        self:startGameCallFunc()
    end)
    self.m_BonusStartView:setVisible(true)

end

function MermaidBonusView:showBonusPaoView( )

    self.m_BonusPaoView:setVisible(true)
    -- 按钮可以点击
    self:startGameCallFunc()


end


function MermaidBonusView:restView( spinData, featureData )
    
    local bonusdata = featureData.p_bonus or {}
    local choose = bonusdata.choose or {}
    local content = bonusdata.content or {}
    local extra = bonusdata.extra or {}
    local bonusType = extra.pickType or self.m_bonusStartStates
    local totalWinCoins = extra.totalWinCoins or 0
    local winCoins = extra.winCoins or 0
    local pickTimes = extra.pickTimes or 0

    self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN"):setString(util_formatCoins(totalWinCoins,9))
    self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN_0"):setString(pickTimes)

    self.m_picks = {}

    if bonusType == self.m_bonusStartStates then
        if #content == 3 then
            self:showBonusPaoView( )
        else
            self:showBonusStartView( )
        end
    else
        self:showBonusPaoView( )
    end


end


function MermaidBonusView:onEnter()
    BaseGame.onEnter(self)
end
function MermaidBonusView:onExit()
    scheduler.unschedulesByTargetName("MermaidBonusView")
    BaseGame.onExit(self)

end

function MermaidBonusView:isTouch()

    if self.m_action == self.ACTION_SEND then
        return false
    elseif self.m_action == self.ACTION_NONE then
        return false
    elseif self.m_action == self.ACTION_OVER then
        return false
    end

    return true
end

--数据发送
function MermaidBonusView:sendData(pos)

    -- gLobalSoundManager:playSound("OZSounds/music_OZ_Bonus_clickChest.mp3")

    -- release_print("真实点击海螺的数据请求 ")

    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT , data= pos , mermaidVersion = 0 } 
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    
end

--数据接收
function MermaidBonusView:recvBaseData(featureData)

    local bonusdata = featureData.p_bonus or {}
    local choose = bonusdata.choose or {}
    local content = bonusdata.content or {}
    local bonusStates = bonusdata.status

    local extra = bonusdata.extra or {}
    local bonusType = extra.pickType or self.m_bonusStartStates
    local totalWinCoins = extra.totalWinCoins or 0
    local winCoins = extra.winCoins or 0
    local pickTimes = extra.pickTimes or 0
    local actPao = self.m_BonusPaoView.m_clickedPao

    self.m_picks = extra.picks or {}

    if #self.m_picks > 0 then
        self.m_winCoins = 0
        self.m_clickTimes = pickTimes
        self.m_machine:setPickTimes( self.m_clickTimes )
    end
     
    -- release_print("真实点击海螺的数据请求 recvBaseData ")

    if bonusType == self.m_bonusStartStates then

        -- release_print("真实点击海螺的数据请求 进入海螺逻辑 ")

        if #content == 3 then

            -- release_print("真实点击海螺的数据请求 进入海螺逻辑 判断 ")

            -- release_print("真实点击海螺的数据请求 点击位置 " .. self.m_BonusStartView.clickPos)
            local clickPos = self.m_BonusStartView.clickPos
            local chooseTimes = content[choose[1] + 1]
            table.remove(content,choose[1] + 1)

            self.m_BonusStartView["m_hailuo_"..clickPos]:findChild("BitmapFontLabel_1"):setString(chooseTimes)
            
            if clickPos == 1 then
                self.m_BonusStartView.m_hailuo_2:runCsbAction("dark")
                self.m_BonusStartView.m_hailuo_3:runCsbAction("dark")
                self.m_BonusStartView.m_hailuo_2:findChild("BitmapFontLabel_1"):setString(content[1])
                self.m_BonusStartView.m_hailuo_3:findChild("BitmapFontLabel_1"):setString(content[2])
    
            elseif clickPos == 2 then
                self.m_BonusStartView.m_hailuo_1:runCsbAction("dark")
                self.m_BonusStartView.m_hailuo_3:runCsbAction("dark")
                self.m_BonusStartView.m_hailuo_1:findChild("BitmapFontLabel_1"):setString(content[1])
                self.m_BonusStartView.m_hailuo_3:findChild("BitmapFontLabel_1"):setString(content[2])
            else
                self.m_BonusStartView.m_hailuo_1:runCsbAction("dark")
                self.m_BonusStartView.m_hailuo_2:runCsbAction("dark")
                self.m_BonusStartView.m_hailuo_1:findChild("BitmapFontLabel_1"):setString(content[1])
                self.m_BonusStartView.m_hailuo_2:findChild("BitmapFontLabel_1"):setString(content[2])
            end


            -- release_print("真实点击海螺的数据请求 开始播放 actionframe " )
            self.m_BonusStartView["m_hailuo_"..clickPos]:runCsbAction("actionframe",false,function(  )
            
                -- release_print("真实点击海螺的数据请求 开始播放 actionframe 播放完毕 开始定时 " )
                    performWithDelay(self,function(  )

                        util_setCascadeOpacityEnabledRescursion(self.m_BonusStartView,true)

                        -- release_print("真实点击海螺的数据请求 开始播放 actionframe 播放完毕 第一个小游戏结束 " )
                        -- 第一个小游戏结束
                        self.m_BonusStartView:runCsbAction("over",false,function(  )
                            -- release_print("真实点击海螺的数据请求 设置可以点击 并隐藏 m_BonusStartView " )
                            self.m_action=self.ACTION_RECV
                            self.m_BonusStartView:setVisible(false)
                            
                            if #self.m_picks > 0 then

                                self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN"):setString(util_formatCoins(0,9))
                                self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN_0"):setString(pickTimes)

                            else
                                self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN"):setString(util_formatCoins(totalWinCoins,9))
                                self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN_0"):setString(pickTimes)
                            end
                            

                            util_playFadeOutAction(self.m_BonusPaoView,0.1,function(  )
                                self.m_BonusPaoView:setVisible(true)
                                util_playFadeInAction(self.m_BonusPaoView,0.2,function(  )
                                    self:showBonusPaoView( )
                                end)
                            end)
                            

                        end)
                    end,1)
                    
       

            end)
            
            

        end
    
    else

        if actPao then

            -- 这里还保留着点泡泡新代码结构，是为了兼容老关代码
            local betNum = content[#content]
            actPao:setLocalZOrder(10)

            if bonusStates == "CLOSED" then

                actPao:runCsbAction("actionframe",false,function(  )
                    actPao:removeFromParent()
        
                    self.m_BonusPaoView.m_actNode:stopAllActions()
                    util_playFadeOutAction(self.m_BonusPaoView ,0.3)

                    self.m_machine:clearCurMusicBg()
                    self.m_machine:showBonusGameOverView(util_formatCoins(totalWinCoins,50),function(  )
                        
                
                        self.m_machine.m_Mermaid_loadingbar:restLoadingQiPao( )
                        self.m_machine:restAllIce( )
                        self.m_machine:findChild("reel"):setVisible(true)
                        self.m_machine.m_Mermaid_JpBarView:setVisible(true)

                        util_playFadeOutAction(self ,0.5,function(  )

                            local oldCoins = globalData.slotRunData.lastWinCoin 
                            globalData.slotRunData.lastWinCoin = 0
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{totalWinCoins,true,true})
                            globalData.slotRunData.lastWinCoin = oldCoins

                            -- 更新游戏内每日任务进度条
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                            -- 通知bonus 结束， 以及赢钱多少
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{totalWinCoins, GameEffect.EFFECT_BONUS})

                            if self.m_overCallFunc then
                                self.m_overCallFunc()
                            end

                            self:removeFromParent()
                        end)
                            


                    
                    end)
                    
        
                end)

                
                
            else

                actPao:runCsbAction("actionframe",false,function(  )
                    actPao:removeFromParent()
                end)
                
                performWithDelay(self,function(  )
                    self.m_action=self.ACTION_RECV
                end,0.2)
                
            end

            
            actPao:findChild("BitmapFontLabel_3"):setString(util_formatCoins(winCoins,3))

            self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN"):setString(util_formatCoins(totalWinCoins,9))
            self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN_0"):setString(pickTimes)
            self.m_BonusPaoView.m_winBarView:runCsbAction("actionframe")
            self.m_BonusPaoView.m_winBarView:findChild("Particle_1"):resetSystem()
        end
        
        
    end
            
    
                
end


function MermaidBonusView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end



--开始结束流程
function MermaidBonusView:gameOver(isContinue)

end

--弹出结算奖励
function MermaidBonusView:showReward()

   
end

function MermaidBonusView:setEndCall( func)
    self.m_bonusEndCall = func
end



function MermaidBonusView:featureResultCallFun(param)

    -- release_print("新的一套自己模拟点击的 最新的兼容代码 返回 featureResultCallFun")

    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        -- release_print("--" .. cjson.encode(spinData))
        
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果


        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

        if spinData.action == "FEATURE" then
            self.m_featureData:parseFeatureData(spinData.result)
            self.m_spinDataResult = spinData.result

            self:recvBaseData(self.m_featureData)

            self.m_machine:SpinResultParseResultData( spinData)

            
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
        --TODO 佳宝 给与弹板玩家提示。。
        gLobalViewManager:showReConnect(true)
    end
end

function MermaidBonusView:setOverCallFunc( func )
    self.m_overCallFunc = function(  )
        if func then
            func()
        end
    end
end



-- 泡泡点击发送消息
-- 为了兼容两种情况，
-- 1、服务器发送回所有结果客户端自己解析
-- 2、每次点击发送消息
function MermaidBonusView:sendPaoPaoViewData( )

    if #self.m_picks > 0 then
        self.m_action=self.ACTION_SEND
        self:recvPaoPaoViewBaseData()

        -- release_print("最新的自己模拟点击气泡的数据请求 ")

    else

        -- release_print("走老的一套点击气泡的数据请求 ")
        self.m_action=self.ACTION_SEND
        local httpSendMgr = SendDataManager:getInstance()
        -- 拼接 collect 数据， jackpot 数据
        local messageData={msg=MessageDataType.MSG_BONUS_SELECT }
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
    

end

--数据接收 
-- 这里才是点泡泡新代码结构
function MermaidBonusView:recvPaoPaoViewBaseData()

    local bonusdata = self.m_featureData.p_bonus or {}

    local extra = bonusdata.extra or {}
    local bonusType = extra.pickType or self.m_bonusStartStates
    local totalWinCoins = extra.totalWinCoins or 0

    local content = extra.picks or {}

    local coins = content[self.m_clickTimes] or 0

    local winCoins = coins +  self.m_winCoins
    local pickTimes = self.m_clickTimes  - 1
    local actPao = self.m_BonusPaoView.m_clickedPao
    
    self.m_winCoins = winCoins
    self.m_clickTimes = pickTimes
    self.m_machine:setPickTimes( self.m_clickTimes )

    -- release_print("新的一套自己模拟点击的 剩余次数 :" .. self.m_clickTimes)

    local bonusStates = "OPEN"
    if self.m_clickTimes <= 0 then
        bonusStates = "CLOSED"
        self.m_machine:setPickTimes( "" )
    end

    if actPao then
        actPao:setLocalZOrder(10)

        if bonusStates == "CLOSED" then

            actPao:runCsbAction("actionframe",false,function(  )
                actPao:removeFromParent()

                self.m_BonusPaoView.m_actNode:stopAllActions()
                util_playFadeOutAction(self.m_BonusPaoView ,0.3)

                self.m_machine:clearCurMusicBg()
                self.m_machine:showBonusGameOverView(util_formatCoins(totalWinCoins,50),function(  )
                    
                
                    self.m_machine.m_Mermaid_loadingbar:restLoadingQiPao( )
                    self.m_machine:restAllIce( )
                    self.m_machine:findChild("reel"):setVisible(true)
                    self.m_machine.m_Mermaid_JpBarView:setVisible(true)

                    util_playFadeOutAction(self ,0.5,function(  )

                        local oldCoins = globalData.slotRunData.lastWinCoin 
                        globalData.slotRunData.lastWinCoin = 0
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{totalWinCoins,true,true})
                        globalData.slotRunData.lastWinCoin = oldCoins

                        
                        -- 更新游戏内每日任务进度条
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                        -- 通知bonus 结束， 以及赢钱多少
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{totalWinCoins, GameEffect.EFFECT_BONUS})

                        if self.m_overCallFunc then
                            self.m_overCallFunc()
                        end

                        self:removeFromParent()
                    end)
                        


                
                end)
                

            end)

            
            
        else

            actPao:runCsbAction("actionframe",false,function(  )
                actPao:removeFromParent()
            end)
            
            performWithDelay(self,function(  )
                self.m_action=self.ACTION_RECV
            end,0.2)
            
        end

        
        actPao:findChild("BitmapFontLabel_3"):setString(util_formatCoins(coins,3))

        self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN"):setString(util_formatCoins(winCoins,9))
        self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN_0"):setString(pickTimes)
        self.m_BonusPaoView.m_winBarView:runCsbAction("actionframe")
        self.m_BonusPaoView.m_winBarView:findChild("Particle_1"):resetSystem()
    end
    
        
    
            
    
                
end
-- 这里是新加的一次全发过来数据
function MermaidBonusView:restPaoPaoViewView( spinData, featureData )
    
    self.m_featureData = featureData

    local bonusdata = self.m_featureData.p_bonus or {}


    local extra = bonusdata.extra or {}
    local bonusType = extra.pickType or self.m_bonusStartStates
    local totalWinCoins = extra.totalWinCoins or 0
    local winCoins = 0
    local pickTimes =  self.m_machine:getPickTimes() or 0
    local content = extra.picks or {}

    self.m_picks = extra.picks or {}

    for i=1,#content do
        if i > pickTimes then
            winCoins = winCoins + content[i]
        end
        
    end
    self.m_winCoins = winCoins
    self.m_clickTimes = pickTimes

    self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN"):setString(util_formatCoins(winCoins,9))
    self.m_BonusPaoView.m_winBarView:findChild("m_lb_BONUSWIN_0"):setString(pickTimes)

    self:showBonusPaoView( )
    


end


return MermaidBonusView