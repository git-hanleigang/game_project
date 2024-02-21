--大地图上的促销节点
local QuestNewGuideNode = class("QuestNewGuideNode", util_require("base.BaseView"))

function QuestNewGuideNode:initDatas(tipId)
    self.m_tipId = tipId
end

function QuestNewGuideNode:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewGuideNode
end

function QuestNewGuideNode:initUI()
    self:createCsbNode(self:getCsbNodePath())

    -- for i=1,5 do
    --     local nodeGuide = self:findChild("node_guide"..i)
    --     nodeGuide:setVisible("t00"..i == self.m_tipId)
    -- end
    -- self:runCsbAction("show", false, nil, 60)
end
function  QuestNewGuideNode:doGuideAct(tipId)
    self.m_tipId = tipId
    for i=1,5 do
        local nodeGuide = self:findChild("node_guide"..i)
        nodeGuide:setVisible("t00"..i == self.m_tipId)
    end
    self:runCsbAction("show", false, nil, 60)
end

return QuestNewGuideNode
