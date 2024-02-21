-- quest pass

local ShopItem = require "data.baseDatas.ShopItem"
local QuestPassData = class("QuestPassData")

-- message QuestPass {
--     optional int32 level = 1;//等级
--     optional int64 totalExp = 2;//总经验
--     optional int64 curExp = 3;//经验
--     optional bool payUnlocked = 4;//付费奖励解锁标识
--     repeated QuestPassPoint free = 5;
--     repeated QuestPassPoint pay = 6;
--     optional QuestPassBox box = 7;
--     optional string key = 8;
--     optional string keyId = 9;
--     optional string price = 10;
--     optional int32 totalUsd = 11;//总价值
--     optional string questPassPayMult = 12;//玩家付费后通关点数乘倍
--     repeated QuestPassDisplay display = 13;//客户端弹窗显示数据
--   }

function QuestPassData:parseData(_data)
    self.p_level = _data.level
    self.p_totalExp = tonumber(_data.totalExp)
    self.p_curExp = tonumber(_data.curExp)
    self.p_payUnlocked = _data.payUnlocked
    self.p_key = _data.key
    self.p_keyId = _data.keyId
    self.p_price = _data.price
    self.p_totalUsd = _data.totalUsd
    self.p_passFreePoint = self:parsePointData(_data.free)
    self.p_passPayPoint = self:parsePointData(_data.pay)
    self.p_passBox = self:parseBoxData(_data.box)

    self.p_pointMoreBuf = _data.questPassPayMult and tonumber(_data.questPassPayMult) or 0

    self.p_passDisplayPoint = self:parsePointData(_data.display)
    if #self.p_passDisplayPoint > 0 then
        self.p_willShowBuyTicketLayer = true
        -- if not self.p_passDisplayPoint_clone then
            self.p_passDisplayPoint_clone = clone(self.p_passDisplayPoint)
        -- end
    end

    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_QUEST_PASS_DATA_UPDATE)
end

