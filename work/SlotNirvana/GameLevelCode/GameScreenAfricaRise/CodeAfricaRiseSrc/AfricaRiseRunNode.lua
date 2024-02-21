---
--island
--2018年4月12日
--AfricaRiseRunNode.lua
--
-- jackpot top bar
local SpeicalReel = require "Levels.SpeicalReel"
local AfricaRiseRunNode = class("AfricaRiseRunNode", SpeicalReel)

AfricaRiseRunNode.m_runState = nil
AfricaRiseRunNode.m_runSpeed = nil
AfricaRiseRunNode.m_endRunData = nil
AfricaRiseRunNode.m_allRunSymbols = nil

AfricaRiseRunNode.m_runActions = nil
AfricaRiseRunNode.m_runNowAction = nil

local RUN_WIDTH = 600
local CLIP_HIGHT = 310
local SYMBOL_WILD_X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 107

local INCREMENT_SPEED = 100 --速度增量 (像素/帧)
local DECELER_SPEED = -40 --速度减量 (像素/帧)

local BEGIN_SPEED = 500 --初速度
local BEGIN_SPEED_TIME = 0 --x秒后开始加速 (秒)
local ACC_SPEED_TIMES = 1 --加速时间 单位s(秒)
local DECELER_SPEED_TIMES = 1 --减速时间 单位s(秒)
local HIGH_SPEED_TIME = 1.5 --匀速时间
local MAX_SPEED = 6000
local MIN_SPEED = 300

local ANCHOR_POINT_Y = 0.5
local UNIFORM_STATE = 0 --匀速
local ACC_STATE = 1 --加速
local DECELER_STATE = 2 --减速
local HIGH_STATE = 3 --高速

local DECELER_SYMBOL_NUM = 7
--m_clipNode特殊tag
local RUN_TAG = {
    SYMBOL_TAG = 1, --滚动信号tag
    SPEICAL_TAG = 10000 --特殊元素如遮罩层等等 不参与滚动
}

AfricaRiseRunNode.m_endCallBackFun = nil

AfricaRiseRunNode.m_reelHeight = nil

--状态切换
AfricaRiseRunNode.m_timeCount = 0
AfricaRiseRunNode.m_countDownTime = BEGIN_ACC_DELAY_TIME

AfricaRiseRunNode.m_randomDataFunc = nil

AfricaRiseRunNode.distance = 0

function AfricaRiseRunNode:initUI()
    SpeicalReel.initUI(self)
    self.m_runState = UNIFORM_STATE
    self.m_runSpeed = BEGIN_SPEED
    self:setRunningParam(BEGIN_SPEED)
    self:initAction()
    self.m_gundongSoundsId = nil
end

function AfricaRiseRunNode:setParentMachine(parent)
    self.m_parent = parent
end

function AfricaRiseRunNode:initBeginAction()
    self.m_runState = UNIFORM_STATE
    self.m_runSpeed = BEGIN_SPEED
    self:setRunningParam(BEGIN_SPEED)
    self.m_moveNum = 1
end

function AfricaRiseRunNode:initAction()
    self.m_runActions = self:getMoveActions()
    self.m_runNowAction = self:getNextMoveActions()
    self.m_dataListPoint = 1
end

