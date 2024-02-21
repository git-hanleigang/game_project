local GoldMarmotRespinNode = class("GoldMarmotRespinNode", util_require("Levels.RespinNode"))

local NODE_TAG = 10
local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20

--行进方向
local DIRECTION = {
    UP = 1,
    DOWN = 2,
    LEFT = 3,
    RIGHT = 4
}

local JACKPOT_TPYE = {
    "grand",
    "major",
    "minor",
    "mini"
}

local DEFAULT_SCALE_X   =   1.02

-- 构造函数
function GoldMarmotRespinNode:ctor()
    GoldMarmotRespinNode.super.ctor(self)
    self.m_isQuick = false
    self.m_holeFrame = {}
end

function GoldMarmotRespinNode:initUI()
    GoldMarmotRespinNode.super.initUI(self)

    --快滚框
    self.m_quickRunAni = util_createAnimation("WinFrameGoldMarmot_run2.csb")
    self:addChild(self.m_quickRunAni)
    self.m_quickRunAni:runCsbAction("run",true)
    self:showQuickRunAni(false)
end

--裁切区域
function GoldMarmotRespinNode:initClipNode(clipNode,opacity)
    if not clipNode then
          local nodeHeight = self.m_slotReelHeight / self.m_machineRow
          local size = cc.size(self.m_slotNodeWidth,nodeHeight + 1)
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

--裁切遮罩透明度
function GoldMarmotRespinNode:initClipOpacity(opacity)

end

function GoldMarmotRespinNode:setJackpotType(jackpotType)
    self.m_curJackpotType = jackpotType
end

--传入高亮类型 随机类型
function GoldMarmotRespinNode:setEndSymbolType(symbolTypeEnd, symbolRandomType)
    self.m_symbolTypeEnd = symbolTypeEnd
    self.m_runningData = symbolRandomType 
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

--根据配置随机
function GoldMarmotRespinNode:getRunningSymbolTypeByConfig()

    local type = self.m_runningData[self.m_runningDataIndex]
    if self.m_runningDataIndex >= #self.m_runningData then
        self.m_runningDataIndex = 1
    else
        self.m_runningDataIndex = self.m_runningDataIndex + 1
    end
    return type
end

--获取网络消息
function GoldMarmotRespinNode:setRunInfo(runNodeLen, lastNodeType)
    self.m_isGetNetData = true
    self.m_runNodeNum = runNodeLen
    self.m_runLastNodeType = lastNodeType
end

function GoldMarmotRespinNode:showJackpotWinAni()
    for i,frame in ipairs(self.m_holeFrame) do
        if frame:isVisible() then
            frame:runCsbAction("jiesuan",true)
        end
    end
end

function GoldMarmotRespinNode:showQuickRunAni(isShow)
    self.m_quickRunAni:setVisible(isShow)

    self.m_isQuickRun = isShow
end

--设置滚动速度
function GoldMarmotRespinNode:changeRunSpeed(isQuick)
    if isQuick then
        self:setRunSpeed(MOVE_SPEED * 2)
    else
        self:setRunSpeed(MOVE_SPEED)
    end

    self.m_isQuick = isQuick

    self:changeResDis(isQuick)
end

--设置回弹距离
function GoldMarmotRespinNode:changeResDis(isQuick)
    if isQuick then
          self.m_resDis = RES_DIS * 3
    else
          self.m_resDis = RES_DIS
    end
end

--获取回弹动作序列
function GoldMarmotRespinNode:getBaseResAction(startPos)
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
function GoldMarmotRespinNode:runBaseResAction()
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
          if self.m_baseNextNode.p_symbolImage then
                self.m_baseNextNode.p_symbolImage:removeFromParent()
                self.m_baseNextNode.p_symbolImage = nil
          end
          self.m_baseNextNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine,self.m_machine.SYMBOL_SCORE_BONUS), self.m_machine.SYMBOL_SCORE_BONUS)
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

return GoldMarmotRespinNode