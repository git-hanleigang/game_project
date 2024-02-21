local LottoPartyManager = class("LottoPartyManager")

-- ctor
function LottoPartyManager:ctor()
    self.m_winCoins = 0

    self.m_teamData = {}
    self.m_teamData.wins = {} --奖励箱信息
    self.m_teamData.sets = {} -- 座位信息
    self.m_teamData.events = {} -- 房间内的事件
    self.m_teamData.room = {} -- 房间信息
    self.m_teamData.room.ranks = {} --排行榜
    self.m_teamData.room.collects = {} --收集数据
end

function LottoPartyManager:reset()
end
-- get Instance --
function LottoPartyManager:getInstance()
    if not self._instance then
        self._instance = LottoPartyManager.new()
    end
    return self._instance
end

-- message TeamMission {
--     optional string game = 1; //关卡
--     optional string roomId = 2; //房间号
--     repeated TeamMissionWin wins = 3; //奖励箱
--     repeated TeamMissionSet sets = 4; //座位
--     repeated TeamMissionEvent events = 5; //房间内的事件
--     optional TeamMissionRoom room = 6; //房间信息
--   }

--   message TeamMissionWin {
--     optional string udid = 1; //udid
--     optional string head = 2; //头像
--     optional string facebookId = 3; //fb头像
--     optional int64 coins = 4; //金币
--   }

--   message TeamMissionSet {
--     optional string udid = 1; //udid
--     optional string head = 2; //头像
--     optional string facebookId = 3; //fb头像
--   }

--   message TeamMissionEvent {
--     optional string udid = 1; //udid
--     optional string eventType = 2; //事件类型
--     optional string value = 3;
--     optional string extra = 4; //其他
--   }

--   message TeamMissionRoom {
--     repeated TeamMissionRank ranks = 1; //排行榜
--     repeated TeamMissionCollect collects = 2; //收集数据
--     repeated string result = 3; //结算数据
--     optional string extra = 4; //其他信息
--   }

--   message TeamMissionRank {
--     optional string udid = 1; //udid
--     optional string head = 2; //头像
--     optional string facebookId = 3; //fb头像
--     optional int32 value = 4;
--   }

--   message TeamMissionCollect {
--     optional string udid = 1; //udid
--     optional string head = 2; //头像
--     optional string facebookId = 3; //fb头像
--     optional int64 coins = 4; //金币
--     optional int32 position = 5; //位置
--     optional int32 multiple = 6; //倍数
--   }

function LottoPartyManager:parseLottoPartyData(data)
    local teamMissionData = {}
    teamMissionData.game = data.game -- 关卡
    teamMissionData.roomId = data.roomId -- 房间号

    teamMissionData.wins = {} --奖励箱信息
    for i, win in ipairs(data.wins) do
        local winData = {}
        winData.udid = win.udid -- udid
        winData.head = win.head -- 头像
        winData.facebookId = win.facebookId -- fb头像
        winData.coins = tonumber(win.coins) -- 金币
        winData.frame = win.frame   --头像框
        table.insert(teamMissionData.wins, winData)
    end

    teamMissionData.sets = {} -- 座位信息
    for i, set in ipairs(data.sets) do
        local setData = {}
        setData.udid = set.udid --udid
        setData.head = set.head -- 头像
        setData.facebookId = set.facebookId -- fb头像
        table.insert(teamMissionData.sets, setData)
    end

    teamMissionData.events = {} -- 房间内的事件
    for i, event in ipairs(data.events) do
        local eventsData = {}
        eventsData.udid = event.udid --udid
        eventsData.eventType = event.eventType -- 事件类型
        eventsData.value = event.value -- 值
        eventsData.extra = event.extra -- 其他
        table.insert(teamMissionData.events, eventsData)
    end

    teamMissionData.room = {} -- 房间信息
    teamMissionData.room.ranks = {} --排行榜
    for i, rank in ipairs(data.room.ranks) do
        local rankData = {}
        rankData.udid = rank.udid --udid
        rankData.head = rank.head -- 头像
        rankData.facebookId = rank.facebookId -- fb头像
        rankData.value = tonumber(rank.value)
        rankData.frame = rank.frame     --头像框
        table.insert(teamMissionData.room.ranks, rankData)
    end

    teamMissionData.room.collects = {} --收集数据
    for i, collect in ipairs(data.room.collects) do
        local collectData = {}
        collectData.udid = collect.udid --udid
        collectData.head = collect.head -- 头像
        collectData.facebookId = collect.facebookId -- fb头像
        collectData.coins = tonumber(collect.coins)
        collectData.position = tonumber(collect.position)
        collectData.multiple = tonumber(collect.multiple)
        collectData.frame = collect.frame
        table.insert(teamMissionData.room.collects, collectData)
    end
    if data.room.result ~= "" then
        local resultData = cjson.decode(data.room.result) --json格式
        teamMissionData.room.result = resultData --结算数据
    end
    if data.room.extra then
        teamMissionData.room.extra = data.room.extra
    end
    --其他信息
    self.m_teamData = teamMissionData
end

function LottoPartyManager:getRoomPlayersInfo()
    if self.m_teamData then
        return self.m_teamData.sets
    end
end

function LottoPartyManager:getWinSpots()
    if self.m_teamData then
        return self.m_teamData.wins
    end
end

function LottoPartyManager:getMailWinCoins()
    local winCoins = 0
    if self.m_teamData then
        if self.m_teamData.wins then
            for i, v in ipairs(self.m_teamData.wins) do
                winCoins = winCoins + v.coins
            end
        end
    end
    return winCoins
end

function LottoPartyManager:getRoomEvent()
    if self.m_teamData then
        return self.m_teamData.events
    end
end

function LottoPartyManager:getRoomRanks()
    if self.m_teamData then
        return self.m_teamData.room.ranks
    end
end

function LottoPartyManager:getRoomCollects()
    if self.m_teamData then
        return self.m_teamData.room.collects
    end
end

function LottoPartyManager:getSpotResult()
    if self.m_teamData then
        return self.m_teamData.room.result
    end
end
function LottoPartyManager:release()
    self.m_teamData = {}
end
-- Global Var --
GD.LottoPartyManager = LottoPartyManager:getInstance()
