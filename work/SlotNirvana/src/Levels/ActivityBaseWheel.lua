--[[
    基础轮盘
]]
local ActivityBaseWheel = class("ActivityBaseWheel", cc.Node)
ActivityBaseWheel.m_doneFunc = nil            --列停止回调

--滚动方向
GD.DIRECTION = {
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

--默认配置
local START_SPEED   =   0           --开始速度
local MIN_SPEED     =   10          --最小速度(每秒转动的角度)
local MAX_SPEED     =   500         --最大速度(每秒转动的角度)
local ACC_SPEED     =   200          --加速阶段的加速度(每秒增加的角速度)
local REDUCE_SPEED  =   80          --减速结算的加速度(每秒减少的角速度)
local TURN_NUM      =   3           --开始减速前转动的圈数
local BACK_DISTANCE =   3          --回弹距离
local BACK_TIME     =   1.5         --回弹时间
local MIN_DISTANCE  =   36          --以最小速度行进的距离

--[[
    params = {
        doneFunc = ,        --停止回调
        rotateNode = ,      --需要转动的节点
        sectorCount = 10,     --总的扇面数量
        direction = DIRECTION.CLOCK_WISE,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 10,      --最小速度(每秒转动的角度)
        maxSpeed = 500,     --最大速度(每秒转动的角度)
        accSpeed = 200,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 80,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 3,         --开始减速前转动的圈数
        minDistance = 36,   --以最小速度行进的距离
        backDistance = 3,    --回弹距离
        backTime = 1.5      --回弹时间
        pointerDo = true,  --是否开启指针跟着晃动 
        pointerSp = self.m_wheelPointerSp --指针
    }
]]
function ActivityBaseWheel:ctor(params)
    --停止回调
    self.m_doneFunc = params.doneFunc
    self.m_setRotFunc = params.RotFunc
    self.m_setAngFunc = params.AngFunc
    --总的扇面数量
    self.m_sectorCount = params.sectorCount
    --索引从0开始
    self.m_endIndex = -1

    --需要转动的节点
    self.m_rotateNode = params.rotateNode

    --滚动方向
    self.m_direction = params.direction
    if not self.m_direction then
        self.m_direction = DIRECTION.CLOCK_WISE
    end

    self.m_parentView = params.parentView

    --开始速度
    self.m_startSpeed = params.startSpeed or START_SPEED
    --最小速度(每秒转动的角度)
    self.m_minSpeed = params.minSpeed or MIN_SPEED
    --最大速度(每秒转动的角度)
    self.m_maxSpeed = params.maxSpeed or MAX_SPEED
    --加速阶段的加速度(每秒增加的角速度)
    self.m_accSpeed = params.accSpeed or ACC_SPEED
    --减速结算的加速度(每秒减少的角速度)
    self.m_reduceSpeed = params.reduceSpeed or REDUCE_SPEED
    --开始减速前转动的圈数
    self.m_turnNum = params.turnNum or TURN_NUM
    --需要转动的圈数
    self.m_needTurnNum = self.m_turnNum
    --回弹距离
    self.m_backDistance = params.backDistance or BACK_DISTANCE
    --回弹时间
    self.m_backTme = params.backTime or BACK_TIME
    --以最小速度行进的距离
    self.m_minDistance = params.minDistance or MIN_DISTANCE

    --当前状态
    self.m_actionStatus = ACTION_STATUS.ACTION_READY
    --当前速度
    self.m_curSpeed = self.m_startSpeed
    --当前转动的角度(实时记录)
    self.m_curRotation = 0
    --网络消息返回后累计转动的角度
    self.m_rotationAfterNetBack = 0
    --网络消息返回时已经转动的角度
    self.m_rotationOnNetBack = 0
    --开始转动时的角度
    self.m_startRotation = 0

    --结束时最终停留的角度
    self.m_endRotation = 0

    --减速需要的距离
    self.m_reduceDistance = self:getReduceDistance() + self.m_minDistance

    self.m_needTurnNum = self.m_needTurnNum + math.ceil(self.m_reduceDistance / 360)

    --是否等待网络消息返回
    self.m_isWaittingNetBack = false

    self.m_pointerDo = params.pointerDo
    self.m_usingPointerSp = params.pointerSp
    self.m_pointerMusic = params.pointerMusic
    self.m_pointerSpeed = 180

    self:initHandler()
    self:initUI()
end

function ActivityBaseWheel:initHandler()
    self:registerScriptHandler(
        function(tag)
            if self == nil then
                return
            end
            if "enter" == tag then
                if self.onBaseEnter then
                    self:onBaseEnter()
                end
            elseif "exit" == tag then
                if self.onBaseExit then
                    self:onBaseExit()
                end
            end
        end
    )
end

function ActivityBaseWheel:resetSectorCount(_count)
    self.m_sectorCount = _count
end

function ActivityBaseWheel:onBaseEnter()
    if self.onEnter then
        self:onEnter()
    end
end

function ActivityBaseWheel:onBaseExit()
    if self.onExit then
        self:onExit()
    end
end

function ActivityBaseWheel:onEnter()

end

function ActivityBaseWheel:onExit()
    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()
end


--[[
    初始化  
]]
function ActivityBaseWheel:initUI()
    --计时器节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)
