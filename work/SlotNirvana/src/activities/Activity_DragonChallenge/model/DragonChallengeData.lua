--[[
    组队打BOSS
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DragonChallengeData = class("DragonChallengeData", BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"
local DragonChallengePassData = require("activities.Activity_DragonChallenge.model.DragonChallengePassData")

-- message DragonChallenge {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 wheels = 4;//轮盘个数
--     optional int64 bossTotalHp = 5;//boss总血量
--     optional int64 bossCurrentHp = 6;//boss当前血量
--     repeated DragonChallengeTask teamTaskList = 7;//团队任务
--     repeated DragonChallengeTask personalTaskList = 8;//个人任务
--     optional int64 personalKillHp = 9;//个人已经击杀的血量
--     repeated int32 betList = 10;//bet档位
--     optional int64 jackpotCoins = 11;
--     optional int32 rank = 12; //排行榜排名
--     optional int64 points = 13; //排行榜 积分
--     repeated DragonChallengeRankUser rankList = 14;//排行榜
--     optional DragonChallengeBuffSale buffSale = 15;//buff促销
--     repeated DragonChallengeWheelSale wheelSale = 16;//轮盘促销
--     repeated DragonChallengeWeapon weaponList = 17;//武器
--     optional int64 round = 18;//轮次
--     optional int32 vulRemainingTimes = 19;//易伤剩余次数
--     optional int64 injuryExpireAt = 20;//免伤到期时间戳，初始为0
--     optional bool triggerInjury = 21;//是否触发免伤
--     optional bool triggerTailKnifeTips = 22;//是否触发尾刀提示
--     optional DragonChallengeParts head = 23;//头部
--     optional DragonChallengeParts torso = 24;//躯干
--     optional DragonChallengeParts tail = 25;//尾巴
--     repeated DragonChallengePassResult dragonPassData = 26;// pass
--     optional int64 hopeSpinBet = 27;//关卡掉落道具期望spin
--     optional string damageRate = 28;//触发易伤后轮盘显示的伤害比例
--     optional string hopeSpinBetV2 = 29;//关卡掉落道具期望spin
--     optional string jackpotCoinsV2 = 30;
--   }
function DragonChallengeData:parseData(_data)
    DragonChallengeData.super.parseData(self, _data)

    self.p_wheels = _data.wheels
    self.p_bossTotalHp = tonumber(_data.bossTotalHp)
    self.p_bossCurrentHp = tonumber(_data.bossCurrentHp)
    self.p_betList = _data.betList
    self.p_points = tonumber(_data.points)
    self.p_rank = _data.rank
    self.p_jackpotCoins = (_data.jackpotCoinsV2 and _data.jackpotCoinsV2 ~= "") and _data.jackpotCoinsV2 or tonumber(_data.jackpotCoins)
    self.p_personalKillHp = tonumber(_data.personalKillHp)
    self.p_round = tonumber(_data.round)
    self.p_vulRemainingTimes = tonumber(_data.vulRemainingTimes) -- 易伤剩余次数
    self.p_injuryExpireAt = tonumber(_data.injuryExpireAt) -- 免伤到期时间戳，初始为0
    self.p_triggerInjury = _data.triggerInjury -- 是否触发免伤
    self.p_triggerTailKnifeTips = _data.triggerTailKnifeTips -- 是否触发尾刀
    self.p_hopeSpinBet = (_data.hopeSpinBetV2 and _data.hopeSpinBetV2 ~= "") and _data.hopeSpinBetV2 or tonumber(_data.hopeSpinBet)
    self.p_damageRate = tonumber(_data.damageRate)

    self.p_teamTaskList = self:parseTaskData(_data.teamTaskList)
    self.p_personalTaskList = self:parseTaskData(_data.personalTaskList)
    self.p_buffSale = self:parseBuffSale(_data.buffSale)
    self.p_wheelSale = self:parseWheelSale(_data.wheelSale)
    self.p_rankList = self:parseRankList(_data.rankList)
    self.p_weaponList = self:parseWeaponList(_data.weaponList)
    self.p_head = self:parseDragonPartsData(_data.head)
    self.p_torso = self:parseDragonPartsData(_data.torso)
    self.p_tail = self:parseDragonPartsData(_data.tail)
    
    if not self.p_dragonPassData then
        self.p_dragonPassData = DragonChallengePassData:create()
    end
    self.p_dragonPassData:parseData(_data.dragonPassData)
    
end

-- message DragonChallengeTask {
--     optional int32 index = 1;
--     optional int64 hp = 2;//血量
--     optional DragonChallengeReward reward = 3;//奖励
--     optional bool collected = 4;//是否领取
--     optional bool hit = 5;//此阶段是否击杀
--   }
function DragonChallengeData:parseTaskData(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_hp = tonumber(v.hp)
            temp.p_collected = v.collected
            temp.p_hit = v.hit
            temp.p_reward = self:parseRewardData(v.reward)
            table.insert(list, temp)
        end
    end
    return list
end

-- message DragonChallengeBuffSale {
--     optional int64 gems = 1;//第二货币购买
--     optional string multiple = 2;//伤害buff加成倍数
--     optional int32 time = 3;//持续时间
--   }
function DragonChallengeData:parseBuffSale(_data)
    local temp = {}
    if _data then
        temp.p_gems = tonumber(_data.gems)
        temp.p_multiple = tonumber(_data.multiple)
        temp.p_time = _data.time
    end
    return temp
end

-- message DragonChallengeWheelSale {
--     optional string price = 1;
--     optional string key = 2;
--     optional string keyId = 3;
--     optional int32 num = 4;//轮盘个数
--     optional int64 coins = 5;
--     optional string coinsV2 = 6;
--   }
function DragonChallengeData:parseWheelSale(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local temp = {}
            temp.p_price = v.price
            temp.p_key = v.key
            temp.p_keyId = v.keyId
            temp.p_num = v.num
            temp.p_coins = (v.coinsV2 and v.coinsV2 ~= "") and v.coinsV2 or tonumber(v.coins)
            table.insert(list, temp)
        end
    end
    return list
end

-- message DragonChallengeRankUser {
--     optional int32 rank = 1;
--     optional string name = 2;
--     optional int64 points = 3;
--     optional string facebookId = 4;
--     optional string head = 5;
--     optional string frame = 6;
--     optional string udid = 7;
--     optional DragonChallengeReward reward = 8;//奖励
--   }
function DragonChallengeData:parseRankList(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local temp = {}
            temp.p_rank = v.rank
            temp.p_points = tonumber(v.points)
            temp.p_name = v.name
            temp.p_facebookId = v.facebookId
            temp.p_head = v.head
            temp.p_frame = v.frame
            temp.p_udid = v.udid
            temp.p_reward = self:parseRewardData(v.reward)
            table.insert(list, temp)
        end
    end
    return list
end

function DragonChallengeData:parseRankInfo(_data)
    local rankInfo = {}
    if _data then
        rankInfo.p_name = _data.name
        rankInfo.p_facebookId = _data.facebookId
        rankInfo.p_head = _data.head
        rankInfo.p_frame = _data.frame
        rankInfo.p_udid = _data.udid
    end
    return rankInfo
end

-- message DragonChallengeReward {
--     optional int64 coins = 1;
--     repeated ShopItem items = 2;
--     optional string coinsV2 = 3;
--   }
function DragonChallengeData:parseRewardData(_data)
    local temp = {}
    if _data then
        temp.p_coins = (_data.coinsV2 and _data.coinsV2 ~= "") and _data.coinsV2 or tonumber(_data.coins)
        temp.p_items = self:parseItemsData(_data.items)
    end
    return temp
end

-- 解析道具数据
function DragonChallengeData:parseItemsData(_data)
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

-- message DragonChallengeWeapon {
--     optional int32 weapon = 1;
--     optional int64 damage = 2;
--   }
function DragonChallengeData:parseWeaponList(_data)
    local list = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local temp = {}
            temp.p_weapon = v.weapon
            temp.p_damage = tonumber(v.damage)
            table.insert(list, temp)
        end
    end
    return list
end

--[[
    message DragonChallengeParts {
        optional int64 totalHp = 1;
        optional int64 currentHp = 2;
        optional int64 points = 3;
        optional int64 rewardPoints = 4;
    }
]]
function DragonChallengeData:parseDragonPartsData(_data)
    local data = {}
    data.totalHp = tonumber(_data.totalHp)
    data.currentHp = tonumber(_data.currentHp)
    data.points = tonumber(_data.points)
    data.rewardPoints = tonumber(_data.rewardPoints)
    return data
end

function DragonChallengeData:getWheels()
    return self.p_wheels
end

function DragonChallengeData:getBossTotalHp()
    return self.p_bossTotalHp
end

function DragonChallengeData:getBossCurrentHp()
    return self.p_bossCurrentHp
end

function DragonChallengeData:getPersonalKillHp()
    return self.p_personalKillHp
end

function DragonChallengeData:getBetList()
    return self.p_betList
end

function DragonChallengeData:getPoints()
    return self.p_points
end

function DragonChallengeData:getRank(_coins)
    return self.p_rank
end

function DragonChallengeData:getJackpotCoins()
    return self.p_jackpotCoins
end

function DragonChallengeData:getTeamTaskList()
    return self.p_teamTaskList
end

function DragonChallengeData:getPersonalTaskList()
    return self.p_personalTaskList
end

function DragonChallengeData:getBuffSale()
    return self.p_buffSale
end

function DragonChallengeData:getWheelSale()
    return self.p_wheelSale
end

function DragonChallengeData:getRankList()
    return self.p_rankList
end

function DragonChallengeData:getWeaponList()
    return self.p_weaponList
end

function DragonChallengeData:getRound()
    return self.p_round or 1
end

function DragonChallengeData:getDamageRate()
    return self.p_damageRate or 1
end

-- 易伤剩余次数
function DragonChallengeData:getVulRemainingTimes()
    return self.p_vulRemainingTimes
end

-- 免伤到期时间戳，初始为0
function DragonChallengeData:getInjuryExpireAt()
    return math.floor(self.p_injuryExpireAt / 1000)
end

-- 是否触发免伤
function DragonChallengeData:getTriggerInjury()
    return self.p_triggerInjury
end

-- 是否触发尾刀
function DragonChallengeData:getTriggerEndKnife()
    return self.p_triggerTailKnifeTips
end

-- 期望bet
function DragonChallengeData:getHopeSpinBet()
    return self.p_hopeSpinBet or 1
end

function DragonChallengeData:getDragonHead()
    return self.p_head
end

function DragonChallengeData:getDragonTorso()
    return self.p_torso
end

function DragonChallengeData:getDragonTail()
    return self.p_tail
end

-- 1-head, 2-torso, 3-tail
function DragonChallengeData:getAttackPartsById(_id)
    if _id == 1 then
        return self.p_head
    elseif _id == 2 then
        return self.p_torso
    elseif _id == 3 then
        return self.p_tail
    end
    return {}
end

-- 1-head, 2-torso, 3-tail
function DragonChallengeData:isAreaBreakById(_id)
    if _id == 1 then
        return self.p_head.currentHp <= 0
    elseif _id == 2 then
        return self.p_torso.currentHp <= 0
    elseif _id == 3 then
        return self.p_tail.currentHp <= 0
    end
    return true
end

function DragonChallengeData:getOriginAreaId()
    if self.p_head.currentHp > 0 then
        return 1
    end
    if self.p_torso.currentHp > 0 then
        return 2
    end
    if self.p_tail.currentHp > 0 then
        return 3
    end
    return 0
end

-- 是否触发易伤
function DragonChallengeData:isTriggerVul()
    return self:getVulRemainingTimes() > 0
end

-- 是否触发免伤
function DragonChallengeData:isTriggerInjury()
    local curTime = util_getCurrnetTime()
    local isInTime = curTime < self:getInjuryExpireAt()
    return self:getTriggerInjury() and isInTime
end

function DragonChallengeData:getCurPersonalTask()
    for i, v in ipairs(self.p_personalTaskList) do
        if not v.p_collected then
            return v
        end
    end
end

function DragonChallengeData:getMyRankIndex()
    local index = 0
    for i, v in ipairs(self.p_rankList) do
        if v.p_udid == globalData.userRunData.userUdid then
            index = i
            break
        end
    end

    return index
end

function DragonChallengeData:parseSpinData(_data)
    -- self.p_bossCurrentHp  = tonumber(_data.currentBossHp)
    -- self.p_jackpotCoins = tonumber(_data.jackpotCoins)
    self.p_wheels = tonumber(_data.wheels)
end

function DragonChallengeData:getPositionBar()
    return 1
end

-- pass --
function DragonChallengeData:getPassData()
    return self.p_dragonPassData
end

function DragonChallengeData:parsePassData(_data)
    if self.p_dragonPassData then
        self.p_dragonPassData:parseData(_data)
    end
end

return DragonChallengeData
