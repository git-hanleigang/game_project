local BaseWheel = class("BaseWheel", cc.Node)
require("socket")
BaseWheel.ACTION_READY = 0  --准备
BaseWheel.ACTION_START = 1   --开始
BaseWheel.ACTION_RUNNING = 2  --进行
BaseWheel.ACTION_SLOW = 4   --减速
BaseWheel.ACTION_STOPING = 5   --停止
BaseWheel.ACTION_BACK = 6   --回弹
BaseWheel.ACTION_BACK_FRONT = 7 --回弹前 需要在一秒内让速度减到0
function BaseWheel:ctor(node, num, func,setRotFunc)
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


    self.m_startA = 200 --加速度
    self.m_runV = 500--匀速
    self.m_runTime = 2 --匀速时间
    self.m_slowA = 300 --动态减速度
    self.m_slowQ = 2 --减速圈数
    self.m_stopV = 80--25 --停止时速度
    self.m_backV = self.m_targetStep * 1.5 --*0.5 --回弹时最大速度
    self.m_backTime = 0 --回弹前停顿时间
    self.m_stopNum = 0 --停止圈数

    self.m_randomDistance = 0

    self.m_isAnti = nil --是否是逆时针
    self.m_isIgnorePause = nil
end

--是否忽略暂停
function BaseWheel:setIgnorePause(flag)
    self.m_isIgnorePause = flag
end

--是否忽略暂停
function BaseWheel:bindData(key)
    globalData.bindWheelParam(key,self)
end
--是否忽略暂停
function BaseWheel:removeBindData(key)
    globalData.removeWheelParam(key)
end

function BaseWheel:isPauseView()
    if globalData.slotRunData.gameRunPause and not self.m_isIgnorePause then
        return true
    end
    return false
end

function BaseWheel:updateWheel(dt)
    if self:isPauseView() then
        return
    end
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

--保存时间
function BaseWheel:saveTime()
    self.m_curTime = socket.gettime()
end

--读取时间间隔
function BaseWheel:getSpanTime()
    local spanTime = (socket.gettime() - self.m_curTime)
    return spanTime
end --更新滚动

function BaseWheel:changeWheel(offset, maxStep,isBack)
    local step = offset * self.m_frameStep
    if maxStep and step > maxStep then
        step = maxStep
    end
    if isBack then
        if step > 0 then
            isBack = false
        end
    end
    self:changePos(step,isBack)
    return step
end

function BaseWheel:changePos(step,isBack)
    self.m_currentDistance = self.m_currentDistance + step

    while self.m_currentDistance>360 do
        self.m_currentDistance = self.m_currentDistance - 360
    end

    self:setRotation(self.m_currentDistance,isBack)

end

function BaseWheel:setRotation(distance,isBack)
    if self.m_target then
        if self.m_isAnti then
            self.m_target:setRotation(-distance)
        else
            self.m_target:setRotation(distance)
        end
    end
    if self.m_setRotFunc then
        self.m_setRotFunc(distance,self.m_targetStep,isBack)
    end
end

function BaseWheel:beginWheel(isAnti)
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

function BaseWheel:startWheel()
    self.m_curV = self.m_curV + self.m_curA*self.m_frameStep
    self:changeWheel(self.m_curV)
    if self.m_curV >= self.m_targetV then
        self:prepareRun()
    end
end

function BaseWheel:prepareRun()
    self.m_curV = self.m_runV
    self.m_curA = 0
    self.m_status = self.ACTION_RUNNING
    local time = self:getSpanTime()
    print("startWheel time = " .. time)
    self:saveTime()
end
function BaseWheel:runWheel()
    self:changeWheel(self.m_curV)
    local time = self:getSpanTime()
    if time >= self.m_runTime and self.m_isWheelData then
        self:prepareSlow()
    end
end

function BaseWheel:recvData(index)
    self.m_isWheelData = true
    self.overIndex = index --最后停止的下标
    self.m_moveDistance = 360-(self.overIndex - 1) * self.m_targetStep  --需要移动的距离

    self.m_dirType = math.random(-1,1)
    --不需要停在正中央位置的
    if self.m_dirType == 0 then
        self.m_dirType = 1
    end
    --self.m_dirType = 1
    self.m_randomDistance = 0  --最后停留的位置偏移
    if self.m_dirType ==-1 then
        self.m_randomDistance = math.random(-0.2*self.m_targetStep,-self.m_targetStep*0.5)
    elseif self.m_dirType == 1 then
        self.m_randomDistance = math.random(self.m_targetStep*0.2,self.m_targetStep*0.5) --0.5 0.7
        --self.m_randomDistance = self.m_targetStep*0.7
    end
    self.m_targetDistance = 360*self.m_stopNum + self.m_moveDistance+self.m_randomDistance
    self.m_targetDistance1 = self.m_targetDistance - self.m_targetStep
    if self.m_targetDistance1 < 0 then
        self.m_targetDistance1 = self.m_targetDistance1 + 360
    end

    self.m_randomDistance = math.abs( self.m_randomDistance )
end

