---
--smy
--2018年4月18日
--EgyptWheelView.lua


local EgyptWheelView = class("EgyptWheelView", util_require("base.BaseView"))
EgyptWheelView.m_randWheelIndex = nil
EgyptWheelView.m_wheelSumIndex =  12 -- 轮盘有多少块
EgyptWheelView.m_wheelData = {} -- 大轮盘信息
EgyptWheelView.m_wheelNode = {} -- 大轮盘Node 
EgyptWheelView.m_bIsTouch = nil
EgyptWheelView.m_showJackpot = nil


function EgyptWheelView:initUI(data)
    
    self:createCsbNode("Egypt_wheel.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel = require("CodeEgyptSrc.EgyptWheelAction"):create(self:findChild("WheelNode"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.wheel ) -- 设置轮盘信息
    self.m_randWheelIndex = data.select -- 设置轮盘滚动位置

    self:getWheelSymbol()

    local effectNode, effectAct = util_csbCreate("Egypt_wheel_idle.csb")
    self:findChild("effectNode"):addChild(effectNode)
    util_csbPlayForKey(effectAct, "idle", true)
end

function EgyptWheelView:showStart()
    self:runCsbAction("open", false, function ()
        self:runCsbAction("idle", true)
        self:setTouchLayer()
        performWithDelay(self, function()
            self:clickFunc()
        end, 3)
    end)
end

function EgyptWheelView:setTouchLayer()
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

function EgyptWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end
    self.m_bIsTouch = false
    gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_wheel_click.mp3")
    
    self:runCsbAction("dianji", false, function ()
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:removeEventListenersForTarget(self,true)
        self:beginWheelAction()
    end)
    

end

-- 转盘转动结束调用
function EgyptWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        gLobalSoundManager:setBackgroundMusicVolume(0)
        gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_wheel_reward.mp3")
        self:runCsbAction("win", true)
        if self.m_showJackpot ~= nil then
            self.m_showJackpot()
        end
        performWithDelay(self, function()
            callBackFun()
        end, 3)
    end
end

function EgyptWheelView:initShowJackpot(func)
    self.m_showJackpot = func
end

function EgyptWheelView:onEnter()

end

function EgyptWheelView:onExit()
    
end

function EgyptWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("Egypt_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function EgyptWheelView:beginWheelAction()

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
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)

    
end

-- 返回上轮轮盘的停止位置
function EgyptWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function EgyptWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function EgyptWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_wheel_rptate.mp3")       
    end
end

-- 设置轮盘网络消息
function EgyptWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function EgyptWheelView:getWheelSymbol(  )
    self.m_bigWheelNode = {}

    for i = 1, self.m_wheelSumIndex, 1 do
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("text"..i)
    end
    
end

return EgyptWheelView