--[[
    神秘宝箱系统
]]
local InboxItem_BoxSystem = class("InboxItem_BoxSystem", util_require("views.inbox.item.InboxItem_baseNoReward"))

function InboxItem_BoxSystem:initDatasFinish()
    self.m_groupData = self.m_mailData.groupData
end

function InboxItem_BoxSystem:initView()
    InboxItem_BoxSystem.super.initView(self)
    self:setButtonLabelContent("btn_inbox", "COLLECT")
    self:initIcon()
end

function InboxItem_BoxSystem:getCsbName()
    return "InBox/InboxItem_BoxSystem.csb"
end

function InboxItem_BoxSystem:initIcon()
    local sp_icon = self:findChild("sp_icon")
    if sp_icon then
        local icon = self.m_groupData:getIcon()
        util_changeTexture(sp_icon, "PBRes/CommonItemRes/icon/" .. icon .. ".png")
    end
end

-- 描述说明
function InboxItem_BoxSystem:getDescStr()
    local num = self.m_groupData:getNum()
    local activityName = self.m_groupData:getActivityName()
    local icon = self.m_groupData:getIcon()
    local desKey = activityName .. "|" .. icon
    local describe = BoxSystemConfig.inboxDescribe[desKey]
    if describe then
        return string.format(describe, "" .. num)
    end
    return "HERE'S YOUR REWARD"
end

function InboxItem_BoxSystem:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local name = sender:getName()
    if name == "btn_inbox" then
        self:collectBonus()
    end
end

function InboxItem_BoxSystem:collectBonus()
    local overFunc = function()
        local num = self.m_groupData:getNum()
        if num > 0 then
            self:initDesc()
        else
            self:removeSelfItem()
        end
    end
    G_GetMgr(G_REF.BoxSystem):showBoxCollectLayer(self.m_groupData:getGroupName(), overFunc, 1)
end

function InboxItem_BoxSystem:onEnter()
    InboxItem_BoxSystem.super.onEnter(self)
    -- 宝箱开启
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params then
                local groupName = self.m_groupData:getGroupName()
                self.m_groupData = G_GetMgr(G_REF.BoxSystem):getBoxListByGroup(groupName)
            end
        end,
        ViewEventType.NOTIFY_BOX_SYSTEM_COLLECTED
    )
end

return InboxItem_BoxSystem
