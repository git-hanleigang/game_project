--[[
Author: cxc
Date: 2021-12-08 11:06:52
LastEditTime: 2021-12-08 11:06:52
LastEditors: your name
Description: 新赛季开启邮件提示
FilePath: /SlotNirvana/src/views/inbox/InboxItem_MergeGameNotice.lua
--]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_MergeGameNotice = class("InboxItem_MergeGameNotice", InboxItem_base)

function InboxItem_MergeGameNotice:getCsbName( )
    return "InBox/InboxItem_mergeNotify.csb"
end

function InboxItem_MergeGameNotice:collectMailSuccess()
    -- 弹出界面
    -- 关闭该邮件

    self:removeSelfItem()

    -- 弹出
    G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity):popMergeNewSeasonTipLayer()
end

return InboxItem_MergeGameNotice