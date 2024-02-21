--[[--
    调查问卷
]]
local InboxItem_Questionnaire = class("InboxItem_Questionnaire", util_require("views.inbox.item.InboxItem_baseNoReward"))

function InboxItem_Questionnaire:getCsbName()
    return "InBox/InboxItem_Questionnaire.csb"
end
-- 描述说明
function InboxItem_Questionnaire:getDescStr()
    return "HELP US HELP YOU!\nTAKE OUR SURVEY THEN COME BACK\nFOR REWARDS!"
end
-- -- 结束时间(单位：秒)
-- function InboxItem_Questionnaire:getExpireTime()
--     local queData = G_GetActivityDataByRef(ACTIVITY_REF.Questionnaire)
--     if queData then
--         return tonumber(queData:getExpireAt())
--     else
--         return 0
--     end
-- end

function InboxItem_Questionnaire:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_inbox" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        local queData = G_GetActivityDataByRef(ACTIVITY_REF.Questionnaire)
        if queData then
            gLobalDataManager:setBoolByField(queData:getClientCacheKey(), true)
            -- 跳转网页
            cc.Application:getInstance():openURL(globalData.constantData.QUESTIONNAIRE_URL)
        else
            release_print(" ------ Questionnaire, click btn_collect, queData is nil ------ ")
        end
        -- 界面关闭
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
    end
end

return InboxItem_Questionnaire
