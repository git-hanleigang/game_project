---
--smy
--2018年4月18日
--AliceWheelView.lua


local AliceWheelView = class("AliceWheelView", util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"
AliceWheelView.m_randWheelIndex = nil
AliceWheelView.m_wheelSumIndex = 6 -- 轮盘有多少块
AliceWheelView.m_wheelData = {} -- 大轮盘信息
AliceWheelView.m_wheelNode = {} -- 大轮盘Node 
AliceWheelView.m_bIsTouch = nil

function AliceWheelView:initUI(data)
    
    self:createCsbNode("Alice/Alice_Wheel.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = false
    self.m_wheel = require("CodeAliceSrc.AliceWheelAction"):create(self:findChild("lunpan"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:getWheelSymbol()

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_bIsTouch = true
    end)
    -- 点击layer
    -- self:setTouchLayer()
    self:setWheelData(data) -- 设置轮盘信息

    self:initWheelSymbol(data)

    self.m_delayAction = performWithDelay(self, function()
        self.m_delayAction = nil
        self:clickFunc()
    end, 5)
end

function AliceWheelView:initWheelSymbol(data)
    local skip = util_csbCreate("wheel_lab_score_2.csb")
    self:findChild("shuzi_0"):addChild(skip)

    local index = 1
    while true do
        local parent = self:findChild("shuzi_"..index)
        if parent ~= nil then
            local collectNum = util_csbCreate("wheel_lab_score_1.csb")
            parent:addChild(collectNum)
            local lab = util_getChildByName(collectNum, "m_lb_score_1")
            lab:setString(data[index + 1])
        else
            break
        end
        index = index + 1
    end
end

function AliceWheelView:setTouchLayer()
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

function AliceWheelView:clickFunc(sender)
    if self.m_bIsTouch == false then
        return
    end
    if self.m_delayAction ~= nil then
        self:stopAction(self.m_delayAction)
        self.m_delayAction = nil
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_wheel_click.mp3")
    -- local eventDispatcher = self:getEventDispatcher()
    -- eventDispatcher:removeEventListenersForTarget(self, true)
    self.m_bIsTouch = false

    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, false)
    self:findChild("Button"):setEnabled(false)
    self:runCsbAction("rotation")
end

-- 转盘转动结束调用
function AliceWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        gLobalSoundManager:setBackgroundMusicVolume(0)
        self:runCsbAction("actionframe", true)
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_wheel_reward.mp3")
        performWithDelay(self, function()
            self:runCsbAction("over", false, function()
                callBackFun()
            end)
        end, 2)
        
    end
end

function AliceWheelView:onEnter()
   
end

function AliceWheelView:onExit()
    
end

function AliceWheelView:wheelResultCallFun(select)
   
    self.m_randWheelIndex = select -- 设置轮盘滚动位置
    self:beginWheelAction()
end

function AliceWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("Alice_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function AliceWheelView:beginWheelAction()

    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 600--匀速
    wheelData.m_runTime = 3 --匀速时间
    wheelData.m_slowA = 600 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 600 --停止时速度
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
function AliceWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function AliceWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function AliceWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_wheel_rptate.mp3")       
    end
end

-- 设置轮盘网络消息
function AliceWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function AliceWheelView:getWheelSymbol(  )
    self.m_bigWheelNode = {}

    for i = 1, self.m_wheelSumIndex, 1 do
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("对应小node节点"..i)
    end
    
end

return AliceWheelView