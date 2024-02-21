--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 20:00:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 20:00:52
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/chess/ExpandPlinkoLaunchUI.lua
Description: 扩圈小游戏 弹珠 发射器UI
--]]
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")
local ExpandPlinkoLaunchUI = class("ExpandPlinkoLaunchUI", BaseView)

-- 一秒移动距离
local ONE_SEC_MOVE_POSX = 100

function ExpandPlinkoLaunchUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_out.csb"
end

-- 初始化节点
function ExpandPlinkoLaunchUI:initCsbNodes()
    self.m_nodeBall = self:findChild("node_coinball")
end


function ExpandPlinkoLaunchUI:initDatas(_posXList, _mainView)
    ExpandPlinkoLaunchUI.super.initDatas(self)

    self.m_mainView = _mainView
    self.m_posXList = _posXList
    self.m_curPosArrInfo = {posX = _posXList[1], arr = "RIGHT"}
    self.m_state = ExpandGamePlinkoConfig.LAUNCH_STATE.STOP
    local posArrStr = gLobalDataManager:getStringByField("PlinkoPrePosArrInfo", "")
    if posArrStr ~= "" then
        self.m_curPosArrInfo = cjson.decode(posArrStr)
    end
    self:setPositionX(self.m_curPosArrInfo.posX)
end

function ExpandPlinkoLaunchUI:initUI()
    ExpandPlinkoLaunchUI.super.initUI(self)
    
    -- 创建ball
    self:initBallUI()
end

-- 创建ball
function ExpandPlinkoLaunchUI:initBallUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.chess.ExpandPlinkoBallUI")
    self.m_nodeBall:addChild(view)
    view:setVisible(false)
    self.m_ballView = view

    self.m_nodeBallParticle = cc.ParticleSystemQuad:create("PlinkoGame/effect/NewUser_Plinkotuowei.plist")
    self.m_nodeBall:addChild(self.m_nodeBallParticle, -1)
    self.m_nodeBallParticle:setVisible(false)
end

function ExpandPlinkoLaunchUI:onEnter()
    ExpandPlinkoLaunchUI.super.onEnter(self)

    self:runCsbAction("idle")
    self:onUpdate(util_node_handler(self, self.onTick))
end

function ExpandPlinkoLaunchUI:onExit()
    ExpandPlinkoLaunchUI.super.onExit(self)

    local posArrStr = cjson.encode(self.m_curPosArrInfo)
    gLobalDataManager:setStringByField("PlinkoPrePosArrInfo", posArrStr)
end

