--[[--
    拉新
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_base")
local InboxItem_Invite = class("InboxItem_Invite", InboxItem_base)

function InboxItem_Invite:getCsbName()
    return "InBox/InboxItem_Invite.csb"
end

function InboxItem_Invite:initView()
    self:updataTime()
    self.m_labelContent = self:findChild("Text_1")
    if self.m_mailData.count.id then
       local name = self:getName(self.m_mailData.count.id)
       local str = "PLAYER "..name.." was successfully invited! Check your rewards now."
       self.m_labelContent:setString(str)
    end
end

function InboxItem_Invite:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_collect" then
        if G_GetMgr(G_REF.Inbox).sendFireBaseClickLog then
            G_GetMgr(G_REF.Inbox):sendFireBaseClickLog()
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local data = G_GetMgr(G_REF.Invite):getData()
        if data == nil then
            return
        end
        G_GetMgr(G_REF.Invite):showInviterLayer("btn_email")
        local mail_data = data:getMailCount()
        for i,v in ipairs(mail_data) do
            v.collect = 1
        end
        gLobalDataManager:setStringByField("invite_Mail",cjson.encode(mail_data))
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
        
    end
    
end

function InboxItem_Invite:updataTime()
    self.lb_daojishi = self:findChild("lb_daojishi")
    local endTime = 0
    if string.len(self.m_mailData.count.time) > 11 then
        endTime = math.floor(self.m_mailData.count.time/1000)
    else
        endTime = math.floor(self.m_mailData.count.time)
    end
    local expireTime = endTime - util_getCurrnetTime()
    self.m_expireTime = expireTime
    local timeStr = util_count_down_str(expireTime)
    self.lb_daojishi:setString(timeStr)
    self:clearSchedule()
    self.m_schedu =
        schedule(
        self,
        function()
            self.m_expireTime = self.m_expireTime - 1
            if self.m_expireTime <= 0 then
                self:clearSchedule()
            end
            -- 刷新倒计时
            local timeStr = util_count_down_str(self.m_expireTime)
            self.lb_daojishi:setString(timeStr)
        end,
        1
    )
end

function InboxItem_Invite:clearSchedule()
    if self.m_schedu then
        self:stopAction(self.m_schedu)
        self.m_schedu = nil
    end
end

function InboxItem_Invite:getName(str)
    if not str then
        return
    end
    if string.len(str) > 6 then
        str = string.sub(str,1,6)
        str = str.."..."
    end
    return str
end

return InboxItem_Invite