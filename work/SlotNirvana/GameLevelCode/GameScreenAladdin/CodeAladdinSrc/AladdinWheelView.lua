---
--smy
--2018年4月18日
--AladdinWheelView.lua


local AladdinWheelView = class("AladdinWheelView", util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"
AladdinWheelView.m_randWheelIndex = nil
AladdinWheelView.m_wheelSumIndex =  12 -- 轮盘有多少块
AladdinWheelView.m_wheelData = {} -- 大轮盘信息
AladdinWheelView.m_wheelNode = {} -- 大轮盘Node 
AladdinWheelView.m_bIsTouch = nil

function AladdinWheelView:initUI(data)
    
    self:createCsbNode("Aladdin_Wheel.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel = require("CodeAladdinSrc.AladdinWheelAction"):create(self:findChild("zhuanpan"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    

    self:getWheelSymbol()

    self.m_btnSpin = util_createView("CodeAladdinSrc.AladdinWheelBtn")
    self:findChild("anniu"):addChild(self.m_btnSpin)

    self.m_rewardEffect = util_createView("CodeAladdinSrc.AladdinWheelEffect")
    self:findChild("zhongjiang"):addChild(self.m_rewardEffect)
    self.m_rewardEffect:setVisible(false)
    -- 点击layer
    self:showWheel()
end

function AladdinWheelView:showWheel()
    self:runCsbAction("show", false, function()
        self.m_btnSpin:showClickAnim()
        self:runCsbAction("idleframe", true)
        self:setTouchLayer()
        self.m_bIsTouch = true
    end)
end

function AladdinWheelView:showBtnAnimation()
    self.m_rewardEffect:setVisible(false)
    self.m_wheel.m_target:setRotation(0)
    self.m_btnSpin:showClickAnim()
    self:runCsbAction("idleframe", true)
end

function AladdinWheelView:addClickEvent()
    self:setTouchLayer()
    self.m_bIsTouch = true
end

function AladdinWheelView:setWheelResult(data)
    self:setWheelData(data.wheel ) -- 设置轮盘信息
    self.m_randWheelIndex = data.select -- 设置轮盘滚动位置
    self:runCsbAction("animation0", true)
    self.m_btnSpin:showIdle()
    self:beginWheelAction()
    self.m_effectID = 1
    local result = data.wheel[data.select]
    if type(result) == "number" then
        self.m_effectID = 3
    elseif result == "wild" then
        self.m_effectID = 2
    end
end

function AladdinWheelView:setTouchLayer()
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

function AladdinWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end

    gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_wheel_click.mp3")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false

    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, false)

end

-- 转盘转动结束调用
function AladdinWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        self:runCsbAction("zhongjiang")
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_wheel_reward.mp3")
        self.m_rewardEffect:showRewardAnim(self.m_effectID)
        performWithDelay(self, function()
            callBackFun()
        end, 5)
    end
end

function AladdinWheelView:onEnter()

end

function AladdinWheelView:onExit()
    
end

function AladdinWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("Aladdin_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function AladdinWheelView:beginWheelAction()

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

    self.distance_pre = 0
    self.distance_now = 0
    self.m_wheel:beginWheel()
    -- 设置轮盘功能滚动结束停止位置
    self.m_wheel:recvData(self.m_randWheelIndex)

    
end

-- 返回上轮轮盘的停止位置
function AladdinWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function AladdinWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function AladdinWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_wheel_rotate.mp3")       
    end
end

-- 设置轮盘网络消息
function AladdinWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function AladdinWheelView:getWheelSymbol(  )
    self.m_bigWheelNode = {}

    for i = 1, self.m_wheelSumIndex, 1 do
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("对应小node节点"..i)
    end
    
end

return AladdinWheelView