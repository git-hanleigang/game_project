--横向滚动的滚轮
local ReelHelper = class("ReelHelper")
require("socket")

ReelHelper.REEL_READY = 0 --待机 准备中
ReelHelper.REEL_BEFORE_RUNNING = 1 --滚动之前操作
ReelHelper.REEL_RUNNING = 2 --开始滚动
ReelHelper.REEL_BEFORE_STOP = 3 --滚动停止之前操作
ReelHelper.REEL_SLOWDOWN = 4 --开始停止滚动
ReelHelper.REEL_SLOWDOWN_OVER = 5 --开始停止滚动结束
ReelHelper.REEL_STOPPING = 6 --停止滚动
ReelHelper.REEL_RUNBACK = 7 --回弹
ReelHelper.REEL_MOVE_TARGET = 8 --移动指定距离
ReelHelper.m_state = ReelHelper.REEL_READY --状态

ReelHelper.m_startTime = nil --当前滚动状态开始时间
ReelHelper.m_frameStep = nil --每一帧需要走的步长
ReelHelper.m_frameTime = nil --每一帧时间
ReelHelper.m_targetStep = nil -- 目标步数

ReelHelper.m_itemWidth = nil --小块宽度
ReelHelper.m_reelWidth = nil --小块背景宽度

ReelHelper.m_reelMaxStep = nil --停止时的最大速度

ReelHelper.m_startDelayTime = nil -- 转轮转动的时间延迟
--转动
ReelHelper.m_runtime = nil -- 转轮转动时间
ReelHelper.m_runV = nil -- 转轮的速度
--停止
ReelHelper.m_stopDelayTime = nil -- 转轮停止时间
ReelHelper.m_stopV = nil --轮盘停止速度 如果存在减速
ReelHelper.m_stopA = nil

ReelHelper.m_itemList = nil --滚动类
ReelHelper.m_itemCount = nil
ReelHelper.m_moveDistance = nil  -- 滚动距离
ReelHelper.m_currentV = nil --减速时使用
ReelHelper.m_currentA = nil --
ReelHelper.m_targetV = nil --目标速度
ReelHelper.m_reelResultIndex = nil --最终轮盘结果
ReelHelper.m_reelRunData = nil --滚轮数据

ReelHelper.m_totalMove = nil --目标距离
ReelHelper.m_currentReelIndex = nil --最新小块的下标
ReelHelper.m_isInit = nil
function ReelHelper:ctor()

end
--初始化滚轮
function ReelHelper:initReel(itemList)
--   left <- right
    self.m_itemList = itemList
end

--滚动参数
--数据格式 {reelWidth = 400,itemWidth = 100,elementNumber = 5, runData = {} ,runtime = 3,runV =3,stopV=0.5,stopA = 50}
function ReelHelper:parseReelData(reelConfig)
    self.m_isInit = true
    self.m_itemCount = reelConfig.elementNumber
    self.m_currentReelIndex = reelConfig.elementNumber
    self.m_reelRunData = reelConfig.runData
    self.m_itemWidth = reelConfig.itemWidth --小块高度
    self.m_reelWidth = reelConfig.reelWidth --父级高度
    self.m_reelMaxStep = self.m_itemWidth * 0.5-5
    self.m_targetStep = self.m_itemWidth * 2

    self.m_startDelayTime = 0 --滚动前等待时间
    --转动
    self.m_runtime = reelConfig.runtime-- 转轮转动时间
    self.m_runV = reelConfig.runV -- 转轮的速度
    --停止
    self.m_stopDelayTime = 0 -- 转轮停止时间
    self.m_stopV = reelConfig.stopV
    self.m_stopA = reelConfig.stopA

    self.m_lastV = reelConfig.lastV
    self.m_lastPara = reelConfig.lastPara

end
-----------------------
function ReelHelper:startRoll(resultIndex,reelConfig,callback)
    self.m_callBack = callback
    self.m_reelResultIndex = resultIndex
    self:parseReelData(reelConfig)
    self:beginReel()
end
function ReelHelper:startIdle(reelConfig)
     --滚动参数
    self:parseReelData(reelConfig)
    self:beginReel()
end
--改变小格子坐标 1 2 3 4 5
function ReelHelper:changeReelPosition(offset)
    if offset > self.m_reelMaxStep then
        offset = self.m_reelMaxStep
    end
    for i=1,#self.m_itemList do
        local x = self.m_itemList[i]:getPositionX()
        self.m_itemList[i]:setPositionX(x-offset)
    end
    self:checkItemExchange()
end

