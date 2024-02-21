
local RespinNode = util_require("Levels.RespinNode")
local HowlingMoonNode = class("HowlingMoonNode",RespinNode)
local NODE_TAG = 10
HowlingMoonNode.REPIN_NODE_TAG = 1000

function HowlingMoonNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
        --   local pos = cc.p(-self.m_slotNodeWidth*0.5+2 , -self.m_slotNodeHeight*0.5-2)
          local pos = cc.p(0 , -3)
          local clipSize = cc.size(self.m_clipNode.clipSize.width-8,self.m_clipNode.clipSize.height+0)
          local spPath = "Symbol/HowlingMoon_hei.png"--RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
          local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
          self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

function HowlingMoonNode:checkRemoveFirstNode()
    local node = self.m_baseFirstNode
    if not node then
        return
    end
    if node.p_symbolType ==  94
        or node.p_symbolType ==  102
        or node.p_symbolType ==  103
        or node.p_symbolType ==  104
        or node.p_symbolType ==  105
    then
        if node:getPositionY() <= -self.m_slotNodeHeight/2 then
            self:baseRemoveNode(self.m_baseFirstNode)
            self.m_baseFirstNode = nil
        end
    end
end
--子类可以重写 最后一个上边缘小块是否提前移除不参与回弹
function HowlingMoonNode:checkRemoveNextNode()
    return true
end
--刷新
function HowlingMoonNode:baseUpdateMove(dt)
    if globalData.slotRunData.gameRunPause then
        return
    end
    -- self:checkRemoveFirstNode()
    RespinNode.baseUpdateMove(self,dt)
end
--根据配置随机
function HowlingMoonNode:getRunningSymbolTypeByConfig()
    local type = self.m_runningData[self.m_runningDataIndex]
    if self.m_runningDataIndex >= #self.m_runningData then
        self.m_runningDataIndex = 1
    else
        self.m_runningDataIndex = self.m_runningDataIndex + 1
    end
    local score = nil
    if type == 94 then
        score =  globalData.slotRunData.levelConfigData:getRespinRunningScore()
        if score == 20 then
            type = 102
        elseif score == 50 then
            type = 103
        elseif score == 100 then
            type = 104
        elseif score == 500 then
            type = 105
        end
    end
    return type, score
end
--放入首节点
function HowlingMoonNode:setFirstSlotNode(node)
    RespinNode.setFirstSlotNode(self,node)
    node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
end
--放入light首节点
function HowlingMoonNode:setLightFirstSlotNode(node)
    RespinNode.setFirstSlotNode(self,node)
    node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    node:setTag(self.REPIN_NODE_TAG)
end
return HowlingMoonNode