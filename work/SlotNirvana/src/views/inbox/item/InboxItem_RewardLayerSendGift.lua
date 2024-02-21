--[[
    邮箱三级弹板
]]
local InboxItem_RewardLayerSendGift = class("InboxItem_RewardLayerSendGift", BaseLayer)

-- function InboxItem_RewardLayerSendGift:initUI(_mailID, _rewardItemData)
--     local isAutoScale = true
--     if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
--         isAutoScale = false
--     end
--     self:createCsbNode("InBox/InboxRewardLayer_SendGift.csb", isAutoScale)
--     util_adaptPortrait(self.m_csbNode)
--     self:initData(_mailID, _rewardItemData)
--     self:initNode()
--     self:initView()

--     self:commonShow(
--         self:findChild("root"),
--         function()
--             if not self.btnEnabledFlag then
--                 self:runCsbAction("idle", true)
--             end
--         end
--     )
-- end

--初始化数据
function InboxItem_RewardLayerSendGift:initDatas(_mailID, _rewardItemData)
    self:setLandscapeCsbName("InBox/InboxRewardLayer_SendGift.csb")
    self.m_mailID = _mailID
    self.m_rewardItemData = _rewardItemData
    self.m_rowItemCount = 5
end

function InboxItem_RewardLayerSendGift:initCsbNodes()
    self.m_addRewardItem = self:findChild("node_list")
    self.m_root = self:findChild("root")
end

function InboxItem_RewardLayerSendGift:onEnter()
    InboxItem_RewardLayerSendGift.super.onEnter(self)
    self:runCsbAction("idle", true)
end

function InboxItem_RewardLayerSendGift:initView()
    --显示道具
    self:checkItemCount()
    self:showItem()
end

function InboxItem_RewardLayerSendGift:showItem()
    --通用道具
    local rewardItems = self.m_rewardItemData
    local count = #rewardItems
    local itemList = {}
    local otherItemList = {}
    if rewardItems and count > 0 then
        for i, v in ipairs(rewardItems) do
            if i <= self.m_rowItemCount then
                table.insert(itemList, v)
            else
                table.insert(otherItemList, v)
            end
        end
    end

    if #itemList > 0 then
        local itemNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.REWARD)
        self.m_addRewardItem:addChild(itemNode)
    end

    if #otherItemList > 0 and self.m_otherAddRewardItem then
        local itemNode = gLobalItemManager:addPropNodeList(otherItemList, ITEM_SIZE_TYPE.REWARD)
        self.m_otherAddRewardItem:addChild(itemNode)
    end
end
-- 检测道具个数，超过5个换行
function InboxItem_RewardLayerSendGift:checkItemCount()
    if #self.m_rewardItemData > 5 then
        self.m_otherAddRewardItem = cc.Node:create()
        self.m_otherAddRewardItem:setPosition(cc.p(0, -70))
        self.m_otherAddRewardItem:addTo(self:findChild("node_center"), 1)
        self.m_addRewardItem:setPosition(cc.p(0, 70))
    end
end

function InboxItem_RewardLayerSendGift:clickFunc(sender)
    local name = sender:getName()
    if self.m_isNotTouch then
        return
    end
    if name == "btn_collect" or name == "btn_close" then
        self.m_isNotTouch = true
        self:closeUI()
    end
end

--移除自身
function InboxItem_RewardLayerSendGift:closeUI()
    if self.isClosed then
        return
    end
    self.isClosed = true
    
    local mailID = self.m_mailID
    local callback = function()
        if CardSysManager:needDropCards("Gift Code") == true then
            CardSysManager:doDropCards("Gift Code", nil)
        end
        
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_GIFT_COLLECT, {id = mailID})
    end
    InboxItem_RewardLayerSendGift.super.closeUI(self, callback)
end

return InboxItem_RewardLayerSendGift
