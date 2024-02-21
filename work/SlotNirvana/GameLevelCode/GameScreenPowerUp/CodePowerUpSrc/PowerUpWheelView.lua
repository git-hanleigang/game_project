---轮盘界面
local PowerUpWheelView = class("PowerUpWheelView", util_require("base.BaseView"))
PowerUpWheelView.randBigWheelIndex = nil
PowerUpWheelView.randSmallWheelIndex = nil
PowerUpWheelView.m_bigWheelNode = {} -- 大轮盘Node
PowerUpWheelView.playSmallWheelSound = nil --是否播放小轮盘音效

PowerUpWheelView.m_isRotPointer = nil  --原先用于判断是否自动旋转指针  现在用判断指针和轮盘的接触和分离状态
PowerUpWheelView.m_isRotPointer2 = nil  --原先用于判断是否自动旋转指针  现在用判断指针和轮盘的接触和分离状态

PowerUpWheelView.m_outWheel = nil
PowerUpWheelView.m_innerWheel = nil
PowerUpWheelView.m_startRoll = nil
PowerUpWheelView.smallBg = {"PowerUp_Wheel_xiaoyuan01","PowerUp_Wheel_xiaoyuan02","PowerUp_Wheel_xiaoyuan03"}
PowerUpWheelView.m_wheelStepIndex = 0

function PowerUpWheelView:initUI(data)
    self.m_machine = data
    self:createCsbNode("PowerUp_Wheel.csb")

    self.m_wheelEff = util_createAnimation("PowerUp_lunpan_xuanzhuan.csb")
    self:findChild("Node_playEff"):addChild(self.m_wheelEff)
    self.m_wheelEff:playAction("animation0",true)

    self.m_wheelOutCircle = util_createAnimation("PowerUp_lunpan_outCircle.csb")
    self:findChild("Node_playEff"):addChild(self.m_wheelOutCircle)
    self.m_wheelOutCircle:playAction("animation0",true)
    self.m_wheelOutCircle:setVisible(false)

    -- Node_playEff
    self.m_topArrowBg = util_createAnimation("PowerUp_Wheel_zhizhenOut.csb")
    self:findChild("Node_top"):addChild(self.m_topArrowBg)

    self.m_topArrow = util_createAnimation("PowerUp_Wheel_zhizhenIn.csb")
    self.m_wheelPointerSp = self.m_topArrow:findChild("PowerUp_Wheel_zzhen2_4")
    self:findChild("Node_top2"):addChild(self.m_topArrow)


    self.m_topArrow2 = util_createAnimation("PowerUp_Wheel_zhizhen.csb")
    self.m_wheelPointerSp2 = self.m_topArrow2:findChild("PowerUp_Wheel_zzhen2_4")
    self:findChild("Node_in"):addChild(self.m_topArrow2)

    self.m_wheelSelectEff = util_createAnimation("PowerUp_Wheel_zhongjiang.csb")
    self:findChild("Node_select"):addChild(self.m_wheelSelectEff)
    self.m_wheelSelectEff:setVisible(false)
    self.m_wheelSelectEff:playAction("actionframe")

    self.m_smallwheelSelectEff = util_createAnimation("PowerUp_Wheel_zhongjiang.csb")
    self:findChild("Node_innerSelect"):addChild(self.m_smallwheelSelectEff)
    self.m_smallwheelSelectEff:setVisible(false)

    self.m_Particle_1 = self:findChild("Particle_1")
    self.m_Particle_1:setVisible(false)
    self.m_Particle_1:stopSystem()

    self.m_outWheel = require("CodePowerUpSrc.PowerUpWheelAction"):create(self:findChild("bigWheel"),16,function()
        -- 滚动结束调用
        self:bigWheelOver()
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
     self:addChild(self.m_outWheel)

    self.m_innerWheel = require("CodePowerUpSrc.PowerUpWheelAction"):create(self:findChild("smallNode"),4,function()
        -- 滚动结束调用
        self:smallWheelOver()
    end,function(distance,targetStep,isBack)
        -- 滚动实时调用
    end)
    self:addChild(self.m_innerWheel)

    self:setSmallWheelRotModel()
    self:setWheelRotModel()

    self:SlowWheelRun()
    self:showAnchor(0)
    self.m_pointerSpeed = 180
    self:startRoolWheel()
end


function PowerUpWheelView:bigWheelOver()

    self.m_startRoll = false
    self.m_wheelSelectEff:setVisible(true)
    self.m_wheelOutCircle:setVisible(false)
    self.m_wheelEff:setVisible(false)
    self.m_wheelSelectEff:playAction("actionframe",true)
    performWithDelay(self,function()
        -- "BONUS","60","400","GRAND","BONUS","75","MAJOR","BONUS","MINOR","200","90","MINI","BONUS","120"
        if self.m_data.p_selfMakeData.select  ==  "BONUS"  then--PowerUp_Wheel_xiaoyuan01_1
            self:showAnchor(2)
            self:findChild("smallWheelMul"):setVisible(false)
            self:findChild("smallWheelMul_2"):setVisible(false)

            if self.m_machine.m_betLevel == 0 then -- 低bet 只有4层
                -- self:findChild("smallNode"):setRotation(0)
                self:findChild("smallWheelBonus"):setVisible(false)
                self:findChild("smallWheelBonus2"):setVisible(true)
            else --
                self:findChild("smallWheelBonus"):setVisible(true)
                self:findChild("smallWheelBonus2"):setVisible(false)
            end

            globalMachineController:playBgmAndResume("PowerUpSounds/music_PowerUp_bigWheelSelect.mp3",2,0.4,1)

            self:runCsbAction("taiji_change",false,function()
                self.m_Particle_1:setVisible(true)
                self.m_Particle_1:resetSystem()
                if self.m_machine.m_betLevel == 1 then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SHOW_TAP_SPIN)
                else-- 低bet 只有4层
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SHOW_TAP_SPIN,{isDirectRequest=true})
                end
            end)
        elseif self.m_data.p_selfMakeData.select  ==  "MINI"  then
            self.m_machine:showBonusJackpot(self.m_data.p_selfMakeData.select)
        elseif self.m_data.p_selfMakeData.select  ==  "MINOR"  then
            self.m_machine:showBonusJackpot(self.m_data.p_selfMakeData.select)
        elseif self.m_data.p_selfMakeData.select  ==  "MAJOR"  then
            self.m_machine:showBonusJackpot(self.m_data.p_selfMakeData.select)
        elseif self.m_data.p_selfMakeData.select  ==  "GRAND"  then
            self.m_machine:showBonusJackpot(self.m_data.p_selfMakeData.select)
        else
            self:showAnchor(2)
            if self.m_data.p_bonusExtra.isShowRespin == "1" then
                self:findChild("smallWheelMul"):setVisible(true)
                self:findChild("smallWheelMul_2"):setVisible(false)
            else
                self:findChild("smallWheelMul"):setVisible(false)
                self:findChild("smallWheelMul_2"):setVisible(true)
            end
            self:findChild("smallWheelBonus"):setVisible(false)
            self:findChild("smallWheelBonus2"):setVisible(false)
           
            globalMachineController:playBgmAndResume("PowerUpSounds/music_PowerUp_changeSmallWheel.mp3",2,0.4,1)

            self:runCsbAction("taiji_change",false,function()
                self.m_Particle_1:setVisible(true)
                self.m_Particle_1:resetSystem()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SHOW_TAP_SPIN)
            end)
        end

    end,4)

    globalMachineController:playBgmAndResume("PowerUpSounds/music_PowerUp_bigWheelSelect.mp3",4,0.4,1)

