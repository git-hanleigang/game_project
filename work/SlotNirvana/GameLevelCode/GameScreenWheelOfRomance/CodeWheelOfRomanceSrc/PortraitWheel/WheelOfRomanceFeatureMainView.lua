local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local WheelOfRomanceFeatureMainView = class("WheelOfRomanceFeatureMainView",BaseGame)

WheelOfRomanceFeatureMainView.DARK_ZORDER = 50
WheelOfRomanceFeatureMainView.POINT_ZORDER = 150

WheelOfRomanceFeatureMainView.POINT_POS = {cc.p(0,-2),cc.p(0,0),cc.p(0,0),cc.p(0,-2)}

WheelOfRomanceFeatureMainView.m_curIndex = 1

WheelOfRomanceFeatureMainView.DIRECTION_TYPE_LEFT = "0"
WheelOfRomanceFeatureMainView.DIRECTION_TYPE_RIGHT = "1"

WheelOfRomanceFeatureMainView.JACKPOT_WHEEL_NUM = 5

WheelOfRomanceFeatureMainView.m_endCallFunc = nil -- 普通结束回调
WheelOfRomanceFeatureMainView.m_endShowJpCallFunc = nil -- 显示另一个jp大圆盘那种结束

WheelOfRomanceFeatureMainView.m_oldBsWinCoins = 0


function WheelOfRomanceFeatureMainView:initUI(machine)
    
    self:createCsbNode("WheelOfRomance_Wheel_1.csb")
    self.m_machine = machine

    self.m_endCallFunc = nil -- 普通结束回调
    self.m_endShowJpCallFunc = nil -- 显示另一个jp大圆盘那种结束


    self.m_jiantou = util_createAnimation("WheelOfRomance_Wheel_jiantou.csb") 
    self:findChild("Node_1"):addChild( self.m_jiantou , self.POINT_ZORDER + 1 )
    self.m_jiantou:runCsbAction("idleframe",true)
    self.m_jiantou:setVisible(false)

    self.m_point = util_createAnimation("WheelOfRomance_Wheel_Kuang_act.csb") 
    self:findChild("Node_1"):addChild( self.m_point , self.POINT_ZORDER )

    self.m_kuang = util_createAnimation("WheelOfRomance_Wheel_kuang.csb") 
    self.m_point:findChild("reel"):addChild( self.m_kuang , self.POINT_ZORDER )
    self.m_kuang:runCsbAction("idleframe",true)

    
    for i=1,4 do
        local wheelData = {}
        wheelData.m_machine = self.m_machine
        wheelData.m_index = i
        local wheel = util_createView("CodeWheelOfRomanceSrc.PortraitWheel.WheelOfRomanceFeatureView",wheelData)
        self:findChild("Node_reel_"..i):addChild(wheel)
        wheel:runCsbAction("dark")
        self:findChild("Node_reel_"..i):setLocalZOrder(i)
        wheel:findChild("Dark"):setVisible(false)
        self["m_wheelView_"..i] = wheel
        
    end
    

    self.m_curIndex = 1
    

end



function WheelOfRomanceFeatureMainView:restFeatureMainView( )


    self.m_kuang:runCsbAction("idleframe",true)
    
    for i=1,4 do
        self:findChild("Node_reel_"..i):setLocalZOrder(i)
        self["m_wheelView_"..i]:runCsbAction("dark")
        self["m_wheelView_"..i]:findChild("Dark"):setVisible(false)
        self["m_wheelView_"..i]:updateFeatureNodeScore()
    end

end

function WheelOfRomanceFeatureMainView:beginRunShowDark(_index )
    for i=1,4 do
        if i ~=  _index then
            self:findChild("Node_reel_"..i):setLocalZOrder(i)
            self["m_wheelView_"..i]:runCsbAction("dark")
            self["m_wheelView_"..i]:findChild("Dark"):setVisible(true) 
        end
        
    end
end

function WheelOfRomanceFeatureMainView:beginOneWheelRun( _index )

    self:beginRunShowDark(_index )

    self.m_curIndex = _index
    self:updatePointPos( self.m_curIndex )
    self:updateWheelZorder(self.m_curIndex )

    gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portraitWheel_Jump_".. self.m_curIndex .. ".mp3")

    

    self.m_point:runCsbAction("actionframe")
    self["m_wheelView_".._index]:beginMove()
    self["m_wheelView_".._index]:runCsbAction("actionframe",false,function(  )
        self["m_wheelView_".._index]:runCsbAction("turn",true)
        self.m_kuang:runCsbAction("actionframe",true)
        self:sendData() 
    end,60)
    

end



