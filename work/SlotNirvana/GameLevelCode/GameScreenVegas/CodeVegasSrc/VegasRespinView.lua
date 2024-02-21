local VegasRespinView = class("VegasRespinView", util_require("Levels.RespinView"))

VegasRespinView.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
VegasRespinView.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
VegasRespinView.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
VegasRespinView.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

function VegasRespinView:readyMove()
    local fixNode = self:getFixSlotsNode()
    local nBeginAnimTime = 0
    local tipTime = 0
    self.m_addNewNode = {}
    self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    if self.m_startCallFunc then
        self.m_startCallFunc()
    end
    self.m_bulingOver = false
end

function VegasRespinView:runNodeEnd(endNode)
    if endNode.p_symbolType == self.SYMBOL_FIX_SYMBOL or endNode.p_symbolType == self.SYMBOL_FIX_MINI or endNode.p_symbolType == self.SYMBOL_FIX_MINOR or endNode.p_symbolType == self.SYMBOL_FIX_MAJOR then
        local waitTime = 0
        self.m_bulingOver = false
        endNode:runAnim(
            "buling2",
            false,
            function()
                self.m_bulingOver = true
            end
        )
        gLobalSoundManager:playSound("VegasSounds/sound_vegas_respin_link_ground.mp3")
        table.insert(self.m_addNewNode, endNode)
    end
end

function VegasRespinView:oneReelDown()
    gLobalSoundManager:playSound("VegasSounds/sound_vegas_reel_stop.mp3")
end

---获取所有参与结算节点
function VegasRespinView:getAllCleaningNode()
    --从 从上到下 左到右排序
    local cleaningNodes = {}
    local childs = self:getChildren()

    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
            node.m_firstNode = false
            cleaningNodes[#cleaningNodes + 1] = node
        end
    end

    --排序
    local sortNode = {}
    for iCol = 1, self.m_machineColmn do
        local sameRowNode = {}
        for i = 1, #cleaningNodes do
            local node = cleaningNodes[i]
            if node.p_cloumnIndex == iCol then
                sameRowNode[#sameRowNode + 1] = node
            end
        end
        table.sort(
            sameRowNode,
            function(a, b)
                return b.p_rowIndex < a.p_rowIndex
            end
        )

        for i = 1, #sameRowNode do
            sortNode[#sortNode + 1] = sameRowNode[i]
        end
    end
    cleaningNodes = sortNode
    return cleaningNodes
end

function VegasRespinView:getFirstNode()
    local childs = self:getChildren()
    local first = false
    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
            node.m_firstNode = true
            return
        end
    end
end

---获取所有参与结算节点
function VegasRespinView:allPlayIdle()
    local childs = self:getChildren()
    for i = 1, #childs do
        local node = childs[i]
        if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
            if node.m_firstNode == true then
                node:runAnimForeverFun("idle",true,handler(self,self.playNewNodeIdle))
            else
                node:runAnim("idle", true)
            end
        end
    end
end

function VegasRespinView:playNewNodeIdle()
    if self.m_bulingOver == true and #self.m_addNewNode > 0 then
        local childs = self:getChildren()
        for i = 1, #childs do
            local node = childs[i]
            if node:getTag() == self.REPIN_NODE_TAG and self:getPartCleaningNode(node.p_rowIndex, node.p_cloumnIndex) then
                if node.m_firstNode == true then
                    node:runAnimForeverFun("idle",true,handler(self,self.playNewNodeIdle))
                else
                    node:runAnim("idle", true)
                end
            end
        end
        self.m_bulingOver = false
        self.m_addNewNode = {}
    end
end

return VegasRespinView
