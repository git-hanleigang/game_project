---
--xcyy
--2018年5月23日
--MermaidSlotFastNode.lua

local MermaidSlotFastNode = class("MermaidSlotFastNode",util_require("Levels.SlotsNode"))

function MermaidSlotFastNode:checkLoadCCbNode()

    local ccbNode = self:getCCBNode()

    -- 处理从内存池加载动画节点的逻辑。
    if ccbNode == nil then
        ccbNode = globalData.slotRunData.levelGetAnimNodeCallFun(self.p_symbolType,self.m_ccbName)

        self:addChild(ccbNode, 1, self.m_TAG_CCBNODE)

        -- 检测是否放到big mask 里面去
        self:checkAddToBigSymbolMask()
    end

    ccbNode:setVisible(true)
    
    return ccbNode
end

return MermaidSlotFastNode