function WheelOfRomanceFeatureMainView:updateWheelZorder(_index,_isRest )
    self:findChild("Node_reel_".._index):setLocalZOrder(self.DARK_ZORDER + 2)
    self["m_wheelView_".._index]:findChild("Dark"):setVisible(false)
    if _isRest then
        self["m_wheelView_".._index]:findChild("Dark"):setVisible(true)
        self:findChild("Node_reel_".._index):setLocalZOrder(_index) 
        self["m_wheelView_".._index]:runCsbAction("dark")
    end
end

function WheelOfRomanceFeatureMainView:updatePointPos( _index )
    local Node_reel_pos = cc.p(self:findChild("Node_reel_".._index):getPosition())
    local pos = cc.p(self.POINT_POS[_index].x + Node_reel_pos.x , self.POINT_POS[_index].y + Node_reel_pos.y)
    self.m_point:setPosition(pos)
end

function WheelOfRomanceFeatureMainView:playPointMoveRightAction( _index,_oldIndex,_func)

    local Node_reel_pos = cc.p(self:findChild("Node_reel_".._index):getPosition())
    local pos = cc.p(self.POINT_POS[_index].x + Node_reel_pos.x , self.POINT_POS[_index].y + Node_reel_pos.y)

    local pointPos = cc.p(self.m_point:getPosition())

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portrairWheel_JianTou.mp3")

        local old_reel_pos = cc.p(self:findChild("Node_reel_".._oldIndex):getPosition())
        local jiantouPos = cc.p(self.POINT_POS[_oldIndex].x + old_reel_pos.x , self.POINT_POS[_oldIndex].y + old_reel_pos.y)
        self.m_jiantou:setPosition(cc.p(jiantouPos.x,jiantouPos.y))
        self.m_jiantou:setVisible(true)
        self.m_jiantou:runCsbAction("actionframe".._oldIndex)
    end)
    actList[#actList + 1] = cc.DelayTime:create(36/60)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portraitWheel_Jump_".. _oldIndex .. ".mp3")

        self.m_jiantou:setVisible(false)
        self["m_wheelView_".._oldIndex]:runCsbAction("actionframe1")
        self.m_point:runCsbAction("actionframe1")
    end)
    actList[#actList + 1] = cc.DelayTime:create(18/60)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        self["m_wheelView_".._oldIndex]:findChild("Particle"):resetSystem()
    end)
    actList[#actList + 1] = cc.DelayTime:create(28/60) 
    actList[#actList + 1] = cc.MoveTo:create(0.1,pos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if _func then
            _func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    self.m_point:runAction(sq)
end

function WheelOfRomanceFeatureMainView:playPointMoveLeftAction( _index,_oldIndex,_func)

    local Node_reel_pos = cc.p(self:findChild("Node_reel_".._index):getPosition())
    local pos = cc.p(self.POINT_POS[_index].x + Node_reel_pos.x , self.POINT_POS[_index].y + Node_reel_pos.y)

    local pointPos = cc.p(self.m_point:getPosition())

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        self.m_jiantou:setVisible(false)
        self["m_wheelView_".._oldIndex]:runCsbAction("actionframe2")
        self.m_point:runCsbAction("actionframe2")
    end)
    actList[#actList + 1] = cc.DelayTime:create(6/60)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        self["m_wheelView_".._oldIndex]:findChild("Particle"):resetSystem()
    end)
    actList[#actList + 1] = cc.DelayTime:create(18/60)
    actList[#actList + 1] = cc.MoveTo:create(6/60,pos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if _func then
            _func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    self.m_point:runAction(sq)
end

function WheelOfRomanceFeatureMainView:onEnter()
    BaseGame.onEnter(self)
end

function WheelOfRomanceFeatureMainView:onExit()
    BaseGame.onExit(self)
 end

 
--接收返回消息
function WheelOfRomanceFeatureMainView:featureResultCallFun(param)

    if self:isVisible() then

        if param[1] == true then
                local spinData = param[2]
                local userMoneyInfo = param[3]
                self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果

                globalData.userRate:pushCoins(self.m_serverWinCoins)
                globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        
                self.m_spinDataResult = spinData.result
                self.m_machine:SpinResultParseResultData(spinData)

                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
                
        else
                -- 处理消息请求错误情况
                --TODO 佳宝 给与弹板玩家提示。。
                gLobalViewManager:showReConnect(true)
        end
    end
   
end

function WheelOfRomanceFeatureMainView:wheelRunDownCallFunc(_nextcurIndex,_moveState )


    if _nextcurIndex == self.JACKPOT_WHEEL_NUM then

        print( "--  -----------  进入 jackpot大圆盘")

        self.m_machine:clearCurMusicBg()

        self["m_wheelView_"..self.m_curIndex]:runCsbAction("dark",false,function(  )

            gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_PortraitWheel_OverMove.mp3")

            self:runCsbAction("over",false,function(  )
                if self.m_endShowJpCallFunc then
                    self.m_endShowJpCallFunc()
                end

            end,60)

        end,60)
        
        
    else

        self.m_kuang:runCsbAction("idleframe")
        
        local dev = self:getMovePosDeviation(_moveState )

        if dev > 0 then

            -- 向右
            self:playPointMoveRightAction( _nextcurIndex,self.m_curIndex,function(  )

                self:updateWheelZorder(self.m_curIndex,true ) -- 重置老的滚轮层级
                self.m_curIndex = _nextcurIndex
                self:beginOneWheelRun(_nextcurIndex)

            end)

        else
            -- 向左
            self:playPointMoveLeftAction( _nextcurIndex,self.m_curIndex,function(  )

                self:updateWheelZorder(self.m_curIndex,true ) -- 重置老的滚轮层级
                self.m_curIndex = _nextcurIndex
                self:beginOneWheelRun(_nextcurIndex)

            end)
        end
    end

    


end

function WheelOfRomanceFeatureMainView:getMovePosDeviation(_moveStates )
    if _moveStates == self.DIRECTION_TYPE_LEFT then

        return -1
    elseif _moveStates == self.DIRECTION_TYPE_RIGHT then
        return 1
    end

end

function WheelOfRomanceFeatureMainView:getAnlysisWheelNetData( _str)
    
    local pos = string.find(_str,"=")
    local strLen = string.len(_str)
    local poins = string.sub(_str,1 ,pos - 1)
    local moveStates = string.sub(_str,pos + 1 ,strLen)

    return poins,moveStates
end

--数据接收
function WheelOfRomanceFeatureMainView:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action = self.ACTION_RECV
  
    --数据赋值
    local bonusdata =  featureData.p_bonus or {}
    self.p_status = bonusdata.status
    self.p_bsWinCoins = bonusdata.bsWinCoins 
    local data = featureData.p_data or {}
    self.m_selfData = data.selfData or {}


    local wheelResult =  self.m_selfData.wheelResult or {}
    local endIndex = wheelResult.index or 0 -- 返回数据的位置
    local endPoints = wheelResult.points or 0 -- 点数
    local endNumber = wheelResult.number or 1 -- 当前是哪个滚轮请求的数据
    local wheelData = wheelResult.wheel 
    local endValue = endIndex + 1
    local wheelIndexData = wheelData[endValue]
  
    local poins,moveStates = self:getAnlysisWheelNetData( wheelIndexData)
    local nextReelIndex =  self.m_curIndex + self:getMovePosDeviation(moveStates )

    if wheelData then
        
        print("---------------wheelIndexData: "..wheelIndexData)
    end
    
    self["m_wheelView_"..self.m_curIndex]:setOverCallBackFun(function(  )
        

        local index = math.random(1,2)
        if moveStates == self.DIRECTION_TYPE_LEFT then
            gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portrairWheel_WinCoins_Left".. index.. ".mp3")
        elseif moveStates == self.DIRECTION_TYPE_RIGHT then
            gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portrairWheel_WinCoins_Right".. index.. ".mp3")
        end
       
        gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_portrairWheel_WinCoins.mp3")

        self["m_wheelView_"..self.m_curIndex]:runCsbAction("idleframe",true)
        

        self.m_kuang:runCsbAction("actionframe1")

        -- 先更新赢钱
        local bsWincoins = self.p_bsWinCoins or 0
        local beginCoins = self.m_oldBsWinCoins
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        local params = {bsWincoins,nil,nil,beginCoins}
        params[self.m_machine.m_stopUpdateCoinsSoundIndex] = true

        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
        globalData.slotRunData.lastWinCoin = lastWinCoin 
        
        self.m_oldBsWinCoins = bsWincoins

        performWithDelay(self,function(  )

            if self.p_status == "CLOSED" then
                print(" -- 竖版滚轮滚到最左边结束")
                if self.m_endCallFunc then
                    self.m_endCallFunc()
                    self.m_endCallFunc = nil
                end
            else
                self:wheelRunDownCallFunc(nextReelIndex,moveStates)
            end

        end,1.5)

        

        

    end)
    self["m_wheelView_"..self.m_curIndex]:setEndValue(endIndex + 1)

end


--数据发送
function WheelOfRomanceFeatureMainView:sendData()
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData={msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function WheelOfRomanceFeatureMainView:setWheelEndCall(_func,_funcShowJp )
    self.m_endCallFunc = function(  )

        self:setVisible(false)

        if _func then
            _func()
        end
        self.m_endCallFunc = nil
        self.m_endShowJpCallFunc = nil
    end

    self.m_endShowJpCallFunc = function(  )

        self:setVisible(false)

        if _funcShowJp then
            _funcShowJp()
        end

        self.m_endCallFunc = nil
        self.m_endShowJpCallFunc = nil
    end
end

return WheelOfRomanceFeatureMainView