function ReelHelper:checkItemExchange()
    if self.m_itemList[1]:getPositionX() <= -self.m_itemWidth/2 then
        local temp = self.m_itemList[1]
        self.m_currentReelIndex = self.m_currentReelIndex + 1
        if self.m_currentReelIndex >  #self.m_reelRunData then
            self.m_currentReelIndex = self.m_currentReelIndex - #self.m_reelRunData
        end
            -- -112345
        if self.m_state >= self.REEL_STOPPING and self.m_currentReelIndex == self.m_reelResultIndex - 2 then
            -- self:checkSameSymbol()
            temp:setViewData({num=self.m_reelRunData[self.m_currentReelIndex],index = self.m_currentReelIndex})
        else
            -- self:checkSameSymbol()
            temp:setViewData({num=self.m_reelRunData[self.m_currentReelIndex],index = self.m_currentReelIndex})
        end
        temp:setPositionX(self.m_itemList[#self.m_itemList]:getPositionX()+self.m_itemWidth)
        local tempList = {}
        for i=2,#self.m_itemList do
            tempList[i-1] = self.m_itemList[i]
        end
        tempList[#tempList+1] = temp
        self.m_itemList = tempList
        gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_beginRollBigWheel.mp3")
    end
end

--保存时间
function ReelHelper:saveTime()
    self.m_startTime = socket.gettime()
end

--读取时间间隔
function ReelHelper:getSpanTime()
    local spanTime = (socket.gettime() - self.m_startTime)
    return spanTime
end --更新滚动
----------------------------------------------------------

--[[
    @desc: 滚动相关逻辑   方式是按运行顺序写的
    author:{jinxin}
    time:2018-09-27 15:55:47
    --@dt:
    @return:
]]
function ReelHelper:updateReel(dt)
    self.m_frameTime = dt
    self.m_frameStep = dt * self.m_targetStep --每一帧需要走的步长
    if self.m_state == self.REEL_READY then
    elseif self.m_state == self.REEL_BEFORE_RUNNING then
        self:beforeRunning()
    elseif self.m_state == self.REEL_RUNNING  then
        self:reelRunning()
    elseif self.m_state == self.REEL_BEFORE_STOP then
        self:beforeStop()
    elseif self.m_state == self.REEL_SLOWDOWN_FASTRUN then

    elseif self.m_state == self.REEL_SLOWDOWN then
        self:slowDown()
    elseif self.m_state == self.REEL_SLOWDOWN_OVER then
        self:slowDownOver()
    elseif self.m_state == self.REEL_STOPPING then
        self:stoping()
    elseif self.m_state == self.REEL_RUNBACK then

    end
end

--触发滚动
function ReelHelper:beginReel()

    if self.m_startDelayTime > 0 then
        self:prepareBeforeRunning()
    else
        self:prepareReelRunning()
    end
end
--准备延时滚动
function ReelHelper:prepareBeforeRunning()
    self:saveTime()
    self.m_state = self.REEL_BEFORE_RUNNING
end

--准备滚动
function ReelHelper:beforeRunning()
    local spantime = self:getSpanTime()
    if spantime >= self.m_startDelayTime then
        self:prepareReelRunning()
    end
end

--准备滚动
function ReelHelper:prepareReelRunning()
    self:saveTime()
    self.m_state = self.REEL_RUNNING
    -- self:changeFastSymbol()
end

--开始滚动
function ReelHelper:reelRunning()
    local needJumpToNextState = false
    local spantime = self:getSpanTime()
    if spantime > self.m_runtime then
        needJumpToNextState = true
    end
    local offset = self.m_frameStep * self.m_runV
    self:changeReelPosition(offset)
    if needJumpToNextState then
        self:prepareBeforeStop()
    end
end

--开始停止滚动之前的操作
function ReelHelper:prepareBeforeStop()
    self:saveTime()
    self.m_state = self.REEL_BEFORE_STOP
end
--开始停止滚动
function ReelHelper:beforeStop()
    local spantime = self:getSpanTime()
    if spantime >= self.m_stopDelayTime then
        self:prepareSlowDown()
    else
        local offset = self.m_frameStep * self.m_runV
        self:changeReelPosition(offset)
    end
end

-----------------
--[[
    @desc: 减速 目前没有减速阶段
    author:{jinxin}
    time:2018-09-27 15:56:58
    @return:
]]
function ReelHelper:prepareSlowDown()
    self.m_state = self.REEL_SLOWDOWN
    self.m_currentV = self.m_runV

    self.m_currentA = self.m_stopA

    self.m_targetV = self.m_stopV

    self:saveTime()
end
--减速
function ReelHelper:slowDown()
    local offset = self.m_frameStep * self.m_currentV
    self:changeReelPosition(offset)

    self.m_currentV = self.m_currentV - self.m_frameTime * self.m_currentA
    if self.m_currentV < self.m_targetV then
        self.m_currentV = self.m_targetV
        self:prepareSlowDownOver()
    end
end

--准备结束减速阶段
function ReelHelper:prepareSlowDownOver()
    self.m_state = self.REEL_SLOWDOWN_OVER
    self:saveTime()
end

--结束减速阶段 开启真实停止状态
function ReelHelper:slowDownOver()
    self:prePareStoping()
    -- if self.m_isRunStopping  then --and LocomotiveElement != null
    --     self:prePareStoping()
    -- else
    --     self:changeReelPosition(self.m_frameStep * self.m_currentV)
    -- end
end
-- 6 7 8 9
--准备进入停止阶段 替换真轮
function ReelHelper:prePareStoping()
    self.m_currentReelIndex = self.m_reelResultIndex - 3
    if self.m_currentReelIndex < 0 then
        self.m_currentReelIndex = #self.m_reelRunData - math.abs(self.m_currentReelIndex)
    end
    -- 1 2 3 4 5 6 Q Q r X X
    local def = self.m_itemList[#self.m_itemList]:getPositionX() - self.m_reelWidth/2
    self.m_moveDistance = math.ceil(self.m_itemCount/2) * self.m_itemWidth + def
    -- self:changeReelIndex(self.m_reelResultIndex-offIndex)
    -- self.m_moveDistance = self:stopMoveDistance(offIndex)
    self.m_totalMove = 0
    self.m_state = self.REEL_STOPPING

    self.m_currentV = self.m_stopV
end

--进入停止阶段
function ReelHelper:stoping()
    local offset = self.m_frameStep * self.m_currentV
    --真数据停止期间帧速度不能跨格
    if offset > self.m_reelMaxStep then
        offset = self.m_reelMaxStep
    end

    if self.m_currentV < self.m_lastV then
        self.m_currentV = self.m_lastV
    elseif self.m_currentV > self.m_lastV then
        self.m_currentV = self.m_currentV - self.m_currentV*self.m_lastPara*self.m_frameTime
    end

    if self.m_totalMove < self.m_moveDistance then
        if self.m_totalMove + offset > self.m_moveDistance then
            offset = self.m_moveDistance - self.m_totalMove
        end
        self:changeReelPosition(offset)
        self.m_totalMove = self.m_totalMove + offset
    else
        self:reelDown()
    end
end

--滚轮停下
function ReelHelper:reelDown()
    local isRunBack = true
    if isRunBack then
        self:perpareRunBack()
    else
        --不回弹直接结束
        self:reelRunOver()
    end
end

--准备回弹
function ReelHelper:perpareRunBack()
    self.m_state = self.REEL_RUNBACK
    local time1,time2 = 0.4,0.1
    local distance = 24
    for i=1,#self.m_itemList do
        local itemNode = self.m_itemList[i]
        local x, y = itemNode:getPosition()
        local moveAction = cc.MoveTo:create(time1, cc.p(x-distance,y))
        local callfunc = cc.CallFunc:create(function()
            local moveAction1 = cc.MoveTo:create(time2, cc.p(x,y))
            local callfunc1 = cc.CallFunc:create(function()
                if i == math.ceil(#self.m_itemList/2) then
                    self:reelRunOver()
                end
            end)
            local seq1 =  cc.Sequence:create(moveAction1, callfunc1)
            itemNode:runAction(seq1)
        end)
        local seq =  cc.Sequence:create(moveAction, callfunc)
        itemNode:runAction(seq)
    end

end

--结束本次滚动
function ReelHelper:reelRunOver()
    self.m_state = self.REEL_READY
    if self.m_callBack then
        self.m_callBack()
    end
end

function ReelHelper:checkSameSymbol()
    local lastNum = self.m_itemList[#self.m_itemList].m_data.num
    local nextNum = self.m_reelRunData[self.m_currentReelIndex+1]
    local nowNum = self.m_reelRunData[self.m_currentReelIndex]
    if lastNum == nowNum or nextNum == nowNum then
        local temp = self:dealType(self.m_reelRunData)
        for i,v in pairs(temp) do
            if i ~= lastNum and i ~= nextNum then
                self.m_reelRunData[self.m_currentReelIndex] = i
                break
            end
        end
    end
end

function ReelHelper:dealType(retab)
    local list = {}
    copyTable(retab,list)
    table.sort(list, function(a,b)
        return tonumber(a) < tonumber(b)
    end)
    local temp = {}
    local index = 1
    for i=1,#list do
        if temp[list[i]] == nil then
            temp[list[i]] = index
            index = index+1
        end
    end
    return temp
end

return ReelHelper