end
function PowerUpWheelView:smallWheelOver()

    self.m_startRoll = false
    gLobalSoundManager:setBackgroundMusicVolume(0)
    gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_smallWheelSelect.mp3")
      --内圈之中
    self.m_smallwheelSelectEff:setVisible(true)
    self.m_smallwheelSelectEff:playAction("actionframe2",true,function()
        if self.m_data.p_selfMakeData.select ==  "RESPIN"  then--PowerUp_Wheel_xiaoyuan01_1
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_ROLL_OVER)
            performWithDelay(self,function()
                self.m_machine:showFeatureResult(self.m_machine.RESULT_WHEEL,false,function()
                    self.m_machine:changeGameState(self.m_machine.STATE_WHEEL_GAME,{nextViewState = 1,isDirect = true,isRespin = true})
                end)
            end,2)
        else
            if self.m_data.p_bonusStatus == "CLOSED" then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_ROLL_OVER)
                performWithDelay(self,function()
                    self.m_machine:showFeatureResult(self.m_machine.RESULT_WHEEL,true)
                end,2)
            else
                performWithDelay(self,function()
                    self.m_wheelOutCircle:setVisible(false)
                    self.m_wheelSelectEff:setVisible(false)
                    self.m_smallwheelSelectEff:setVisible(false)
                    self:showAnchor(0)
                    self.m_machine:hideJackpotAndNextView(function()
                        self.m_machine:changeGameState(self.m_machine.STATE_TOWER_GAME,{isReConnect = false})
                    end,2)
                end,2)
            end
        end
    end)
end

