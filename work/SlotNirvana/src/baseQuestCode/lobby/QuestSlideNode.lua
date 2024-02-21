--[[
    
    author: 徐袁
    time: 2021-08-18 10:18:22
]]
local QuestSlideNode = class("QuestSlideNode", util_require("views.lobby.SlideNode"))

function QuestSlideNode:initCsbNodes()
    self.m_content = self:findChild("content")
    if self.m_content then
        self.m_content:setVisible(true)
    end
    self.m_content1 = self:findChild("content_0")
    if self.m_content1 then
        self.m_content1:setVisible(false)
    end
    self.m_lb_more = self:findChild("m_lb_more")
    self.m_lb_lastTime = self:findChild("m_lb_lastTime")
end

function QuestSlideNode:onEnter()
    QuestSlideNode.super.onEnter(self)
    schedule(
        self,
        function()
            self:updateDiscount()
        end,
        1
    )
end

function QuestSlideNode:updateView()
    if self.m_data == nil then
        return
    end
end

function QuestSlideNode:updateDiscount()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        local expireTime = questConfig:getLeftTime()
        if expireTime <= questConfig.p_questExtraPrize then
            if self.m_content then
                self.m_content:setVisible(false)
            end
            if self.m_content1 then
                self.m_content1:setVisible(true)
            end

            if self.m_lb_more then
                self.m_lb_more:setString(questConfig.p_discount .. "%")
            end

            if self.m_lb_lastTime then
                self.m_lb_lastTime:setString(util_count_down_str(expireTime))
            end
        end
    end
end

return QuestSlideNode
