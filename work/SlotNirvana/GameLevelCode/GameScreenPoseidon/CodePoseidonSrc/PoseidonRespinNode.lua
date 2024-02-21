--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-02-21 15:18:16                                                                                              
]]
local RespinNode =  util_require("Levels.RespinNode")
local PoseidonRespinNode = class("PoseidonRespinNode", RespinNode)

local BEGIN_SPEED = 2000
PoseidonRespinNode.m_endSpeed = nil
local ADD_RUN_NUM = 15
local END_SPEED_UP = 190
local END_SPEED_BLOW= 200

PoseidonRespinNode.m_bSpecialRun = nil
PoseidonRespinNode.m_runLens = nil
PoseidonRespinNode.m_decelerSpeed = nil
PoseidonRespinNode.m_bStore = nil
PoseidonRespinNode.m_respinView = nil
PoseidonRespinNode.m_bUpRes = nil

function PoseidonRespinNode:initUI()
    RespinNode.initUI(self)
    self:setRunSpeed(BEGIN_SPEED)
    self.m_bSpecialRun = false
    self.m_runLens = 0
    self.m_resDis = 40
    self.m_bUpRes = false
    self.m_endSpeed = END_SPEED_BLOW
end

function PoseidonRespinNode:initClipNode(clipNode,opacity)
    RespinNode.initClipNode(self,clipNode)
end

function PoseidonRespinNode:setRespinView(respinView)
    self.m_respinView = respinView
end

function PoseidonRespinNode:setDecelerSpeed()
    self.m_decelerSpeed = (self.m_endSpeed* self.m_endSpeed - self:getRunSpeed() * self:getRunSpeed()) / (2 * (ADD_RUN_NUM ) * self.m_slotNodeHeight) 
end

function PoseidonRespinNode:setRunInfo(runNodeLen, lastNodeType, bSpecialRun, bStore) 
    self.m_bUpRes = false
    self.m_bStore = bStore
    self.m_bSpecialRun = bSpecialRun 
    if self.m_bSpecialRun and self.m_bStore and xcyy.SlotsUtil:getArc4Random() % 2 then
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
function PoseidonRespinNode:getBaseMoveDis(dt)
    return -self:getMoveDis(dt)
end
function PoseidonRespinNode:getMoveDis(dt)
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

function PoseidonRespinNode:startMove()
    self:setRunSpeed(BEGIN_SPEED)
    RespinNode.startMove(self)
    
    -- if self.m_bUpRes == false then
    --     if self.m_lastNode and self.m_lastNode:getPositionY() + delayMoveDis < 0 then
    --         delayMoveDis = -self.m_lastNode:getPositionY() 
    --     end
    -- else
    --     if self.m_lastNode and self.m_lastNode:getPositionY() + delayMoveDis < self.m_slotNodeHeight then
    --         delayMoveDis = -self.m_lastNode:getPositionY() 
    --     end
    -- end
    
    -- local diff = 0
    -- if self.m_bUpRes then
    --     diff =  self.m_slotNodeHeight
    -- end
    -- --判断是否是最后一个
    -- if self.m_lastNode ~= nil and self.m_runNodeNum <= 0  and self.m_lastNode:getPositionY() <= diff then
    -- end
end
function PoseidonRespinNode:baseOverMove()
    if self.m_bUpRes then
        self:baseRemoveNode(self.m_baseFirstNode)
        self.m_baseFirstNode = nil
    end
    RespinNode.baseOverMove(self)
end
--获取回弹action
function PoseidonRespinNode:getResAction(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis =  self.m_resDis 
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

function PoseidonRespinNode:getBaseResAction()
    if self.m_bUpRes == false then
        return RespinNode.getBaseResAction(self,0)
    else
        return self:getResAction()
    end
end
--创建下个小块
function PoseidonRespinNode:getBaseNodeType()
    --创建下一个
    local nodeType = nil
    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        nodeType = self.m_runLastNodeType
    else 
        if  self.m_bSpecialRun  then
            if self.m_bStore then
                if self.m_bUpRes then
                    if self.m_runNodeNum == 1 then
                        nodeType = 100 
                    else
                        if self.m_runningData == nil then
                            nodeType = self:randomRuningSymbolType()
                        else
                            nodeType = self:getRunningSymbolTypeByConfig()
    
                            if nodeType == 0 then
                                nodeType = self.m_respinView:getSpecialSymbolType() 
                            end
                        end
                    end
                else
                    if self.m_runNodeNum < 0 then
                        nodeType = 100 
                    else
                        if self.m_runningData == nil then
                            nodeType = self:randomRuningSymbolType()
                        else
                            nodeType = self:getRunningSymbolTypeByConfig()
    
                            if nodeType == 0 then
                                nodeType = self.m_respinView:getSpecialSymbolType() 
                            end
                        end
                    end
                end
            else
                if self.m_bUpRes then
                    if self.m_runNodeNum == 1 then
                        if xcyy.SlotsUtil:getArc4Random() % 5 == 1 then
                            nodeType = 1001
                        else
                            nodeType = self.m_respinView:getSpecialSymbolType() 
                        end
                    else
                        if self.m_runningData == nil then
                            nodeType = self:randomRuningSymbolType()
                        else
                            nodeType = self:getRunningSymbolTypeByConfig()
    
                            if nodeType == 0 then
                                nodeType = self.m_respinView:getSpecialSymbolType() 
                            end
    
                        end
                    end
                else
                    if self.m_runNodeNum < 0 then
                        if xcyy.SlotsUtil:getArc4Random() % 3 == 1 then
                            nodeType = 1001
                        else
                            nodeType = self.m_respinView:getSpecialSymbolType() 
                        end
                    else
                        if self.m_runningData == nil then
                            nodeType = self:randomRuningSymbolType()
                        else
                            nodeType = self:getRunningSymbolTypeByConfig()
    
                            if nodeType == 0 then
                                nodeType = self.m_respinView:getSpecialSymbolType() 
                            end
                        end
                    end
                end
            end
        else
            if self.m_runningData == nil then
                nodeType = self:randomRuningSymbolType()
            else
               nodeType = self:getRunningSymbolTypeByConfig()
               
               if nodeType == 0 then
                    nodeType = self.m_respinView:getSpecialSymbolType() 
               end
            end
        end
    end
    return nodeType
end

return  PoseidonRespinNode