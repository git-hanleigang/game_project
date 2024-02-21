
local CodeGameScreenDazzlingDynastyMachine = util_require("CodeGameScreenDazzlingDynastyMachine")
local RespinNode =  util_require("Levels.RespinNode")
local DazzlingDynastyNode = class("DazzlingDynastyNode", RespinNode)

local NODE_TAG = 10

DazzlingDynastyNode.REPIN_NODE_TAG = 1000


--最后一个小块是否提前移除
function DazzlingDynastyNode:checkRemoveNextNode()
    return true
end

function DazzlingDynastyNode:formatAddSpinSymbol(symbolType)
    if symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 then
        return CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV2
    elseif symbolType == CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
        return CodeGameScreenDazzlingDynastyMachine.SYMBOL_FIX_BONUS_LV3
    end
    return symbolType
end

function DazzlingDynastyNode:baseCreateNextNode()
    RespinNode.baseCreateNextNode(self)
    local lbScore = self.m_baseNextNode:getCcbProperty("m_lb_score")
    if lbScore ~= nil then
        lbScore:setVisible(false)
    end
end

function DazzlingDynastyNode:initClipNode(clipNode,opacity)
    --去掉颜色遮罩
    RespinNode.initClipNode(self,clipNode)
end

function DazzlingDynastyNode:changeNodeDisplay(node)
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
    if imageName ~= nil then
        local name = imageName[1]
        name = string.gsub(name, ".png", "_gray.png")
        node:removeAndPushCcbToPool()
        if node.p_symbolImage == nil then
            node.p_symbolImage = display.newSprite(name)
            node:addChild(node.p_symbolImage)
        else
            node:spriteChangeImage(node.p_symbolImage,name)
        end

        node.p_symbolImage:setScale(1)
        
        node.p_symbolImage:setVisible(true)
    end
end

function DazzlingDynastyNode:getBaseResAction(startPos)
    local actionTable ,downTime = RespinNode.getBaseResAction(self,startPos)
    return actionTable,0
end

return DazzlingDynastyNode