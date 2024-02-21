--[[
    活动任务邮件
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_diningRoomTask = class("InboxItem_diningRoomTask", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_diningRoomTask:getCsbName( )
    return "InBox/InboxItem_diningRoomTask.csb"
end

function InboxItem_diningRoomTask:initView()
    self.m_rewardUIList = {}
    local awards = self.m_mailData.awards
    self.m_coins = tonumber(awards.coins)
    self:initNode()
    self:updateCoinNum(self.m_coins)
    self:initItems(awards)
    self:checkItems()
end

--初始化节点
function InboxItem_diningRoomTask:initNode()
    self.m_sp_coin = self:findChild("sprite_coin")
    self.m_lb_coins = self:findChild("label_coin")
    self.m_coinNode = self:findChild("coinNode")
    self.m_addNode  = self:findChild("add")
    self.m_notCoinNode = self:findChild("node_notCoin")
    self.m_addItemNode = self:findChild("addItemNode")
end
--更新金币数
function InboxItem_diningRoomTask:updateCoinNum(_num)
    local num = tonumber(_num)
    if num > 0 then 
        local strCoins = util_formatCoins(num,9)
        self.m_lb_coins:setString(strCoins)
        self:updateLabelSize({label = self.m_lb_coins},203)
        self.m_rewardUIList = {
        {node = self.m_sp_coin},
        {node = self.m_lb_coins,alignX = 2,alignY = 3}}
    else
        self.m_addNode:setVisible(false)
    end
end
--加载道具
function InboxItem_diningRoomTask:initItems(_rewardItems)
    --通用道具
    local rewardItems = _rewardItems.items
    local itemDataList = {}
    local count = #rewardItems
    if rewardItems and count > 0 then 
        self.m_addNode:setVisible(true)
        for i,v in ipairs(rewardItems) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            itemDataList[#itemDataList+1] = gLobalItemManager:createLocalItemData(tempData.p_icon,tempData.p_num,tempData)
        end
    end
    local itemNode = gLobalItemManager:addPropNodeList(itemDataList,ITEM_SIZE_TYPE.TOP,0.7,80,self:checkItems())
    self.m_addItemNode:addChild(itemNode)
end
--检测道具位置
function InboxItem_diningRoomTask:checkItems( )
    if self.m_coins and self.m_coins > 0 then 
        return true
    else
        self.m_addItemNode:setPosition(self.m_notCoinNode:getPosition())
        self.m_sp_coin:setVisible(false)
        self.m_lb_coins:setVisible(false)
        self.m_addNode:setVisible(false)
        return false
    end
end

function InboxItem_diningRoomRank:getCardSource()
    return {"DinnerLand Mission"}
end
return  InboxItem_diningRoomTask