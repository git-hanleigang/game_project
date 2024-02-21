--[[
    新版餐厅排行奖励
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_diningRoomRank = class("InboxItem_diningRoomRank", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_diningRoomRank:getCsbName( )
    return "InBox/InboxItem_diningRoom.csb"
end

function InboxItem_diningRoomRank:initNode()
    self.m_lb_rank   = self:findChild("m_lb_dec")
    self.m_node_coin = self:findChild("coinNode")
    self.m_sp_coin   = self:findChild("sprite_coin")
    self.m_lb_coins  = self:findChild("label_coin")
    self.m_sp_add    = self:findChild("add")
    self.m_sp_add:setVisible(false)
end

function InboxItem_diningRoomRank:initView()
    self:initNode()
    local mailData = self.m_mailData
    local rewardUIList = {}
    --名次
    local extra = mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        self.m_rankNum = extraData.rank
        local strRank = string.format("Rank %s Rewards",self.m_rankNum)
        local m_lb_dec = self:findChild("m_lb_dec")
        m_lb_dec:setString(strRank)
    end

    local coins = tonumber(mailData.awards.coins)
    if coins and coins > 0 then 
        local coinStr = util_formatCoins(coins,3)
        self.m_lb_coins:setString(coinStr)
        table.insert(rewardUIList,{node = self.m_sp_coin})
        table.insert(rewardUIList,{node = self.m_lb_coins,alignX = 5})
    else
        self.m_sp_coin:setVisible(false)
        self.m_lb_coins:setVisible(false)
    end

    local rewardItems = mailData.awards.items
    if rewardItems and #rewardItems > 0 then 
        self.m_sp_add:setVisible(true)
        table.insert(rewardUIList,{node = self.m_sp_add, alignX = 5})
        for i,v in ipairs(rewardItems) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            local itemUI = gLobalItemManager:createRewardNode(tempData,ITEM_SIZE_TYPE.TOP)
            if itemUI then 
                itemUI:setScale(0.7)
                self.m_node_coin:addChild(itemUI)
                local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
                table.insert(rewardUIList,{node = itemUI, size = cc.size(width*1.2,width*1.2),anchor = cc.p( 0.5,0.5 )})
            end
        end
    end
    util_alignCenter(rewardUIList)
end

function InboxItem_diningRoomRank:getCardSource()
    return {"DinnerLand Rank Rewards"}
end

return  InboxItem_diningRoomRank