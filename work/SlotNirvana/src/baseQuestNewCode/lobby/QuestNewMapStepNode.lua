--金币滚动节点
local QuestNewMapStepNode = class("QuestNewMapStepNode", util_require("base.BaseView"))

function QuestNewMapStepNode:initDatas(data)
    self.m_type = data.type -- cell box wheel
    self.m_index = data.index
    self.m_unlock = data.unlock
end

function QuestNewMapStepNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewMapStepNode 
end

function QuestNewMapStepNode:initUI()
    self:createCsbNode(self:getCsbName())
    --self:runCsbAction("idle", true)
    self:initView()
end

function QuestNewMapStepNode:refreshByData(data)
    self.m_data = data
    self:initView()
end

function QuestNewMapStepNode:initCsbNodes()
    self.m_cellNodeMap = {}
    for i=2,8 do
        local node = self:findChild("Node_"..i) 
        if node then
            self.m_cellNodeMap["cell" ..i] = node
            node:setVisible(false)
        end
    end

    for i=2,8 do
        local node_box = self:findChild("Node_box_"..i) 
        if node_box then
            self.m_cellNodeMap["box" ..i] = node_box
            node_box:setVisible(false)
        end
    end

    local node_wheel = self:findChild("Node_wheel") 
    if node_wheel then
        self.m_cellNodeMap["wheel8"] = node_wheel
        node_wheel:setVisible(false)
    end
end

function QuestNewMapStepNode:initView()
    local node = self.m_cellNodeMap[self.m_type ..self.m_index]
    if node then
        node:setVisible(true)
    end
    if self.m_unlock then
        self:runCsbAction("idle2", false)
    else
        self:runCsbAction("idle", false)
    end
end

function QuestNewMapStepNode:doStepAct(callFun)
    self:runCsbAction("start", false,function ()
        self:runCsbAction("idle2", false)
        if callFun then
            callFun()
        end
    end)
end

function QuestNewMapStepNode:addBubble()
    if not self.m_bubbleNode then
        self.m_bubbleNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapBoxBubbleNode, {rewardData = self.m_data})
        self.m_bubbleNode:setScale(1.5)
        self.m_Node_qipao:addChild(self.m_bubbleNode,2000)
    end
end

return QuestNewMapStepNode
