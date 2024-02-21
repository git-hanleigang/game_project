local BaseActivityData = util_require("baseActivity.BaseActivityData")
local YearEndSummaryData = class("YearEndSummaryData", BaseActivityData)

--[[
    message AnnualSummary {
        optional int64 spinTimes = 6;//总spin次数
        optional int32 playGameCount = 7;//玩过关卡数量
        optional string totalWinCoins = 8;//玩家总赢钱数
        optional int32 activeDays = 9;//玩家活跃天数
        optional string title = 10;//称号
        optional AnnualSummaryWinCoinsGame winCoinsGame = 11;//玩家获得最大赢钱数量以及对应关卡
        repeated AnnualSummarySpinTimesGame spinTimesGame = 12;//玩家spin次数最多的三个关卡以及对应spin次数
        optional bool collect = 13;//是否已经分享过了
        optional string titleDescription = 14;//称号描述上
        optional string titleDescription1 = 15;//称号描述下

        -- 2023 新增字段
        optional string spinTimesRank = 16;//spin总数排名(百分比)
        repeated AnnualSummarySpinTimesGame spinTimesAllGame = 17; //整个游戏spin次数最多的的三个关卡及对应spin次数
        optional string totalWinCoinsRank = 18; //玩家总赢钱数排名(百分比)
        optional string friendGaveCoins = 19; //玩家当年通过好友系统赠送的金币
        optional int64 friendGaveCards = 20;//玩家当年通过好友系统赠送的卡片数量
    }

    message AnnualSummaryWinCoinsGame {
        optional string game = 1;//关卡
        optional int64 winCoins = 2;//最大赢钱数
    }
    message AnnualSummarySpinTimesGame {
        optional string game = 1;//关卡
        optional int64 spinTimes = 2;//关卡spin次数
    }

]]

function YearEndSummaryData:ctor()
    YearEndSummaryData.super.ctor(self)
    self.m_totalWinCoins = toLongNumber(0)

end

function YearEndSummaryData:parseData(_data)
    YearEndSummaryData.super.parseData(self, _data)
    self.m_spinTimes = _data.spinTimes  --总spin次数
    self.m_playGameCount = _data.playGameCount --玩过关卡数量
    self.m_totalWinCoins:setNum(_data.totalWinCoins) --玩家总赢钱数
    self.m_activeDays = _data.activeDays --玩家活跃天数
    self.m_title = _data.title --称号
    self.m_titleDescription = _data.titleDescription --称号描述
    self.m_titleDescription1 = _data.titleDescription1 or "" --称号描述 1

    self.m_winCoinsGame = {} --玩家获得最大赢钱数量以及对应关卡
    if _data.winCoinsGame then
        self.m_winCoinsGame.m_game = _data.winCoinsGame.game --关卡
        self.m_winCoinsGame.m_winCoins = _data.winCoinsGame.winCoins  --最大赢钱数
    end

    self.m_spinTimesGame = {} --玩家spin次数最多的三个关卡以及对应spin次数
    if _data.spinTimesGame and #_data.spinTimesGame > 0 then
        for i,v in ipairs(_data.spinTimesGame) do
            local oneData = {}
            oneData.m_game = v.game --关卡
            oneData.m_spinTimes = v.spinTimes --关卡spin次数
            table.insert(self.m_spinTimesGame,oneData)
        end
    end
    self.m_collect = _data.collect --是否已经分享过了

    self.p_spinTimesRank = _data.spinTimesRank
    
    self.p_spinTimesAllGame = {}
    if _data.spinTimesAllGame and #_data.spinTimesAllGame > 0 then
        for i, v in ipairs(_data.spinTimesAllGame) do
            local oneData = {}
            oneData.m_game = v.game --关卡
            oneData.m_spinTimes = v.spinTimes --关卡spin次数
            table.insert(self.p_spinTimesAllGame, oneData)
        end
    end

    self.p_totalWinCoinsRank = _data.totalWinCoinsRank
    self.p_friendGaveCoins = toLongNumber(_data.friendGaveCoins)
    self.p_friendGaveCards = toLongNumber(_data.friendGaveCards)
end

function YearEndSummaryData:isCollect()
    return self.m_collect
end

function YearEndSummaryData:getSpinTimesRank()
    return math.floor(self.p_spinTimesRank)
end

function YearEndSummaryData:getSpinTimesAllGame()
    return self.p_spinTimesAllGame
end

function YearEndSummaryData:getTotalWinCoinsRank()
    return self.p_totalWinCoinsRank
end

function YearEndSummaryData:getFriendGaveCoins()
    return self.p_friendGaveCoins
end

function YearEndSummaryData:getFriendGaveCards()
    return self.p_friendGaveCards
end

return YearEndSummaryData
