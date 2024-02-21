

local HallowinNode = class("HallowinNode", 
                                    util_require("Levels.RespinNode"))

local SHOW_ZORDER = 
    {
        SHADE_ORDER = 1000,
        SHADE_LAYER_ORDER = 2000,
        LIGHT_ORDER = 3000
    }
local NODE_TAG = 10

HallowinNode.REPIN_NODE_TAG = 1000

--裁切遮罩透明度
function HallowinNode:initClipOpacity(opacity)
    if opacity and opacity > 0 then
        local pos = cc.p(0 , 0)
        local clipSize = cc.size(self.m_clipNode.clipSize.width + 2,self.m_clipNode.clipSize.height + 10)
        local spPath = "Symbol/GameScreenHallowin_respinMask.png"
        local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
        self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

--创建下个小块
function HallowinNode:createNextNode(createNum, moveDis)
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

return HallowinNode