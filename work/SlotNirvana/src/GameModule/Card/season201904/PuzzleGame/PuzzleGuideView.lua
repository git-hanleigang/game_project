--[[--
    小游戏引导气泡界面
]]
local BaseView = util_require("base.BaseView")
local PuzzleGuideView = class("PuzzleGuideView", BaseView)
function PuzzleGuideView:initUI()

    self:createCsbNode(CardResConfig.PuzzleGameGuideRes)

    local nodes = {
        {node = "Node_welcome"}, 
        {node = "Node_freepick", text = "lb_freepick"}, 
        {node = "Node_haveTry"}, 
        {node = "Node_collect"}, 
        {node = "Node_Reset"}, 
        {node = "Node_useRubies"}, 
        {node = "Node_extrapick", text = "lb_extra_pick"},
    }

    self.m_nodeList = {}
    for i=1,#nodes do
        self.m_nodeList[i] = {}
        self.m_nodeList[i].node = self:findChild(nodes[i].node)
        if nodes[i].text then
            self.m_nodeList[i].text = self:findChild(nodes[i].text)
        end
    end
end

function PuzzleGuideView:updateUI(index, text)
    self.m_index = index
    self.m_text = text

    for i=1,#self.m_nodeList do
        local nodes = self.m_nodeList[i]
        nodes.node:setVisible(i == self.m_index)

        if i == self.m_index and nodes.text and self.m_text then
            -- 必须要传参数text哦
            nodes.text:setString(self.m_text)
        end
    end

end


return PuzzleGuideView
-- return CashPuzzleBubble