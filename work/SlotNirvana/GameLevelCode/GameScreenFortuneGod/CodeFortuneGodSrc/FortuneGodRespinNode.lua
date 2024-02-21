

local FortuneGodRespinNode = class("FortuneGodRespinNode", 
util_require("Levels.RespinNode"))

FortuneGodRespinNode.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12
FortuneGodRespinNode.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
FortuneGodRespinNode.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
FortuneGodRespinNode.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
FortuneGodRespinNode.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
FortuneGodRespinNode.SYMBOL_RS_SCORE_BLANK = 100

local MOVE_SPEED = 1500     --滚动速度 像素/每秒


function FortuneGodRespinNode:initUI(rsView)
    FortuneGodRespinNode.super.initUI(self,rsView)
    self.m_moveSpeed = MOVE_SPEED
end

--最后一个小块是否提前移除
function FortuneGodRespinNode:checkRemoveNextNode()
    return true
end


--子类继承修改节点显示内容
function FortuneGodRespinNode:changeNodeDisplay(node)

    local isShowNode = self:isFixSymbol(node.p_symbolType)
    if isShowNode then
        if node.p_symbolType == self.SYMBOL_RS_SCORE_BLANK then
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
        else
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
        end
    else
        if node.p_symbolType ~= self.SYMBOL_RS_SCORE_BLANK then
            self:hideNodeShow(node)
        end
        node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    end
end

function FortuneGodRespinNode:hideNodeShow(symbol_node)
    if(not symbol_node)then
        return
    end

    local blankType = self.SYMBOL_RS_SCORE_BLANK
    local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
    symbol_node:changeCCBByName(ccbName, blankType)
    symbol_node:changeSymbolImageByName( ccbName )
end

-- 是不是 respinBonus小块
function FortuneGodRespinNode:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_GRAND or 
        symbolType == self.SYMBOL_FIX_MAJOR or 
        symbolType == self.SYMBOL_FIX_MINOR or 
        symbolType == self.SYMBOL_FIX_MINI or 
        symbolType == self.SYMBOL_RS_SCORE_BLANK or
        symbolType == self.SYMBOL_FIX_SYMBOL then
        return true
    end
    return false
end

--裁切遮罩透明度
function FortuneGodRespinNode:initClipOpacity(opacity)
    -- if opacity and opacity>0 then
    --       local pos = cc.p(0, 0)
    --       local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+20)
    --       local spPath = "Symbol/FortuneGod_link_relldi.png"
    --       opacity = 255
    --       local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
    --       self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    -- end
end

return FortuneGodRespinNode