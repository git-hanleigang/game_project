-- Created by jfwang on 2019-05-21.
-- QuestNewTaskNum
--
local QuestNewTaskNum = class("QuestNewTaskNum", util_require("base.BaseView"))

function QuestNewTaskNum:getCsbNodePath()
    return QUEST_RES_PATH.QuestNewTaskNum
end

function QuestNewTaskNum:initUI(data)
    self:createCsbNode(self:getCsbNodePath())
    self.m_lb_value = self:findChild("BitmapFontLabel_1")
    self:updateView(data)
end

function QuestNewTaskNum:updateView(d)
    if self.m_lb_value ~= nil then
        self.m_lb_value:setString(d)
    end
end

return QuestNewTaskNum