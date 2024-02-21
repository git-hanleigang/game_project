--[[
    @desc: 跟 LevelRushGameData 一样,复制一份专门做minigame 结构
    time:2021-06-16 18:04:10
]]
local MiniGameLevelFishData = class("MiniGameLevelFishData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function MiniGameLevelFishData:ctor()
end

-- message LevelRushGame {
--     optional int32 index = 1; //序号
--     optional string buyKey = 2; //付费点
--     optional string price = 3; //价格
--     optional int32 leftBalls = 4;//剩余次数
--     optional int64 coins = 5;//金币奖励
--     repeated ShopItem items = 6;//物品奖励
--     optional int64 coinsDis = 7;//金币奖励折扣值
--     optional int64 fishTankDis = 8;//鱼缸奖励折扣值
--     optional bool collected = 9; //奖励领取标识
--     repeated LevelRushGameReward rewardConfig = 10;//奖励配置
--     optional int64 freeMaxCoins = 11;//最大金币奖励-免费
--     optional bool purchased = 12; //奖励领取标识
--     optional int32 endLevel = 13; //完成等级
--     optional int64 payMaxCoins = 14;//最大金币奖励-付费
--     optional int64 expireAt = 15; //过期时间
--     optional int64 expire = 16; //剩余时间
--     optional string source = 17; //投放来源
--   }

function MiniGameLevelFishData:parseGameData(_data)
    self.m_nIndex       = _data.index
    self.m_sBuyKey      = _data.buyKey
    self.m_sPrice       = _data.price
    self.m_nLeftBalls   = _data.leftBalls
    self.m_nCoins       = _data.coins
    self.m_nCoinsDis    = _data.coinsDis
    self.m_nFishTankDis = _data.fishTankDis
    self.m_bCollected   = _data.collected
    self.m_nFreeMaxCoins= _data.freeMaxCoins
    self.m_bPurchased   = _data.purchased
    self.m_nEndLevel    = _data.endLevel
    self.m_nPayMaxCoins = tonumber(_data.payMaxCoins)
    self.m_nExpireAt    = _data.expireAt
    self.m_nExpire      = _data.expire
    self.m_nSource      = _data.source

    if _data.items and next(_data.items) then
        self.m_lShopItemList = self:parseShopItem(_data.items)
    end

    if _data.rewardConfig and #_data.rewardConfig > 0  then
        self:parseRewardConfig(_data.rewardConfig)
    else
        self.m_lRewardConfig = nil
    end
   
end

function MiniGameLevelFishData:getRewardConfig()
    return self.m_lRewardConfig
end

function MiniGameLevelFishData:getLeftBallsCount()
    return self.m_nLeftBalls
end

function MiniGameLevelFishData:getGameIndex()
    return self.m_nIndex
end

function MiniGameLevelFishData:getRewardIsCollect()
    return self.m_bCollected
end

function MiniGameLevelFishData:getHasPurchase()
    return self.m_bPurchased
end

function MiniGameLevelFishData:getGameEndLevel()
    return self.m_nEndLevel
end

function MiniGameLevelFishData:getPayMaxCoins()
    return self.m_nPayMaxCoins
end

function MiniGameLevelFishData:getPrice()
    return self.m_sPrice
end

function MiniGameLevelFishData:getBuyKey()
    return self.m_sBuyKey
end

function MiniGameLevelFishData:getShopItem()
    return self.m_lShopItemList
end

function MiniGameLevelFishData:getMaxRewardCoins()
    return self.m_nFreeMaxCoins
end

function MiniGameLevelFishData:getCoinDis()
    return self.m_nCoinsDis
end

function MiniGameLevelFishData:parseShopItem(_data)
    local data = {}
    for i = 1,#_data do
        local shopItem = ShopItem:create()
        shopItem:parseData(_data[i])
        data[i] = shopItem
    end
    return data
end

-- message LevelRushRewardConfig {
--     optional int32 position = 1;//位置
--     optional int64 freeCoins = 2;//免费版金币
--     repeated ShopItem freeItems = 3;//免费版物品
--     optional int64 payCoins = 4;//付费版金币
--     repeated ShopItem payItems = 5;//付费版物品
--   }

function MiniGameLevelFishData:parseRewardConfig(_data)
    self.m_lRewardConfig = {}
    
    for i = 1,#_data do
        local data = {}
        data.nPosition  = _data[i].position
        data.nFreeCoins = _data[i].freeCoins
        data.nPayCoins  = _data[i].payCoins
        
        data.freeItems  = self:parseShopItem(_data[i].freeItems)
        data.payItems   = self:parseShopItem(_data[i].payItems)
        data.sType      = _data[i].type

        self.m_lRewardConfig[i] = data
    end
end

function MiniGameLevelFishData:getRewardByIndex(_nIndex)
    for i=1,#self.m_lRewardConfig do
        local data = self.m_lRewardConfig[i]
        if data.nPosition == _nIndex then
            return data
        end
    end
    return nil
end

--grandJp 唯一
function MiniGameLevelFishData:getGrandJpReward()
    for i=1,#self.m_lRewardConfig do
        local data = self.m_lRewardConfig[i]
        if data.sType == "Grand" then
            return data
        end
    end
    return nil
end

--majorJp 唯一
function MiniGameLevelFishData:getMajorJpReward()
    for i=1,#self.m_lRewardConfig do
        local data = self.m_lRewardConfig[i]
        if data.sType == "Major" then
            return data
        end
    end
    return nil
end

function MiniGameLevelFishData:checkHasRewards()
    if self.m_lRewardConfig and #self.m_lRewardConfig > 0 then
        return true
    end
    return false
end

-- leftBalls 
function MiniGameLevelFishData:getLeftBalls()
    return self.m_nLeftBalls
end

function MiniGameLevelFishData:getRewardBaseCoins()
    return self.m_nCoins 
end

-- rewardCoins 
function MiniGameLevelFishData:getRewardCoins()
    return self.m_nCoins + self.m_nCoins*self.m_nCoinsDis*0.01
end

-- 参数：外部操作(玩家点击了确认付费界面的关闭按钮)，影响游戏结束
function MiniGameLevelFishData:setClickXInPayConfirm()
    self.m_isClickXInPayConfirm = true
end

function MiniGameLevelFishData:getClickXInPayConfirm()
    return self.m_isClickXInPayConfirm
end

--添加新接口返回剩余时间
function MiniGameLevelFishData:getTodayLeftTime()
    local strTime, isOver = util_daysdemaining(self.m_nExpireAt / 1000)
    return strTime, isOver
end

function MiniGameLevelFishData:getSource( )
    return self.m_nSource
end

return MiniGameLevelFishData