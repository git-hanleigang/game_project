---
--xcyy
--2018年5月23日
--JollyFactoryWheelNode.lua
local PublicConfig = require "JollyFactoryPublicConfig"
local JollyFactoryWheelNode = class("JollyFactoryWheelNode",util_require("Levels.BaseReel.BaseWheelNew"))

--滚动方向
local DIRECTION = {
    CLOCK_WISE = 1,             --顺时针
    ANTI_CLOCK_WISH = -1,       --逆时针
}
--转动阶段
local ACTION_STATUS = {
    ACTION_READY = 0,  --准备
    ACTION_START = 1,   --开始
    ACTION_RUNNING = 2,  --进行
    ACTION_ACCELERATE = 3,  --加速
    ACTION_UNIFORM = 4, --匀速 
    ACTION_SLOW = 5,   --减速
    ACTION_STOPING = 6,   --停止
    ACTION_BACK = 7,   --回弹
}

--[[
    设置减速回调
]]
function JollyFactoryWheelNode:setSlowFunc(func)
    self.m_slowFunc = func
end

--[[
    开启计时器
]]
function JollyFactoryWheelNode:startSchedule()
    --设置状态机
    self:setActionStatus(ACTION_STATUS.ACTION_RUNNING)
    self.m_scheduleNode:onUpdate(function(dt)
        if globalData.slotRunData.gameRunPause then
            return
        end

        --刷新速度
        self:updateSpeed(dt)

        --计算偏移量
        local offset = dt * self.m_curSpeed

        --当前的偏转角度
        self.m_curRotation  = self.m_curRotation + offset * self.m_direction
        self.m_rotateNode:setRotation(self.m_curRotation)

        if not self.m_isWaittingNetBack then
            self.m_rotationAfterNetBack  = self.m_rotationAfterNetBack + offset

            --判断是否停轮
            if self.m_direction == DIRECTION.CLOCK_WISE then
                local totalDistance = self:getTotalDistance()
                if self.m_rotationAfterNetBack >= totalDistance then
                    self:wheelDown()
                end

                if self.m_rotationAfterNetBack >= totalDistance - 36 then
                    if type(self.m_slowFunc) == "function" then
                        self.m_slowFunc()
                        self:setSlowFunc(nil)
                    end
                end
            else
                local totalDistance = self:getTotalDistance()
                if self.m_rotationAfterNetBack >= totalDistance then
                    self:wheelDown()
                end
            end
        end
    end)
end

return JollyFactoryWheelNode