end

--[[
    设置等待网络消息返回
]]
function ActivityBaseWheel:setIsWaitNetBack(isBack)
    self.m_isWaittingNetBack = isBack
end

--[[
    设置当前状态
]]
function ActivityBaseWheel:setActionStatus(status)
    self.m_actionStatus = status
end

--[[
    重置转动数据
]]
function ActivityBaseWheel:resetData()
    --当前速度
    self.m_curSpeed = self.m_startSpeed

    --网络消息返回后累计转动的角度
    self.m_rotationAfterNetBack = 0

    --网络消息返回时已经转动的角度
    self.m_rotationOnNetBack = 0

    --开始转动时的角度
    self.m_startRotation = self.m_curRotation

    --结束时最终停留的角度
    self.m_endRotation = 0
end

--[[
    重置转盘状态(归零)
]]
function ActivityBaseWheel:resetViewStatus()
    --当前转动的角度(实时记录)
    self.m_curRotation = 0
    --网络消息返回后累计转动的角度
    self.m_rotationAfterNetBack = 0
    --网络消息返回时已经转动的角度
    self.m_rotationOnNetBack = 0
    --开始转动时的角度
    self.m_startRotation = 0

    --结束时最终停留的角度
    self.m_endRotation = 0

    --是否等待网络消息返回
    self.m_isWaittingNetBack = false

    self.m_rotateNode:setRotation(0)
end

--[[
    开始滚动
]]
function ActivityBaseWheel:startMove(func)
    if self.m_idleSchedule then
        self.m_idleSchedule:unscheduleUpdate()
    end

    if self.m_actionStatus > ACTION_STATUS.ACTION_READY then
        return
    end
    if self.m_pointerDo then
        self:startRoolWheel()
    end
    --设置消息等待
    self:setIsWaitNetBack(true)

    self:resetData()

    --设置状态机
    self:setActionStatus(ACTION_STATUS.ACTION_START)

    self:startSchedule()
end

--[[
    开启计时器
]]
function ActivityBaseWheel:startSchedule()
    --设置状态机
    self:setActionStatus(ACTION_STATUS.ACTION_RUNNING)
    self.m_scheduleNode:onUpdate(function(dt)
        --刷新速度
        self:updateSpeed(dt)

        --计算偏移量
        local offset = dt * self.m_curSpeed

        --当前的偏转角度
        self.m_curRotation  = self.m_curRotation + offset * self.m_direction
        self.m_rotateNode:setRotation(self.m_curRotation)

        self:setRotionOne(self.m_curRotation, 360/self.m_sectorCount)

        if self.m_setRotFunc then
            self.m_setRotFunc(self.m_curRotation)
        end

        if not self.m_isWaittingNetBack then
            self.m_rotationAfterNetBack  = self.m_rotationAfterNetBack + offset

            --判断是否停轮
            if self.m_direction == DIRECTION.CLOCK_WISE then
                if self.m_rotationAfterNetBack >= (360 - self.m_rotationOnNetBack) + 360 * self.m_needTurnNum + (self.m_endRotation - self.m_startRotation) then
                    self:wheelDown()
                end
            else
                if self.m_rotationAfterNetBack >= (360 - self.m_rotationOnNetBack) + 360 * self.m_needTurnNum + (self.m_startRotation - self.m_endRotation) then
                    self:wheelDown()
                end
            end
        end
    end)
