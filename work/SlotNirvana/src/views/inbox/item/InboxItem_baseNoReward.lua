--[[
    不带奖励类邮件基类
]]

local InboxItem_baseNoReward = class("InboxItem_baseNoReward", util_require("views.inbox.item.InboxItem_base"))

function InboxItem_baseNoReward:getCsbName()
    assert("需设置资源路径")    
end
-- 描述说明
function InboxItem_baseNoReward:getDescStr()
    return ""
end
-- -- 结束时间(单位：秒)
-- function InboxItem_baseNoReward:getExpireTime()
--     return 0
-- end
-- 倒计时结束回调
function InboxItem_baseNoReward:timeEndCallback()
    
end

function InboxItem_baseNoReward:initCsbNodes()
    self.m_lb_time = self:findChild("txt_time")
    self.m_sp_time_bg = self:findChild("sp_time_bg")
    self.m_lb_desc = self:findChild("txt_desc")
    self.m_lb_desc2 = self:findChild("txt_desc1")
    self.m_btn_inbox = self:findChild("btn_inbox")
    self.m_node_button = self:findChild("node_button")

    if self.m_btn_inbox then
        self.m_btn_inbox:setSwallowTouches(false)
    end
end

function InboxItem_baseNoReward:initView()
    -- self:initTime()
    self:initDesc()
end

function InboxItem_baseNoReward:initTime()
    if self.m_lb_time then 
        local expireAt = self.m_mailData.getExpireTime and self.m_mailData:getExpireTime() or 0

        local days = util_leftDays(expireAt, true)
        if days >= 15 then 
            self:hideTime()
        else
            local updateTimeLable = function()
                local strTime,isOver = util_daysdemaining(expireAt, true)
                if isOver then 
                    self.m_lb_time:stopAllActions()
                    self:timeEndCallback()
                    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
                    local collecData = G_GetMgr(G_REF.Inbox):getSysRunData()
                    if collecData then
                        collecData:removeShowMailDataById({self.m_mailData.id})
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
                    -- 更新邮件信息
                    self:removeSelfItem()
                else
                    self.m_lb_time:setString(strTime)
                end
            end
            util_schedule(self.m_lb_time, updateTimeLable, 1)
            updateTimeLable()
        end
    end
end

function InboxItem_baseNoReward:hideTime()
    if self.m_sp_time_bg then 
        self.m_sp_time_bg:setVisible(false)
    end
    if self.m_node_button then 
        self.m_node_button:setPosition(718, 56)
    end
end

function InboxItem_baseNoReward:initDesc()
    local desc1, desc2 = self:getDescStr()
    if self.m_lb_desc then 
        if desc1 then 
            self.m_lb_desc:setString(desc1)
            self:updateLabelSize({label = self.m_lb_desc}, 470)
        else
            self.m_lb_desc:setString("")
        end
    end
    if self.m_lb_desc2 then 
        if desc2 then 
            self.m_lb_desc2:setString(desc2)
            self:updateLabelSize({label = self.m_lb_desc2}, 470)
        else
            self.m_lb_desc2:setString("")
        end
    end
end

function InboxItem_baseNoReward:removeSelfItem()
    if self.m_btn_inbox then 
        self.m_btn_inbox:setTouchEnabled(false)
    end
    
    -- 渐隐效果
    util_fadeOutNode(self, 1, function ()
        if self.m_removeMySelf ~= nil then
            --刷新界面
            self.m_removeMySelf(self)
        end
    end)
end

function InboxItem_baseNoReward:onEnter()
    InboxItem_baseNoReward.super.onEnter(self)
    self:initTime()
end

function InboxItem_baseNoReward:onExit()
    if self.m_lb_time then 
        self.m_lb_time:stopAllActions()
    end
    InboxItem_baseNoReward.super.onExit(self)
end

return InboxItem_baseNoReward
