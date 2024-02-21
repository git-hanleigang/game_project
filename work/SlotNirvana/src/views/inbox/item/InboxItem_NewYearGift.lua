local InboxItem_baseNoReward = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_NewYearGift = class("InboxItem_NewYearGift", InboxItem_baseNoReward)

function InboxItem_NewYearGift:getCsbName()
    return "InBox/InboxItem_NewYearGift.csb"
end

-- 描述说明
function InboxItem_NewYearGift:getDescStr()
    return "Enter your contact info and address\nfor physical gift delivery!"
end

-- -- 结束时间(单位：秒)
-- function InboxItem_NewYearGift:getExpireTime()
--     local data = G_GetMgr(ACTIVITY_REF.NewYearGift):getData()
--     if data then
--         return data:getExpireAt()
--     end
--     return 0
-- end

-- 倒计时结束回调
function InboxItem_NewYearGift:timeEndCallback()
end

function InboxItem_NewYearGift:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_inbox" then
        local data = G_GetMgr(ACTIVITY_REF.NewYearGift):getData()
        if data then
            local address = data:getAddress()
            if address and address ~= "" then
                G_GetMgr(G_REF.SurveyInGame):showMainLayer(address .. globalData.userRunData.userUdid)
            end
        end
    end
end

return InboxItem_NewYearGift
