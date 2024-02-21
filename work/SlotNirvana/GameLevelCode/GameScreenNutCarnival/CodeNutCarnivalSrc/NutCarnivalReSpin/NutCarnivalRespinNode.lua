local NutCarnivalRespinNode = class("NutCarnivalRespinNode", util_require("Levels.RespinNode"))
local MOVE_SPEED = 1500     --滚动速度 像素/每秒

--裁切区域
function NutCarnivalRespinNode:initClipNode(clipNode,opacity)
    if true or not clipNode then
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
function NutCarnivalRespinNode:initClipOpacity(opacity)
    -- opacity = 255
    -- if opacity and opacity>0 then
        -- local pos = cc.p(0, 0)
        -- local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
        -- local spPath = "NutCarnivalSymbol/NutCarnival_respinDi.png"
        -- local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE, pos, clipSize, opacity, spPath)
        -- self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    -- end
end

--获取回弹动作序列
function NutCarnivalRespinNode:getBaseResAction(startPos, symbolNode)
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
          if self:isQuickRun() then
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
--是否为快滚
function NutCarnivalRespinNode:isQuickRun() 
    return self.m_moveSpeed == MOVE_SPEED * 2
end

--设置滚动速度
function NutCarnivalRespinNode:changeRunSpeed(isQuick)
    local speed = isQuick and MOVE_SPEED * 2 or MOVE_SPEED
    self:setRunSpeed(MOVE_SPEED)
end
--设置回弹距离
function NutCarnivalRespinNode:changeResDis(isQuick)
    local RES_DIS = 20
    self.m_resDis = isQuick and RES_DIS * 3 or RES_DIS
end



return NutCarnivalRespinNode
