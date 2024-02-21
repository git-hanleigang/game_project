--[[
    邮箱二级弹板
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_PageLayerSendGift = class("InboxItem_PageLayerSendGift", BaseLayer)

local TOUCH_TYPE = {
    COLLECT = "collect",
    CLOSE = "close"
}

function InboxItem_PageLayerSendGift:ctor()
    InboxItem_PageLayerSendGift.super.ctor(self)

    self:setLandscapeCsbName("InBox/InboxPageLayer_SendGift.csb")
end

--初始化数据
function InboxItem_PageLayerSendGift:initDatas(_mailData)
    self.m_mailData = _mailData
    self.m_rewardItemData = {}
    self.m_itemData = {}
    self.m_gems = 0
end
function InboxItem_PageLayerSendGift:initCsbNodes()
    self.m_title = self:findChild("lb_title") --标题
    self.m_content = self:findChild("TextField_desc") --说明
    self.m_addRewardItem = self:findChild("Node_Reward_Item")
end
--初始化不同奖励类型UI self.m_inboxType
function InboxItem_PageLayerSendGift:initView()
    self:setDesc()
    --显示道具
    self:showItem()
end

function InboxItem_PageLayerSendGift:setDesc()
    self.m_title:setString(self.m_mailData.title)
    -- local str = "Dear player,\n as the new Season of the Album kicks off,\n GOD STATUE resets to the very beginning. GOD STATUE resets to the very beginning. GOD STATUE Chips in the last round have turned to Coin rewards for you. Please collect and enjoy!"
    local str = self.m_mailData.content
    util_AutoLine(self.m_content, str, 850, true)
end

function InboxItem_PageLayerSendGift:showItem(coinsVisible)
    --金币道具
    local coins = tonumber(self.m_mailData.awards.coins)
    if coins and coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        itemData:setTempData({p_limit = 3})
        local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.TOP)
        itemNode:setScale(1.3)
        local dis = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
        local info = {node = itemNode, size = cc.size(dis, dis), alignX = 2, anchor = cc.p(0.5, 0.5)}
        self.m_addRewardItem:addChild(itemNode)
        table.insert(self.m_itemData, info)
    end

    --通用道具
    local rewardItems = self.m_mailData.awards.items
    local count = #rewardItems
    if rewardItems and count > 0 then
        local itemList = self:mergeItems(rewardItems)
        for i, v in ipairs(itemList) do
            local itemData = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            if v.p_icon ~= "Gem" then 
                table.insert(self.m_rewardItemData, itemData)
            end
            local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.TOP)
            if itemNode then
                itemNode:setScale(1.3)
                local dis = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
                local info = {node = itemNode, size = cc.size(dis, dis), alignX = 2, anchor = cc.p(0.5, 0.5)}
                self.m_addRewardItem:addChild(itemNode)
                table.insert(self.m_itemData, info)
            end
        end
    end

    if #self.m_itemData > 0 then
        self.m_itemData[1].alignX = 0
        util_alignCenter(self.m_itemData, nil, 900)
    end
end

function InboxItem_PageLayerSendGift:mergeItems(_data)
    local items = {}
    local temp = {}
    local buff = {}
    for i,v in ipairs(_data) do
        local tempData = ShopItem:create()
        tempData:parseData(v)
        local key = tempData.p_icon
        if tempData.p_type == "Buff" then 
            table.insert(buff, tempData)
        else
            local itemInfo = temp[key]
            if itemInfo then 
                itemInfo.p_num = itemInfo.p_num + tempData.p_num
            else
                temp[key] = tempData
            end
        end
        -- 砖石
        if key == "Gem" then 
            self.m_gems = self.m_gems + tempData.p_num
        end
    end
    for i,v in pairs(temp) do
        table.insert(items, v)
    end
    for i,v in pairs(buff) do
        table.insert(items, v)
    end
    return items
end

function InboxItem_PageLayerSendGift:clickFunc(sender)
    local name = sender:getName()
    if self.m_isNotTouch then
        return
    end
    if name == "btn_collect" then
        self.m_touchBntType = TOUCH_TYPE.COLLECT
        self.m_isNotTouch = true
        self:sendCollectMail()
    else
        self.m_touchBntType = TOUCH_TYPE.CLOSE
        self:closeUI()
    end
end

-- 领取请求
function InboxItem_PageLayerSendGift:sendCollectMail()
    local id = {}
    id[#id + 1] = self.m_mailData.id

    self.m_isCollectMailData = false
    G_GetMgr(G_REF.Inbox):getSysNetwork():collectMail(
        id,
        function(data)
            self.m_isCollectMailData = true
            if self.collectMailSuccess then
                self:collectMailSuccess()
            end
        end,
        function(data)
            self.m_isCollectMailData = true
            if self.collectMailFailed then
                self:collectMailFailed()
            end
        end
    )
end

function InboxItem_PageLayerSendGift:collectMailSuccess() 
    --第二货币消息
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    self:flyBonusGameCoins()
end

function InboxItem_PageLayerSendGift:collectMailFailed()
    --领取失败
    gLobalViewManager:showReConnect()
end

--飞金币
function InboxItem_PageLayerSendGift:flyBonusGameCoins()
    -- local coins = tonumber(self.m_mailData.awards.coins)
    -- if coins and coins > 0 then 
    --     local endPos = globalData.flyCoinsEndPos
    --     local btnCollect = self:findChild("btn_collect")
    --     local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    --     local baseCoins = globalData.topUICoinCount
    --     local rewardCoins = coins
    --     gLobalViewManager:pubPlayFlyCoin(
    --         startPos,
    --         endPos,
    --         baseCoins,
    --         rewardCoins,
    --         function()
    --             self:closeUI()
    --         end
    --     )
    -- else
    --     self:closeUI()
    -- end
    local coins = tonumber(self.m_mailData.awards.coins)
    local flyList = {}
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    if coins and coins > 0 then
        table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
    end
    if self.m_gems and self.m_gems > 0 then 
        table.insert(flyList, {cuyType = FlyType.Gem, addValue = self.m_gems, startPos = startPos})
    end

    if #flyList > 0 then 
        if G_GetMgr(G_REF.Currency) then 
            G_GetMgr(G_REF.Currency):playFlyCurrency(flyList, function()
                if not tolua.isnull(self) then 
                    self:closeUI()
                end
             end)
        end
    else
        self:closeUI()
    end
end

--移除自身
function InboxItem_PageLayerSendGift:closeUI()
    if self.isClosed then
        return
    end
    self.isClosed = true

    local callback = function()
        if self.m_touchBntType then
            local mailID = self.m_mailData.id
            local rewardItemData = clone(self.m_rewardItemData)
            if self.m_touchBntType == TOUCH_TYPE.COLLECT then
                if #rewardItemData > 0 then
                    local view = util_createView("views.inbox.item.InboxItem_RewardLayerSendGift", mailID, rewardItemData)
                    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_GIFT_COLLECT, {id = mailID})
                end
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_GIFT_END, {id = mailID})
            end
        end
    end
    InboxItem_PageLayerSendGift.super.closeUI(self, callback)
end

return InboxItem_PageLayerSendGift
