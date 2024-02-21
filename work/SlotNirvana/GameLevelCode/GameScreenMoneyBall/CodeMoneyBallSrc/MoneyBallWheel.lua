---
--xcyy
--2018年5月23日
--MoneyBallWheel.lua

local MoneyBallWheel = class("MoneyBallWheel",util_require("base.BaseView"))

local JACKPOT_ANGLE = 
{
    GRAND = {78, 90, 102},
    MAJOR = {168, 180, 192},
    MINOR = {348, 0, 12},
    MINI = {258, 270, 282}
}
local JACKPOT_END_POS =
{
    GRAND = {cc.p(63.5, 278.5), cc.p(2, 285.50), cc.p(-59.50, 278.5)},
    MAJOR = {cc.p(-278.50, 58.5), cc.p(-284.50, -3.5), cc.p(-278.00, -65)},
    MINOR = {cc.p(279.50, -65.50), cc.p(286.00, -3.5), cc.p(279.00, 58)},
    MINI = {cc.p(-60, -278), cc.p(2, -285), cc.p(63, -278.50)}
}
local  JACKPOT_ARRAY = {"GRAND", "MAJOR", "MINOR", "MINI"}


MoneyBallWheel.ACTION_READY = 0  --准备
MoneyBallWheel.ACTION_START = 1   --开始
MoneyBallWheel.ACTION_RUNNING = 2  --进行
MoneyBallWheel.ACTION_SLOW = 4     -- 减速

function MoneyBallWheel:initUI(_machine)
    self.m_machine = _machine
    self:createCsbNode("MoneyBall_Wheel.csb")

    -- self:runCsbAction("idle") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self.m_spinBtn = util_createView("CodeMoneyBallSrc.MoneyBallWheelSpinBtn")
    self:findChild("Node_2"):addChild(self.m_spinBtn)
    self.m_spinBtn:setVisible(false)

    self.m_tip = util_createAnimation("MoneyBall_anniutishi.csb")
    self:findChild("Node_2"):addChild(self.m_tip)
    self.m_tip:setPositionY(162)

    for i = 1, #JACKPOT_ARRAY, 1 do
        local name = JACKPOT_ARRAY[i]
        local parent = self:findChild(name)
        if parent ~= nil then
            self["jackpot_"..name] = util_createView("CodeMoneyBallSrc.MoneyBallWheelJackpot", name)
            parent:addChild(self["jackpot_"..name])

            self["effect_"..name] = util_createView("CodeMoneyBallSrc.MoneyBallWheelEffect")
            parent:addChild(self["effect_"..name])
        end
    end

    self.m_effect = util_createView("CodeMoneyBallSrc.MoneyBallWheelEffect1")
    self:findChild("Node_1"):addChild(self.m_effect)
    self.m_effect:setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self, true)

    self.m_vecBallsEffect = {}

    self.m_status = self.ACTION_READY
    self.m_startAngle = 270
    self.m_radius = 340

    self.m_startV = 5
    self.m_addV = 0.2
    self.m_runV = 30
    self.m_runTime = 0.5
    self.m_subV = 0.1
    self.m_stopV = 4

end

function MoneyBallWheel:onEnter()
    gLobalNoticManager:addObserver(self,function()  -- 更新赢钱动画
        if self.m_bBallRun == true then
            self.m_status = self.ACTION_SLOW
            self.m_bQuickStop = true
        else
            self:ballStartRun()
        end
    end, "CLICK_BALL_SPIN")
    
end

function MoneyBallWheel:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function MoneyBallWheel:initGameOverCall(func)
    
end

function MoneyBallWheel:showWheel(func)
    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_wheel_change.mp3")
    self:runCsbAction("start", false, function()
        self.m_spinBtn:setVisible(true)
        self.m_spinBtn:showBtn()
        self.m_tip:playAction("show")
    end)
    if func ~= nil then
        self.m_gameOverCall = function()
            func()
        end
    end
end

--保存时间
function MoneyBallWheel:saveTime()
    self.m_curTime = socket.gettime()
end

--读取时间间隔
function MoneyBallWheel:getSpanTime()
    local spanTime = (socket.gettime() - self.m_curTime)
    return spanTime
end --更新滚动

