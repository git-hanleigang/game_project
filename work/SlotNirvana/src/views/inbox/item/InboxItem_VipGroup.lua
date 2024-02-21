--[[--
    vip社群邀请邮件
]]
local InboxItem_VipGroup = class("InboxItem_VipGroup", util_require("views.inbox.item.InboxItem_baseNoReward"))

function InboxItem_VipGroup:getCsbName()
    return "InBox/InboxItem_VipGroup.csb"
end
-- 描述说明
function InboxItem_VipGroup:getDescStr()
    return "JOIN OUR CTS MVP GROUP!\nENJOY TONS OF BENEFITS!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_VipGroup:getExpireTime()
--     local expireAt = self.m_mailData.expireAt
--     local time = 0 
--     if expireAt and expireAt ~= "" and expireAt ~= 0 then 
--         time = tonumber(expireAt) / 1000
--     elseif self.m_mailData.validEnd then 
--         time = util_getymd_time(self.m_mailData.validEnd)
--     end
--     return time
-- end

function InboxItem_VipGroup:showMvpInviteLayer()  -- 添加二级弹板
    local view = util_createView("views.dialogs.MvpInvite")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function InboxItem_VipGroup:initView()
    self:initTime()
    self:initDesc()
end

function InboxItem_VipGroup:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_inbox" then
        self:sendCollectMail()
        -- globalPlatformManager:openFB(globalData.constantData:getFbVipGroupsUrl(), "groups")
        self:showMvpInviteLayer()
    end
end

function InboxItem_VipGroup:sendCollectMail()
    G_GetMgr(G_REF.Inbox):getSysNetwork():collectMail({self.m_mailData.id},
        function(data)
            if not tolua.isnull(self) then 
                self:removeSelfItem()
            end
        end,
        function(data)
        end
    )
end

function InboxItem_VipGroup:removeSelfItem()
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

return InboxItem_VipGroup
