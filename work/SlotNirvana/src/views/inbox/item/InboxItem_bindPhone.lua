---
--island
--2019年3月14日
--InboxItem_bindPhone.lua

-- local BindPhoneCtrl = require("views.BindPhone.BindPhoneCtrl")
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_bindPhone = class("InboxItem_bindPhone", InboxItem_base)

function InboxItem_bindPhone:getCsbName()
    return "InBox/InboxItem_bindPhone.csb"
end

function InboxItem_bindPhone:initView()
    self.m_btnInbox = self:findChild("btn_inbox")
    self.m_btnCollect = self:findChild("btn_collect")

    self:initReward()
    self:initDesc()
    self:updateBindStatus()
end

function InboxItem_bindPhone:initReward()
    -- 金币
    self.m_uiList = {}
    local _data = G_GetMgr(G_REF.BindPhone):getBindData()
    if _data then
        local strCoins = util_formatCoins(_data:getCoins(), 6)
        self.m_lb_coin:setString(strCoins)
        local size = self.m_sp_coin:getContentSize()
        local scale = self.m_sp_coin:getScale()
        table.insert(self.m_uiList, {node = self.m_sp_coin, alignX = -size.width / 2 * scale})
        table.insert(self.m_uiList, {node = self.m_lb_coin, alignX = 5.5})
        table.insert(self.m_uiList, {node = self.m_lb_add, alignX = 3.5})

        local sp = util_createSprite("InBox/ui/fb_sale.png")
        self.m_node_reward:addChild(sp)
        table.insert(self.m_uiList, {node = sp, alignX = 3.5})

        -- local itemDataList = {}
        -- local items = _data:getBindRewardItems()
        -- if items and #items > 0 then
        --     for i, v in ipairs(items) do
        --         itemDataList[#itemDataList + 1] = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
        --     end
        -- end

        -- local itemNode = gLobalItemManager:addPropNodeList(itemDataList, ITEM_SIZE_TYPE.REWARD)
        -- if itemNode then
        --     self.m_node_reward:addChild(itemNode)
        -- end
        -- table.insert(self.m_uiList, {node = itemNode, alignX = 3.5})

        self:alignLeft(self.m_uiList)
    end
end

function InboxItem_bindPhone:initDesc()
    self.m_lb_desc:setString("BIND PHONE NUMBER")
end

function InboxItem_bindPhone:updateBindStatus()
    local isBound = G_GetMgr(G_REF.BindPhone):isBound()

    self.m_btnCollect:setVisible(isBound)
    self.m_btnInbox:setVisible(not isBound)
end

function InboxItem_bindPhone:initTime()
    if self.m_lb_time then
        local _data = G_GetMgr(G_REF.BindPhone):getBindData()
        if _data then
            local expireAt = _data:getExpireAt()
            local time = 0
            if expireAt and expireAt ~= 0 then
                time = expireAt
            end

            local days = util_leftDays(time, true)
            if days >= 15 then
                self:hideTime()
            else
                local updateTimeLable = function()
                    local strTime, isOver = util_daysdemaining(time, true)
                    if isOver then
                        self.m_lb_time:stopAllActions()
                        G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
                        local collecData = G_GetMgr(G_REF.Inbox):getSysRunData()
                        if collecData then
                            collecData:removeBindPhoneMail()
                        end
                        gLobalNoticManager:postNotification(
                            ViewEventType.NOTIFY_REFRESH_MAIL_COUNT,
                            G_GetMgr(G_REF.Inbox):getMailCount()
                        )
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
    end
end

function InboxItem_bindPhone:onEnter()
    InboxItem_bindPhone.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:updateBindStatus()
        end,
        "notify_succ_bindPhone"
    )
end

-- 绑定成功后的逻辑
function InboxItem_bindPhone:bindSuccessFunc()
    -- 绑定成功对话框
    G_GetMgr(G_REF.BindPhone):showBindSuccDialog()
end

function InboxItem_bindPhone:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_inbox" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.BindPhone):showMainLayer(function()
            if not tolua.isnull(self) then
                self:bindSuccessFunc()
            end
        end)
    elseif name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local callback = function()
            -- 显示领奖弹窗
            G_GetMgr(G_REF.BindPhone):showBindRewardLayer()
            if not tolua.isnull(self) then
                self:removeSelfItem()
            end
        end
        G_GetMgr(G_REF.BindPhone):gainBindReward(callback)
    end
end

function InboxItem_bindPhone:getLanguageTableKeyPrefix()
    return nil
end

return InboxItem_bindPhone
