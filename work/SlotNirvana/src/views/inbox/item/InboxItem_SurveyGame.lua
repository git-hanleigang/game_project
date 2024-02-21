--[[--
    调查问卷
]]
local InboxItem_SurveyGame = class("InboxItem_SurveyGame", util_require("views.inbox.item.InboxItem_baseNoReward"))

function InboxItem_SurveyGame:getCsbName()
    return "InBox/InboxItem_SurveyGame.csb"
end
-- 描述说明
function InboxItem_SurveyGame:getDescStr()
    return "TAKE OUR SURVEY THEN COME BACK\nFOR REWARDS!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_SurveyGame:getExpireTime()
--     local Data = G_GetActivityDataByRef(ACTIVITY_REF.SurveyinGame)
--     if Data then
--         return tonumber(Data:getExpireAt())
--     else
--         return 0
--     end
-- end

function InboxItem_SurveyGame:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_inbox" then
        G_GetMgr(ACTIVITY_REF.SurveyinGame):sendCollectMessage()
    end
end

function InboxItem_SurveyGame:onEnter()
    InboxItem_SurveyGame.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self, function(target, params)
        G_GetMgr(ACTIVITY_REF.SurveyinGame):showSurveyinLayer(params)
        -- 界面关闭
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
    end, ViewEventType.NOTIFY_ACTIVITY_SURVEYIN_GAME_COLLECT)
end

return InboxItem_SurveyGame
