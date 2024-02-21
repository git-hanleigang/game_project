---
--smy
--2018年4月18日
--FrogPrinceExtraFreeSpinWheelView.lua


local FrogPrinceExtraFreeSpinWheelView = class("FrogPrinceExtraFreeSpinWheelView", util_require("base.BaseView"))
FrogPrinceExtraFreeSpinWheelView.m_randWheelIndex = nil
FrogPrinceExtraFreeSpinWheelView.m_wheelSumIndex =  8 -- 轮盘有多少块
FrogPrinceExtraFreeSpinWheelView.m_wheelData = {} -- 大轮盘信息
FrogPrinceExtraFreeSpinWheelView.m_wheelNode = {} -- 大轮盘Node 
FrogPrinceExtraFreeSpinWheelView.m_bIsTouch = nil

function FrogPrinceExtraFreeSpinWheelView:initUI(data)
    
    self:createCsbNode("FrogPrince_wheel_0.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel = require("CodeFrogPrinceSrc.FrogPrinceWheelAction"):create(self:findChild("di"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.m_wheelData ) -- 设置轮盘信息
    -- self.m_randWheelIndex = data.select -- 设置轮盘滚动位置
    self.m_wheelData = data.m_wheelData -- 大轮盘信息
    self:getWheelSymbol()


    -- 点击layer
    -- self:setTouchLayer()
    self:InitSmallWheel( )

end
function FrogPrinceExtraFreeSpinWheelView:InitSmallWheel( )
    
    for k,v in pairs(self.m_wheelData) do
        local data ={}
        data._num = v
        local lab = util_createView("CodeFrogPrinceSrc.FrogPrinceExtraFreeSpinWheelLab",data)
        self:findChild("text"..k):addChild(lab)
        -- table.insert( self.m_smallWheelNode, lab )
    end
end

function FrogPrinceExtraFreeSpinWheelView:setTouchLayer()
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

function FrogPrinceExtraFreeSpinWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false

end

-- 转盘转动结束调用
function FrogPrinceExtraFreeSpinWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
            callBackFun()   
    end
end

function FrogPrinceExtraFreeSpinWheelView:onEnter()

end

function FrogPrinceExtraFreeSpinWheelView:onExit()
    
end

function FrogPrinceExtraFreeSpinWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("FrogPrince_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function FrogPrinceExtraFreeSpinWheelView:beginWheelAction(endindex)

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
    self.m_randWheelIndex = endindex
    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)

    
end

-- 返回上轮轮盘的停止位置
function FrogPrinceExtraFreeSpinWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function FrogPrinceExtraFreeSpinWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function FrogPrinceExtraFreeSpinWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_big_wheel_rotation.mp3")       
    end
end

-- 设置轮盘网络消息
function FrogPrinceExtraFreeSpinWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function FrogPrinceExtraFreeSpinWheelView:getWheelSymbol(  )
    self.m_bigWheelNode = {}

    for i = 1, self.m_wheelSumIndex, 1 do
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("对应小node节点"..i)
    end
    
end

return FrogPrinceExtraFreeSpinWheelView