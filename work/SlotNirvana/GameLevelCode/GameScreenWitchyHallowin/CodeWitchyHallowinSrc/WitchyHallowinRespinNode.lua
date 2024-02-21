---
--xcyy
--2018年5月23日
--WitchyHallowinRespinNode.lua

local WitchyHallowinRespinNode = class("WitchyHallowinRespinNode",util_require("Levels.RespinNode"))

local MOVE_SPEED = 2000     --滚动速度 像素/每秒
local RES_DIS = 20

-- 构造函数
function WitchyHallowinRespinNode:ctor()
    WitchyHallowinRespinNode.super.ctor(self)
    self.m_isQuick = false
end


--裁切区域
function WitchyHallowinRespinNode:initClipNode(clipNode,opacity)
    if not clipNode then
        local nodeHeight = self.m_slotReelHeight / self.m_machineRow
        local size = cc.size(self.m_slotNodeWidth,nodeHeight - 1)
        local pos = cc.p(-math.ceil( self.m_slotNodeWidth / 2 ),- nodeHeight / 2)
        self.m_clipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,pos)
        self:addChild(self.m_clipNode)
        --设置裁切块属性
        local originalPos = cc.p(0,0)
        util_setClipNodeInfo(self.m_clipNode,RESPIN_CLIPTYPE.SINGLE,RESPIN_CLIPMODE.RECT,size,originalPos)
    else
        self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity)

    
end

function WitchyHallowinRespinNode:addTipNode(parentNode,zOrder)
    self.m_tipNode = util_createAnimation("WitchyHallowin_Moneychange_tishi.csb")
    parentNode:addChild(self.m_tipNode,zOrder)
    self.m_tipNode:setVisible(false)
    self.m_tipNode:setPosition(util_convertToNodeSpace(self,parentNode))

    self.m_grandTip = util_createAnimation("WitchyHallowin_Bonus_tishi.csb")
    parentNode:addChild(self.m_grandTip,zOrder)
    self.m_grandTip:runCsbAction("actionframe",true)
    self.m_grandTip:setVisible(false)
    self.m_grandTip:setPosition(util_convertToNodeSpace(self,parentNode))
end

--子类可以重写 读取配置
function WitchyHallowinRespinNode:initRunningData()
    self.m_runningData = globalData.slotRunData.levelConfigData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--裁切遮罩透明度
function WitchyHallowinRespinNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
    end
end

--[[
    显示加钱提示框
]]
function WitchyHallowinRespinNode:showChangeMoneyTipAni()
    self.m_tipNode:setVisible(true)
    self.m_tipNode:runCsbAction("start",false,function(  )
        self.m_tipNode:runCsbAction("idle",true)
    end)
end

--[[
    隐藏加钱提示框
]]
function WitchyHallowinRespinNode:hideChangeMoneyTipAni()
    self.m_tipNode:runCsbAction("over",false,function(  )
        self.m_tipNode:setVisible(false)
    end)
end

--[[
    显示grand提示
]]
function WitchyHallowinRespinNode:showGrandTip( )
    self.m_grandTip:setVisible(true)
end

--[[
    隐藏grand提示
]]
function WitchyHallowinRespinNode:hideGrandTip( )
    self.m_grandTip:setVisible(false)
end

---------------------------------快滚相关-------------------------------------------
--设置滚动速度
function WitchyHallowinRespinNode:changeRunSpeed(isQuick)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end

    self.m_isQuick = isQuick

    self:changeResDis(isQuick)
end

--设置回弹距离
function WitchyHallowinRespinNode:changeResDis(isQuick)
    if isQuick then
        self.m_resDis = RES_DIS * 3
    else
        self.m_resDis = RES_DIS
    end
end

--获取回弹动作序列
function WitchyHallowinRespinNode:getBaseResAction(startPos)
    local timeDown = 0
    local speedActionTable = {}
    local dis =  startPos + self.m_resDis
    local speedStart = self.m_moveSpeed
    local preSpeed = speedStart/ 118
    for i= 1, 10 do
          speedStart = speedStart - preSpeed * (11 - i) * 2
          local moveDis = dis / 10
          local time = 0
          --判断是否在快滚状态下
          if self.m_moveSpeed == MOVE_SPEED * 2 then
                time = moveDis / speedStart * 12
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

--执行回弹动作
function WitchyHallowinRespinNode:runBaseResAction()
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
        --快滚时将上边缘小块变为bonus
        if self.m_isQuick then
            if self.m_baseNextNode.p_symbolImage then
                self.m_baseNextNode.p_symbolImage:removeFromParent()
                self.m_baseNextNode.p_symbolImage = nil
            end
            local symbolType = 94
            if self.m_baseNextNode.p_symbolType ~= symbolType then
                self.m_machine:changeSymbolType(self.m_baseNextNode,symbolType)
            end
        end
       
        self.m_baseNextNode:setLocalZOrder(SHOW_ZORDER.SHADE_LAYER_ORDER + 1)
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
----------------------------------------------------------------------------

return WitchyHallowinRespinNode