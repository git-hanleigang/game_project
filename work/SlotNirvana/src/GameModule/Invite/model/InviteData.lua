local InviteData = class("InviteData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function InviteData:ctor()
    self.invitee_reward = nil -- 被邀请者奖励列表
    self.inviter_reward = nil --邀请者奖励列表
    self.free_item = {} --邀请人数奖励道具
    self.pay_item = {} --邀请人数付费奖励
    self.invitee_fitem = {} --被邀请免费奖励
    self.invitee_pitem = {} -- 被邀请付费奖励
    self.level = 1 --被邀请时的等级
    self.is_share = true
    self.share_coin = 0
    self.is_Reward = false
    self.invite_uid = nil
    self.is_firstInvite = false
    self.is_chaoTwo = false
    self.p_open = true
    self.p_openLevel = 0
    self.mailCount = {}
end

function InviteData:parseData(_data)
    if _data == nil then
        return
    end
    self.invitee_reward = _data.invitee
    self.inviter_reward = _data.inviter
    self.is_share = _data.share
    if self.invitee_reward ~= nil then
        self.level = self.invitee_reward.level
        self:parseShopItems(self.invitee_reward)
    end
    if self.inviter_reward ~= nil then

        self.mailCount = {}
        if self.inviter_reward.mailMap == nil then
            return
        end
        local mapl = self.inviter_reward.mailMap
        for i,v in pairs(mapl) do
            local map = {}
            map.id = i
            map.time = v
            table.insert(self.mailCount,map)
        end
    end
end

function InviteData:getOpenLevel()
    return 0
end

function InviteData:parseShopItems(_data)
    self.invitee_pitem = {}
    self.invitee_fitem = {}
    for i,v in ipairs(_data.freeRewards) do
        table.insert(self.invitee_fitem,self:setShopItem(v))
    end
    for i,v in ipairs(_data.payRewards) do
        table.insert(self.invitee_pitem,self:setShopItem(v))
    end
end

function InviteData:setShopItem(_data)
    local item = {}
    if _data.items and #_data.items > 0 then
        item = ShopItem:create()
        item:parseData(_data.items[1])
    else
        item = gLobalItemManager:createLocalItemData("Coins", _data.coins)
    end
    item.coinValue = _data.coinValue
    item.coins = _data.coins
    item.collect = _data.collect
    item.value = _data.value

    return item
end

function InviteData:getInviteeReward()
    return self.invitee_reward
end

function InviteData:getInviterReward()
    return self.inviter_reward
end

function InviteData:setShare(_share)
    self.is_share = _share
end

function InviteData:getShare()
    return self.is_share
end

function InviteData:setShareCoin(coin)
    self.share_coin = coin
end

function InviteData:getShareCoin()
    return self.share_coin
end

function InviteData:setIsReward(_isreward)
    self.is_Reward = _isreward
end

function InviteData:getIsReward()
    return self.is_Reward
end
-- 邀请人数奖励道具
function InviteData:parseFreeItemsData(_data)
    self.free_item = {}
    if _data.coins ~= nil and _data.coins > 0 then
        local item_data = gLobalItemManager:createLocalItemData("Coins", _data.coins)
        table.insert(self.free_item,item_data)
    end
    if _data.items and #_data.items > 0 then 
        for i,v in ipairs(_data.items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(self.free_item, tempData)
        end
    end
end
--邀请付费奖励道具
function InviteData:parsePayItemsData(_data)
    self.pay_item = {}
    if _data.coins ~= nil and _data.coins > 0 then
        local item_data = gLobalItemManager:createLocalItemData("Coins", _data.coins)
        table.insert(self.pay_item,item_data)
    end
    if _data.items and #_data.items > 0 then 
        for i,v in ipairs(_data.items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(self.pay_item, tempData)
        end
    end
end

function InviteData:getInviteeFree()
    return self.invitee_fitem
end

function InviteData:getInviteePay()
    return self.invitee_pitem
end

function InviteData:getFreeItems()
    return self.free_item
end

function InviteData:getPayItems()
    return self.pay_item
end

function InviteData:getPayNum()
    return self.invitee_reward.price
end

function InviteData:setInviteUid(_uid)
    self.invite_uid = _uid
end

function InviteData:getInviteUid()
    return self.invite_uid
end
--被邀请时的等级
function InviteData:getLevel()
    return self.level
end

function InviteData:setIsFirst(_isfirst)
    self.is_firstInvite = _isfirst
end

function InviteData:setIsOut(_out)
    self.is_chaoTwo = _out
end

function InviteData:getIsFirst()
    return self.is_firstInvite
end

function InviteData:getIsOut()
    return self.is_chaoTwo
end

function InviteData:getMailCount()
    return self.mailCount
end

function InviteData:setMailCount(_data)
    self.mailCount = _data
end

--获取邀请界面付费当前奖励
function InviteData:getInviterRecharg()
    local _reward = self:getPersonReward(self.inviter_reward.rechargerRewards,self.inviter_reward.rechargeAmount)
    self:parsePayItemsData(_reward)
    return _reward
end

--获取邀请界面人数当前奖励
function InviteData:getInviterPerson()
    local _reward = self:getPersonReward(self.inviter_reward.rewards ,self.inviter_reward.inviteNum)
    self:parseFreeItemsData(_reward)
    return _reward
end

function InviteData:getPersonReward(_reward,_num)
    --人数奖励
    local current = 1
    for i,v in ipairs(_reward) do
        if _num <= v.value then
            current = i
            if v.collect then
                if current ~= #_reward then
                    current = current + 1
                end
            end
            break
        end
    end
    local cur_data = nil
    if _num > _reward[#_reward].value then
        current = #_reward
        cur_data = _reward[current]
    else
        cur_data = _reward[current]
    end
    if _num >= _reward[#_reward].value then
        cur_data.big = true
    end
    return cur_data
end

function InviteData:getLastCollect(_reward)
    local _data = nil
    for i,v in ipairs(_reward) do
        if not v.collect then
            _data = v
            break
        end
    end
    return _data
end

function InviteData:getPersonReceive()
    return self:setRevice(self.inviter_reward.rewards,self.inviter_reward.inviteNum)
end

function InviteData:getPayReceive()
    return self:setRevice(self.inviter_reward.rechargerRewards,self.inviter_reward.rechargeAmount)
end

function InviteData:setRevice(_data,num)
    local collect_item = {}
    local coin_data = {}
    local coin_num = 0
    local charger_rewards = clone(_data)
    for i,v in ipairs(charger_rewards) do
        if num >= v.value and not v.collect then
            if v.coins > 0 then
                table.insert(coin_data,v)
                coin_num = coin_num + v.coins
            else
                local index = self:composeItem(collect_item,v)
                if index then
                    collect_item[index].items[1].num = collect_item[index].items[1].num + v.items[1].num
                else
                    table.insert(collect_item,v)
                end
            end
        end
    end
    if #coin_data > 0 then
        local itm = coin_data[1]
        itm.coins = coin_num
        table.insert(collect_item,itm)
    end
    for i,v in ipairs(collect_item) do
        v.link = "1"
        v.shop = self:parseReceiveItemsData(v)
    end
    collect_item.zCoins = coin_num
    return collect_item
end

function InviteData:composeItem(_data,item)
    local index = nil
    for i,v in ipairs(_data) do
        if item and v.item ~= nil then
            if item.items[1].id == v.items[1].id then
                index = i
                break
            end
        end
        
    end
    return index
end

function InviteData:parseReceiveItemsData(_data)
    local shop_item = {}
    if _data.coins ~= nil and _data.coins > 0 then
        local item_data = gLobalItemManager:createLocalItemData("Coins", _data.coins)
        table.insert(shop_item,item_data)
    end
    if _data.items and #_data.items > 0 then 
        for i,v in ipairs(_data.items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(shop_item, tempData)
        end
    end
    return shop_item
end

return InviteData
