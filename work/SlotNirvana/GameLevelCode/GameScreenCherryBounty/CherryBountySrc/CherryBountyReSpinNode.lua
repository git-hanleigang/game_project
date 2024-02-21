local CherryBountyReSpinNode = class("CherryBountyReSpinNode", util_require("Levels.RespinNode"))

--重写-采用单格裁切
function CherryBountyReSpinNode:initClipNode(clipNode, opacity)
    if true or not clipNode then
        local nodeHeight = self.m_slotReelHeight / self.m_machineRow
        local size = cc.size(self.m_slotNodeWidth,nodeHeight + 1)
        local pos  = cc.p(-math.ceil(self.m_slotNodeWidth / 2 ),- nodeHeight / 2)
        self.m_clipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,pos)
        self:addChild(self.m_clipNode, 10)
        local originalPos = cc.p(0,0)
        util_setClipNodeInfo(self.m_clipNode,RESPIN_CLIPTYPE.SINGLE,RESPIN_CLIPMODE.RECT,size,originalPos)
    else
        self.m_clipNode = clipNode
    end
    self:initClipOpacity(opacity)
end
--重写-裁切遮罩透明度
function CherryBountyReSpinNode:initClipOpacity(opacity)
end

--重写-获取随机信号
function CherryBountyReSpinNode:randomRuningSymbolType()
    local machineConfigData = self.m_machine.m_configData
    local nodeType = machineConfigData:getReSpinReelRandomSymbol()
    return nodeType
end

return CherryBountyReSpinNode