---
--smy
--2018年4月18日
--BuffaloWildWheelAction.lua


local BuffaloWildWheelAction = class("BuffaloWildWheelAction", util_require("base.BaseWheel"))

function BuffaloWildWheelAction:ctor(node, num, func,setRotFunc,Array)
    self.m_target = node
    self.m_status = self.ACTION_READY
    self.m_func = func
    self.m_setRotFunc = setRotFunc
    self.m_isWheelData = false
    self.m_targetStep = 360 / num


    self.m_targetDistance = 0
    self.m_moveDistance = 0
    self.m_currentDistance = 0
    self.m_stopDistance = 0

    self.m_curTime = 0
    self.m_curV = 0
    self.m_curA = 0
    self.m_targetV = 0
    self.m_frameStep = 0


    self.m_startA = 300 --加速度
    self.m_runV = 500--匀速
    self.m_runTime = 2 --匀速时间
    self.m_slowA = 150 --动态减速度
    self.m_slowQ = 1 --减速圈数
    self.m_stopV = 110 --停止时速度
    self.m_backTime = 0 --回弹前停顿时间
    self.m_stopNum = 0 --停止圈数
    self.m_randomDistance = 0

    self.m_backV = self.m_targetStep*0.5 --回弹时速度

end
function BuffaloWildWheelAction:updateWheel(dt)

    self.m_frameStep = dt
    if self.m_status == self.ACTION_READY then
    elseif self.m_status == self.ACTION_START then
        self:startWheel()
    elseif self.m_status == self.ACTION_RUNNING then
        self:runWheel()
    elseif self.m_status == self.ACTION_SLOW then
        self:slowWheel()
    elseif self.m_status == self.ACTION_STOPING then
        self:stopingWheel()
    elseif self.m_status == self.ACTION_BACK_FRONT then
        self:backFrontWheel()
    elseif self.m_status == self.ACTION_BACK then
        self:backWheel()
    end
end

function BuffaloWildWheelAction:beginWheel(isAnti)
    self.m_currentDistance = self.m_target:getRotation()

    local function update(dt)
        self:updateWheel(dt)
    end
    self:onUpdate(update)

    self.m_status = self.ACTION_START
    self.m_curV = 0
    self.m_curA = self.m_startA
    self.m_targetV = self.m_runV
    self.m_isAnti = isAnti
    self:saveTime()
end
function BuffaloWildWheelAction:changeWheelRunData( Array)

    self.m_status = self.ACTION_READY

    self.m_startA = Array.m_startA --加速度
    self.m_runV = Array.m_runV--匀速
    self.m_runTime = Array.m_runTime --匀速时间
    self.m_slowA = Array.m_slowA --动态减速度
    self.m_slowA = Array.m_slowA --减速圈数
    self.m_stopV = Array.m_stopV --停止时速度
    self.m_backTime = Array.m_backTime --回弹前停顿时间
    self.m_stopNum = Array.m_stopNum --停止圈数
    -- self.m_func = Array.m_func
end
function BuffaloWildWheelAction:recvData(index,dirType)
    self.m_isWheelData = true
    self.overIndex = index --最后停止的下标
    self.m_moveDistance = 360-(self.overIndex - 1) * self.m_targetStep  --需要移动的距离

    self.m_dirType = math.random(-1,1)
    --不需要停在正中央位置的
    if self.m_dirType == 0 then
        self.m_dirType = 1
    end
    self.m_dirType = -1
    self.m_randomDistance = 0  --最后停留的位置偏移
    if self.m_dirType ==-1 then
        self.m_randomDistance = math.random(-0.5*self.m_targetStep,-self.m_targetStep*0.5)
    elseif self.m_dirType == 1 then
        self.m_randomDistance = math.random(self.m_targetStep*0.6,self.m_targetStep*0.7) --0.5 0.7
        --self.m_randomDistance = self.m_targetStep*0.7
    end
    -- if dirType then
    --     self.m_randomDistance = math.random(-0.25*self.m_targetStep,self.m_targetStep*0.25)
    -- -- self.m_randomDistance = 0
    --     self.m_moveDistance =  self.m_moveDistance +self.m_randomDistance
    -- end
    self.m_targetDistance = 360*self.m_stopNum + self.m_moveDistance+self.m_randomDistance
    self.m_targetDistance1 = self.m_targetDistance - self.m_targetStep
    if self.m_targetDistance1 < 0 then
        self.m_targetDistance1 = self.m_targetDistance1 + 360
    end

    self.m_randomDistance = math.abs( self.m_randomDistance )
end
function BuffaloWildWheelAction:setWheelRotFunc( setRotFunc )
    self.m_setRotFunc = setRotFunc
end

--保存时间
function BuffaloWildWheelAction:saveTime()
    self.m_curTime = socket.gettime()
end

--读取时间间隔
function BuffaloWildWheelAction:getSpanTime()
    local spanTime = (socket.gettime() - self.m_curTime)
    return spanTime
end



function BuffaloWildWheelAction:overWheel()
    local time = self:getSpanTime()
    print("backWheel time = " .. time)
    if self.m_target then
        self:setRotation(self.m_moveDistance)
    end
    self.m_status = self.ACTION_READY
    if self.m_func then
        self.m_func()
    end
    -- self:stopAllActions()
end

return BuffaloWildWheelAction