--[[
    优惠劵类邮件基类
]]

local InboxItem_baseCoupon = class("InboxItem_baseCoupon", util_require("views.inbox.item.InboxItem_base"))

InboxItem_baseCoupon.CSB_TYPE = {
    ["coin"] = "CommonButton/csb_inbox/Common_couponNew_coin.csb",
    ["gem"] = "CommonButton/csb_inbox/Common_couponNew_gem.csb",
    ["piggy"] = "CommonButton/csb_inbox/Common_couponNew_piggy.csb"
}

InboxItem_baseCoupon.DESC = {
    ["coin"] = {all = "ON ALL COIN STORE PACKAGES", part = "ON PART OF COIN STORE PACKAGES"},
    ["gem"] = {all = "ON ALL GEM STORE PACKAGES", part = "ON PART OF GEM STORE PACKAGES"},
    ["piggy"] = {all = "ONLY AVAILABLE FOR PIGGY BANK", part = "ONLY AVAILABLE FOR PIGGY BANK"},
}

function InboxItem_baseCoupon:initDatasFinish()
    local mType = self.m_mailData:getType()
    local isNetMail = self.m_mailData:isNetMail()
    local cfg = InboxConfig.getNameMapConfig(mType, isNetMail)
    self.m_info = cfg.info
end

function InboxItem_baseCoupon:getCsbName()
    return self.CSB_TYPE[self.m_info.type]
end

function InboxItem_baseCoupon:initCsbNodes()
    self.m_lb_time = self:findChild("txt_time")
    self.m_lb_desc = self:findChild("txt_desc")
    self.m_lb_percent = self:findChild("lb_percent")
    self.m_btn_inbox = self:findChild("btn_inbox")

    if self.m_btn_inbox then
        self.m_btn_inbox:setSwallowTouches(false)
    end
end

function InboxItem_baseCoupon:initView()
    local config = globalData.itemsConfig:getCommonTicket(self.m_mailData.ticketId)
    if not config or not config:checkEffective() then --无数据或者过期了
        self:removeSelfItem()
        return
    end

    self:initPercent(config)
    self:initTime(config)
    self:initDesc()
end

function InboxItem_baseCoupon:initPercent(_config)
    if _config.p_num then
        self.m_lb_percent:setString(_config.p_num .. "% MORE")
    end
end

function InboxItem_baseCoupon:initTime(_config)
    if self.m_lb_time then 
        local expireAt = tonumber(_config.p_expireAt) / 1000
        local updateTimeLable = function()
            local strTime,isOver = util_daysdemaining(expireAt, true)
            if isOver then 
                self.m_lb_time:stopAllActions()
                G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
                local collecData = G_GetMgr(G_REF.Inbox):getSysRunData()
                if collecData then
                    collecData:removeShowMailDataById({self.m_mailData.id})
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
                -- 更新邮件信息
                self:removeSelfItem()
            else
                self.m_lb_time:setString(strTime)
            end
        end
        util_schedule(self.m_lb_time, updateTimeLable, 1)
        updateTimeLable()
    end
end

function InboxItem_baseCoupon:initDesc()
    local desc = self.DESC[self.m_info.type][self.m_info.scope] or ""
    self.m_lb_desc:setString(desc)
end

function InboxItem_baseCoupon:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    if name == "btn_inbox" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
        self:sendCollectMail()
    end
end

function InboxItem_baseCoupon:sendCollectMail()
    gLobalViewManager:addLoadingAnimaDelay()
    gLobalSendDataManager:getNetWorkFeature():sendUseTicket(
        self.m_mailData.ticketId,
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

function InboxItem_baseCoupon:openShop()
    if self.m_info.type == "coin" then 
        G_GetMgr(G_REF.Shop):showMainLayer()
    elseif self.m_info.type == "gem" then 
        G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
    elseif self.m_info.type == "piggy" then
        G_GetMgr(G_REF.PiggyBank):showMainLayer()
    end
end

function InboxItem_baseCoupon:removeSelfItem()
    self.m_btn_inbox:setTouchEnabled(false)

    -- 渐隐效果
    util_fadeOutNode(self, 1, function ()
        if self.m_removeMySelf ~= nil then
            --刷新界面
            self.m_removeMySelf(self)
        end
    end)
end

function InboxItem_baseCoupon:getLanguageTableKeyPrefix()
    return "InboxItem_coupon"
end

function InboxItem_baseCoupon:onExitStart()
    InboxItem_baseCoupon.super.onExitStart(self)
    if not tolua.isnull(self.m_lb_time) then
        self.m_lb_time:stopAllActions()
    end
end

function InboxItem_baseCoupon:onExit()
    InboxItem_baseCoupon.super.onExit(self)
end

return InboxItem_baseCoupon
