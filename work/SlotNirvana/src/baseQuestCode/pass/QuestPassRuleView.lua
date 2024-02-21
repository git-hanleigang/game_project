--[[
    Quest Pass
]]

local QuestPassRuleView = class("QuestPassRuleView", BaseLayer)

function QuestPassRuleView:ctor()
    QuestPassRuleView.super.ctor(self)

    self:setLandscapeCsbName(QUEST_RES_PATH.QuestPassRuleView)
    self:setExtendData("QuestPassRuleView")
end

function QuestPassRuleView:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return QuestPassRuleView