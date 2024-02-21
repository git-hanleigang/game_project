---
--smy
--2018年4月18日
--QuickSpinWheelView.lua


local QuickSpinWheelView = class("QuickSpinWheelView", util_require("base.BaseView"))
QuickSpinWheelView.m_randWheelIndex = nil
QuickSpinWheelView.m_wheelSumIndex =  20 -- 轮盘有多少块
QuickSpinWheelView.m_wheelData = {} -- 大轮盘信息
QuickSpinWheelView.m_wheelNode = {} -- 大轮盘Node 

function QuickSpinWheelView:initUI(data)
    
    self:createCsbNode("QuickSpin_Wheel.csb") 

    self.m_wheel = require("CodeQuickSpinSrc.QuickSpinWheelAction"):create(self:findChild("wheel"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)
    self:setWheelRotModel()

    self.m_eye = util_createView("CodeQuickSpinSrc.QuickSpinWheelEye")
    self:findChild("yan"):addChild(self.m_eye)
    self.m_multip = util_createView("CodeQuickSpinSrc.QuickSpinWheelMultip")
    self:findChild("yan"):addChild(self.m_multip)
    self.m_multip:setVisible(false)
    self.m_multipAction = util_createView("CodeQuickSpinSrc.QuickSpinWheelMultipAction")
    self:findChild("QuickSpin_zhizhen_light"):addChild(self.m_multipAction)
    self.m_light = util_createView("CodeQuickSpinSrc.QuickSpinWheelLight")
    self:findChild("QuickSpin_Light"):addChild(self.m_light)
    -- self.m_lock = util_createView("CodeQuickSpinSrc.QuickSpinWheelLock")
    -- self:findChild("QuickSpin_suo"):addChild(self.m_lock)
    self.m_bgLight = util_createView("CodeQuickSpinSrc.QuickSpinWheelBgLight")
    self:findChild("QuickSpin_Wheel_bglight"):addChild(self.m_bgLight)
    self.m_bgLight:setVisible(false)

    self:rotateWheel()

    self:runCsbAction("animation0", true)
end

function QuickSpinWheelView:rotateWheel()
    self.m_wheel:rotateWheel()
end

function QuickSpinWheelView:showMultipAction(betLevel)
    if betLevel == 1 then
        self.m_multipAction:reset()
    else
        self.m_multipAction:lowerBetTipShow(function()
            -- local tip, act = util_csbCreate("QuickSpin_tishi.csb")
            -- self:findChild("QuickSpin_suo"):addChild(tip)
            -- util_csbPlayForKey(act, "auto", false, function()
            --     tip:removeFromParent(true)
            -- end)
        end)
    end
end

function QuickSpinWheelView:showLock()
    -- self.m_lock:show()
end

function QuickSpinWheelView:hideLock()
    -- self.m_lock:hide()
end

function QuickSpinWheelView:hideMask()
    self:findChild("black"):setVisible(false)
end

function QuickSpinWheelView:resetWheel()
    self:findChild("black"):setVisible(true)
    self:findChild("zhongjaing"):removeAllChildren()
    self:rotateWheel()
    self.m_light:hide()
    self.m_multipAction:reset()
    self.m_bgLight:setVisible(false)
    if self.m_iMultip ~= 1 then
        self.m_multip:hide(function()
            self.m_eye:show()
        end)
    end
end

function QuickSpinWheelView:clickFunc(multip)
    self:setMultip(multip)
    self.m_light:show()
    self.m_bgLight:setVisible(true)
    if multip == 1 then
        self:beginWheelAction()
    else
        gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_wheel_multiple_"..multip..".mp3") 
        self.m_multipAction:showMultip(multip)
        self.m_eye:hide(function()
            self.m_multip:setVisible(true)
            self.m_multip:show(multip, function()
                self:beginWheelAction()
            end)
        end)
    end
end

-- 转盘转动结束调用
function QuickSpinWheelView:initCallBack(callBackFun)
    self.m_callFunc = function()
        gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_wheel_selected.mp3")       
        local select, act = util_csbCreate("QuickSpin_Wheel_zhongjiang.csb")
        self:findChild("zhongjaing"):addChild(select)
        util_csbPlayForKey(act, "show", false, function()
            util_csbPlayForKey(act, "idle", true)
            callBackFun()
        end)
    end
    -- util_csbPlayForKey(act, "over", false, function()
    --     callBackFun()
    -- end, 20)
end

function QuickSpinWheelView:setResultIndex(index)
    self.m_randWheelIndex = index
end

function QuickSpinWheelView:setMultip(multip)
    self.m_iMultip = multip
end

function QuickSpinWheelView:onEnter()

end

function QuickSpinWheelView:onExit()
    
end

-- 设置转盘盘滚动参数
function QuickSpinWheelView:beginWheelAction()

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

    gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_wheel_rptate.mp3")       
    
end

-- 返回上轮轮盘的停止位置
function QuickSpinWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function QuickSpinWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function QuickSpinWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        -- self:runCsbAction("animation0") 
        -- gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_wheel_rptate.mp3")       
    end
end

return QuickSpinWheelView