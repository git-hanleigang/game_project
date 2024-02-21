---
--smy
--2018年4月18日
--DwarfFairyWheelView.lua


local DwarfFairyWheelView = class("DwarfFairyWheelView", util_require("base.BaseView"))
DwarfFairyWheelView.m_randWheelIndex = nil
DwarfFairyWheelView.m_wheelSumIndex = 16 -- 轮盘有多少块
DwarfFairyWheelView.m_wheelData = {} -- 大轮盘信息
DwarfFairyWheelView.m_wheelNode = {} -- 大轮盘Node 
DwarfFairyWheelView.m_bIsTouch = nil

function DwarfFairyWheelView:initUI(data)
    
    self:createCsbNode("DwarfFairy_lunpan.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel = require("CodeDwarfFairySrc.DwarfFairyWheelAction"):create(self:findChild("wheel"),16,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self:setWheelData(data.wheel )
    self.m_randWheelIndex = data.select
    self:getWheelSymbol()
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_wheel_appear.mp3")
    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
        self:setTouchLayer()
    end)

end

function DwarfFairyWheelView:setTouchLayer()
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

function DwarfFairyWheelView:clickFunc()
    if self.m_bIsTouch == false then
        return
    end
    gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_click_wheel.mp3")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    self.m_bIsTouch = false
    self:runCsbAction("jiantouxiaoshi", false, function ()
        self:beginWheelAction()
    end)
end

function DwarfFairyWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        local selectNode, selectAct = util_csbCreate("DwarfFairy_lunpan_zhongjiang.csb")
        self:findChild("select"):addChild(selectNode)
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_wheel_stop.mp3")
        util_csbPlayForKey(selectAct, "animation0", false, function()
            util_getChildByName(selectNode, "particle"):stopSystem()
            callBackFun()
        end)
        
    end
end

function DwarfFairyWheelView:onEnter()

end

function DwarfFairyWheelView:onExit()
    
end

function DwarfFairyWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("DwarfFairy_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

function DwarfFairyWheelView:beginWheelAction()

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
    self.m_wheel:recvData(self.m_randWheelIndex)

    
end

-- 返回上轮轮盘的停止位置
function DwarfFairyWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

function DwarfFairyWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function DwarfFairyWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_wheel_rptate.mp3")       
    end
end

function DwarfFairyWheelView:setWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end

function DwarfFairyWheelView:getWheelSymbol(  )
    self.m_bigWheelNode = {}

    for i = 1, self.m_wheelSumIndex, 1 do
        self.m_bigWheelNode[#self.m_bigWheelNode + 1] = self:findChild("reward_"..i)
    end
    
end

return DwarfFairyWheelView