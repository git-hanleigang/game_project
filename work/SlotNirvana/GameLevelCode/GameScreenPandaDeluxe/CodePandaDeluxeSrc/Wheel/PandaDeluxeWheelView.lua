---
--xcyy
--2018年5月23日
--PandaDeluxeWheelView.lua

local PandaDeluxeWheelView = class("PandaDeluxeWheelView",util_require("base.BaseView"))
PandaDeluxeWheelView.m_wheelSumIndex = 12
PandaDeluxeWheelView.m_wheel = nil
PandaDeluxeWheelView.m_callFunc = nil
PandaDeluxeWheelView.m_endIndex = nil
PandaDeluxeWheelView.m_wheelData = nil

PandaDeluxeWheelView.m_baseWinIndex_1 = {1,4,7,10}
PandaDeluxeWheelView.m_baseWinIndex_2 = {3,6,9,12}
PandaDeluxeWheelView.m_baseWinIndex_3 = {2,5,8,11}

PandaDeluxeWheelView.m_baseWheelRunType = 1
PandaDeluxeWheelView.m_FsWheelRunType = 2
PandaDeluxeWheelView.m_JsWheelGrandRunType = 3
PandaDeluxeWheelView.m_JsWheelMiniRunType = 4

PandaDeluxeWheelView.m_WheelRunType = 1

