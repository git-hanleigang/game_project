--[[
    结算界面
]]
local QuestJackpotRuleLayer = class("QuestJackpotRuleLayer", BaseLayer)

function QuestJackpotRuleLayer:getCsbName()
    return QUEST_RES_PATH.QuestJackpotRuleLayer
end

function QuestJackpotRuleLayer:initCsbNodes()
    self.m_btn_close = self:findChild("btn_close")
    
end

function QuestJackpotRuleLayer:clickFunc(sender)
    if self:isShowing() then
        return
    end
    if self:isHiding() then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end


return QuestJackpotRuleLayer