function ExpandPlinkoLaunchUI:onTick(_dt)
    if self.m_state ~= ExpandGamePlinkoConfig.LAUNCH_STATE.MOVE then
        self:checkUpdateParticlePos() 
        return
    end

    local curPosX = self:getPositionX()
    local disX = _dt * ONE_SEC_MOVE_POSX * (self.m_curPosArrInfo.arr == "RIGHT" and 1 or -1)
    curPosX = curPosX + disX
    if curPosX >= self.m_posXList[#self.m_posXList] then
        curPosX = self.m_posXList[#self.m_posXList]
        self.m_curPosArrInfo.arr = "LEFT"
    end
    if curPosX <= self.m_posXList[1] then
        curPosX = self.m_posXList[1]
        self.m_curPosArrInfo.arr = "RIGHT"
    end
    self.m_curPosArrInfo.posX = curPosX
    self:setPositionX(curPosX)
end

-- 发射器 状态
function ExpandPlinkoLaunchUI:updateState(_state)
    self.m_state = _state
    if _state == ExpandGamePlinkoConfig.LAUNCH_STATE.LAUNCH then
        -- 发射 球
        self:moveLaunchAndDropBall()
    elseif _state == ExpandGamePlinkoConfig.LAUNCH_STATE.STOP then
        self:runCsbAction("idle")
        -- gLobalSoundManager:stopAudio(self.m_moveSoundsId)
    elseif _state == ExpandGamePlinkoConfig.LAUNCH_STATE.MOVE then
        -- self.m_moveSoundsId = gLobalSoundManager:playSound(ExpandGamePlinkoConfig.SOUNDS.LAUNCH_MOVE, true)
    end
end

-- 移动发射器到 合适位置 然后发射 掉球
function ExpandPlinkoLaunchUI:moveLaunchAndDropBall()
    local cb = function()
        self:runCsbAction("start", false, util_node_handler(self, self.dropBall), 60)
    end

    self:moveLaunchToFallIdx(cb)
end
-- 移动发射器到 发射位置
function ExpandPlinkoLaunchUI:moveLaunchToFallIdx(_cb)
    local curPosX = self:getPositionX()
    local nextPosX = self:getNextPosX()
    
    local moveTime = math.abs(nextPosX - curPosX) / ONE_SEC_MOVE_POSX
    local moveTo = cc.MoveTo:create(moveTime, cc.p(nextPosX, self:getPositionY()))
    local callFunc = cc.CallFunc:create(_cb)
    self:runAction(cc.Sequence:create(moveTo, callFunc))
end
function ExpandPlinkoLaunchUI:getNextPosX()
    local curPosX = self:getPositionX()
    local nextPosX = curPosX
    local nextIdx = 1
    for i=1, #self.m_posXList do
        local posX = self.m_posXList[i]
            
        if posX > curPosX then
            if self.m_curPosArrInfo.arr == "RIGHT" then
                -- 右走取大的
                nextPosX = posX
                nextIdx = i
            end
            
            break
        end

        if self.m_curPosArrInfo.arr == "LEFT" then
            -- 左走取小的
            nextPosX = posX
            nextIdx = i
        end

    end

    return nextPosX, nextIdx
end

-- 掉球
function ExpandPlinkoLaunchUI:dropBall()
    self:updateState(ExpandGamePlinkoConfig.LAUNCH_STATE.STOP)
    self.m_mainView:setArrowAniVisible(false)

    gLobalSoundManager:playSound(ExpandGamePlinkoConfig.SOUNDS.DROP_BALL)

    local actionList = {}
    self.m_ballView:setVisible(true)
    self.m_ballView:move(0, 0)
    self.m_nodeBallParticle:setVisible(true)
    self.m_nodeBallParticle:move(0, 0)
    for i=1, #self.m_pathNodePosList do
        local pathInfo = self.m_pathNodePosList[i]
        local endPos = self:getBallActPos(i, pathInfo)
        local dingView = pathInfo.view

        -- local moveTo = cc.MoveTo:create(1, endPos)
        local time = util_random(3, 4) * 0.1
        local jumpHeight = 20
        if i == #self.m_pathNodePosList then
            jumpHeight = 30
        end
        local jumpTo = cc.JumpTo:create(time, endPos, jumpHeight, 1)
        local rotation = time * 80
        local rotateBy = cc.RotateBy:create(time, pathInfo.direction == "RIGHT" and rotation or -rotation)
        table.insert(actionList, cc.Spawn:create(jumpTo, rotateBy))
        if dingView then
            local callFunc = cc.CallFunc:create(function()
                -- 钉子撞击动画
                dingView:playHitAni()
            end)
            table.insert(actionList, callFunc)
        end
    end

    local endCallFunc =  cc.CallFunc:create(function()
        self.m_ballView:reset()
        self.m_nodeBallParticle:move(0, 0)
        self.m_nodeBallParticle:setVisible(false)
        self.m_mainView:checkPlayFlyCoinsAni()
    end)
    table.insert(actionList, endCallFunc)

    self.m_ballView:runAction(cc.Sequence:create(actionList))
end

function ExpandPlinkoLaunchUI:getBallActPos(_idx, _curInfo)
    local sourcePos = self.m_nodeBall:convertToNodeSpace(_curInfo.posW)
    local offsetPos = self:getOffsetPos(_idx, _curInfo.direction) 
    local endPos = cc.pAdd(sourcePos, offsetPos)
    return endPos
end
function ExpandPlinkoLaunchUI:getOffsetPos(_idx, _direction)
    if _idx == 1 then
        return cc.p(0, ExpandGamePlinkoConfig.RADIUS.BALL+ExpandGamePlinkoConfig.RADIUS.DING)
    end

    if not _direction then
        return cc.p(0, 0)
    end
    
    local angle = 0
    if _direction == "LEFT" then
        angle = util_random(95, 135)
    elseif _direction == "RIGHT" then
        angle = util_random(55, 85)
    end

    local radius = ExpandGamePlinkoConfig.RADIUS.BALL+ExpandGamePlinkoConfig.RADIUS.DING
    local x = radius * math.cos(angle*math.pi/180)
    local y = radius * math.sin(angle*math.pi/180)
    return cc.p(x, y)
end

-- 掉球时 更新粒子位置
function ExpandPlinkoLaunchUI:checkUpdateParticlePos()
    if not self.m_nodeBallParticle then
        return
    end

    self.m_nodeBallParticle:move(self.m_ballView:getPosition())
end

-- 设置本次发射球 掉落路径
function ExpandPlinkoLaunchUI:setDropBallPathInfo(_pathNodePosList)
    self.m_pathNodePosList = _pathNodePosList
end

return ExpandPlinkoLaunchUI