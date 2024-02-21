local InboxItem_spinBonusReward = class("InboxItem_spinBonusReward", util_require("views.inbox.item.InboxItem_baseNoReward"))

function InboxItem_spinBonusReward:getCsbName()
    return "InBox/InboxItem_spinBonusReward.csb"
end
-- 描述说明
function InboxItem_spinBonusReward:getDescStr()
    if globalData.spinBonusData then
        return "Spin Bouns!", "Your progress:  " .. (globalData.spinBonusData.p_current.."/"..globalData.spinBonusData.p_target)
    else
        return "Spin Bouns!", ""
    end
end
-- -- 结束时间(单位：秒)
-- function InboxItem_spinBonusReward:getExpireTime()
--     if globalData.spinBonusData and globalData.spinBonusData:isTaskOpen() then
--         return tonumber(globalData.spinBonusData.p_taskExpireAt / 1000)
--     else
--         return 0
--     end
-- end

function InboxItem_spinBonusReward:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_inbox" then
        G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
        if globalData.spinBonusData and globalData.spinBonusData:isTaskOpen() then
            local view = util_createFindView("Activity/Activity_SpinBonus",nil,"InboxUi")
            if view ~= nil then
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(view,name,DotUrlType.UrlName,false)
                end
                gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
        elseif self.removeSelfItem ~= nil then
            self.removeSelfItem()
        end
    end
end

return  InboxItem_spinBonusReward