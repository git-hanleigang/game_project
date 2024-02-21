

--
-- Author:  刘阳
-- Date:    2019-08-12
-- Desc:    餐厅排行榜的邮件

local ShopItem = require "data.baseDatas.ShopItem"
local InBoxItem_dinnerLandRank = class("InBoxItem_dinnerLandRank", util_require("views.inbox.item.InboxItem_baseReward"))



function InBoxItem_dinnerLandRank:getCsbName( )
    return "InBox/InboxItem_dinnerLand.csb"
end

function InBoxItem_dinnerLandRank:initView()
    
    local awards = self.m_mailData.awards
    
    self.sprite_coin = self:findChild("sprite_coin")
    self.m_lb_coins = self:findChild("label_coin")
    self.coinNode = self:findChild("coinNode")
    local strCoins = util_formatCoins(tonumber(awards.coins),3)
    self.m_lb_coins:setString(strCoins)
    self:updateLabelSize({label = self.m_lb_coins},203)
    self.addNode  = self:findChild("add")
    self.addNode:setVisible(false)
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        --名次
        self.m_rankNum = extraData.rank
        local m_lb_dec = self:findChild("lb_num")
        m_lb_dec:setString(self.m_rankNum)
    end
    
    local awardsItem = awards.items
    local extraPropList = {}
    --奖励道具
    if awardsItem ~= nil then
        for k,v in ipairs(awardsItem) do
            local cell = ShopItem:create()
            cell:parseData(v,true)
            extraPropList[#extraPropList+1] = cell
        end
    end
    local rewardUIList = 
    {
        {node = self.sprite_coin},
        {node = self.m_lb_coins,alignX = 2,alignY = 3},
    }
    self:initProp(rewardUIList,extraPropList)
end

function InBoxItem_dinnerLandRank:initProp(rewardUIList,extraPropList)
    if extraPropList ~= nil and #extraPropList > 0 then
        self.addNode:setVisible(true)
        local coinNode = self.coinNode
        -- coinNode:setPositionX(coinNode:getPositionX() - 160)
        table.insert(rewardUIList,{node = self.addNode,alignX = 5})
        for k,v in ipairs(extraPropList) do
            local propUI = util_createItemByShopData(v)
            if propUI ~= nil then
                local info = {}
                local pType = v.p_type
                if pType == "Package" then
                    info.alignX = 5
                    propUI:setScale(0.5)
                elseif pType == "Item" then
                    if v.p_icon == "DeluxeClub" then
                        propUI:setScale(0.8)
                        info.size = cc.size(80,70)
                        info.anchor = cc.p(0.5,0.5)
                    end
                elseif pType == "Buff" then
                    propUI:setScale(0.8)
                    info.size = cc.size(80,75)
                    info.anchor = cc.p(0.5,0.5)
                end
                coinNode:addChild(propUI)
                info.node = propUI
                table.insert(rewardUIList,info)
                --排行榜显示不全，只显示前2个
                if k == 2 then
                    break
                end
            end
        end
        util_alignCenter(rewardUIList,nil)
    else
        util_alignCenter(rewardUIList)
    end
end

function InBoxItem_dinnerLandRank:getCardSource()
    return {"Dinner Land Rank Rewards"}
end

return InBoxItem_dinnerLandRank

