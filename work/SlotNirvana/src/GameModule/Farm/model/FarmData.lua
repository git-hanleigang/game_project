--[[
    
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseGameModel = require("GameBase.BaseGameModel")
local FarmData = class("FarmData", BaseGameModel)

-- message Farm {
--     optional int32 expire = 1;
--     optional int64 expireAt = 2;
--     optional FarmInfo info = 3;// 农场信息
--     repeated FarmCrop crops = 4;// 作物信息
--     repeated FarmStat stats = 5;// 成就
--     optional FarmWarehouse seedWarehouse = 6;// 种子仓库
--     optional FarmWarehouse fruitWarehouse = 7;// 果实仓库
--     optional FarmStore store = 8;// 商店
--     optional FarmDailyReward dailyReward = 9;// 每日奖励
--     repeated FarmLand lands = 10;// 土地
--     optional FarmConstant constant = 11;// 常量
--     optional string saveData = 12;// 新手引导数据
--     optional int32 leftStealTimes = 13;// 剩余偷取次数
--   }
function FarmData:parseData(_data)
    self.p_expire = _data.expire
    self.p_expireAt = tonumber(_data.expireAt)
    self.p_info = self:parseInfo(_data.info)
    self.p_crops = self:parseCrops(_data.crops)
    self.p_stats = self:parseStats(_data.stats)
    self.p_seedWarehouse = self:parseWarehouse(_data.seedWarehouse)
    self.p_fruitWarehouse = self:parseWarehouse(_data.fruitWarehouse)
    self.p_store = self:parseStore(_data.store)
    self.p_dailyReward = self:parseDailyReward(_data.dailyReward)
    self.p_lands = self:parseLands(_data.lands)
    self.p_constant = self:parseConstant(_data.constant)
    self.p_saveData = _data.saveData
    self.p_leftStealTimes = _data.leftStealTimes
    self:setGuideMaturityTime()
end
-- message FarmInfo {
--     optional string name = 1; // 农场名称
--     optional int32 level = 2; // 等级
--     optional int64 exp = 3; // 经验
--     optional int64 expMax = 4; // 满格经验
--     optional int64 levelMax = 5; // 最大等级
--   }
function FarmData:parseInfo(_info)
    local tempData = {}
    if _info then
        tempData.p_name = _info.name
        tempData.p_level = _info.level
        tempData.p_levelMax = _info.levelMax or 90
        tempData.p_exp = tonumber(_info.exp)
        tempData.p_expMax = tonumber(_info.expMax)
        tempData.p_levelMax = tonumber(_info.levelMax)
    end
    return tempData
end
-- message FarmCrop {
--     optional int32 id = 1;
--     optional string description = 2; // 描述
--     optional int32 status = 3; //解锁状态 0 未解锁， 1 解锁
--     optional int32 ripeTime = 4; //成熟时间
--     optional int32 yield = 5; //产量
--     optional int64 coins = 6; //出售金币
--   }
function FarmData:parseCrops(_crops)
    local tempData = {}
    if _crops and #_crops > 0 then
        for i, v in ipairs(_crops) do
            local temp = {}
            temp.p_id = v.id
            temp.p_description = v.description
            temp.p_status = v.status
            temp.p_ripeTime = v.ripeTime
            temp.p_yield = v.yield
            temp.p_coins = tonumber(v.coins)
            table.insert(tempData, temp)
        end
    end
    return tempData
end
-- message FarmStat {
--     optional string description = 1; // 描述
--     optional int64 value = 2; //值
--   }
function FarmData:parseStats(_stats)
    local tempData = {}
    if _stats and #_stats > 0 then
        for i, v in ipairs(_stats) do
            local temp = {}
            temp.p_description = v.description
            temp.p_value = tonumber(v.value)
            table.insert(tempData, temp)
        end
    end
    return tempData
end
-- message FarmWarehouse {
--     optional int32 capacity = 1;// 容量
--     repeated FarmWare wares = 2; // 货物
--   }
function FarmData:parseWarehouse(_data)
    local tempData = {}
    if _data then
        tempData.p_capacity = _data.capacity
        tempData.p_wares = self:parseWares(_data.wares)
    end
    return tempData
end
-- message FarmWare {
--     optional int32 id = 1;// id
--     optional string type = 2; // 类型
--     optional int32 num = 3; //数量
--   }
function FarmData:parseWares(_wares)
    local tempData = {}
    if _wares and #_wares > 0 then
        for i, v in ipairs(_wares) do
            local temp = {}
            temp.p_id = v.id
            temp.p_type = v.type
            temp.p_num = v.num
            table.insert(tempData, temp)
        end
    end
    table.sort(
        tempData,
        function(a, b)
            return tonumber(a.p_id) < tonumber(b.p_id)
        end
    )
    return tempData
end
-- message FarmStore {
--     repeated FarmStoreGoods goods = 1; // 商品
--   }
function FarmData:parseStore(_store)
    local tempData = {}
    if _store then
        tempData.p_goods = self:parseGoods(_store.goods)
    end
    return tempData
end
-- message FarmStoreGoods {
--     optional int32 id = 1;
--     optional string gems = 2; // 第二货币价格
--   }
function FarmData:parseGoods(_goods)
    local tempData = {}
    if _goods and #_goods > 0 then
        for i, v in ipairs(_goods) do
            local temp = {}
            temp.p_id = v.id
            temp.p_gems = v.gems
            table.insert(tempData, temp)
        end
    end
    return tempData
end
-- message FarmDailyReward {
--     optional int32 refreshTime = 1;
--     optional int64 refreshAt = 2;
--     optional int32 status = 3; // 0未领取 1已领取
--     optional int64 coins = 4; // 奖励金币
--     repeated ShopItem items = 5; // 奖励物品
--   }
function FarmData:parseDailyReward(_reward)
    local tempData = {}
    if _reward then
        tempData.p_refreshTime = _reward.refreshTime
        tempData.p_refreshAt = tonumber(_reward.refreshAt)
        tempData.p_status = _reward.status
        tempData.p_coins = tonumber(_reward.coins)
        tempData.p_items = self:parseItems(_reward.items)
    end
    return tempData
end
function FarmData:parseItems(_items)
    local tempData = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local temp = ShopItem:create()
            temp:parseData(v)
            table.insert(tempData, temp)
        end
    end
    return tempData
end
-- message FarmLand {
-- optional int32 id = 1; // 土地Id
-- optional int32 unlockLevel = 2; // 解说等级
-- optional int32 status = 3; // 备用
-- optional int32 crop = 4; // 作物
-- optional int32 mature = 5;// 成熟时间
-- optional int64 matureAt = 6;// 成熟时间
-- optional int32 protect = 7;// 保护时间
-- optional int64 protectAt = 8;// 保护时间
-- optional int32 left = 9; // 剩余果实数量
-- optional int32 bound = 10; // 最小剩余数量
--   }
function FarmData:parseLands(_lands)
    self.p_info.p_lockLandID = 0
    local tempData = {}
    if _lands and #_lands > 0 then
        for i, v in ipairs(_lands) do
            local temp = {}
            temp.p_id = v.id
            temp.p_unlockLevel = v.unlockLevel
            temp.p_status = v.status
            temp.p_crop = v.crop
            temp.p_status = v.status
            temp.p_mature = v.mature
            temp.p_matureAt = tonumber(v.matureAt)
            temp.p_protect = v.protect
            temp.p_protectAt = tonumber(v.protectAt)
            temp.p_left = v.left
            temp.p_bound = v.bound
            table.insert(tempData, temp)
            if temp.p_status > 0 then
                self.p_info.p_lockLandID = i
            end
        end
    end
    table.sort(
        tempData,
        function(a, b)
            return (a.p_id) < (b.p_id)
        end
    )
    return tempData
end

function FarmData:parseConstant(_constant)
    self.p_openLevel = 50

    local tempData = {}
    if _constant then
        tempData.p_speedGem = _constant.speedGem
        tempData.p_speedTime = _constant.speedTime
        self.p_openLevel = _constant.openLevel or 50
    end
    return tempData
end

-- message FarmFriend {
--     repeated FarmFriendUser game = 1; // 游戏好友
--     repeated FarmFriendUser clan = 2; // 公会好友
--     repeated FarmFriendUser other = 3; // 推荐好友
--   }
function FarmData:parseFriends(_friends)
    local tempData = {}
    if _friends then
        tempData.p_game = self:parseFriendData(_friends.game)
        tempData.p_clan = self:parseFriendData(_friends.clan)
        tempData.p_other = self:parseFriendData(_friends.other)
    end
    return tempData
end
-- message FarmFriendUser {
--     optional int32 rank = 1;
--     optional string name = 2;
--     optional int64 points = 3;
--     optional string facebookId = 4;
--     optional string udid = 5;
--     optional string head = 6;
--     optional string status = 7;//UP DOWN SAME
--     optional string robotHead = 8;
--     optional string frame = 9;
--   }
function FarmData:parseFriendData(_data)
    local tempData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local temp = {}
            temp.p_rank = v.rank
            temp.p_name = v.name
            temp.p_points = tonumber(v.points)
            temp.p_facebookId = v.facebookId
            temp.p_udid = v.udid
            temp.p_head = v.head
            temp.p_status = v.status
            temp.p_robotHead = v.robotHead
            temp.p_frame = v.frame
            table.insert(tempData, temp)
        end
    end
    return tempData
end

function FarmData:getInfo()
    return self.p_info
end

function FarmData:getCrops()
    return self.p_crops
end

function FarmData:getStats()
    return self.p_stats
end

function FarmData:getSeedWarehouse()
    return self.p_seedWarehouse
end

function FarmData:getFruitWarehouse()
    return self.p_fruitWarehouse
end

function FarmData:getStore()
    return self.p_store
end

function FarmData:getDailyReward()
    return self.p_dailyReward
end

function FarmData:getLands()
    return self.p_lands
end

function FarmData:getFriends()
    return self.p_friends
end

function FarmData:getExpireAt()
    return self.p_expireAt
end

function FarmData:getSaveData()
    return self.p_saveData or "{}"
end

function FarmData:isRunning()
    if self.p_expireAt and self.p_expireAt > 0 then
        local curTime = os.time()
        if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
            curTime = globalData.userRunData.p_serverTime / 1000
        end
        local leftTime = self.p_expireAt / 1000 - curTime
        return leftTime > 0
    end
    return true
end

-- 通过id获得作物信息
function FarmData:getCropsById(_id)
    local crops = self:getCrops()
    for i = 1, #crops do
        local info = crops[i]
        if info.p_id == _id then
            return info
        end
    end
    return nil
end

-- 获得作物出售总额
function FarmData:getCropSellCoins()
    local totalCoins = 0
    for i = 1, #self.p_fruitWarehouse.p_wares do
        local info = self.p_fruitWarehouse.p_wares[i]
        local crop = self:getCropsById(info.p_id)
        totalCoins = totalCoins + (crop.p_coins * info.p_num)
    end
    return totalCoins
end

-- 获得作物总数量
function FarmData:getCropTotalNum()
    local totalNum = 0
    for i = 1, #self.p_fruitWarehouse.p_wares do
        local info = self.p_fruitWarehouse.p_wares[i]
        totalNum = totalNum + info.p_num
    end
    return totalNum
end

-- 获得种子总数量
function FarmData:getSeedTotalNum()
    local totalNum = 0
    for i = 1, #self.p_seedWarehouse.p_wares do
        local info = self.p_seedWarehouse.p_wares[i]
        totalNum = totalNum + info.p_num
    end
    return totalNum
end

-- 获得作物仓库（堆叠规则 - 超过100个新建一组）
function FarmData:getFruitBarn()
    local barnList = {}
    local fruitBarn = self.p_fruitWarehouse.p_wares
    for i, v in ipairs(fruitBarn) do
        if v.p_num > 0 then
            if v.p_num <= 100 then
                table.insert(barnList, v)
            else
                local num = math.floor(v.p_num / 100)
                for i = 1, num do
                    local info = clone(v)
                    info.p_num = 100
                    table.insert(barnList, info)
                end
                local info = clone(v)
                info.p_num = v.p_num - 100 * num
                if info.p_num > 0 then
                    table.insert(barnList, info)
                end
            end
        end
    end
    return barnList
end

-- 获得种子仓库（数量为0剔除）
function FarmData:getSeedBarn()
    local seedList = {}
    local seedBarn = self.p_seedWarehouse.p_wares
    for i, v in ipairs(seedBarn) do
        if v.p_num > 0 then
            v.p_type = "SEED"
            if v.p_num <= 100 then
                table.insert(seedList, v)
            else
                local num = math.floor(v.p_num / 100)
                for j = 1, num do
                    local info = clone(v)
                    info.p_num = 100
                    table.insert(seedList, info)
                end
                local info = clone(v)
                info.p_num = v.p_num - 100 * num
                if info.p_num > 0 then
                    table.insert(seedList, info)
                end
            end
        end
    end
    return seedList
end

-- 获得作物仓库总容量
function FarmData:getCropCapacity()
    local capacity = tonumber(self.p_fruitWarehouse.p_capacity) or 0
    return capacity
end

-- 获得作物成熟总数
function FarmData:getRipeCropNum()
    local num = 0
    for i,v in ipairs(self.p_lands) do
        if v.p_crop > 0 then
            local matureAt = v.p_matureAt 
            local curTime = os.time()
            if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
                curTime = globalData.userRunData.p_serverTime / 1000
            end
            if matureAt/1000 - curTime <= 0 then
                num = num + 1
            end
        end
    end
    return num
end

function FarmData:getLeftStealTimes()
    return self.p_leftStealTimes
end

function FarmData:getConstant()
    return self.p_constant
end

function FarmData:saveRecords(_data)
    self.m_hasNewRecordData = false
    if _data and #_data > 0 then
        local lastTime = gLobalDataManager:getNumberByField("farmRecord", 0)
        local timestamp = tonumber(_data[1].timestamp) or 0
        if timestamp ~= lastTime then
            self.m_hasNewRecordData = true
            gLobalDataManager:setNumberByField("farmRecord", timestamp)
        end
    end
    
    return self.m_hasNewRecordData and 1 or 0
end

function FarmData:hasNewRecords()
    return self.m_hasNewRecordData
end

function FarmData:setNewRecords(_flag)
    self.m_hasNewRecordData = _flag
end

function FarmData:isAllLandEmpty()
    local isEmpty = true
    local lands = self:getLands()
    for i = 1, #lands do
        local land = lands[i]
        if land.p_status > 0 and land.p_crop > 0 then
            isEmpty = false
            break
        end
    end
    return isEmpty
end

-- 引导检测（引导中作物成熟时间无限）
function FarmData:setGuideMaturityTime()
    local lands = self:getLands()
    if lands and #lands > 0 then
        local land = lands[1]
        local landStepInfo = G_GetMgr(G_REF.Farm):getGuide():getCurGuideStepInfo("FarmLandGuide", G_REF.Farm)
        if landStepInfo then
            local stepId = landStepInfo:getStepId()
            if stepId == "1103" or stepId == "1104" then
                land.p_matureAt = 1988121600000 -- 在引导中设置作物成熟时间无限大
            end
        end
    end
end

return FarmData
