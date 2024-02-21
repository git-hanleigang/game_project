--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-12-15 17:45:31
]]
--[[
    PokerRecallGame

    optional int32 index = 1; //序号
    optional string source = 2; //投放来源
    repeated string buyKey = 3; //付费点  S1 
    repeated string price = 4; //价格
    optional int64 expireAt = 5; //过期时间
    optional int64 expire = 6; //剩余时间
    optional string status = 7; //游戏状态:INIT, PLAYING
    optional bool mark = 8;//是否带付费项
    optional bool pay = 9;//是否付过费
    optional int32 payCount = 10; //付费次数
    optional int32 leftCount = 11; //翻牌剩余次数
    repeated int64 jackpotCoins = 12; //jackPotCoins
    repeated PokerRecall pokers = 13; //翻开的牌
    repeated PokerRecall showPoker = 14;//展示的牌
    repeated string keyValue = 15;//档位value值  slots_casinocashlink_0p99
    optional PokerRecallWin winTypeData = 16;//奖励
]]
local PokerRecallCardData = import(".PokerRecallCardData")
local PokerRecallGameData = class("PokerRecallData")
local PokerUnitData = util_require("activities.Activity_Poker.model.PokerUnitData")
function PokerRecallGameData:ctor()
end

function PokerRecallGameData:parseData(_data)
    self.m_index = _data.index
    self.m_source = _data.source
    self.m_expireAt = tonumber(_data.expireAt)
    self.m_expire = _data.expire
    self.m_status = _data.status

    self.m_isMark = _data.mark
    self.m_isPay = _data.pay
    self.m_payCount = _data.payCount
    self.m_leftCount = _data.leftCount

    if _data.buyKey then
        self.buyKey = {}
        for i=1,#_data.buyKey do
            self.buyKey[i] = _data.buyKey[i]
        end
    end

    if _data.price then
        self.price = {}
        for i = 1, #_data.price do
            self.price[i] = _data.price[i]
        end
    end

    if _data.keyValue then
        self.keyValue = {}
        for i = 1, #_data.keyValue do
            self.keyValue[i] = _data.keyValue[i]
        end
    end

    if _data.jackpotCoins then
        self.jackpotCoins = {}
        for i = 1, #_data.jackpotCoins do
            if i == 1 then
                self.m_totalWin = tonumber(_data.jackpotCoins[i])
            else
                self.jackpotCoins[i - 1] = tonumber(_data.jackpotCoins[i])
            end
        end
    end

    if _data.pokers and #_data.pokers > 0 then
        self.pokers = {}
        self.currentPokers = {}
        for i = 1, #_data.pokers do
            local curPokerData = PokerUnitData:create()
            curPokerData:parseData(_data.pokers[i].poker)
            curPokerData.flag = _data.pokers[i].flag
            table.insert(self.pokers, curPokerData)
            -- self.pokers[i] = {}
            -- self.pokers[i].poker = curPokerData
            -- self.pokers[i].flag = _data.pokers[i].flag
        end
    end

    if _data.showPoker then
        self.showPoker = {}

        for i = 1, #_data.showPoker do
            local pokerUnitData = PokerUnitData:create()
            pokerUnitData:parseData(_data.showPoker[i])
            table.insert(self.showPoker, pokerUnitData)
        end
    end

    if _data.winTypeData then
        -- 玩家中的钱
        self.m_winTypeData = {}
        self.m_winTypeData.coins = tonumber(_data.winTypeData.coins) 
        self.m_winTypeData.winType = _data.winTypeData.winType
    end

end
--获取小游戏ID
function PokerRecallGameData:getGameId()
    return self.m_index
end
--获取投放来源
function PokerRecallGameData:getSource()
    return self.m_souce
end
-- S1
function PokerRecallGameData:getBuyKey()
    return self.m_buyKey
end
--获取付费价格数据（数组）
function PokerRecallGameData:getPrice()
    return self.price
end
-- slots_casinocashlink_0p99
function PokerRecallGameData:getKeyValue()
    return self.keyValue
end
--获得过期时间
function PokerRecallGameData:getExpireAt()
    return self.m_expireAt
end
--获取当前游戏状态
function PokerRecallGameData:getIsPlaying()
    return self.m_status == "PLAYING"
end
--获取是否带付费项
function PokerRecallGameData:getIsMark()
    return self.m_isMark
end
--获取是否付过费
function PokerRecallGameData:getIsPay()
    return self.m_isPay
end
--获取付费次数
function PokerRecallGameData:getPayCount()
    return self.m_payCount
end
--更新翻牌剩余次数
function PokerRecallGameData:setLeftCount(_count)
    self.m_leftCount = _count
end
--获取翻牌剩余次数
function PokerRecallGameData:getLeftCount()
    return self.m_leftCount
end
--获取PayTable奖励
function PokerRecallGameData:getJackpot()
    return self.jackpotCoins
end
--获取最大的PayTable奖励
function PokerRecallGameData:getTotalWin()
    return self.m_totalWin
end
--获取玩家奖励数据
function PokerRecallGameData:getPokerReward()
    return self.m_winTypeData or nil
end

--获取玩家翻过得牌(最多五张)
function PokerRecallGameData:getPokers()
    return self.pokers
end

--获取开场展示20张牌
function PokerRecallGameData:getShowPoker()
    return self.showPoker
end

return PokerRecallGameData
