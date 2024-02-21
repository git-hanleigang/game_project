local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local WheelOfRomanceWheelView = class("WheelOfRomanceWheelView",BaseGame)

WheelOfRomanceWheelView.WHEEL_RUN_DATA_5 = {"grand","mini","major","mini","minor","mini","major","mini","minor","mini","grand","mini","major","mini","minor","mini","major","mini","minor","mini",}


function WheelOfRomanceWheelView:initUI(machine)
    
    self:createCsbNode("WheelOfRomance_Wheel_2.csb")
    self.m_machine = machine

    self.m_triggerCoins = 0

    self.distance_now = 0
    self.distance_pre = 0
    --添加转动盘
    self.m_wheel = require("CodeWheelOfRomanceSrc.CircularWheel.WheelOfRomanceWheelAction"):create(self:findChild("Wheel"),20,function()
        
    end,function(distance,targetStep,isBack)
        -- 滚动实时调用
        self:setRotionWheel(distance,targetStep)
    end)
    self:addChild(self.m_wheel)
    
    self:addClick(self:findChild("click"))
end

function WheelOfRomanceWheelView:setRotionWheel(distance,targetStep)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_circleWheelRoll.mp3")
    end
end

function WheelOfRomanceWheelView:onEnter()
    BaseGame.onEnter(self)
end

function WheelOfRomanceWheelView:onExit()
    BaseGame.onExit(self)
end

function WheelOfRomanceWheelView:setWheelEndCall(_func )
    self.m_endCallFunc = function(  )

        self:setVisible(false)

        if _func then
            _func()
        end
        self.m_endCallFunc = nil
    end
end

--接收返回消息
function WheelOfRomanceWheelView:featureResultCallFun(param)
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

--点击回调
function WheelOfRomanceWheelView:clickFunc(sender)
    local name = sender:getName()
    if name == "click" then

        self.m_wheel.m_isWheelData = false

        self:beginWheelAction(  )
        self:findChild("click"):setVisible(false)
        -- gLobalSoundManager:playSound("WheelOfRomanceSounds/music_WheelOfRomance_clickedWheelSpin.mp3")
        self:sendData()

    end
end

--数据发送
function WheelOfRomanceWheelView:sendData()
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    local messageData={msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end


--数据接收
function WheelOfRomanceWheelView:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV

    local data = featureData.p_data or {}
    self.m_selfData = data.selfData or {}

    local selfdata = self.m_selfData or {}
    local wheelResult = selfdata.wheelResult or {}
    local endindex = wheelResult.index
    local jackpot = wheelResult.jackpot 

    if endindex then

        self:stopWheelRun( endindex)

    else

    end
 
    
    

    

end

function WheelOfRomanceWheelView:resetView()
    self:findChild("Wheel"):setRotation(0)
end

function WheelOfRomanceWheelView:wheelEndCallFunc( )
    
    self.distance_now = 0
    self.distance_pre = 0

    local selfdata = self.m_selfData  or {}
    local wheelResult = selfdata.wheelResult or {}
    local jackpot = wheelResult.jackpot 
    local number = wheelResult.number 
    local index = 1
    local jpCoins = self.m_serverWinCoins
    local totalCoins = self.m_machine.m_runSpinResultData.p_bonusWinCoins or 0
    if jackpot == "Mini" then
        index = 4
    elseif jackpot == "Minor" then
        index = 3
    elseif jackpot == "Major" then
        index = 2
    elseif jackpot == "Grand" then
        index = 1
    end

    print("-----------  转盘停止 -- "..jackpot)


    local overCallFunc = function(  )

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{totalCoins, GameEffect.EFFECT_BONUS})

        local beiginCoins = self.m_triggerCoins

        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{totalCoins,true,true,beiginCoins})
        globalData.slotRunData.lastWinCoin = lastWinCoin 

        if self.m_endCallFunc then
            self.m_endCallFunc()
        end

    end

    gLobalSoundManager:playSound("WheelOfRomanceSounds/sound_WheelOfRomance_cirleWheel_WinCoins.mp3")

    self.m_machine:clearCurMusicBg()
    
    self:runCsbAction("actionframe1",true)

    performWithDelay(self,function(  )

        if number and number >= 5 then
            -- 说明玩过竖版的滚轮玩法
            self.m_machine:showGrandBonusOver(jpCoins,totalCoins-jpCoins,index,function(  )
                overCallFunc()
            end)
        else
            
            self.m_machine:showJackpotWinView(index,jpCoins,function(  )
                overCallFunc()
            end)
    
        end 

    end,84/60)
    

    
    


    

end

function WheelOfRomanceWheelView:beginWheelAction(  )


    self:runCsbAction("actionframe",false,function(  )
        
        self:runCsbAction("turn",true)
        
    end,60)

    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = handler(self,self.wheelEndCallFunc)

    self.m_wheel:changeWheelRunData(wheelData)
    self.m_wheel:beginWheel()

    

    
end

function WheelOfRomanceWheelView:stopWheelRun( _endindex)
    
    self.m_wheelIndex = _endindex + 1

    self.m_wheel:recvData(self.m_wheelIndex)
end


return WheelOfRomanceWheelView