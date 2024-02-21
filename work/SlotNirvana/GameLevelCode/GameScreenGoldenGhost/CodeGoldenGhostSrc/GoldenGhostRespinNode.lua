
local CodeGameSceneJmsGoldenGhostMachine = util_require("CodeGameScreenGoldenGhostMachine")
local RespinNode =  util_require("Levels.RespinNode")
local GoldenGhostNode = class("GoldenGhostNode", RespinNode)

local NODE_TAG = 10

GoldenGhostNode.REPIN_NODE_TAG = 1000


function GoldenGhostNode:initUI(rsView)
    RespinNode.initUI(self,rsView)
end

function GoldenGhostNode:formatAddSpinSymbol(symbolType)
    if symbolType == CodeGameSceneJmsGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 then
        return CodeGameSceneJmsGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2
    elseif symbolType == CodeGameSceneJmsGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
        return CodeGameSceneJmsGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3
    end
    return symbolType
end

function GoldenGhostNode:getBaseResAction(startPos)
    local actionTable ,downTime = RespinNode.getBaseResAction(self,startPos)
    return actionTable,0
end

--最后一个小块是否提前移除
function GoldenGhostNode:checkRemoveNextNode()
    return true
end

function GoldenGhostNode:initClipNode(clipNode,opacity)
    --去掉颜色遮罩
    RespinNode.initClipNode(self,clipNode)
end

--裁切遮罩透明度
-- function GoldenGhostNode:initClipOpacity(opacity)
--     if opacity and opacity>0 then
--           local pos = cc.p(-self.m_slotNodeWidth*0.5-2 , -self.m_slotNodeHeight*0.5-5)
--           local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
--           local spPath = "Common/GoldenGhost_link_reel_2.png"
--         --   opacity = 255
--           local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.LAYERCOLOR,pos,clipSize,opacity,spPath)
--           self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
--     end
-- end

function GoldenGhostNode:baseCreateNextNode()
    RespinNode.baseCreateNextNode(self)
    local lbScore = self.m_baseNextNode:getCcbProperty("m_lb_score")
    if lbScore ~= nil then
        local nodeType,score = self:getBaseNodeType()
        if  nodeType == CodeGameSceneJmsGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 or
            -- lbScore:setVisible(true)
            nodeType == CodeGameSceneJmsGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 then
                lbScore:setVisible(false)
        end
    end
end

function GoldenGhostNode:changeNodeDisplay(node)
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
    if imageName ~= nil then
        local name = imageName[1]

        name = "#Symbol/GoldenGhost_link_reel.png"
        node:removeAndPushCcbToPool()
        if node.p_symbolImage == nil then
            node.p_symbolImage = display.newSprite(name)
            node:addChild(node.p_symbolImage)
        else
            node:spriteChangeImage(node.p_symbolImage,name)
        end
        node.p_symbolImage:setScale(0.5)
        node.p_symbolImage:setVisible(true)
    end
end

return GoldenGhostNode