end

--[[
    刷新速度
]]
function ActivityBaseWheel:updateSpeed(dt)
    --加速状态
    if self.m_actionStatus <= ACTION_STATUS.ACTION_ACCELERATE then
        self:setActionStatus(ACTION_STATUS.ACTION_ACCELERATE)
        self.m_curSpeed  = self.m_curSpeed + self.m_accSpeed * dt
        --速度加到最大
        if self.m_curSpeed >= self.m_maxSpeed then
            self.m_curSpeed = self.m_maxSpeed
            self:setActionStatus(ACTION_STATUS.ACTION_UNIFORM)
        end
    elseif self.m_actionStatus == ACTION_STATUS.ACTION_UNIFORM then --匀速状态
        if not self.m_isWaittingNetBack then    --网络消息返回
            if self.m_direction == DIRECTION.CLOCK_WISE then
                if self.m_rotationAfterNetBack >= (360 - self.m_rotationOnNetBack) + 360 * self.m_needTurnNum + (self.m_endRotation - self.m_startRotation) - self.m_reduceDistance then
                    --减速状态
                    self:setActionStatus(ACTION_STATUS.ACTION_SLOW)
                end
            else
                if self.m_rotationAfterNetBack >= (360 - self.m_rotationOnNetBack) + 360 * self.m_needTurnNum + (self.m_startRotation - self.m_endRotation) - self.m_reduceDistance then
                    --减速状态
                    self:setActionStatus(ACTION_STATUS.ACTION_SLOW)
                end
            end
            
        end
    else    --减速状态
        if self.m_curSpeed > self.m_minSpeed then
            self.m_curSpeed  = self.m_curSpeed - self.m_reduceSpeed * dt
            --速度降到最低
            if self.m_curSpeed <= self.m_minSpeed then
                self.m_curSpeed = self.m_minSpeed
            end
        end
    end
end

--[[
    设置停止索引 计算到停止的总距离(网络消息返回时调用)
]]
function ActivityBaseWheel:setEndIndex(endIndex)
    --索引从0开始
    self.m_endIndex = endIndex
    self:setIsWaitNetBack(false)

    self.m_rotationOnNetBack = math.abs(self.m_curRotation - self.m_startRotation) % 360

    --结束时所停的角度
    local endRotation = 360 / self.m_sectorCount * endIndex
    
    if self.m_direction == DIRECTION.CLOCK_WISE then
        self.m_endRotation = 360 - endRotation
    else
        self.m_endRotation = - endRotation
    end
end

--[[
    获取减速所需要的距离
]]
function ActivityBaseWheel:getReduceDistance()
    --匀加速运动求距离公式 s = v0 * t + a * t * t / 2

    --计算减速时间
    local time = (self.m_maxSpeed - self.m_minSpeed) / self.m_reduceSpeed
    --计算减速距离
    local distance = self.m_maxSpeed * time -  self.m_reduceSpeed * math.pow(time,2) / 2

    return distance
end