-- message QuestPassPoint {
--     optional int32 level = 1;//等级
--     optional int64 exp = 2;//所需经验
--     optional bool collected = 3;
--     optional int64 coins = 4;
--     repeated ShopItem items = 5;
--     optional string label = 6;//底板颜色
--     optional string description = 7;//奖励描述

--   }
function QuestPassData:parsePointData(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_level = v.level
            info.p_exp = tonumber(v.exp)
            if v.exp and self.p_curExp >= info.p_exp and self.p_level < v.level then
                self.p_level = v.level
            end
            info.p_collected = v.collected
            info.p_coins = tonumber(v.coins)
            info.p_items = self:parseItemData(v.items)
            info.gems = self:getTotalGem(info.p_items)
            info.p_desc = v.description or "" -- 气泡文字
            if info.p_coins > 0 then
                info.p_desc = util_formatCoins(info.p_coins, 3) .. (v.description or "")
            end
            info.p_labelColor = v.label or "0" -- 
            
            table.insert(reward, info)
        end
    end
    return reward
end 

-- message QuestPassBox {
    -- optional int64 coins = 1;
    -- repeated ShopItem items = 2;
    -- optional int64 totalExp = 3;//总经验
    -- optional int64 curExp = 4;//经验
--   }
function QuestPassData:parseBoxData(_data)
    local boxData = {}
    if _data then 
        boxData.p_coins = tonumber(_data.coins)
        boxData.p_items = self:parseItemData(_data.items)
        boxData.p_totalExp = tonumber(_data.totalExp)
        boxData.p_curExp = tonumber(_data.curExp)
    end
    return boxData
end 

function QuestPassData:parseItemData(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function QuestPassData:getAllCanCollectReward()
    local data = {}
    local coins = 0
    local gems = 0
    local items = {}
    for i,v in ipairs(self.p_passFreePoint) do
        if v.p_exp <= self.p_curExp and not v.p_collected then
           coins = coins + (v.p_coins or 0)
           gems = gems + self:getTotalGem(v.p_items)
           table.insertto(items, clone(v.p_items))
        end
    end
    if self.p_payUnlocked then
        for i,v in ipairs(self.p_passPayPoint) do
            if v.p_exp <= self.p_curExp and not v.p_collected then
                coins = coins + (v.p_coins or 0)
                gems = gems + self:getTotalGem(v.p_items)
                table.insertto(items, clone(v.p_items))
            end
        end
    end

    data.p_coins = coins
    data.p_items = items
    data.gems = gems

    return data
end

function QuestPassData:getTotalGem(itemList)
    local gems = 0
    if itemList and #itemList > 0 then
        for i = 1, #itemList do
            local itemInfo = itemList[i]
            if itemInfo.p_icon == "Gem" then
                gems = gems + itemInfo.p_num
            end
        end
    end
    return gems
end

function QuestPassData:getRewardCount()
    local count = 0
    for i,v in ipairs(self.p_passFreePoint) do
        if v.p_exp <= self.p_curExp and not v.p_collected then
            count = count + 1
        end
    end

    if self.p_payUnlocked then
        for i,v in ipairs(self.p_passPayPoint) do
            if v.p_exp <= self.p_curExp and not v.p_collected then
                count = count + 1
            end
        end
    end

    if self.p_passBox.p_curExp >= self.p_passBox.p_totalExp and not self.p_passBox.p_collected then
        count = count + 1
    end

    return count
end

function QuestPassData:isGetAllReward()
    local lastReward = self.p_passFreePoint[#self.p_passFreePoint]
    local flag = false
    if lastReward.p_exp <= self.p_curExp then
        flag = true
    end

    return flag
end

function QuestPassData:getFreeRewards()
    return self.p_passFreePoint
end

function QuestPassData:getPayRewards()
    return self.p_passPayPoint
end

function QuestPassData:getBoxReward()
    return self.p_passBox
end

function QuestPassData:getCurExp()
    return self.p_curExp
end 

function QuestPassData:getTotalExp()
    return self.p_totalExp
end

function QuestPassData:getPayUnlocked()
    return self.p_payUnlocked
end 

function QuestPassData:getKeyId()
    return self.p_keyId
end

function QuestPassData:getPrice()
    return self.p_price
end

function QuestPassData:getTotalUsd()
    return self.p_totalUsd
end

function QuestPassData:getPointMoreBuf()
    return self.p_pointMoreBuf
end

function QuestPassData:getLevelValue()
    return self.p_level , #self.p_passPayPoint
end

-- 预览数据
function QuestPassData:getPreviewIndex(_curIndex)
    if _curIndex ~= nil and self.p_passFreePoint and #self.p_passFreePoint > 0 then
        for i=1,#self.p_passFreePoint do
            if i > _curIndex then
                local info = self.p_passFreePoint[i]
                if info and info.p_labelColor and info.p_labelColor == "1" then
                    return i
                end
            end
        end
    end
    return nil
end

function QuestPassData:getDisplayRewardPoints()
    return self.p_passDisplayPoint_clone
end

function QuestPassData:isWillShowBuyTicketLayer()
    return self.p_willShowBuyTicketLayer
end
function QuestPassData:clearWillShowBuyTicketLayer()
    self.p_passDisplayPoint_clone = {}
    self.p_willShowBuyTicketLayer = false
end

function QuestPassData:getTableUseData()
    local viewData = {}
    viewData[#viewData + 1] = {
        occupied = true
    }
    for i = 1, #self.p_passFreePoint do
        local data = {}
        local freeReward = self.p_passFreePoint[i]
        local payReward = self.p_passPayPoint[i]
        data.free = freeReward
        data.pay = payReward
        data.curExp = self.p_curExp
        data.payUnlocked = self.p_payUnlocked
        viewData[#viewData + 1] = data
    end

    viewData[#viewData + 1] = {
        box = self.p_passBox,
        curExp = self.p_curExp,
        totalExp = self.p_totalExp,
        payUnlocked = self.p_payUnlocked
    }

    return viewData
end

function QuestPassData:getPassInfoByIndex(_index)
    local passPointsInfo = self:getTableUseData()
    if _index and #passPointsInfo > 0 then
        return passPointsInfo[_index + 1]
    end
    return nil
end

function QuestPassData:getCurrentPassBigIndex()
    local result = 0
    for i = 1, #self.p_passPayPoint do
        local data = {}
        local payReward = self.p_passPayPoint[i]
        if self.p_level > payReward.p_level and payReward.p_labelColor and payReward.p_labelColor == "1" then
            result = payReward.p_level
        else
            break
        end
    end
    return result
end

return QuestPassData