function MoneyBallWheel:updateBall(dt, ball, endAngle, endPos, jackpot, tail)
    if self.m_status == self.ACTION_START then
        if self.currV >= self.m_runV then
            self.currV = self.m_runV
            self.m_status = self.ACTION_RUNNING
            self:saveTime()
        else
            self.currV = self.currV + self.m_addV
        end
    elseif self.m_status == self.ACTION_RUNNING then
        local time = self:getSpanTime()
        if time >= self.m_runTime then
            if math.abs(self.m_startAngle - endAngle) >= 170 and math.abs(self.m_startAngle - endAngle) <= 200 then
                self.m_status = self.ACTION_SLOW
            end
        end 
    elseif self.m_status == self.ACTION_SLOW then 
        self.currV = self.currV - self.m_subV
        if self.currV <= self.m_stopV then
            self.currV =self.m_stopV
        else
            self.currV = self.currV - self.m_subV
        end
    end
    local angle = self.currV * 180 / 3.14 / self.m_radius

    local gameOver = false
    self.m_startAngle = (self.m_startAngle + angle) % 360
    if self.m_bQuickStop == true then
        self.m_startAngle = endAngle
        tail:removeFromParent()
        tail = nil
    end
    if self.m_status == self.ACTION_SLOW then
        if math.abs(self.m_startAngle - endAngle) <= 2 or math.abs(self.m_startAngle - endAngle) >= 358 then
            self.m_startAngle = endAngle
            gameOver = true
            self.m_bBallRun = false
            self:unscheduleUpdate()

            local pos = cc.p(self:findChild(jackpot):getPosition())
            local rotation = self:findChild(jackpot):getRotation()
            self.m_effect:setVisible(true)
            self.m_effect:setPosition(pos)
            self.m_effect:setRotation(rotation)
            self.m_effect:showAnim(function()
                self.m_effect:setVisible(false)
                if self[jackpot.."_num"] == 1 then
                    self["effect_"..jackpot]:setVisible(true)
                elseif self[jackpot.."_num"] == 2 then
                    local ballEffect = util_createView("CodeMoneyBallSrc.MoneyBallEffect")
                    local parent = self:findChild("Node_1")
                    parent:addChild(ballEffect, 2)
                    ballEffect:setPosition(JACKPOT_END_POS[jackpot][3])
                    ballEffect:showReminder()
                    self.m_vecBallsEffect[#self.m_vecBallsEffect + 1] = ballEffect
                elseif self[jackpot.."_num"] == 3 then
                    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_reward_jackpot.mp3")
                    self["jackpot_"..jackpot]:showAnim()
                end
                
                for i = 1, #JACKPOT_ARRAY, 1 do
                    local jp = JACKPOT_ARRAY[i]
                    if self[jp.."_num"] ~= nil then
                        self["effect_"..jp]:showAnim(self[jp.."_num"])
                    end
                end
            end)
            if self.m_gameProgress <= #self.m_gameData.content then
                self.m_spinBtn:setClickFlag(true)
            end
            
            self.m_ballStartAction = performWithDelay(self, function()
                if self.m_gameProgress > #self.m_gameData.content then
                    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_pop_jackpot.mp3")
                    local jackpotLayer = util_createView("CodeMoneyBallSrc.MoneyBallJackpotView", self.m_machine)
                    jackpotLayer:initViewData(self.m_gameData.bsWinCoins, jackpot, function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, false)
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_gameData.bsWinCoins, true, false})
                        self.m_gameOverCall()
                    end)
                    gLobalViewManager:showUI(jackpotLayer)
                else
                    self.m_ballStartAction = nil
                    self.m_spinBtn:startGame()
                    -- self:ballStartRun()
                end
            end, 3)
        elseif math.abs(self.m_startAngle - endAngle) <= 30 or math.abs(self.m_startAngle - endAngle) >= 330 then
            self.m_radius = self.m_radius - 3
            if self.m_radius < 285 then
                self.m_radius = 285
            end
        end
    end
    local pos = cc.p(util_getCirclePointPos(0, 0, self.m_radius, self.m_startAngle))
    if gameOver == true then
        pos = endPos
        local ballEffect = util_createView("CodeMoneyBallSrc.MoneyBallEffect")
        local parent = self:findChild("Node_1")
        parent:addChild(ballEffect, 2)
        ballEffect:setPosition(JACKPOT_END_POS[jackpot][self[jackpot.."_num"]])
        ballEffect:ballArrive()

        if self.m_ballRunSoundID ~= nil then
            gLobalSoundManager:stopAudio(self.m_ballRunSoundID)
            self.m_ballRunSoundID = nil
        end
        
        if self[jackpot.."_num"] == 1 then
            gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_ball_enter_1.mp3")
        elseif self[jackpot.."_num"] == 2 then
            gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_ball_enter_2.mp3")
        elseif self[jackpot.."_num"] == 3 then
            gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_ball_enter_3.mp3")
            gLobalSoundManager:stopBgMusic()
            self.m_spinBtn:setStopFlag(false)
            for i = #self.m_vecBallsEffect, 1, -1 do
                local effect = self.m_vecBallsEffect[i]
                effect:removeFromParent()
                table.remove(self.m_vecBallsEffect, i)
            end
        end
    end
    ball:setPosition(pos)
    if gameOver ~= true then
        pos = cc.p(util_getCirclePointPos(0, 0, self.m_radius, self.m_startAngle + 3))
    end
    if tail ~= nil then
        tail:setPosition(pos)
    end