--[[
    转盘停止
]]
function ActivityBaseWheel:wheelDown()
    --停止计时器
    self.m_scheduleNode:unscheduleUpdate()

    self:setActionStatus(ACTION_STATUS.ACTION_STOPING)

    --刷新结果显示
    self.m_rotateNode:setRotation(self.m_endRotation)
    self.m_curRotation = self.m_endRotation

    --回弹
    if self.m_backDistance > 0 then
        self:setActionStatus(ACTION_STATUS.ACTION_BACK)

        local rotation = self.m_endRotation + self.m_backDistance
        if self.m_direction == DIRECTION.ANTI_CLOCK_WISH then --逆时针
            rotation = self.m_endRotation - self.m_backDistance
        end
        local action1 = cc.EaseBackOut:create(cc.RotateTo:create(self.m_backTme / 2, rotation))
        local action2 = cc.RotateTo:create(self.m_backTme / 2,self.m_endRotation)
        local callBack = cc.CallFunc:create(function()
            self:setActionStatus(ACTION_STATUS.ACTION_READY)
            if type(self.m_doneFunc) == "function" then
                self.m_doneFunc()
                if self.m_pointerDo then
                    self:resetUsingPointerSp()
                end
                
            end
        end)
        local seq = cc.Sequence:create({action1,action2,callBack})
        self.m_rotateNode:runAction(seq)
    else
        self:setActionStatus(ACTION_STATUS.ACTION_READY)
        if type(self.m_doneFunc) == "function" then
            self.m_doneFunc()
            if self.m_pointerDo then
                self:resetUsingPointerSp()
            end
        end
    end
end

function ActivityBaseWheel:quickStop()
    self.m_backDistance = 0
    self:wheelDown()
end

--[[
    @desc: 开始旋转轮盘
    time:2019-04-18 12:00:18
    @return:
]]
function ActivityBaseWheel:startRoolWheel()
    self.m_isRotPointer = true
    local function update(dt)
        self:updateFunc(dt)
    end
    if self.m_usingPointerSp then
        self.m_usingPointerSp:onUpdate(update)
    end
end

function ActivityBaseWheel:updateFunc(dt)
    if self.m_isRotPointer == true then
        local pointerRot = self.m_usingPointerSp:getRotation()
        pointerRot = pointerRot + self.m_pointerSpeed * dt
        if pointerRot >= 0 then
            pointerRot = 0
            self.m_isRotPointer = false
        end
        self.m_usingPointerSp:setRotation(pointerRot)
    end
end

function ActivityBaseWheel:resetUsingPointerSp()
    self.m_usingPointerSp:setRotation(0)
    self.m_usingPointerSp:stopAllActions()
end

--[[
    @desc: 设置滚动信息
    time:2019-04-19 12:24:37
    --@distance:
    --@targetStep:
    --@isBack:
    @return:
]]
function ActivityBaseWheel:setRotionOne(distance, targetStep)
    local ang = distance % targetStep
    if ang >= 9 and ang < 20 then
        local pointerRot = self:changeAng(ang)
        if pointerRot >= -40 then
            if self.m_pointerMusic then
                gLobalSoundManager:playSound(self.m_pointerMusic)
            end

            if self.m_usingPointerSp and pointerRot <= self.m_usingPointerSp:getRotation() then
                self.m_isRotPointer = false
                self.m_usingPointerSp:setRotation(pointerRot)
            end
            print("ActivityBaseWheel:setRotionOne", distance, targetStep, ang, pointerRot)
            if self.m_setAngFunc then
                self.m_setAngFunc()
            end
        end
    else
        self.m_isRotPointer = true
    end
end

function ActivityBaseWheel:changeAng(ang)
    local k = 0
    local b = 0
    if ang >= 18 then
        k = 0
        b = -40
    elseif ang >= 16 then
        k = -2
        b = -4
    elseif ang >= 13 then
        k = -4
        b = 28
    elseif ang >= 12 then
        k = -7
        b = 67
    elseif ang >= 11 then
        k = -5
        b = 43
    elseif ang >= 9 then
        k = -6
        b = 54
    end
    local pointerRot = k * ang + b
    return pointerRot
end

--[[
    待机状态下,转盘慢速转动
]]
function ActivityBaseWheel:idleRolling(_speed)
    --计时器节点
    self.m_idleSchedule = cc.Node:create()
    self:addChild(self.m_idleSchedule)

    self.m_idleSchedule:onUpdate(function(dt)
        --计算偏移量
        local offset = dt * _speed
        --当前的偏转角度
        self.m_curRotation  = self.m_curRotation + offset * self.m_direction
    
        self.m_rotateNode:setRotation(self.m_curRotation)

        self:setRotionOne(self.m_curRotation, 360/self.m_sectorCount)
    end)
end

return ActivityBaseWheel
