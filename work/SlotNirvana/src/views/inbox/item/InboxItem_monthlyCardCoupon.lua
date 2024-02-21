--[[
    月卡优惠券
]]

local InboxItem_baseCoupon = util_require("views.inbox.item.InboxItem_baseCoupon")
local InboxItem_monthlyCardCoupon = class("InboxItem_monthlyCardCoupon", InboxItem_baseCoupon)

InboxItem_monthlyCardCoupon.CSB_TYPE = {
    coin = "InBox/InboxItem_MonthlyCard.csb",
    gem = "CommonButton/csb_inbox/Common_coupon_gem.csb",
    piggy = "CommonButton/csb_inbox/Common_coupon_piggy.csb"
}

function InboxItem_monthlyCardCoupon:initView()
    local config = globalData.itemsConfig:getCommonTicket(self.m_mailData.ticketIdList[1])
    if not config or not config:checkEffective() then --无数据或者过期了
        self:removeSelfItem()
        return
    end

    self:initPercent(config)
    self:initTime(config)
    self:initDesc()
    self:iniTicketsNum()
end

function InboxItem_monthlyCardCoupon:iniTicketsNum()
    local descNum = self:findChild("lb_num")
    if descNum then
        descNum:setString("X" .. #self.m_mailData.ticketIdList)
    end
end

function InboxItem_monthlyCardCoupon:sendCollectMail()
    gLobalViewManager:addLoadingAnimaDelay()
    gLobalSendDataManager:getNetWorkFeature():sendUseTicket(
        self.m_mailData.ticketIdList[1],
        function(target, resData)
            gLobalViewManager:removeLoadingAnima()
            if not tolua.isnull(self) then
                -- 折扣券通用功能，使用后进入商城，关闭邮件
                self:openShop()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
            end
        end,
        function(target, errorCode)
            gLobalViewManager:removeLoadingAnima()
            if errorCode and errorCode == 10 then
                return
            end
            gLobalViewManager:showReConnect()
        end
    )
end

return InboxItem_monthlyCardCoupon
