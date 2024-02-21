

local ClassicCashNode = class("ClassicCashNode", 
                                    util_require("Levels.RespinNode"))
-- 这一关没有滚出的grand（全满算grand）
ClassicCashNode.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

ClassicCashNode.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
ClassicCashNode.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
ClassicCashNode.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

-- 特殊bonus
ClassicCashNode.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
ClassicCashNode.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
ClassicCashNode.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
ClassicCashNode.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 

--最后一个小块是否提前移除
function ClassicCashNode:checkRemoveNextNode()
    return true
end
function ClassicCashNode:changeNodeDisplay( node )
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
    if node.p_symbolType then
        if self:isFixSymbol(node.p_symbolType )  then
            return
        end
    end
    if imageName ~= nil then
        if imageName[1] then
            local imgName = string.gsub(imageName[1], ".png", "_gray.png")
            node:removeAndPushCcbToPool()
            if node.p_symbolImage == nil then
                node.p_symbolImage = display.newSprite(imgName)
                node:addChild(node.p_symbolImage)
            else
                node:spriteChangeImage(node.p_symbolImage,imgName)
            end
            node.p_symbolImage:setVisible(true)
        end
    end
end

--裁切遮罩透明度
function ClassicCashNode:initClipOpacity(opacity)
    opacity = 0
    if opacity and opacity>0 then
          local pos = cc.p(-self.m_slotNodeWidth*0.5-2 , -self.m_slotNodeHeight*0.5-5)
          local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
          local spPath = nil --RESPIN_COLOR_TYPE.SPRITE 使用图片时需要和小块合并到一张大图 (不填默认图片路径 spPath = globalData.slotRunData.machineData.p_levelName.."_respinMask.png")
          local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)
          self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

-- 是不是 respinBonus小块
function ClassicCashNode:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or 
        symbolType == self.SYMBOL_MID_LOCK or 
        symbolType == self.SYMBOL_ADD_WILD or 
        symbolType == self.SYMBOL_TWO_LOCK or 
        symbolType == self.SYMBOL_Double_BET or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MAJOR  then
        return true
    end
    return false
end

return ClassicCashNode