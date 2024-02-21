

local AllStarRespinNode = class("AllStarRespinNode", 
                            util_require("Levels.RespinNode"))
-- 这一关没有滚出的grand（全满算grand）
AllStarRespinNode.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

AllStarRespinNode.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
AllStarRespinNode.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
AllStarRespinNode.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8

-- 特殊bonus
AllStarRespinNode.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
AllStarRespinNode.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
AllStarRespinNode.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
AllStarRespinNode.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 

--最后一个小块是否提前移除
function AllStarRespinNode:checkRemoveNextNode()
    return true
end
function AllStarRespinNode:changeNodeDisplay( node )
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


-- 是不是 respinBonus小块
function AllStarRespinNode:isFixSymbol(symbolType)
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
--重置节点坐标
function AllStarRespinNode:baseResetNodePos()
    AllStarRespinNode.super.baseResetNodePos(self)
    if self.m_baseFirstNode then
        self:changeNodeDisplay( self.m_baseFirstNode )
    end
    if self.m_baseNextNode then
        self:changeNodeDisplay( self.m_baseNextNode )
    end
end

return AllStarRespinNode