function PowerUpWheelView:directEnterTower()
    performWithDelay(self,function()
        self.m_startRoll = false
        gLobalSoundManager:setBackgroundMusicVolume(0)
        gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_smallWheelSelect.mp3")
          --内圈之中
        self.m_smallwheelSelectEff:setVisible(true)
        self.m_smallwheelSelectEff:playAction("actionframe2",true,function()
            performWithDelay(self,function()
                self.m_wheelOutCircle:setVisible(false)
                self.m_wheelSelectEff:setVisible(false)
                self.m_smallwheelSelectEff:setVisible(false)
                self:showAnchor(0)
                self.m_machine:hideJackpotAndNextView(function()
                    self.m_machine:changeGameState(self.m_machine.STATE_TOWER_GAME,{isReConnect = false})
                end,2)
            end,2)
        end)

    end,1)
end

--[[
    @desc:  轮盘上面的指针
    author:{author}
    time:2019-07-24 13:59:22
    --@type:
    @return:
]]
function PowerUpWheelView:showAnchor(type)
    if type == 0 then
        self.m_topArrow:setVisible(false)
        self.m_topArrowBg:setVisible(false)
        self.m_topArrow2:setVisible(false)
    elseif type == 1 then
        self.m_topArrow:setVisible(true)
        self.m_topArrow:playAction("show")
        self.m_topArrowBg:setVisible(true)
        self.m_topArrowBg:playAction("show")
        self.m_topArrow2:setVisible(false)
    else
        self.m_topArrow:setVisible(false)
        self.m_topArrowBg:setVisible(false)
        self.m_topArrow2:setVisible(true)
        self.m_topArrow2:playAction("show")
    end
end
function PowerUpWheelView:resetView()
    self:showAnchor(0)
    self:stopAllActions()
    self:runCsbAction("idle")
    self:SlowWheelRun()
    self.m_wheelEff:setVisible(true)
    self.m_wheelOutCircle:setVisible(false)
    self.m_wheelSelectEff:setVisible(false)
    self.m_smallwheelSelectEff:setVisible(false)
    self.m_wheelStepIndex = 0
end

--更新轮盘数据
function PowerUpWheelView:updateViewData(data,isReConnect)
    self.m_data = data
    if self.m_data.p_selfMakeData and self.m_data.p_selfMakeData.type then
        if self.m_data.p_selfMakeData.type == "0" then --外圈结果出来
            if self.m_data.p_selfMakeData.index then--第一次进入 未转动轮盘
                self:beginBigWheelAction(data.p_selfMakeData.index+1)
            end
        elseif self.m_data.p_selfMakeData.type == "1" then --内圈结果 1 bonus玩法
            if self.m_machine.m_betLevel == 1 then
                if self.m_data.p_selfMakeData.index then--第一次进入 未转动轮盘
                    self:beginSmallWheelAction(data.p_selfMakeData.index+1)
                end
            else--低bet只有一个结果 不用转 直接显示
                self:directEnterTower()
            end

        elseif self.m_data.p_selfMakeData.type == "2" then --内圈结果 2 数字
            if isReConnect then -- 内环出了结果，并且断线又回到了这里。 只能是respin触发了
                -- if self.m_data.p_selfMakeData.index then--第一次进入 未转动轮盘
                --     self:beginSmallWheelAction(data.p_selfMakeData.index+1)
                -- end
            else
                if self.m_data.p_selfMakeData.index then--第一次进入 未转动轮盘
                    self:beginSmallWheelAction(data.p_selfMakeData.index+1)
                end
            end

        elseif self.m_data.p_selfMakeData.type == "3" then --塔轮玩法

        end
    end
end


-- --点击回调
function PowerUpWheelView:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()

end
-- 创建正常状态轮盘缓慢滚动
function PowerUpWheelView:SlowWheelRun()
    -- self:StopSlowWheelRun()
    self.m_wheelOutCircle:setVisible(false)
    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 10--匀速
    wheelData.m_runTime = 2000000 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_bigcallFunc
    self.m_outWheel:changeWheelRunData(wheelData)
    self.m_outWheel:beginWheel()

end


function PowerUpWheelView:beginBigWheelAction( endindex )

    self.m_startRoll = true
        self.m_wheelOutCircle:setVisible(true)
        local wheelData = {}
        wheelData.m_startA = 30 --加速度
        wheelData.m_runV = 180--匀速
        wheelData.m_runTime = 2 --匀速时间
        wheelData.m_slowA = 80 --动态减速度
        wheelData.m_slowQ = 1 --减速圈数
        wheelData.m_stopV = 30 --停止时速度
        wheelData.m_backTime = 0 --回弹前停顿时间
        wheelData.m_stopNum = 0 --停止圈数
        wheelData.m_randomDistance = 0
        wheelData.m_func = self.m_bigcallFunc
        self.m_outWheel:changeWheelRunData(wheelData)
        self.randBigWheelIndex = endindex
        self.m_outWheel:recvData(self.randBigWheelIndex)
        self.m_outWheel:beginWheel()