function PandaDeluxeWheelView:initUI()

    self:createCsbNode("PandaDeluxe_wheel.csb")

    self.m_wheel = require("CodePandaDeluxeSrc.Wheel.PandaDeluxeWheelAction"):create(self:findChild("wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
    end,function(distance,targetStep,isBack)
         -- 滚动实时调用
    end)
    self:addChild(self.m_wheel)


    self.m_idleLight = util_createAnimation("PandaDeluxe_wheel_Light.csb")
    self:findChild("Node_Light"):addChild(self.m_idleLight,200)
    self.m_idleLight:runCsbAction("idle",true)

    self:setWheelRotModel( )

end


function PandaDeluxeWheelView:setRunWheelData(endIndex)
    self.m_endIndex =  endIndex
end


function PandaDeluxeWheelView:onEnter()


end


function PandaDeluxeWheelView:onExit()

end

function PandaDeluxeWheelView:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:clickFunc()
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function PandaDeluxeWheelView:clickFunc()
    if self.m_bIsTouched == true then
        return
    end

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouched = true


    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    self:beginWheelAction()

end

-- 创建正常状态轮盘缓慢滚动
function PandaDeluxeWheelView:SlowWheelRun( )

    self.m_wheel:rotateWheel()
end

-- 停止正常状态轮盘缓慢滚动
function PandaDeluxeWheelView:StopSlowWheelRun( )

    -- self:findChild("Node_Wheel_p"):stopAllActions()
    -- self:findChild("Node_Wheel_p"):setRotation(0)
    -- self:findChild("wheel"):setRotation(0)
end


function PandaDeluxeWheelView:resetView()

    if  self.m_selectEff then
        self.m_selectEff:removeFromParent() 
        self.m_selectEff = nil
    end


end

function PandaDeluxeWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 1 --匀速时间
    wheelData.m_slowA = 350 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 100 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 1 --停止圈数
    wheelData.m_randomDistance = 10
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel(false)

    self.m_wheel:recvData(self.m_endIndex)

    self:StopSlowWheelRun()
end

function PandaDeluxeWheelView:isInArray( array,value )
    
    for i=1,#array do
        if value == array[i] then
            return true
        end

    end
end

function PandaDeluxeWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()

        gLobalSoundManager:setBackgroundMusicVolume(0.4)

        gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxeSounds_Wheel_Win.mp3")

        if self.m_selectEff then
            print("错！！！！！")
        end

        print("m_WheelRunType -- " .. self.m_WheelRunType)
        print("m_endIndex -- " .. self.m_endIndex)

        self.m_selectEff = util_createAnimation("PandaDeluxe_wheel_zhongjiang.csb")
        self:findChild("Node_light_"..self.m_WheelRunType):addChild(self.m_selectEff,100)

        if self:isInArray(self.m_baseWinIndex_1,self.m_endIndex) then

            if self.m_WheelRunType == self.m_baseWheelRunType then
                self.m_selectEff:playAction("bese_" .. 1,true)
            elseif self.m_WheelRunType == self.m_FsWheelRunType then
                self.m_selectEff:playAction("bese_" .. 1,true)
            elseif self.m_WheelRunType == self.m_JsWheelGrandRunType then
                self.m_selectEff:playAction("jackpot2_".. 1,true)
            elseif self.m_WheelRunType == self.m_JsWheelMiniRunType then
                self.m_selectEff:playAction("jackpot1_".. 1,true)
            end
            

        elseif self:isInArray(self.m_baseWinIndex_2,self.m_endIndex) then

            if self.m_WheelRunType == self.m_baseWheelRunType then
                self.m_selectEff:playAction("bese_" .. 3,true)
            elseif self.m_WheelRunType == self.m_FsWheelRunType then
                self.m_selectEff:playAction("bese_" .. 3,true)
            elseif self.m_WheelRunType == self.m_JsWheelGrandRunType then
                self.m_selectEff:playAction("jackpot2_".. 3,true)
            elseif self.m_WheelRunType == self.m_JsWheelMiniRunType then
                self.m_selectEff:playAction("jackpot1_".. 3,true)
            end

        elseif self:isInArray(self.m_baseWinIndex_3,self.m_endIndex) then

            if self.m_WheelRunType == self.m_baseWheelRunType then
                self.m_selectEff:playAction("bese_" .. 2,true)
            elseif self.m_WheelRunType == self.m_FsWheelRunType then
                self.m_selectEff:playAction("bese_" .. 2,true)
            elseif self.m_WheelRunType == self.m_JsWheelGrandRunType then
                self.m_selectEff:playAction("jackpot2_".. 2,true)
            elseif self.m_WheelRunType == self.m_JsWheelMiniRunType then
                self.m_selectEff:playAction("jackpot1_".. 2,true)
            end

        end



        performWithDelay(self,function(  )

            -- self:resetView()
            gLobalSoundManager:setBackgroundMusicVolume(1)
            
            if callBackFun then
                callBackFun()
            end
            
        end,3)

    end
end

function PandaDeluxeWheelView:setWheelRotModel( )

    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function PandaDeluxeWheelView:setRotionAction( distance,targetStep,isBack )

    local temp = math.floor(distance / targetStep)
    if self.distance_now and self.distance_now ~= temp then
        self.distance_now = temp
        gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_wheelTurn.mp3")
    end

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then

        self.distance_pre = self.distance_now

    end
end

function PandaDeluxeWheelView:baseToFreespin( func)
    self:runCsbAction("bese_freespin",false,function(  )
        if func then
            func()
        end
    end)
    
end
function PandaDeluxeWheelView:freespinToBase( func)
    self:runCsbAction("freespin_bese",false,function(  )
        if func then
            func()
        end
    end)
    
end
function PandaDeluxeWheelView:baseToJackPot( func)
    self:runCsbAction("bese_jackpot",false,function(  )
        if func then
            func()
        end
    end)
    
end
function PandaDeluxeWheelView:jackPotToBase( func)
    self:runCsbAction("jackpot_bese",false,function(  )
        if func then
            func()
        end
    end)
    
end

function PandaDeluxeWheelView:freespinToJackpot(func )
    
    

    self:runCsbAction("freespin_jackpot",false,function(  )
        if func then
            func()
        end
    end)

end

function PandaDeluxeWheelView:jackpotToFreeSpin( func)
    
    self:runCsbAction("jackpot_freespin",false,function(  )
        if func then
            func()
        end
    end)
    

end

return PandaDeluxeWheelView