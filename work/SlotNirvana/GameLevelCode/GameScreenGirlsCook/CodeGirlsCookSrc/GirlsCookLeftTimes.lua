---
--xcyy
--2018年5月23日
--GirlsCookLeftTimes.lua

local GirlsCookLeftTimes = class("GirlsCookLeftTimes",util_require("base.BaseView"))

local STATUS_WITH_TIMER                 =       2001        --限时任务
local STATUS_WITH_SPINCOUNT_1           =       2002        --限次任务(在次数内)
local STATUS_WITH_SPINCOUNT_2           =       2003        --限次任务(超出次数)


function GirlsCookLeftTimes:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("GirlsCook_menu_spin_left.csb")
    self.m_leftTimes = 0
    --倒计时标签
    self.m_lb_time = self:findChild("m_lb_time")

    self.m_isTimeStart = false
end


function GirlsCookLeftTimes:onEnter()

end


function GirlsCookLeftTimes:onExit()
 
end

--[[
    变换菜单项
]]
function GirlsCookLeftTimes:changeMenu(menuType)
    self:findChild("Node_time"):setVisible(menuType == STATUS_WITH_TIMER)
    self:findChild("Node_spinleft_1"):setVisible(menuType == STATUS_WITH_SPINCOUNT_1)
    self:findChild("Node_spinleft_2"):setVisible(menuType == STATUS_WITH_SPINCOUNT_2)
end

--[[
    隐藏菜单项
]]
function GirlsCookLeftTimes:hideAllMenu()
    self:findChild("Node_time"):setVisible(false)
    self:findChild("Node_spinleft_1"):setVisible(false)
    self:findChild("Node_spinleft_2"):setVisible(false)
end

--[[
    开始动作
]]
function GirlsCookLeftTimes:startAni(func)
    self:setVisible(true)
    
    self:runCsbAction("start",false,function()
        self.m_isOver = false
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    结束动作
]]
function GirlsCookLeftTimes:overAni(func)
    self.m_isOver = true
    self:runCsbAction("over",false,function()
        self:setVisible(false)
    end)
    self.m_machine:delayCallBack(20 / 60,function()
        self:hideAllMenu()
    end)
end

--[[
    初始化食物
]]
function GirlsCookLeftTimes:initFood(dishData)
    self.m_foodItem = nil
    if not dishData then
        return
    end

    self:updataCountDownTimes(dishData)

    --变更菜单
    if dishData.collectType == "TIME" then
        self:changeMenu(STATUS_WITH_TIMER)
        
    elseif dishData.collectType == "COUNT" and dishData.spinCount < dishData.firstCount then
        self:changeMenu(STATUS_WITH_SPINCOUNT_1)
        self:updateLeftTimes(dishData)
    else
        self:changeMenu(STATUS_WITH_SPINCOUNT_2)
        self:updateLeftTimes(dishData)
    end
end


--[[
    刷新剩余次数
]]
function GirlsCookLeftTimes:updateLeftTimes(dishData)
    local leftTimes = dishData.firstCount - dishData.spinCount
    if leftTimes <= 0 then
        leftTimes = dishData.secondCount - dishData.spinCount

        self:changeMenu(STATUS_WITH_SPINCOUNT_2)
    end
    if leftTimes <= 0 then
        leftTimes = 0
    end

    self:findChild("m_lb_num_cishu2"):setString(leftTimes)
    self:findChild("m_lb_num_cishu"):setString(leftTimes)
end

--[[
    刷新倒计时时间
]]
function GirlsCookLeftTimes:updataCountDownTimes(dishData)
    if dishData.collectType == "TIME" then
        self.m_isTimeStart = dishData.timeStart
        -- print("curLeftTime = "..self.m_leftTimes)
        -- print("serverLeftTime = "..dishData.surplusTime)
        self.m_leftTimes = math.floor(dishData.surplusTime / 1000)
        
        local str = util_hour_min_str(self.m_leftTimes)
        self.m_lb_time:setString(str)
    end
end

--[[
    倒计时
]]
function GirlsCookLeftTimes:countDown()
    if not self.m_isTimeStart then
        return
    end
    self.m_leftTimes = self.m_leftTimes - 1
    if self.m_leftTimes <= 0 then
        self.m_leftTimes = 0
    end
    local str = util_hour_min_str(self.m_leftTimes or 0)
    self.m_lb_time:setString(str)
end

--[[
    停止倒计时
]]
function GirlsCookLeftTimes:stopCountDown()
    self.m_lb_time:stopAllActions()
end

return GirlsCookLeftTimes