function BaseWheel:prepareSlow()
    local dis = self.m_slowQ * 360 + self.m_targetDistance1 - self.m_target:getRotation()
    self.m_curA = (self.m_curV * self.m_curV - self.m_stopV * self.m_stopV)/(2*dis) --2*a*s=v*v-v0*v0
    self.m_targetV = self.m_stopV
    self.m_status = self.ACTION_SLOW
    local time = self:getSpanTime()
    print("runWheel time = " .. time)
    self:saveTime()
end

function BaseWheel:slowWheel()
    self.m_curV = self.m_curV - self.m_curA*self.m_frameStep
    self:changeWheel(self.m_curV)
    if self.m_curV <= self.m_targetV then
        self:prepareStoping()
    end
end

function BaseWheel:prepareStoping()
    self.m_status = self.ACTION_STOPING
    if self.m_dirType == -1 then
        self.m_targetV =30
    else
        self.m_targetV = 10
    end
    local v0  = self.m_targetV

    self.m_stopDistance = self.m_targetDistance -self.m_currentDistance
    if self.m_stopDistance < 0 then
        self.m_stopDistance = self.m_stopDistance + 360
    end

    --self.m_curV  = self.m_stopV --self.m_stopDistance * 0.4

    self.m_curA = (self.m_curV * self.m_curV - v0 * v0) / (2*self.m_stopDistance*0.9) --2*a*s=v*v-v0*v0
    local time = self:getSpanTime()
    print("slowWheel time = " .. time)
    self:saveTime()
end

function BaseWheel:stopingWheel()
    self.m_curV = self.m_curV - self.m_curA*self.m_frameStep
    local step = self:changeWheel(self.m_curV)
    print("!!! BaseWheel:stopingWheel", self.m_curV, self.m_targetV, self.m_stopDistance, step)

    self.m_stopDistance = self.m_stopDistance-step
    if self.m_stopDistance<=0 then
        self:changePos(self.m_stopDistance)
        self:prepareBackFront(self.m_targetV)
    elseif self.m_curV <= self.m_targetV then
        self:prepareBackFront(self.m_targetV)
    end
end

function BaseWheel:prepareBack(backV)

    self.m_status = self.ACTION_BACK
    local time = self:getSpanTime()
    print("stopingBackFront time = " .. time)
    self:saveTime()
    local distance=math.abs(self.m_moveDistance-self.m_currentDistance)
    if self.m_dirType == 0 then
        self:overWheel()
    else
        if backV == 0 then  --回弹
            self.m_curA = (self.m_curV * self.m_curV - self.m_backV* self.m_backV) / (distance) --2*a*s=v*v-v0*v0
            --self.m_curV= self.m_backV

            --self.m_curA = self.m_curV * self.m_curV / (2*distance)

        else   --划过
            self.m_curA = (self.m_curV * self.m_curV - 0) / (2*distance) --2*a*s=v*v-v0*v0
        end
        self.m_targetV = 0
    end
    if self.m_curV < 0 then
        self.m_curV = 0
    end
end



function BaseWheel:backWheel()

    local time = self:getSpanTime()
    if self.m_dirType == 1 and time<self.m_backTime  then
        return
    end

    if self.m_dirType == 1 and self.m_curV > self.m_backV then
        self.m_curA = -self.m_curA
    end
    self.m_curV = self.m_curV - self.m_curA*self.m_frameStep

    local step = self:changeWheel(-1*self.m_curV*self.m_dirType,nil,true)
    self.m_randomDistance = self.m_randomDistance-math.abs(step)
    if self.m_randomDistance<=0 then
        self:overWheel()
    elseif self.m_curV <= self.m_targetV then
        self:overWheel()
    end
end

function BaseWheel:prepareBackFront(backV)

    self.m_status = self.ACTION_BACK_FRONT
    if self.m_dirType == -1 then
        self.m_targetV =20
    else
        self.m_targetV = 0
    end
    local v0 = self.m_targetV
    self.m_curA = (self.m_curV * self.m_curV - v0 * v0) / (2*self.m_stopDistance) --2*a*s=v*v-v0*v0
    local time = self:getSpanTime()
    print("stopingWheel time = " .. time)
    self:saveTime()

end



function BaseWheel:backFrontWheel()

    self.m_curV = self.m_curV - self.m_curA*self.m_frameStep
    local step = self:changeWheel(self.m_curV)

    self.m_stopDistance = self.m_stopDistance-step
    if self.m_stopDistance<=0 then
        self:changePos(self.m_stopDistance)
        self:prepareBack(self.m_targetV)
    elseif self.m_curV <= self.m_targetV then
        self:prepareBack(self.m_targetV)
    end

    -- local time = self:getSpanTime()
    -- self.m_curV = self.m_curV - self.m_curA*self.m_frameStep

    -- local step = self:changeWheel(-1*self.m_curV*self.m_dirType,nil,true)
    -- self.m_randomDistance = self.m_randomDistance-math.abs(step)
    -- if self.m_randomDistance<=0 then
    --     self:overWheel()
    -- elseif self.m_curV <= self.m_targetV then
    --     self:overWheel()
    -- end
end

function BaseWheel:overWheel()
    local time = self:getSpanTime()
    print("backWheel time = " .. time)
    if self.m_target then
        self:setRotation(self.m_moveDistance)
    end
    self.m_status = self.ACTION_READY
    if self.m_func then
        self.m_func()
    end
    self:stopAllActions()
end

return BaseWheel
