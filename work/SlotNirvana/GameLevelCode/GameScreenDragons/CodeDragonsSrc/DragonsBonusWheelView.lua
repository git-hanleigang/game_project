---
--smy
--2018年4月18日
--DragonsBonusWheelView.lua


local DragonsBonusWheelView = class("DragonsBonusWheelView", util_require("base.BaseView"))
DragonsBonusWheelView.m_randWheelIndex = nil
DragonsBonusWheelView.m_wheelSumIndex =  16 -- 轮盘有多少块
DragonsBonusWheelView.m_wheelData = {} -- 大轮盘信息
DragonsBonusWheelView.m_wheelNode = {} -- 大轮盘Node 
DragonsBonusWheelView.m_bIsTouch = nil

function DragonsBonusWheelView:initUI(data)
    
    self:createCsbNode("Dragons_wheel2.csb") 

    self:changeBtnEnabled(false)
    self.m_wheelPointerSp = self:findChild("Dragons_Wheel_2_3")
    self:setUsingPointerSp(self.m_wheelPointerSp)
    self.m_bIsTouch = true
    self.m_wheel = require("CodeDragonsSrc.DragonsWheelAction"):create(self:findChild("zhuan"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.m_wheelData ) -- 设置轮盘信息
    self:initWheelRoolInfo( )
    -- self:InitWheel( )
    local touch =self:findChild("touch")
    if touch then
        self:addClick(touch)
    end

end
function DragonsBonusWheelView:setParent(_parent)
    self.m_parent = _parent
end
function DragonsBonusWheelView:InitWheel( )
    for k,v in pairs(self.m_wheelData) do
        local data ={}
        data.num = v
        local lab = util_createView("CodeDragonsSrc.DragonsBonusWheelLab",data)
        self:findChild("text"..k):addChild(lab)
    end
end

function DragonsBonusWheelView:setUsingPointerSp(pointerSp)
    self.m_usingPointerSp = pointerSp
end
function DragonsBonusWheelView:resetUsingPointerSp()
    self.m_usingPointerSp:setRotation(0)
    self.m_usingPointerSp:stopAllActions()
end

function DragonsBonusWheelView:setTouchLayer()
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

function DragonsBonusWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end
    self.m_bIsTouch = false
    -- self.m_parent:sendData()
    -- self:beginWheelAction()
end

function DragonsBonusWheelView:initWheelRoolInfo( )
    self.distance_pre = 0
    self.distance_now = 0
    self.m_isRotPointer = false  --原先用于判断是否自动旋转指针  现在用判断指针和轮盘的接触和分离状态
    self.m_isCollide = false
    self.m_rotPointerPam = -1  --指针走向系数
    self.m_pointerLimit = -70  --指针惯性限制值
    self.m_pointerTation = 1 --指针走向 1 逆时针 0 顺时针
    self.m_angDistance = 0 --轮盘转过的距离
    self.m_pointerSpeed = 180
    self.m_accelerated = 1 --重力加速度 原先0.35  1
    self.m_deceleration = 0.4 --阻力  原先0.08  0.4
end
-- 转盘转动结束调用
function DragonsBonusWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        self:resetUsingPointerSp()
        self:initWheelRoolInfo( )
        callBackFun()
    end
end

function DragonsBonusWheelView:onEnter()

end

function DragonsBonusWheelView:onExit()
    
end

function DragonsBonusWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("Dragons_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function DragonsBonusWheelView:beginWheelAction(endindex)

    local wheelData = {}
    wheelData.m_startA = 150 --加速度
    wheelData.m_runV = 400--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 50 --动态减速度
    wheelData.m_slowQ = 3 --减速圈数
    wheelData.m_stopV = 30 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)
    self.m_randWheelIndex = endindex
    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)

    self.m_wheel:setWheelRotFunc(function(distance,targetStep,isBack)
        -- 滚动实时调用
        self:setRotionWheel(distance,targetStep)
        self:setRotionOne(distance,targetStep,isBack)
    end)
    self:startRoolWheel()
end

-- 返回上轮轮盘的停止位置
function DragonsBonusWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function DragonsBonusWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function DragonsBonusWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_wheel_zhuan.mp3")       
    end
end

-- 设置轮盘网络消息
function DragonsBonusWheelView:setWheelData(data )
    self.m_wheelData = data -- 大轮盘信息
end

function DragonsBonusWheelView:startRoolWheel()
    self.m_isRotPointer = true
    local function update(dt)
        self:updateFunc(dt)
    end
    if self.m_usingPointerSp then
        self.m_usingPointerSp:onUpdate(update)
    end
end

function DragonsBonusWheelView:updateFunc(dt)
    if self.m_isRotPointer == true  then
        local pointerRot = self.m_usingPointerSp:getRotation()
        pointerRot =  pointerRot + self.m_pointerSpeed*dt
        if pointerRot >= 0 then
            pointerRot = 0
            self.m_isRotPointer = false
        end
        self.m_usingPointerSp:setRotation(pointerRot)
    end
end
function DragonsBonusWheelView:changeAng(ang)

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

--[[
    @desc: 设置滚动信息
    time:2019-04-19 12:24:37
]]
function DragonsBonusWheelView:setRotionOne(distance,targetStep,isBack)

    local ang = distance % targetStep

    self.m_angDistance = distance
    local pointerSpeed = self.m_pointerSpeed
    if ang >= 10 and ang <20 then
        local pointerRot = self:changeAng(ang)
        if pointerRot >= -40 and pointerRot <=  self.m_usingPointerSp:getRotation() or isBack then
            self.m_isRotPointer = false
            self.m_usingPointerSp:setRotation(pointerRot)
        end
    else
        self.m_isRotPointer = true
    end
end
function DragonsBonusWheelView:setRotionWheel(distance,targetStep)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_wheel_zhuan.mp3")   
    end
end

return DragonsBonusWheelView