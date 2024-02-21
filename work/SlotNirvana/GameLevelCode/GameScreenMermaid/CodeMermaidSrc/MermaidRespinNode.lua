

local RespinNode = util_require("Levels.RespinNode")
local MermaidNode = class("MermaidNode",RespinNode)
function MermaidNode:checkRemoveNextNode()
    return true
end
function MermaidNode:initClipNode()
    local nodeHeight = self.m_slotReelHeight / self.m_machineRow
    self.m_clipNode= cc.ClippingRectangleNode:create({x= -math.ceil( self.m_slotNodeWidth / 2 ) , y= - nodeHeight / 2, width = self.m_slotNodeWidth, height = nodeHeight + 1 })
    self:addChild(self.m_clipNode)

    local colorLayer = ccui.ImageView:create("Symbol/zhezhao.png",1)
    colorLayer:setOpacity(130)
    colorLayer:setScale9Enabled(true)
    colorLayer:setSize(cc.size( self.m_slotNodeWidth , self.m_slotNodeHeight ))
    self.m_clipNode:addChild(colorLayer, SHOW_ZORDER.SHADE_LAYER_ORDER)
end
--创建下个小块
function MermaidNode:baseCreateNextNode()
    RespinNode.baseCreateNextNode(self)
    if self.m_runNodeNum == 0 then
    else
        self:setNodeScore(self.m_baseNextNode)
    end
end

function MermaidNode:setNodeScore( symbolNode )
    if symbolNode then
        local score =  self.m_machine:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        if score and type(score) ~= "string" then
                local lineBet = globalData.slotRunData:getCurTotalBet()

                local labRed = symbolNode:getCcbProperty("m_lb_score_0")
                local labBlue = symbolNode:getCcbProperty("m_lb_score")
                if labBlue then
                    labBlue:setVisible(false)    
                end

                if labRed then
                    labRed:setVisible(false)   
                end
                
                if score >= self.m_machine.m_respinCollectBet   then
                
                    if labRed then
                            labRed:setVisible(true)   
                    end

                else
                    if labBlue then
                            labBlue:setVisible(true)    
                    end
                end

                
                score = score * lineBet
                score = util_formatCoins(score, 3)

                if labRed then
                    labRed:setString(score)
                end

                if labBlue then
                    labBlue:setString(score)
                end
        end
    end
    
end

return MermaidNode