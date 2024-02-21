--[[
    活动任务邮件
]]

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_blastTask = class("InboxItem_blastTask", InboxItem_base)

-- 如果有掉卡，在这里设置来源
function InboxItem_blastTask:getCardSource()
    return {"Carnival Mission"}
end
-- 描述说明
function InboxItem_blastTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

function InboxItem_blastTask:getCsbName()
    local csbName = "InBox/InboxItem_blastTask.csb"
    return csbName
end

function InboxItem_blastTask:initView()
    local extra = self.m_mailData.extra
    local themeName = "Activity_Blast"
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --主题名
        themeName = extraData.theme
    end
    local mgr = G_GetMgr(ACTIVITY_REF.Blast)
    if mgr and mgr:getRunningData() then
        themeName = mgr:getConfig():getThemeName() 
    end
    local pngPath = "InBox/ui_blastTask/"..themeName.."Mission.png"
    local sp_icon = self:findChild("sp_icon")
    if sp_icon then
        util_changeTexture(sp_icon,pngPath)
    end
    InboxItem_blastTask.super.initView(self)
end
 
return InboxItem_blastTask
