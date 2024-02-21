local VegasNode = class("VegasNode", util_require("Levels.RespinNode"))


function VegasNode:checkRemoveNextNode()
    return true
end

function VegasNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
        local pos = cc.p(-self.m_slotNodeWidth*0.5+4 , -self.m_slotNodeHeight*0.5-5)
        local clipSize = cc.size(self.m_clipNode.clipSize.width-15,self.m_clipNode.clipSize.height+10)
          local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
          local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)
          self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

return VegasNode
