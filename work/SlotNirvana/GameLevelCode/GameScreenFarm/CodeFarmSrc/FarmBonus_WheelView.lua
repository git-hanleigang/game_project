---
--xcyy
--2018年5月23日
--FarmBonus_WheelView.lua

local FarmBonus_WheelView = class("FarmBonus_WheelView",util_require("base.BaseView"))
FarmBonus_WheelView.m_wheelSumIndex = 8

function FarmBonus_WheelView:initUI(data)

    self:createCsbNode("Farm_zhuanpan.csb")


    self.m_spinBtn = util_createView("CodeFarmSrc.FarmBonus_Wheel_SpinView")
    self:findChild("spin"):addChild(self.m_spinBtn)
    self.m_spinBtn:setSpinBtnParent( data.m_BonusWheel )


    -- self.m_point = util_createView("CodeFarmSrc.FarmBonus_Wheel_PointView")
    -- self:findChild("point"):addChild(self.m_point)


    self.m_WinTip = util_createView("CodeFarmSrc.FarmBonus_Wheel_WinTipView")
    self:findChild("wintip"):addChild(self.m_WinTip)
    self.m_WinTip:setVisible(false)

    self.m_RunActBg = util_createView("CodeFarmSrc.FarmBonus_Wheel_RunActBgView")
    self:findChild("RunActBg"):addChild(self.m_RunActBg)
    self.m_RunActBg:setVisible(false)

    self.m_RunActBgTop = util_createView("CodeFarmSrc.FarmBonus_Wheel_RunActBgTopView")
    self:findChild("RunActBg_0"):addChild(self.m_RunActBgTop)
    self.m_RunActBgTop:setVisible(false)


    self.m_RunActBgDown = util_createView("CodeFarmSrc.FarmBonus_Wheel_RunActBgDownView")
    self:findChild("RunActBg_1"):addChild(self.m_RunActBgDown)

    self.m_runLight = util_createView("CodeFarmSrc.FarmBonus_Wheel_RunLightView")
    self:findChild("runLight"):addChild(self.m_runLight)
    self.m_runLight:runCsbAction("idleframe")


    self.m_wheel = require("CodeFarmSrc.FarmBonus_WheelAction"):create(self:findChild("wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
     self:addChild(self.m_wheel)

    self:setWheelRotModel( )

    
    self.m_wheelData = data.content 
    self.m_betlevel = data.m_betlevel 
    self.m_machine = data.m_machine
    
    self:initWheelLittleNode( )
end

function FarmBonus_WheelView:initWheelLittleNode( )
    local index = 1
    for i=1,#self.m_wheelData do
        local data = self.m_wheelData[i]
        if type(data) == "number" then
            local node = self:findChild("num_" .. index) 
            if node then
                node:setString(data)
            end
            index = index + 1
        end
    end
    
end

function FarmBonus_WheelView:onEnter()
 

end

function FarmBonus_WheelView:onExit()
 
end

function FarmBonus_WheelView:setSpinBtnClickCallFunc(func )
    self.m_spinBtn:setClickCall(function(  )
        if func then
            func()
        end
    end )
end

function FarmBonus_WheelView:setSpinBtnCanTouch( )
    self.m_spinBtn:setCanTouch(true)
end

function FarmBonus_WheelView:setSpinBtnNotCanTouch( )
    self.m_spinBtn:setCanTouch(false)
    self.m_spinBtn:setClickCall(nil )
end

function FarmBonus_WheelView:beginWheel( data )
    -- self.m_endIndex =  (data.choose + 1) 
    self.m_endIndex =  data.choose

    self.m_callFunc = function()


            gLobalSoundManager:playSound("FarmSounds/music_Farm_Bonus_Wheel_end_win.mp3")

            self:fadeOutRunBg( function(  )
                self.m_RunActBgTop:setVisible(false)
                self.m_RunActBgTop:runCsbAction("idleframe")

                self.m_RunActBg:setVisible(false)
                self.m_RunActBg:runCsbAction("idleframe")
                self.m_runLight:runCsbAction("idleframe")   
            end  )

            self.m_WinTip:setVisible(true)
            -- self.m_WinTip:runCsbAction("actionframe",false,function(  )
                      
            self.m_WinTip:runCsbAction("actionframe",true)
            -- end)  
            if data.endCallBack then
                data.endCallBack()
            end   

            
            
  
    end
    
    self:fadeInRunBg(  )

    self.m_RunActBgTop:setVisible(true)
    self.m_RunActBgTop:runCsbAction("actionframe",true)

    self.m_RunActBg:setVisible(true)
    self.m_RunActBg:runCsbAction("actionframe",true)
    self.m_runLight:runCsbAction("actionframe",true)

    -- local actionList = {}
    -- actionList[#actionList + 1] = cc.RotateTo:create(0.6,-15)
    -- actionList[#actionList + 1] = cc.CallFunc:create(function(  )

        self:beginWheelAction()

    -- end)
    -- actionList[#actionList + 1] = cc.RotateTo:create(0.3,0)

    -- local sq = cc.Sequence:create(actionList)

    -- self:findChild("wheel_act"):runAction(sq)

    
    
end

function FarmBonus_WheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 550 --加速度
    wheelData.m_runV = 550--匀速
    wheelData.m_runTime = 0 --匀速时间
    wheelData.m_slowA = 200 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 150 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel(false)
    
    self.m_wheel:recvData(self.m_endIndex)

    
end


function FarmBonus_WheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function FarmBonus_WheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = (distance / targetStep) + 0.5
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
    --     -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        gLobalSoundManager:playSound("FarmSounds/music_Farm_Bonus_Wheel_run.mp3")

    
    end
end


function FarmBonus_WheelView:fadeInRunBg(  )
    
   

    util_setCascadeOpacityEnabledRescursion(self:findChild("runLight"),true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("RunActBg"),true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("RunActBg_0"),true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("RunActBg_1"),true)

    self:findChild("runLight"):setOpacity(0)
    self:findChild("RunActBg"):setOpacity(0)
    self:findChild("RunActBg_0"):setOpacity(0)
    self:findChild("RunActBg_1"):setOpacity(0)

    local time = 0.4

    local actList_1 = {}
    actList_1[#actList_1 + 1] = cc.FadeIn:create(time)
    local sq_1 = cc.Sequence:create(actList_1)
    self:findChild("runLight"):runAction(sq_1)
    


    local actList_2 = {}
    actList_2[#actList_2 + 1] = cc.FadeIn:create(time)
    local sq_2 = cc.Sequence:create(actList_2)
    self:findChild("RunActBg"):runAction(sq_2)
    

    local actList_3 = {}
    actList_3[#actList_3 + 1] = cc.FadeIn:create(time)
    local sq_3 = cc.Sequence:create(actList_3)
    self:findChild("RunActBg_0"):runAction(sq_3)
    
    
    local actList_4 = {}
    actList_4[#actList_4 + 1] = cc.FadeIn:create(time)
    local sq_4 = cc.Sequence:create(actList_4)
    self:findChild("RunActBg_1"):runAction(sq_4)


end

function FarmBonus_WheelView:fadeOutRunBg( func )
    
    util_setCascadeOpacityEnabledRescursion(self:findChild("runLight"),true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("RunActBg"),true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("RunActBg_0"),true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("RunActBg_1"),true)

    local time = 1

    local actList_1 = {}
    actList_1[#actList_1 + 1] = cc.FadeOut:create(time)
    local sq_1 = cc.Sequence:create(actList_1)
    self:findChild("runLight"):runAction(sq_1)
    


    local actList_2 = {}
    actList_2[#actList_2 + 1] = cc.FadeOut:create(time)
    local sq_2 = cc.Sequence:create(actList_2)
    self:findChild("RunActBg"):runAction(sq_2)
    

    local actList_3 = {}
    actList_3[#actList_3 + 1] = cc.FadeOut:create(time)
    local sq_3 = cc.Sequence:create(actList_3)
    self:findChild("RunActBg_0"):runAction(sq_3)
    
    
    local actList_4 = {}
    actList_4[#actList_4 + 1] = cc.FadeOut:create(time)
    local sq_4 = cc.Sequence:create(actList_4)
    self:findChild("RunActBg_1"):runAction(sq_4)

    performWithDelay(self,function(  )

        if func then
            func()
        end
    end,time)


end

return FarmBonus_WheelView