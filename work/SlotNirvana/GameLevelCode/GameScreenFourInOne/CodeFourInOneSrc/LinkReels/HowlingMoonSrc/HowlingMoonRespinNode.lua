
local RespinNode = util_require("Levels.RespinNode")
local HowlingMoonNode = class("HowlingMoonNode",RespinNode)
HowlingMoonNode.REPIN_NODE_TAG = 1000
function HowlingMoonNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
        local pos = cc.p(-self.m_slotNodeWidth*0.5+1 , -self.m_slotNodeHeight*0.5)
        local clipSize = cc.size(self.m_clipNode.clipSize.width-6,self.m_clipNode.clipSize.height+2)
        local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
        local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)
        self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end
function HowlingMoonNode:setMachine( machine )
    self.m_machine = machine
end
function HowlingMoonNode:initClipNode()
    local nodeHeight = self.m_slotReelHeight / self.m_machineRow
    self.m_clipNode= cc.ClippingRectangleNode:create({x= -math.ceil( self.m_slotNodeWidth / 2 ) , y= - (nodeHeight - 8) / 2, width = self.m_slotNodeWidth, height = nodeHeight - 5 })
    self:addChild(self.m_clipNode)

    local colorLayer = ccui.ImageView:create("Symbol/FourInOne_zhezhao.png",1)
    colorLayer:setOpacity(200)
    colorLayer:setScale9Enabled(true)
    colorLayer:setSize(cc.size( self.m_slotNodeWidth , self.m_slotNodeHeight ))
    self.m_clipNode:addChild(colorLayer, SHOW_ZORDER.SHADE_LAYER_ORDER)
end
function HowlingMoonNode:checkRemoveFirstNode()
    local node = self.m_baseFirstNode
    if not node then
        return
    end
    if node.p_symbolType ==  394
        or node.p_symbolType ==  3102
        or node.p_symbolType ==  3103
        or node.p_symbolType ==  3104
        or node.p_symbolType ==  3105
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
    if type == 394 then
        score =  self.m_machine.m_configData:getRespinRunningScore()
        if score == 20 then
            type = 3102
        elseif score == 50 then
            type = 3103
        elseif score == 100 then
            type = 3104
        elseif score == 500 then
            type = 3105
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

function HowlingMoonNode:initRunningData()
    if globalData.slotRunData.totalFreeSpinCount == 0 then
        self.m_runningData = self.m_machine.m_configData:getNormalRespinCloumnByColumnIndex(self.p_rowIndex)
    else
        self.m_runningData = self.m_machine.m_configData:getNormalFreeSpinRespinCloumnByColumnIndex(self.p_rowIndex)
    end
    if self.m_runningData ~= nil then
        self.m_runningDataIndex = xcyy.SlotsUtil:getArc4Random() % #self.m_runningData + 1
    end
end

return HowlingMoonNode