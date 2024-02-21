--[[
    des: 邮件中小猪商店的新手折扣邮件
    author:{author}
    time:2019-09-03 16:04:12
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_base")
local InboxItem_piggyNoviceDiscount = class("InboxItem_piggyNoviceDiscount", InboxItem_base)

function InboxItem_piggyNoviceDiscount:getCsbName()
    return "InBox/InboxItem_piggyNoviceDiscount.csb"
end

function InboxItem_piggyNoviceDiscount:initView()
    self.m_discountNode = self:findChild("discount")
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if piggyBankData then
        self.m_discountNode:setString(piggyBankData:getNoviceFirstDiscount() .. "%")
    end
end

function InboxItem_piggyNoviceDiscount:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_readme" then
        -- if G_GetMgr(G_REF.Inbox).sendFireBaseClickLog then
        --     G_GetMgr(G_REF.Inbox):sendFireBaseClickLog()
        -- end
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.mainClase.m_isTouchOneItem then
            return
        end
        self.mainClase.m_isTouchOneItem = true
        -- 关闭邮件
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
        -- 打开小猪商店
        local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
        if piggyBankData and piggyBankData:checkInNoviceDiscount() then
            G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(view, name, DotUrlType.UrlName, false)
                end
            end)             
        end
    end
end

return InboxItem_piggyNoviceDiscount
