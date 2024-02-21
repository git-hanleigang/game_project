--[[--
    4连折扣券
]]
local InboxItem_ticket = class("InboxItem_ticket", util_require("views.inbox.item.InboxItem_base"))

function InboxItem_ticket:getCsbName()
    return "InBox/InboxItem_coupon.csb" --默认皮肤
end

function InboxItem_ticket:initData(mailData, callFun, addTouchLayer, removeTouchLayer, mainClase)
    self.m_addTouchLayer = addTouchLayer
    self.m_removeTouchLayer = removeTouchLayer
    self.m_removeMySelf = callFun
    --界面显示
    self.m_mailData = mailData
    self.mainClase = mainClase

    if self.m_schedu then
        self:stopAction(self.m_schedu)
        self.m_schedu = nil
    end
    self.m_schedu =
        schedule(
        self,
        function()
            self:updateTime()
        end,
        0.5
    )

    self:updateCustomUI()
    self:updateTime()
end

function InboxItem_ticket:updateCustomUI()
end

function InboxItem_ticket:updateTime()
    local config = globalData.itemsConfig:getCommonTicket(self.m_mailData.ticketId)
    if not config or not config:checkEffective() then --无数据或者过期了
        if self.m_schedu then
            self:stopAction(self.m_schedu)
            self.m_schedu = nil
        end
        self:hideTicket()
        return
    end
    local m_lb_more = self:findChild("m_lb_more")
    if m_lb_more then
        if config.p_num then
            m_lb_more:setString(config.p_num .. "%")
        end
    end

    local expireTime = tonumber(config.p_expireAt) / 1000 - util_getCurrnetTime()
    local m_lb_time = self:findChild("m_lb_time")
    if m_lb_time then
        local timeStr = util_daysdemaining1(expireTime)
        m_lb_time:setString(timeStr)
    end
end

function InboxItem_ticket:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_collect" then
        -- if G_GetMgr(G_REF.Inbox).sendFireBaseClickLog then
        --     G_GetMgr(G_REF.Inbox):sendFireBaseClickLog()
        -- end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendCollectMail()
    end
end

function InboxItem_ticket:sendCollectMail()
    gLobalViewManager:addLoadingAnimaDelay()
    gLobalSendDataManager:getNetWorkFeature():sendUseTicket(
        self.m_mailData.ticketId,
        function(target, resData)
            gLobalViewManager:removeLoadingAnima()
            if not tolua.isnull(self) then
                if self.collectMailSuccess then
                    self:collectMailSuccess()
                end
                -- 折扣券通用功能，使用后进入商城，关闭邮件
                if self.openShop then
                    self:openShop()
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
            end
        end,
        function(target, errorCode)
            gLobalViewManager:removeLoadingAnima()
            if not tolua.isnull(self) and self.collectMailFail then
                self:collectMailFail()
            end
            if errorCode and errorCode == 10 then
                return
            end
            gLobalViewManager:showReConnect()
        end
    )
end

function InboxItem_ticket:openShop()
    G_GetMgr(G_REF.Shop):showMainLayer()
end

function InboxItem_ticket:collectMailSuccess()
end

function InboxItem_ticket:collectMailFail()
end

function InboxItem_ticket:hideTicket()
    if self.isHide then
        return
    end
    self.isHide = true
    G_GetMgr(G_REF.Inbox):getDataMessage(
        function()
            if self.removeSelfItem ~= nil then
                self:removeSelfItem()
            end
        end,
        function()
            self.isHide = false
        end
    )
end

function InboxItem_ticket:removeSelfItem()
    if self.m_isRemoveSelf then
        return
    end
    self.m_isRemoveSelf = true
    self.mainClase.m_isRefreshCount = self.mainClase.m_isRefreshCount - 1

    local btn_collect = self:findChild("btn_collect")
    btn_collect:setTouchEnabled(false)
    -- 渐隐效果
    local item_bg = self:findChild("item_bg")
    util_fadeOutNode(item_bg, 1, function ()
        --刷新界面
        self.m_removeMySelf(self)
    end)
    -- local actionList = {}
    -- actionList[#actionList + 1] = cc.FadeOut:create(1)
    -- actionList[#actionList + 1] =
    --     cc.CallFunc:create(
    --     function()
    --     end
    -- )
    -- local seq = cc.Sequence:create(actionList)
    -- item_bg:runAction(seq) --???  3 好像是设置动画 但是设置了怎样的动画不太理解
end

function InboxItem_ticket:onKeyBack()
end

function InboxItem_ticket:onEnter()
end

function InboxItem_ticket:onExit()
    if self.m_schedu then
        self:stopAction(self.m_schedu)
        self.m_schedu = nil
    end
end

return InboxItem_ticket
