---
--smy
--2018年4月18日
--FrogPrinceReelGameWheelView.lua

local FrogPrinceReelGameWheelView = class("FrogPrinceReelGameWheelView", util_require("base.BaseView"))
FrogPrinceReelGameWheelView.m_randWheelIndex = nil
FrogPrinceReelGameWheelView.m_wheelSumIndex = 8 -- 轮盘有多少块
FrogPrinceReelGameWheelView.m_wheelData = {} -- 大轮盘信息
FrogPrinceReelGameWheelView.m_wheelNode = {} -- 大轮盘Node
FrogPrinceReelGameWheelView.m_bIsTouch = nil

function FrogPrinceReelGameWheelView:initUI(data)
    self:createCsbNode("FrogPrince_wheel.csb")

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_controlBig =
        require("CodeFrogPrinceSrc.FrogPrinceWheelAction"):create(
        self:findChild("di_xia"),
        self.m_wheelSumIndex,
        function()
            -- 滚动结束调用
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end
    )
    self:addChild(self.m_controlBig)
    self:setWheelRotModel()

    self.m_controlSmall =
        require("CodeFrogPrinceSrc.FrogPrinceWheelAction"):create(
        self:findChild("di_shang"),
        self.m_wheelSumIndex,
        function()
            -- 滚动结束调用
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end
    )
    self:addChild(self.m_controlSmall)

    self:setWheelData(data.m_BigWheelData) -- 设置轮盘信息
    -- self.m_randWheelIndex = data.select -- 设置轮盘滚动位置
    self.m_smallWheelData = data.m_SmallWheelData
    self:getWheelSymbol()
    self:InitSmallWheel()
    -- local touch =self:findChild("Panel_1")
    -- if touch then
    --     self:addClick(touch)
    -- end
    -- 点击layer
    self:setTouchLayer()
end
function FrogPrinceReelGameWheelView:InitSmallWheel()
    for k, v in pairs(self.m_smallWheelData) do
        local data = {}
        data._num = v
        local lab = util_createView("CodeFrogPrinceSrc.FrogPrinceReelGameWheelLab", data)
        self:findChild("text" .. k):addChild(lab)
        -- table.insert( self.m_smallWheelNode, lab )
    end
end

function FrogPrinceReelGameWheelView:createHandEffect( )
    self.m_hand = util_createAnimation("FrogPrince_wheel_2.csb")
    self:findChild("Hand"):addChild(self.m_hand, 1)
    self.m_hand:playAction("actionframe",true)
end

function FrogPrinceReelGameWheelView:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        self.m_touchBeganPos = touch:getLocation()
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self.m_touchEndPos = touch:getLocation()
        if  self.m_touchBeganPos.x ~= self.m_touchEndPos.x or self.m_touchBeganPos.y ~= self.m_touchEndPos.y then
             self:clickFunc()
        end
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved_callback, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded_callback, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end


function FrogPrinceReelGameWheelView:clickFunc(sender)
    if self.m_bIsTouch == false then
        return
    end
    self.m_bIsTouch = false
    -- local name = sender:getName()
    if self.m_parent then
        -- if name == "Panel_1" then
            if  self.m_hand then
                self.m_hand:removeFromParent()
                self.m_hand = nil
            end
            self:createTouchEffect()
            self.m_parent:beginWheelViewAction()
        -- end
    end
end
function FrogPrinceReelGameWheelView:createTouchEffect( )
    local effect = util_createAnimation("FrogPrince_wheel_1.csb")
    self:findChild("touch"):addChild(effect)
    effect:playAction(
        "actionframe",
        false,
        function()
            effect:removeFromParent()
        end
    )
end
function FrogPrinceReelGameWheelView:setParent(_parent)
    self.m_parent = _parent
end

-- 转盘转动结束调用
function FrogPrinceReelGameWheelView:initSmallCallBack(callBackFun)
    self.m_smallcallFunc = function()
        callBackFun()
    end
end

function FrogPrinceReelGameWheelView:initBigCallBack(callBackFun)
    self.m_bigcallFunc = function()
        callBackFun()
    end
end

function FrogPrinceReelGameWheelView:onEnter()
end

function FrogPrinceReelGameWheelView:onExit()
end

function FrogPrinceReelGameWheelView:changeBtnEnabled(isCanTouch)
    -- self.m_csbOwner("FrogPrince_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

function FrogPrinceReelGameWheelView:beginBigWheelAction(endindex)
    local wheelData = {}
    wheelData.m_startA = 150 --加速度
    wheelData.m_runV = 500 --匀速
    wheelData.m_runTime = 3.5--匀速时间
    wheelData.m_slowA = 120 --动态减速度
    wheelData.m_slowQ = 2 --减速圈数
    wheelData.m_stopV = 100 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_bigcallFunc
    self.m_controlBig:changeWheelRunData(wheelData)
    self.randBigWheelIndex = endindex
    self.m_controlBig:beginWheel()
    self.m_controlBig:recvData(self.randBigWheelIndex,1)
end

function FrogPrinceReelGameWheelView:beginSmallWheelAction(endindex)
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
    wheelData.m_func = self.m_smallcallFunc
    self.m_controlSmall:changeWheelRunData(wheelData)
    self.randSmallWheelIndex = endindex
    self.distance_pre = 0
    self.distance_now = 0
    self.distance_pre_1 = 0
    self.distance_now_1 = 0
    self.m_controlSmall:beginWheel(true)
    self.m_controlSmall:recvData(self.randSmallWheelIndex)
end

-- 返回上轮轮盘的停止位置
function FrogPrinceReelGameWheelView:getLastEndIndex()
    return self.m_randWheelIndex
end

-- 设置轮盘实时滚动调用
function FrogPrinceReelGameWheelView:setWheelRotModel()
    self.m_controlBig:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

function FrogPrinceReelGameWheelView:setRotionAction(distance, targetStep, isBack)
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
function FrogPrinceReelGameWheelView:setWheelData(data)
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function FrogPrinceReelGameWheelView:getWheelSymbol()
    self.m_bigWheelNode = {}

    -- for i = 1, self.m_wheelSumIndex, 1 do
    --     self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("对应小node节点" .. i)
    -- end
end

return FrogPrinceReelGameWheelView
