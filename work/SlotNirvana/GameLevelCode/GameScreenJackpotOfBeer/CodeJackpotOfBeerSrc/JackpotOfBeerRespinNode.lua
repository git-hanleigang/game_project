

local JackpotOfBeerRespinNode = class("JackpotOfBeerRespinNode", 
util_require("Levels.RespinNode"))


local BEGIN_SPEED       = 1500
JackpotOfBeerRespinNode.m_endSpeed = nil
local ADD_RUN_NUM       = 15
local END_SPEED_UP      = 190
local END_SPEED_BLOW    = 200

JackpotOfBeerRespinNode.m_bSpecialRun = nil
JackpotOfBeerRespinNode.m_runLens = nil
JackpotOfBeerRespinNode.m_decelerSpeed = nil
JackpotOfBeerRespinNode.m_bStore = nil
JackpotOfBeerRespinNode.m_bUpRes = nil

--子类继承修改节点显示内容
function JackpotOfBeerRespinNode:changeNodeDisplay(node)

    local isShowNode = self:isFixSymbol(node.p_symbolType)
    if isShowNode then
        node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    else
        if node.p_symbolType ~= self.m_machine.SYMBOL_RS_SCORE_BLANK then
            self:hideNodeShow(node)
        end
        node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    end
end

function JackpotOfBeerRespinNode:hideNodeShow(symbol_node)
    if(not symbol_node)then
        return
    end

    local blankType = self.m_machine.SYMBOL_RS_SCORE_BLANK
    local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
    symbol_node:changeCCBByName(ccbName, blankType)
    symbol_node:changeSymbolImageByName( ccbName )
end

-- 是不是 respinBonus小块
function JackpotOfBeerRespinNode:isFixSymbol(symbolType)
    if symbolType == self.m_machine.SYMBOL_BONUS_LINK then
        return true
    end
    return false
end


function JackpotOfBeerRespinNode:setDecelerSpeed()
    self.m_decelerSpeed = (self.m_endSpeed* self.m_endSpeed - self:getRunSpeed() * self:getRunSpeed()) / (2 * (ADD_RUN_NUM ) * self.m_slotNodeHeight) 
end

--创建下个小块
function JackpotOfBeerRespinNode:getBaseNodeType()
    --创建下一个
    local nodeType = nil
    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        nodeType = self.m_runLastNodeType
    else 
        if  self.m_bSpecialRun  then
            if self.m_bStore then
                if self.m_bUpRes then
                    if self.m_runNodeNum == 1 then
                        nodeType = self.m_machine.SYMBOL_RS_SCORE_BLANK 
                    else
                        if self.m_runningData == nil then
                            nodeType = self:randomRuningSymbolType()
                        else
                            nodeType = self:getRunningSymbolTypeByConfig()
                        end
                    end
                else
                    if self.m_runNodeNum < 0 then
                        nodeType = self.m_machine.SYMBOL_RS_SCORE_BLANK 
                    else
                        if self.m_runningData == nil then
                            nodeType = self:randomRuningSymbolType()
                        else
                            nodeType = self:getRunningSymbolTypeByConfig()
                        end
                    end
                end
            else
                if self.m_runNodeNum < 0 then
                    nodeType = self.m_machine:getSpecialSymbolType()
                elseif self.m_runNodeNum == 1 then
                    nodeType = self.m_machine.SYMBOL_RS_SCORE_BLANK 
                else
                    if self.m_runningData == nil then
                        nodeType = self:randomRuningSymbolType()
                    else
                        nodeType = self:getRunningSymbolTypeByConfig()
                    end
                end
            end
        else
            if self.m_runningData == nil then
                nodeType = self:randomRuningSymbolType()
            else
               nodeType = self:getRunningSymbolTypeByConfig()
            end
        end
    end
    return nodeType
end
function JackpotOfBeerRespinNode:setRunInfo(runNodeLen, lastNodeType, bSpecialRun, bStore) 
    self.m_bUpRes = false
    self.m_bStore = bStore
    self.m_bSpecialRun = bSpecialRun 
    if self.m_bSpecialRun and self.m_bStore  then
        self.m_bUpRes = true
    end
    self.m_endSpeed = END_SPEED_BLOW
    if  self.m_bUpRes then
        self.m_endSpeed = END_SPEED_UP
    end
    self.m_isGetNetData = true
    self.m_runLens = runNodeLen
    self:setRunSpeed(BEGIN_SPEED)
    if self.m_bSpecialRun then
        self.m_runNodeNum = runNodeLen + ADD_RUN_NUM
        self:setDecelerSpeed()
    else
        self.m_runNodeNum = runNodeLen
    end
    self.m_runLastNodeType = lastNodeType
end
function JackpotOfBeerRespinNode:getBaseMoveDis(dt)
    return -self:getMoveDis(dt)
end
function JackpotOfBeerRespinNode:getMoveDis(dt)
    if self.m_bUpRes == false then
        if self.m_bSpecialRun 
        and  self.m_runNodeNum <= ADD_RUN_NUM 
        and self.m_isGetNetData 
        then
            if self:getRunSpeed() > self.m_endSpeed then
                local s = -(dt * self:getRunSpeed() + self.m_decelerSpeed * dt * dt / 2)
                local vEnd = self:getRunSpeed() + self.m_decelerSpeed * dt
                self:setRunSpeed(vEnd)
                return s
            else
                self:setRunSpeed(self.m_endSpeed)
                local s = -dt * self:getRunSpeed()
                return s
            end
        else
            local s = -dt * self:getRunSpeed()
            return  s
        end
    else
        if self.m_bSpecialRun 
        and  self.m_runNodeNum <= ADD_RUN_NUM
        and self.m_isGetNetData 
        then
            if self:getRunSpeed() > self.m_endSpeed then
                local s = -(dt * self:getRunSpeed() + self.m_decelerSpeed * dt * dt / 2)
                local vEnd = self:getRunSpeed() + self.m_decelerSpeed * dt
                self:setRunSpeed(vEnd)
                return s
            else
                self:setRunSpeed(self.m_endSpeed)
                local s = -dt * self:getRunSpeed()
                return s
            end
        else
            local s = -dt * self:getRunSpeed()
            return  s
        end
    end

end

function JackpotOfBeerRespinNode:startMove()
    self:setRunSpeed(BEGIN_SPEED)
    JackpotOfBeerRespinNode.super.startMove(self)
end
--获取回弹action
function JackpotOfBeerRespinNode:getResAction(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis = startPos + self.m_resDis 
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = moveDis / speedStart
        timeDown = timeDown + time
        local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end
    local moveBy = cc.MoveBy:create(0.1,cc.p(0, - self.m_slotNodeHeight / 2))
    speedActionTable[#speedActionTable + 1] = moveBy
    timeDown = timeDown + 0.1
    return speedActionTable, timeDown
end

function JackpotOfBeerRespinNode:getBaseResAction(startPos)
    if self.m_bUpRes == false then
        return JackpotOfBeerRespinNode.super.getBaseResAction(self,startPos)
    else
        return self:getResAction(startPos)
    end
end


--结束回调
function JackpotOfBeerRespinNode:baseOverCallBack()
    self:baseResetNodePos()
    --没有节点默认idle状态
    if not self.m_lastNode or self:getTypeIsEndType(self.m_lastNode.p_symbolType) == false then
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.IDLE)
     else 
        self:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)
        self:setVisible(false)
     end
    if  self.m_DownCallback ~= nil then
        self.m_DownCallback(self.m_lastNode,self:getRespinNodeStatus())
    end
end


return JackpotOfBeerRespinNode