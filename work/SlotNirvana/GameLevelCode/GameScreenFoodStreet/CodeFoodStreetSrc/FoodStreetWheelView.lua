---
--smy
--2018年4月18日
--FoodStreetWheelView.lua

local FoodStreetWheelView = class("FoodStreetWheelView", util_require("base.BaseView"))
FoodStreetWheelView.m_randWheelIndex = nil
FoodStreetWheelView.m_wheelSumIndex = 8 -- 轮盘有多少块
FoodStreetWheelView.m_wheelData = {} -- 大轮盘信息
FoodStreetWheelView.m_wheelNode = {} -- 大轮盘Node
FoodStreetWheelView.m_bIsTouch = nil

function FoodStreetWheelView:initUI(data)
    self:createCsbNode("FoodStreet_Wheel.csb")

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel =
        require("CodeFoodStreetSrc.FoodStreetWheelAction"):create(
        self:findChild("zhuanpan"),
        self.m_wheelSumIndex,
        function()
            -- 滚动结束调用
        end,
        function(distance, targetStep, isBack)
            -- 滚动实时调用
        end
    )
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.wheel) -- 设置轮盘信息
    self.m_randWheelIndex = data.select + 1
     -- 设置轮盘滚动位置

    self:getWheelSymbol()

    local index = 1
    while true do
        local parent = self:findChild("text_" .. index)
        if parent ~= nil then
            local csbName = "FoodStreet_Wheel_zi1.csb"
            if index % 2 == 0 then
                csbName = "FoodStreet_Wheel_zi.csb"
            end
            local info = {}
            info.name = csbName
            info.coin = data.wheel[index + 1]
            local coinNum = util_createView("CodeFoodStreetSrc.FoodStreetWheelCoin", info)
            parent:addChild(coinNum)
        else
            break
        end
        index = index + 1
    end

    -- 点击layer
    self:setTouchLayer()

    self:runCsbAction("actionframe", true)
end

function FoodStreetWheelView:setTouchLayer()
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
    listener:registerScriptHandler(onTouchBegan_callback, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved_callback, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded_callback, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function FoodStreetWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end

    self:runCsbAction("idle")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self, true)
    self.m_bIsTouch = false

    self:beginWheelAction()
end

-- 转盘转动结束调用
function FoodStreetWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_stop.mp3")
        self:runCsbAction("zhongjiang", true)
        performWithDelay(
            self,
            function()
                callBackFun()
            end,
            3
        )
    end
end

function FoodStreetWheelView:onEnter()
end

function FoodStreetWheelView:onExit()
end

function FoodStreetWheelView:changeBtnEnabled(isCanTouch)
    -- self.m_csbOwner("FoodStreet_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function FoodStreetWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 1 --匀速时间
    wheelData.m_slowA = 350 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 100 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 10

    wheelData.m_func = self.m_callFunc

    self.m_wheel:changeWheelRunData(wheelData)

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()

    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)

    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_begin.mp3")
end

-- 返回上轮轮盘的停止位置
function FoodStreetWheelView:getLastEndIndex()
    return self.m_randWheelIndex
end

-- 设置轮盘实时滚动调用
function FoodStreetWheelView:setWheelRotModel()
    self.m_wheel:setWheelRotFunc(
        function(distance, targetStep, isBack)
            self:setRotionAction(distance, targetStep, isBack)
        end
    )
end

function FoodStreetWheelView:setRotionAction(distance, targetStep, isBack)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now

        -- self:runCsbAction("animation0")
        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_wheel_rot.mp3")
    end
end

-- 设置轮盘网络消息
function FoodStreetWheelView:setWheelData(data)
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function FoodStreetWheelView:getWheelSymbol()
    self.m_bigWheelNode = {}

    for i = 1, self.m_wheelSumIndex, 1 do
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("对应小node节点" .. i)
    end
end

return FoodStreetWheelView
