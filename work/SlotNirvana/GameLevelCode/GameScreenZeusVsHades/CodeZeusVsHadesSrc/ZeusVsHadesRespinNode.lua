

local ZeusVsHadesRespinNode = class("ZeusVsHadesRespinNode", util_require("Levels.RespinNode"))
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20
--图标阵营
local TEAMTYPE = {
    ZEUS  = 0,--宙斯阵营
    HADES = 1 --哈迪斯阵营
}
function ZeusVsHadesRespinNode:ctor()
    ZeusVsHadesRespinNode.super.ctor(self)
    self.m_teamType = TEAMTYPE.ZEUS
    self.m_colorNodeBg = nil--滚轴背景
end
--设置阵营
function ZeusVsHadesRespinNode:setTeamType(teamType)
    self.m_teamType = teamType
end

--裁切遮罩透明度   设置滚动块背景
function ZeusVsHadesRespinNode:initClipOpacity(opacity)
    if self.m_colorNodeBg ~= nil then
        self.m_colorNodeBg:removeFromParent()
        self.m_colorNodeBg = nil
    end
    if opacity and opacity > 0 then
        local pos = cc.p( -self.m_slotNodeWidth * 0.5 , -self.m_slotNodeHeight * 0.5)
        if self.m_teamType == TEAMTYPE.ZEUS then
            self.m_colorNodeBg = util_createAnimation("Socre_ZeusVsHades_dilan2.csb")
        else
            self.m_colorNodeBg = util_createAnimation("Socre_ZeusVsHades_dihong2.csb")
        end
        self.m_clipNode:addChild(self.m_colorNodeBg)
    end
end

--读取假滚配置
function ZeusVsHadesRespinNode:initRunningData()
    if self.m_teamType == TEAMTYPE.ZEUS then
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(math.random(1,5))
    else
        self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(math.random(6,10))
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--设置滚动速度
function ZeusVsHadesRespinNode:changeRunSpeed(isQuick)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end
end

--设置回弹距离
function ZeusVsHadesRespinNode:changeResDis(isQuick)
    if isQuick then
        self.m_resDis = RES_DIS * 3
    else
        self.m_resDis = RES_DIS
    end
end

--执行回弹动作
function ZeusVsHadesRespinNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
        local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
        local actionTable ,downTime = self:getBaseResAction(0)
        if actionTable and #actionTable>0 then
            self.m_baseFirstNode:runAction(cc.Sequence:create(actionTable))
        end
        if baseResTime<downTime then
            baseResTime = downTime
        end
    end
    --上边缘小块回弹
    if self.m_baseNextNode then
        -- if self.m_machine:isFixSymbol(self.m_baseFirstNode.p_symbolType) == false then
        --     if self.m_baseNextNode.p_symbolImage then
        --         self.m_baseNextNode.p_symbolImage:removeFromParent()
        --         self.m_baseNextNode.p_symbolImage = nil
        --     end
        --     local changeSymbol = self.m_machine:getRandomFixSymbol(self.p_colIndex)
        --     self.m_baseNextNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,changeSymbol), changeSymbol)
        --     self.m_baseNextNode:setLocalZOrder(SHOW_ZORDER.SHADE_LAYER_ORDER + 1)
        -- end
        local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY - self.m_slotNodeHeight
        local actionTable ,downTime = self:getBaseResAction(0)
        if actionTable and #actionTable>0 then
            self.m_baseNextNode:runAction(cc.Sequence:create(actionTable))
        end
        --回弹结束后移除上边缘小块
        if downTime>0 then
            --检测时长
            if baseResTime<downTime then
                baseResTime = downTime
            end
            performWithDelay(self,function()
                self:baseRemoveNode(self.m_baseNextNode)
                self.m_baseNextNode = nil
            end,downTime)
        else
            self:baseRemoveNode(self.m_baseNextNode)
            self.m_baseNextNode = nil
        end
    end
    return baseResTime
end

--获取回弹动作序列
function ZeusVsHadesRespinNode:getBaseResAction(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis =  startPos + self.m_resDis
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart/ 118
    for i = 1, 10 do
        speedStart = speedStart - preSpeed * (11 - i) * 2
        local moveDis = dis / 10
        local time = 0
        --判断是否在快滚状态下
        if self.m_resDis == RES_DIS * 3 then
            time = moveDis / speedStart * 8
            timeDown = timeDown + time
        else
            time = moveDis / speedStart
            timeDown = timeDown + time
        end
        local moveBy = cc.MoveBy:create(time,cc.p(0, -moveDis))
        speedActionTable[#speedActionTable + 1] = moveBy
    end
    local moveBy = cc.MoveBy:create(0.1,cc.p(0, - self.m_resDis))
    speedActionTable[#speedActionTable + 1] = moveBy:reverse()
    timeDown = timeDown + 0.1
    return speedActionTable, timeDown
end
return ZeusVsHadesRespinNode