function AfricaRiseRunNode:initFirstSymbolBySymbols(initDataList, reelHeight)
    self.m_reelHeight = reelHeight
    local anc = cc.p(self:getAnchorPoint())
    for i = 1, #initDataList do
        local data = initDataList[i]
        local node = self.getSlotNodeBySymbolType(data.SymbolType)
        node:changeImage()
        -- node:runAnim("idleframe")
        node.Width = data.Width
        self.m_clipNode:addChild(node, data.Zorder, data.SymbolType)
        local posY = CLIP_HIGHT
        local posX = 0
        if i < 4 then
            posX = -(4 - i) * node.Width * 0.5+(4-i)*20
        elseif i == 4 then
            posX = 0
        else
            posX = (i - 4) * node.Width * 0.5- (i-4)*20
        end
        -- print("i  ===== " .. i .. "posX  === " .. posX)
        node:setPosition(cc.p(posX, posY))
        self.m_symbolNodeList[#self.m_symbolNodeList + 1] = node
    end
end

function AfricaRiseRunNode:getDisToReelLowBoundary(node)
    local nodePosX = node:getPositionX()
    local dis = nodePosX
    return dis
end

function AfricaRiseRunNode:getNextRunData()
    local nextData = self.m_allRunSymbols[1]
    table.remove(self.m_allRunSymbols, 1)
    return nextData
end

function AfricaRiseRunNode:createNextNode()
    local topX = self:getFirstSymbolTopX()
    if topX < -RUN_WIDTH then
        --最后一个Node > 上边界 创建新的node  反之创建
        return
    end
  
    -- print("AfricaRiseRunNode ==== createNextNode =====" .. self.m_Num)
    self.m_moveNum =  self.m_moveNum + 1
    local nextNodeData = self:getNextRunData()
    if nextNodeData == nil then
        nextNodeData = self.m_randomDataFunc()
    end

    local node = self.getSlotNodeBySymbolType(nextNodeData.SymbolType)
    -- node:runAnim("idleframe")
    node:changeImage()
    node.Width = nextNodeData.Width
    node.isEndNode = nextNodeData.Last

    self.m_clipNode:addChild(node, nextNodeData.Zorder, nextNodeData.SymbolType)
    self:setRunCreateNodePos(node)
    self:pushToSymbolList(node)

    if nextNodeData.Last and self.m_endDis == nil then
        --创建出EndNode 计算出还需多长距离停止移动
        self.m_endDis = self:getDisToReelLowBoundary(node)
    end
    --是否超过上边界 没有的话需要继续创建
    if self:getNodeTopX(node) > -RUN_WIDTH then
      self:createNextNode()
    end
end

function AfricaRiseRunNode:getNextMoveActions()
    if self.m_runActions ~= nil and #self.m_runActions > 0 then
        local action = self.m_runActions[1]
        table.remove(self.m_runActions, 1)
        return action
    end
    assert(false, "没有速度 序列了")
end

--设置滚动序列
function AfricaRiseRunNode:getMoveActions()
    local runActions = {}
    local actionUniform1 = {time = BEGIN_SPEED_TIME, status = UNIFORM_STATE,moveNum = 0}
    local actionAcc = {time = ACC_SPEED_TIMES, addSpeed = INCREMENT_SPEED, maxSpeed = MAX_SPEED, status = ACC_STATE,moveNum = 8}
    local actionUniform2 = {time = HIGH_SPEED_TIME, status = HIGH_STATE,moveNum = 100}
    local actionDeceler = {time = DECELER_SPEED_TIMES, decelerSpeed = DECELER_SPEED, minSpeed = MIN_SPEED, status = DECELER_STATE,moveNum = 8}
    -- local actionUniform3 = {status = UNIFORM_STATE}
    runActions[#runActions + 1] = actionUniform1
    runActions[#runActions + 1] = actionAcc
    runActions[#runActions + 1] = actionUniform2
    runActions[#runActions + 1] = actionDeceler
    -- runActions[#runActions + 1] = actionUniform3
    return runActions
end

--重写每帧走的距离
function AfricaRiseRunNode:setDtMoveDis(dt)
    self:changeRunState(dt)

    self.m_dtMoveDis = dt * self.m_runSpeed

    self.distance = self.distance + self.m_dtMoveDis
end

function AfricaRiseRunNode:getIsNumDown(_num)
    if _num == nil then
        return false
    end

    if self.m_moveNum >= _num then
        return true
    end
    return false
end

function AfricaRiseRunNode:getIsTimeDown(actionTime)
    if actionTime == nil then
        return false
    end

    if self.m_timeCount >= actionTime then
        return true
    end
    return false
end

function AfricaRiseRunNode:initRunDate(runData, getRunDatafunc)
    self.m_randomDataFunc = getRunDatafunc
    self.m_runDataList = getRunDatafunc
    self.m_endRunData = runData
    self.m_dataListPoint = 1
end

function AfricaRiseRunNode:setAllRunSymbols(allSymbols)
    self.m_allRunSymbols = allSymbols
end

function AfricaRiseRunNode:setEndDate(endData)
    self.m_endRunData = endData
end

function AfricaRiseRunNode:beginMove()
    self.m_gundongSoundsId = gLobalSoundManager:playSound(
        "AfricaRiseSounds/sound_AfricaRise_freespin_gundong.mp3",
        false)
    if self:getReelStatus() ~= REEL_STATUS.IDLE then
        return
    end
    self:changeReelStatus(REEL_STATUS.RUNNING)
    local bEndMove = false
    self.m_endNode = nil
    self.m_endDis = nil

    self:onUpdate(
        function(dt)
            if globalData.slotRunData.gameRunPause then
                return
            end
            if bEndMove then
                self:createNextNode()
                self:unscheduleUpdate()
                self:runResAction()
                return
            end

            self:createNextNode()
            self:setDtMoveDis(dt)
            if self.m_endDis ~= nil then
                --判断是否结束
                local endDis = self.m_endDis + self.m_dtMoveDis
                if endDis >= 0 then
                    self.m_dtMoveDis = -self.m_endDis
                    bEndMove = true
                else
                    self.m_endDis = endDis
                end
            end

            self:removeBelowReelSymbol()
            self:updateSymbolPosX()
        end
    )
end

function AfricaRiseRunNode:changeToWild()
    local childs = self.m_clipNode:getChildren()
    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            local nowPosX = node:getPositionX()
            if nowPosX < 10 and nowPosX > -10 then
                node:changeCCBByName("Socre_AfricaRise_wild", SYMBOL_WILD_X)
            end
        end
    end
end

function AfricaRiseRunNode:changeSymbolBg()
    local childs = self.m_clipNode:getChildren()
    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            -- node:runAnim("idleframe")
            node:changeImage()
        end
    end
end

--[[
    @desc:更新所有Symbol坐标
    author:{author}
    time:2018-11-28 15:49:58
    @return:
]]
function AfricaRiseRunNode:updateSymbolPosX()
    local childs = self.m_clipNode:getChildren()
    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            local nowPosX = node:getPositionX()
            local posX = nowPosX + self.m_dtMoveDis
            local scale = self:getSymbolScale(posX)
            node:setPositionX(posX)
            node:setScale(scale)
            if posX < 10 and posX > -10 then
                node:setLocalZOrder(100)
            else
                node:setLocalZOrder(1)
            end
        end
    end
end

function AfricaRiseRunNode:getSymbolScale(posX)
    local scale = 1
    local farPosX = math.abs(posX)
    local scale = 1.8 - (farPosX / RUN_WIDTH)
    return scale
end

function AfricaRiseRunNode:playScaleToBig()
    local childs = self.m_clipNode:getChildren()
    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            local nowPosX = node:getPositionX()
            local scale = self:getSymbolScale(nowPosX)
            local endPos = cc.p(node:getPosition())
            if nowPosX < 10 and nowPosX > -10 then
                node:setLocalZOrder(100)
            elseif nowPosX  <=-10 then
               local index = math.abs(nowPosX)/ (node.Width*0.5)
                -- node:setPositionX(nowPosX-index*20)
                endPos.x = nowPosX-index*20
                node:setLocalZOrder(1)
            elseif nowPosX  >= 10 then
                local index = math.abs(nowPosX)/ (node.Width*0.5)
                -- node:setPositionX(nowPosX+index*20)
                endPos.x = nowPosX+index*20
                node:setLocalZOrder(1)
            end
            local scaleAct = cc.ScaleTo:create(0.6, scale)
            local moveTo = cc.MoveTo:create(0.5, endPos)
            local spw = cc.Spawn:create(scaleAct, moveTo)
            node:runAction(spw)
        end
    end
end

function AfricaRiseRunNode:playScaleToSmall()
    self:removeRunEndBg()
    local childs = self.m_clipNode:getChildren()
    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            local nowPosX = node:getPositionX()
            local endPos = cc.p(node:getPosition())
          
            -- node:runAction(scaleAct)
            if nowPosX < 10 and nowPosX > -10 then
                node:setLocalZOrder(100)
            elseif nowPosX  <=-10 then
                local index = math.abs(nowPosX)/ (node.Width*0.5)
                -- node:setPositionX(nowPosX+index*20)
                endPos.x = nowPosX + index*20
                node:setLocalZOrder(1)
            elseif nowPosX  >= 10 then
                local index = math.abs(nowPosX)/ (node.Width*0.5)
                -- node:setPositionX(nowPosX-index*20)
                endPos.x = nowPosX-index*20
                node:setLocalZOrder(1)
            end
            local moveTo = cc.MoveTo:create(0.4, endPos)
            local scaleAct = cc.ScaleTo:create(0.4, 1)
            local spw = cc.Spawn:create(scaleAct, moveTo)
            node:runAction(spw)
        end
    end
   
end

--- 返回最后一个信号
function AfricaRiseRunNode:getFirstSymbolNode()
    if #self.m_symbolNodeList == 0 then
        return nil
    end
    return self.m_symbolNodeList[1]
end

function AfricaRiseRunNode:getFirstSymbolTopX()
    local lastNode = self:getFirstSymbolNode()
    local topX = 0

    if lastNode == nil then
        return topX, lastNode
    end

    local lastNodePosX = lastNode:getPositionX()
    local topX = -lastNode.Width * (1 - ANCHOR_POINT_Y) + lastNodePosX
    return topX
end

function AfricaRiseRunNode:pushToSymbolList(node)
    table.insert(self.m_symbolNodeList, 1, node)
end

function AfricaRiseRunNode:removeBelowReelSymbol()
    local childs = self.m_clipNode:getChildren()
    for i = 1, #childs do
        local node = childs[i]

        if node:getTag() < RUN_TAG.SPEICAL_TAG then
            local nowPosX = node:getPositionX()
            --计算出移除的临界点
            local removePosX = RUN_WIDTH
            if nowPosX >= removePosX then
                node:removeFromParent()
                self.pushSlotNodeToPoolBySymobolType(node)
                self:popUpSymbolList()
            end
        end
    end
end

function AfricaRiseRunNode:popUpSymbolList()
    table.remove(self.m_symbolNodeList, #self.m_symbolNodeList)
end

function AfricaRiseRunNode:changeRunState(dt)
    self.m_timeCount = self.m_timeCount + dt

    local runState = self.m_runNowAction.status
    local actionTime = self.m_runNowAction.time
    local moveNum = self.m_runNowAction.moveNum
    if runState == UNIFORM_STATE then
        if  self:getIsNumDown(moveNum) then
            self.m_runNowAction = self:getNextMoveActions()
            self.m_moveNum = 1
        end
        -- if self:getIsTimeDown(actionTime) then
        --     print("加速 ==============================UNIFORM_STATE")
        --     self.m_runNowAction = self:getNextMoveActions()
        --     self.m_timeCount = 0
        -- end
    elseif runState == HIGH_STATE then
        if  self:getIsNumDown(moveNum) then
            self.m_runNowAction = self:getNextMoveActions()
            self.m_moveNum = 1
        end
        -- if self:getIsTimeDown(actionTime)  then
        --     print("减速 ==============================HIGH_STATE")
        --     self.m_runNowAction = self:getNextMoveActions()
        --     self.m_timeCount = 0
        -- end
    elseif runState == ACC_STATE then
        local addSpeed = self.m_runNowAction.addSpeed
        local maxSpeed = self.m_runNowAction.maxSpeed
        if  self:getIsNumDown(moveNum) then
            self.m_runNowAction = self:getNextMoveActions()
            self.m_moveNum = 1
        else
            if self.m_runSpeed < maxSpeed then
                self.m_runSpeed = self.m_runSpeed + addSpeed
            else
                self.m_runSpeed = maxSpeed
            end
        end
    elseif runState == DECELER_STATE then
        local decelerSpeed = self.m_runNowAction.decelerSpeed
        local minSpeed = self.m_runNowAction.minSpeed
        if self.m_runSpeed > minSpeed then
            self.m_runSpeed = self.m_runSpeed + decelerSpeed
        else
            self.m_runSpeed = minSpeed
        end
    end
end

function AfricaRiseRunNode:getResAction()
    local timeDown = 0
    local speedActionTable = {}
    local dis = 50
    local speedStart = self.m_runSpeed
    local preSpeed = speedStart / 300
    for i = 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time, cc.p(-moveDis, 0))
        speedActionTable[#speedActionTable + 1] = moveBy
    end

    local moveBy = cc.MoveBy:create(0.2, cc.p(-dis, 0))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1

    return speedActionTable, timeDown
end

function AfricaRiseRunNode:runResAction()
    local downDelayTime = 1
    -- local allNode, lastNode = self:getSlotNode()
    -- for index = 1, #self.m_symbolNodeList do
    --     local node = self.m_symbolNodeList[index]
    --     local actionTable ,downTime = self:getResAction()
    --     node:runAction(cc.Sequence:create(actionTable))
    --     if downDelayTime <  downTime then
    --         downDelayTime = downTime
    --     end
    -- end 
    if self.m_gundongSoundsId then
        gLobalSoundManager:stopAudio(self.m_gundongSoundsId)
        self.m_gundongSoundsId = nil
    end
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_freespin_gundong_stop.mp3",false)
    if self.m_parent then
        self:createRunEndBg() --加个底
        self.m_parent:playEffOver() --加个特效盖住底 穿帮
    end
    -- performWithDelay(
    --     self,
    --     function()
    --         gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_freespin_gundong_gu.mp3",false)
    --     end,
    --     0.5
    -- )
    performWithDelay(
        self,
        function()
            --滚动完毕
            self:runReelDown()
            self.m_endCallBackFun()
        end,
        downDelayTime
    )
end

function AfricaRiseRunNode:setMachine(machine)
    self.m_machine = machine
end

function AfricaRiseRunNode:createRunEndBg()
    self.m_effectBg = util_createView("CodeAfricaRiseSrc.AfricaRiseReelFrameBg")

    self.m_clipNode:addChild(self.m_effectBg,99,RUN_TAG.SPEICAL_TAG)
    self.m_effectBg:changeFrameBg()
    self.m_effectBg:setPosition(cc.p(0, CLIP_HIGHT))
    self.m_effectBg:runCsbAction("zhongjiang", false)
end

function AfricaRiseRunNode:removeRunEndBg()
    if self.m_effectBg then
        self.m_effectBg:runCsbAction("over", false,function (  )
            self.m_effectBg:removeFromParent()
            self.m_effectBg = nil
        end)
    end
end

function AfricaRiseRunNode:playRunEndAnima()
end

function AfricaRiseRunNode:playRunEndAnimaIde()
    for i = 1, #self.m_symbolNodeList do
        local node = self.m_symbolNodeList[i]
        -- node:runAnim("idleframe")
        node:changeImage()
    end
end

function AfricaRiseRunNode:setEndCallBackFun(func)
    self.m_endCallBackFun = func
end



function AfricaRiseRunNode:setRunCreateNodePos(newNode)
    local topX = self:getFirstSymbolTopX()
    local newPosX = topX
    -- print("创建 位置 ==== " .. newPosX)
    newNode:setPosition(cc.p(newPosX, CLIP_HIGHT))
end

function AfricaRiseRunNode:getNodeTopX(node)
    local nodePosX = node:getPositionX()
    local topX = -node.Width * ANCHOR_POINT_Y + nodePosX
    return topX
end

return AfricaRiseRunNode
