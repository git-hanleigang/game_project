--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-01 10:51:56
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-01 10:52:20
FilePath: /SlotNirvana/src/views/inbox/team/InboxItem_TeamBoxAward.lua
Description: 公会点数 结算 邮件
--]]
local InboxItem_TeamBoxAward = class("InboxItem_TeamBoxAward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_TeamBoxAward:initDatas(...)
    InboxItem_TeamBoxAward.super.initDatas(self, ...)

    self.m_boxLevel = 0
    local extra = self.m_mailData.extra
    if extra and extra ~= "" then
        local extraData = cjson.decode(extra)
        local boxLevel = tonumber(extraData.level) or 0
        if boxLevel > 0 then
            self.m_boxLevel = boxLevel 
        end
    end
end

function InboxItem_TeamBoxAward:getCsbName()
    if self.m_boxLevel > 0 then 
        return "InBox/InboxItem_ClubBox.csb"
    end

    return "InBox/InboxItem_ClubBox_defeated.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_TeamBoxAward:getCardSource()
    return {"Clan Points"}
end

-- 邮件 icon
function InboxItem_TeamBoxAward:initIconUI()
    if self.m_boxLevel <= 0 then
        return
    end

    local spBox = self:findChild("sp_Box")
    local iconPath = string.format("InBox/ui_Club/box%d_close.png", self.m_boxLevel)
    local bSuccess = util_changeTexture(spBox, iconPath)
    spBox:setVisible(bSuccess)
end

-- 描述说明
function InboxItem_TeamBoxAward:getDescStr()
    if self.m_boxLevel <= 0 then
        return "YOUR TEAM FAILED TO GET THE KEY"
    end

    return self.m_mailData.title 
end

return InboxItem_TeamBoxAward