

local WingsOfPhoelinxRespinNode = class("WingsOfPhoelinxRespinNode", 
util_require("Levels.RespinNode"))

WingsOfPhoelinxRespinNode.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1   --带钱bonus
WingsOfPhoelinxRespinNode.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2   --winBonus
WingsOfPhoelinxRespinNode.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3   --X3Bonus
WingsOfPhoelinxRespinNode.SYMBOL_BONUS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4   --X5Bonus
WingsOfPhoelinxRespinNode.SYMBOL_RS_SCORE_BLANK = 100

local NODE_TAG = 10
local MOVE_SPEED = 1000     --滚动速度 像素/每秒
--最后一个小块是否提前移除
function WingsOfPhoelinxRespinNode:checkRemoveNextNode()
    return true
end

function WingsOfPhoelinxRespinNode:initUI(rsView)
    WingsOfPhoelinxRespinNode.super.initUI(self,rsView)
    self.m_moveSpeed = MOVE_SPEED
end

function WingsOfPhoelinxRespinNode:baseCreateNextNode()
    if self.m_isGetNetData == true then
        self.m_runNodeNum = self.m_runNodeNum - 1
    end
    --创建下一个
    local nodeType,score = self:getBaseNodeType()
    local node = self:getBaseNextNode(nodeType,score)
    --实现拖尾的效果
    if nodeType == self.SYMBOL_BONUS2 or nodeType == self.SYMBOL_BONUS3 or nodeType == self.SYMBOL_BONUS4 then
        node:runAnim("idleframe2")
    end
    --最后一个小块
    if self.m_runNodeNum == 0 then
        self.m_lastNode = node
    end
    self:playCreateSlotsNodeAnima(node)
    node:setTag(NODE_TAG) 
    self.m_clipNode:addChild(node)
    --赋值给下一个节点
    self.m_baseNextNode = node
    self:updateBaseNodePos()
    self:changeNodeDisplay( node )
end

--子类继承修改节点显示内容
function WingsOfPhoelinxRespinNode:changeNodeDisplay(node)

    local isShowNode = self:isFixSymbol(node.p_symbolType)
    if isShowNode then
        if node.p_symbolType == self.SYMBOL_RS_SCORE_BLANK then
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
        else
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER + 10)
        end
        
    else
        if node.p_symbolType ~= self.SYMBOL_RS_SCORE_BLANK then
            self:hideNodeShow(node)
        end
        node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    end
end

function WingsOfPhoelinxRespinNode:hideNodeShow(symbol_node)
    if(not symbol_node)then
        return
    end

    local blankType = self.SYMBOL_RS_SCORE_BLANK
    local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
    symbol_node:changeCCBByName(ccbName, blankType)
    symbol_node:changeSymbolImageByName( ccbName )
end

-- 是不是 respinBonus小块
function WingsOfPhoelinxRespinNode:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS1 or 
        symbolType == self.SYMBOL_BONUS2 or 
        symbolType == self.SYMBOL_BONUS3 or 
        symbolType == self.SYMBOL_RS_SCORE_BLANK or
        symbolType == self.SYMBOL_BONUS4 then
        return true
    end
    return false
end

--裁切遮罩透明度
function WingsOfPhoelinxRespinNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
          local pos = cc.p(0, 0)
          local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
          local spPath = "Common/Socre_WingsOfPhoelinx_bonusdi2.png"
          opacity = 255
          local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
          self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

return WingsOfPhoelinxRespinNode