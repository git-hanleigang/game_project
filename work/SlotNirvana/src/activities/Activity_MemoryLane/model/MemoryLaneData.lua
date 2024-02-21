--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-05 11:39:30
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local MemoryLaneData = class("MemoryLaneData", BaseActivityData)
--   message MemoryLaneConfig {
--     optional string activityId = 1;
--     optional int64 expireAt = 2;
--     optional int32 expire = 3;
--     repeated MemoryLanePhoto photoList = 4;//照片集合
--     repeated int32 photoIdList = 5;//当日可收集的照片id集合
--     optional bool completed = 6;//是否集齐
--     repeated ShopItem bigReward = 7;//大奖
--     optional bool collectedBigReward = 8;//是否领取大奖
--   }

--   message MemoryLanePhoto {
--     optional int32 photoId = 1;//照片id
--     optional string photoDesc = 2;//照片描述
--     optional bool collected = 3;//是否已收集
--     optional string rewardType = 3;//奖励类型 Coins,Item
--     optional int64 coins = 4;//金币
--     repeated ShopItem itemList = 5;//道具集合
--   }

function MemoryLaneData:parseData(_data)
    MemoryLaneData.super.parseData(self, _data)

    self.p_photoList = self:parsePhotoData(_data.photoList)
    self.p_photoIdList = _data.photoIdList
    self.p_completed = _data.completed
    self.p_bigReward = self:parseItemsData(_data.bigReward)
    self.p_collectedBigReward = _data.collectedBigReward
    if not self.p_isFirstLogin then
        self.p_isFirstLogin = true
        self:initIsClick()
    end
end

function MemoryLaneData:parsePhotoData(_data)
    local photoList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.photoId = v.photoId
            tempData.photoDesc = v.photoDesc
            tempData.collected = v.collected
            tempData.rewardType = v.rewardType
            tempData.coins = v.coins -- 奖励物品
            tempData.itemList = self:parseItemsData(v.itemList)
            table.insert(photoList, tempData)
        end
    end
    return photoList
end

-- 解析道具数据
function MemoryLaneData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function MemoryLaneData:initIsClick()
    for i, v in ipairs(self.p_photoList) do
        if not v.collected then
            self:setIsClick(tonumber(i), false)
        end
    end
end

function MemoryLaneData:getPhotoList()
    return self.p_photoList or {}
end

function MemoryLaneData:getPhotoIdByList()
    for i, v in ipairs(self.p_photoIdList) do
        local info = self:getPhotoDataById(tonumber(v))
        if not info.collected then
            return tonumber(v)
        end
    end
    return nil
end

function MemoryLaneData:getPhotoDataById(id)
    for i, v in ipairs(self.p_photoList) do
        if id == v.photoId then
            return v
        end
    end
    return nil
end

function MemoryLaneData:getBigreward()
    return self.p_bigReward
end

function MemoryLaneData:isCompleted() -- 是否全部集齐
    return self.p_completed
end

function MemoryLaneData:isFirstLogin()
    if table.nums(self.p_photoIdList) <= 0 then
        return false
    end
    for i, v in ipairs(self.p_photoIdList) do
        local info = self:getPhotoDataById(tonumber(v))
        if info and info.collected then
            return false
        end
    end
    return true
end

function MemoryLaneData:isCanCollectBigReward()
    if not self.p_completed then
        return false
    end
    if self.p_collectedBigReward then
        return false
    end
    return true
end

function MemoryLaneData:getStatus(inx)
    local data = self:getPhotoDataById(inx)
    if data.collected then
        if self:getIsClick(inx) then
            return 2
        else
            return 1
        end
    end
    return 0
end

function MemoryLaneData:setIsClick(inx, value)
    gLobalDataManager:setBoolByField("MemoryLaneDataIsClick" .. inx, value)
end

function MemoryLaneData:getIsClick(inx)
    return gLobalDataManager:getBoolByField("MemoryLaneDataIsClick" .. inx, false)
end

return MemoryLaneData
