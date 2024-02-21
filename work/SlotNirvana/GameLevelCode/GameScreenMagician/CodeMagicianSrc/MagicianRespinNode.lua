---
--xcyy
--2018年5月23日
--MagicianRespinNode.lua
local RespinNode = util_require("Levels.RespinNode")
local MagicianRespinNode = class("MagicianRespinNode",RespinNode)

--裁切遮罩透明度
function MagicianRespinNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
        local pos = cc.p(-self.m_slotNodeWidth*0.5-2 , -self.m_slotNodeHeight*0.5-5)
        local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
        local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
        -- local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)
        -- self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

--获得下一个小块
function MagicianRespinNode:getBaseNextNode(nodeType,score)
    local node = nil
    if self.m_runNodeNum == 0 then
        --最后一个小块
        node = self.getSlotNodeBySymbolType(nodeType, self.p_rowIndex , self.p_colIndex, true)
    else
        node = self.getSlotNodeBySymbolType(nodeType)
    end
    if self:getTypeIsEndType(nodeType ) == false then
        node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    else
        node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
    end
    node.score = score
    node.p_symbolType = nodeType
    node.isHitSymbol = false
    return node
end

return MagicianRespinNode