end

function MoneyBallWheel:initGameData(data)
    self.m_gameData = data
    self.m_gameProgress = 1
    self:ballStartRun()
end

function MoneyBallWheel:ballStartRun()
    if self.m_ballStartAction ~= nil then
        self:stopAction(self.m_ballStartAction)
        self.m_ballStartAction = nil
    end
    
    self:saveTime()
    self.m_startAngle = 270
    self.m_radius = 340
    self.currV = self.m_startV
    self.m_status = self.ACTION_START
    local ball = util_csbCreate("MoneyBall_Ball.csb")
    self:findChild("Node_1"):addChild(ball, 3)
    local pos = cc.p(util_getCirclePointPos(0, 0, self.m_radius, self.m_startAngle))
    ball:setPosition(pos)
    ball:setName("ball")

    local tail = cc.MotionStreak:create(0.3, 1, 30, cc.c3b(255, 255, 110), "tail.png")
    tail:setBlendFunc({ src = GL_ONE, dst = GL_ONE })
    self:findChild("Node_1"):addChild(tail, 2)
    tail:setPosition(pos)
    tail:setName("tail")

    local jackpot = self.m_gameData.content[self.m_gameProgress]
    self.m_gameProgress = self.m_gameProgress + 1
    if self[jackpot.."_num"] == nil then
        self[jackpot.."_num"] = 1
    else
        self[jackpot.."_num"] = self[jackpot.."_num"] + 1
    end
    local endAngle = JACKPOT_ANGLE[jackpot][self[jackpot.."_num"]]
    local endPos = JACKPOT_END_POS[jackpot][self[jackpot.."_num"]]
    self.m_currJackpt = jackpot
    self.m_ballRunSoundID = gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_ball_run.mp3")
    self.m_bBallRun = true
    self.m_bQuickStop = false
    self.m_spinBtn:setStopFlag(true)
    self:onUpdate(function(dt)
        self:updateBall(dt, ball, endAngle, endPos, jackpot, tail)
    end)
end

function MoneyBallWheel:hideWheel(func)
    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_wheel_change.mp3")
    self.m_tip:playAction("over")
    self:runCsbAction("over", false, function()
        self.m_spinBtn:setVisible(false)
        self:resetUI()
        if func ~= nil then
            func()
        end
    end)
end

function MoneyBallWheel:resetUI()
    self.m_spinBtn:setVisible(false)
    for i = 1, #JACKPOT_ARRAY, 1 do
        local jackpot = JACKPOT_ARRAY[i]
        self["effect_"..jackpot]:setVisible(false)
        self["jackpot_"..jackpot]:showIdle()
        self[jackpot.."_num"] = nil
    end
    local parent = self:findChild("Node_1")
    local children = parent:getChildren()
    for i = 1, #children, 1 do
        local child = children[i]
        local name = child:getName()
        if name == "tail" or name == "ball" then
            child:removeFromParent()
        end
    end
end



--默认按钮监听回调
function MoneyBallWheel:updataUiPos()
    self.m_spinBtn:setPositionY(50)
    self.m_tip:setVisible(false)
end


return MoneyBallWheel