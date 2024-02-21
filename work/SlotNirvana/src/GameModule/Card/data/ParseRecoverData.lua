--[[--
    回收机数据
]]
local ParseRecoverData = class("ParseRecoverData")

function ParseRecoverData:ctor()
end

-- CARDWHEELCONFIG
function ParseRecoverData:parseData(_netData)
    self.p_coolDown = _netData.coolDown
    self.p_stars = _netData.stars

    self.p_wheels = {}
    local count = 1
    while _netData.wheels[count] do
        self.p_wheels[count] = self:ParseCardWheelInfo(_netData.wheels[count])
        count = count + 1
    end

    self.p_lettos = {}
    local count = 1
    while _netData.lettos[count] do
        self.p_lettos[count] = self:ParseCardLettoInfo(_netData.lettos[count])
        count = count + 1
    end
end

function ParseRecoverData:getCooldown()
    return tonumber(self.p_coolDown) or 0
end

function ParseRecoverData:getStarNum()
    return self.p_stars or 0
end

function ParseRecoverData:getWheelConfig()
    return self.p_wheels or {}
end

function ParseRecoverData:getLettos()
    return self.p_lettos
end

-- CARDWHEEL
-- ("level"      ,  ... , 1 , false , 0     , "int32"   )   --回收机等级，0初级，1中级，2高级
-- ("needStars"  ,  ... , 1 , false , 0     , "int32"   )   --所需要星星数量
-- ("wheelRewards", ... , 3 , false , {}    , "struct" ,  CARDWHEELREWARD  ) --回收机的轮盘奖励数据
-- ("maxReward" ,  ... , 3 , false , {}    , "struct" ,  CARDWHEELREWARD  ) --可获得最大奖励
function ParseRecoverData:ParseCardWheelInfo(wheelData)
    local temp = {}
    if not wheelData then
        return temp
    end
    local baseKeys = {"level", "needStars"}

    for k, v in pairs(baseKeys) do
        if wheelData[v] then
            temp[v] = wheelData[v]
        end
    end

    if wheelData.wheelRewards then
        temp.wheelRewards = self:ParseCardWheelRewardInfo(wheelData.wheelRewards)
    end
    if wheelData.maxReward then
        temp.maxReward = self:ParseCardMaxRewardInfo(wheelData.maxReward)
    end

    if CardProto_pb ~= nil then
        if wheelData.maxReward then
            temp.maxReward = wheelData.maxReward
        end
    else
        if wheelData.maxRewards then
            temp.maxRewards = self:ParseCardWheelRewardInfo(wheelData.maxRewards)
        end
    end

    return temp
end

-- CARDLETTO
-- ("level"      ,  ... , 1 , false , 0     , "int32"   )   --回收机等级，0初级，1中级，2高级
-- ("needStars"  ,  ... , 1 , false , 0     , "int32"   )   --所需要星星数量
-- ("balls", ... , 3 , false , {}    , "struct" ,  CARDLETTOBALL  ) --乐透球列表
-- ("maxReward" ,  ... , 3 , false , {}    , "struct" ,  CARDWHEELREWARD  ) --可获得最大奖励
function ParseRecoverData:ParseCardLettoInfo(wheelData)
    local temp = {}
    if not wheelData then
        return temp
    end
    local baseKeys = {"level", "needStars"}

    for k, v in pairs(baseKeys) do
        if wheelData[v] then
            temp[v] = wheelData[v]
        end
    end

    temp.baseCoins = wheelData.baseCoins

    if wheelData.balls then
        temp.balls = self:ParseCardLettoRewardInfo(wheelData.balls)
    end
    if wheelData.maxReward then
        temp.maxReward = self:ParseCardMaxRewardInfo(wheelData.maxReward)
    end

    if CardProto_pb ~= nil then
        if wheelData.maxReward then
            temp.maxReward = wheelData.maxReward
        end
    else
        if wheelData.maxRewards then
            temp.maxRewards = self:ParseCardWheelRewardInfo(wheelData.maxRewards)
        end
    end

    return temp
end

-- CARDWHEELREWARD
-- ("coins"  , "int64"   )   --奖励金币数量
-- ("rewards", "struct" ,  BaseProto_pb.SHOPITEM  ) --其他奖励物品
function ParseRecoverData:ParseCardWheelRewardInfo(rewards)
    local temp = {}
    if not rewards then
        return temp
    end

    for i = 1, #rewards do
        local rewardData = rewards[i]
        temp[i] = {}
        if rewardData.coins then
            temp[i].coins = rewardData.coins
        end
        if rewardData.rewards then
            temp[i].rewards = self:parseShopItem(rewardData.rewards)
        end
    end
    return temp
end

-- CARDLETTOBALL
-- ("multiply"  , "int32"   )   --奖励倍数
-- ("dropCard", "bool"  ) --是否掉卡
function ParseRecoverData:ParseCardLettoRewardInfo(rewards)
    local temp = {}
    if not rewards then
        return temp
    end

    for i = 1, #rewards do
        local rewardData = rewards[i]
        temp[i] = {}
        if rewardData.multiply then
            temp[i].multiply = rewardData.multiply
        end
        if rewardData.dropCard then
            temp[i].dropCard = rewardData.dropCard
        end
    end
    return temp
end

-- CARDWHEELREWARD
-- ("coins"  , "int64"   )   --奖励金币数量
-- ("rewards", "struct" ,  BaseProto_pb.SHOPITEM  ) --其他奖励物品
function ParseRecoverData:ParseCardMaxRewardInfo(rewardData)
    local temp = {}
    if not rewardData then
        return temp
    end

    if rewardData.coins then
        temp.coins = rewardData.coins
    end
    if rewardData.rewards then
        temp.rewards = self:parseShopItem(rewardData.rewards)
    end
    return temp
end

function ParseRecoverData:parseShopItem(rewards)
    local temp = {}
    if not rewards then
        return temp
    end
    for i = 1, #rewards do
        temp[i] = self:parseShopReward(rewards[i])
    end
    return temp
end

function ParseRecoverData:parseShopReward(rewardData)
    local shopItem = ShopItem:create()
    shopItem:parseData(rewardData)
    return shopItem:getData()
end

return ParseRecoverData