end

function PowerUpWheelView:beginSmallWheelAction( endindex )
     self.m_startRoll = true
    local wheelData = {}
    wheelData.m_startA = 90 --加速度
    wheelData.m_runV = 360--匀速
    wheelData.m_runTime = 2--匀速时间
    wheelData.m_slowA = 180 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 45 --停止时速度

    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_smallcallFunc
    self.m_innerWheel:changeWheelRunData(wheelData)
    self.randSmallWheelIndex = endindex
    self.m_innerWheel:recvData(self.randSmallWheelIndex,true)

    self.m_innerWheel:beginWheel()
end

function PowerUpWheelView:setWheelRotModel( )

    self.m_outWheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionOne(distance,targetStep,isBack)
    end)
end

function PowerUpWheelView:setSmallWheelRotModel( )

    self.m_innerWheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionTwo(distance,targetStep,isBack)
    end)
end

function PowerUpWheelView:startRoolWheel( )
    self.m_isRotPointer = true
    self.m_isRotPointer2 = true
    local function update(dt)
      self:updateFunc(dt)
    end
    local function update2(dt)
        self:updateFunc2(dt)
    end
  self.m_wheelPointerSp:onUpdate(update)
  self.m_wheelPointerSp2:onUpdate(update2)
end

function PowerUpWheelView:updateFunc(dt)
  if self.m_isRotPointer == true  then
      local pointerRot = self.m_wheelPointerSp:getRotation()
      pointerRot =  pointerRot + self.m_pointerSpeed*dt
      if pointerRot >= 0 then
          pointerRot = 0
          self.m_isRotPointer = false
      end
      self.m_wheelPointerSp:setRotation(pointerRot)
  end
end
function PowerUpWheelView:setRotionOne(distance,targetStep,isBack)
    local stepNum = targetStep * 2
    local ang = distance % targetStep


    if ang >= 9 and ang <20 then
        local step = math.ceil(distance / targetStep)
        if self.m_wheelStepIndex ~= step then
            self.m_wheelStepIndex = step
            if self.m_startRoll then
                gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_beginRollBigWheel.mp3")

                gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_zhiZhenRoll.mp3")
            end
        end
        local pointerRot = self:changeAng(ang)
        if pointerRot >= -40 and pointerRot <=  self.m_wheelPointerSp:getRotation() or isBack then
            self.m_isRotPointer = false
            self.m_wheelPointerSp:setRotation(pointerRot)
        end
    else
        self.m_isRotPointer = true
    end
end
function PowerUpWheelView:changeAng(ang)

    local k = 0
    local b = 0
    if ang >=18 then
        k = 0
        b = - 40
    elseif ang >= 16 then
        k = - 2
        b = - 4
    elseif ang >= 13 then
        k = - 4
        b = 28
    elseif ang >= 12 then
        k = - 7
        b = 67
    elseif ang >= 11 then
        k = - 5
        b = 43
    elseif ang >= 9 then
        k = - 6
        b = 54
    end
    local pointerRot = k * ang + b
    return pointerRot
end

function PowerUpWheelView:updateFunc2(dt)
    if self.m_isRotPointer2 == true  then
        local pointerRot = self.m_wheelPointerSp2:getRotation()
        pointerRot =  pointerRot + self.m_pointerSpeed*dt
        if pointerRot >= 0 then
            pointerRot = 0
            self.m_isRotPointer2 = false
        end
        self.m_wheelPointerSp2:setRotation(pointerRot)
    end
  end
--22.5
--90
-- 10
function PowerUpWheelView:setRotionTwo(distance,targetStep,isBack)
    local ang = distance % targetStep
    if ang >= 42 and ang <53 then
        local pointerRot = self:changeAng2(ang)
        if pointerRot >= -40 and pointerRot <=  self.m_wheelPointerSp2:getRotation() or isBack then
            local step = math.ceil(distance / targetStep)
            if self.m_wheelStepIndex ~= step then
                self.m_wheelStepIndex = step
                if self.m_startRoll then
                    gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_beginRollSmallWheel.mp3")
                    gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_zhiZhenRoll.mp3")
                end
            end
            self.m_isRotPointer2 = false
            self.m_wheelPointerSp2:setRotation(pointerRot)
        end
    else
        self.m_isRotPointer2 = true
    end
end
-- {0,-6,-12,-17,-24,-28,-32,-36,-38,-40,-40,-40}
--0 -12 -17 -24 -36 -40

function PowerUpWheelView:changeAng2(ang)
    local pointerRot = 4 * (52-ang) -40
    return pointerRot
end
function PowerUpWheelView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
return PowerUpWheelView
