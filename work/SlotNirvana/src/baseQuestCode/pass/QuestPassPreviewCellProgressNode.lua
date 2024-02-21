--[[
]]
local QuestPassPreviewCellProgressNode = class("QuestPassPreviewCellProgressNode", BaseView)

function QuestPassPreviewCellProgressNode:getCsbName()
    return QUEST_RES_PATH.QuestPassPreviewCellNode_Progress
end

function QuestPassPreviewCellProgressNode:initCsbNodes()
    self.m_lbNum = self:findChild("lb_desc")
    self.m_pro = self:findChild("bar_progress")
end

function QuestPassPreviewCellProgressNode:initUI()
    QuestPassPreviewCellProgressNode.super.initUI(self)
end

function QuestPassPreviewCellProgressNode:updateProgress(_cur, _max)
    if _cur ~= nil and _max ~= nil and _max > 0 then
        self.m_lbNum:setString(_cur.."/".._max)
        local percent = math.floor(_cur / _max * 100)
        self.m_pro:setPercent(percent)
    end
end

return QuestPassPreviewCellProgressNode
