--[[
    
    author: 徐袁
    time: 2021-08-18 10:18:00
]]
local QuestNewHallNode = class("QuestNewHallNode", util_require("views.lobby.HallNode"))

function QuestNewHallNode:initCsbNodes()
    self.m_content = self:findChild("content")
    self.m_content:setVisible(true)
    self.m_content1 = self:findChild("content_0")
    self.m_content1:setVisible(false)
    self.m_lb_more = self:findChild("m_lb_more")
    self.m_flash = self:findChild("Quest_sweep_button_03_1")
end

function QuestNewHallNode:updateDiscount()
    --活动结束时间,大于24小时，直接打开活动主界面
    local _discount = G_GetMgr(ACTIVITY_REF.Quest):getDiscount()
    if _discount > 0 then
        self.m_content:setVisible(false)
        self.m_content1:setVisible(true)

        if self.m_lb_more then
            self.m_lb_more:setString(_discount .. "%")
        end

        if self.m_flash then
            self.m_flash:setVisible(false)
        end
    else
        self.m_content:setVisible(true)
        self.m_content1:setVisible(false)
    end
end

-- 点击是否播点击音效
function QuestNewHallNode:isClickPlaySound()
    return true
end

return QuestNewHallNode
