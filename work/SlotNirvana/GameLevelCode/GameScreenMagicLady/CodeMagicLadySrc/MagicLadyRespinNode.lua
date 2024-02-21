

local MagicLadyNode = class("MagicLadyNode", util_require("Levels.RespinNode"))

local SHOW_ZORDER = 
    {
        SHADE_ORDER = 1000,
        SHADE_LAYER_ORDER = 2000,
        LIGHT_ORDER = 3000
    }
local NODE_TAG = 10
MagicLadyNode.REPIN_NODE_TAG = 1000
MagicLadyNode.m_animState = 1

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20
--子类可以重写修改滚动参数
function MagicLadyNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end
--裁切区域
function MagicLadyNode:initClipNode(clipNode,opacity)
    if not clipNode then
        local nodeHeight = self.m_slotReelHeight / self.m_machineRow
        local size = cc.size(self.m_slotNodeWidth,nodeHeight)
        local pos = cc.p(self.m_slotNodeWidth / 2 ,- nodeHeight / 2)
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
function MagicLadyNode:initClipOpacity(opacity)
    if opacity and opacity > 0 then
        local pos = cc.p(0 , 0)
        local clipSize = cc.size(self.m_clipNode.clipSize.width + 2,self.m_clipNode.clipSize.height + 10)
        local spPath = "Symbol/GameScreenMagicLady_respinMask.png"
        local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
        self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

function MagicLadyNode:setAnimaState(state)
    self.m_animState = state
end

function MagicLadyNode:changeNodeDisplay( node )
    if self.m_animState ~= 1 then
        node:setVisible(false)
        return
    end
    node:runAnim("idleframe")
end

function MagicLadyNode:changeCreateNodeNum(createNum)
    if self.m_runNodeNum == 0  then
        return 0
    end
    return createNum
end


--创建下个小块
function MagicLadyNode:createNextNode(createNum, moveDis)
    if createNum == 0 then
        return
    end

    if self.m_isGetNetData == true then
        self.m_runNodeNum = self.m_runNodeNum - 1
    end

    --创建下一个
    local nodeType = nil
    local score = nil

    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        nodeType = self.m_runLastNodeType
    else 

       if self.m_runningData == nil then
          nodeType = self:randomRuningSymbolType()
       else
          nodeType, score = self:getRunningSymbolTypeByConfig()
       end

    end

    local node = nil
    
    if self.m_runNodeNum == 0 then
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex, self.p_colIndex, true)
          self.m_lastNode = node
    else
        node =  self.getSlotNodeBySymbolType(nodeType)
    end
    node.score = score
    node.p_symbolType = nodeType
    
    if self:getTypeIsEndType(node.p_symbolType ) == false then
        node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    else
        node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    end
    self:playCreateSlotsNodeAnima(node)
    node:setTag(NODE_TAG) 

    local posY = self.m_slotNodeHeight - moveDis % self.m_slotNodeHeight
    
    node:setPosition(cc.p(0, posY))
    self.m_clipNode:addChild(node)

end 

return MagicLadyNode