local BaseRoomData = class("BaseRoomData")

-- ctor
function BaseRoomData:ctor()
    self.m_winCoins = 0

    self.m_teamData = {}
    self.m_teamData.wins = {} --奖励箱信息
    self.m_teamData.sets = {} -- 座位信息
    self.m_teamData.events = {} -- 房间内的事件
    self.m_teamData.room = {} -- 房间信息
    self.m_teamData.room.ranks = {} --排行榜
    self.m_teamData.room.collects = {} --收集数据
end

function BaseRoomData:reset()

end

function BaseRoomData:getInstance()
    if not self._instance then
        self._instance = BaseRoomData.new()
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
--     optional double multiple = 5; //倍数
--     optional double odds = 6; //倍数
--     optional string frame = 7; //头像框
--   }

--   message TeamMissionSet {
--     optional string udid = 1; //udid
--     optional string head = 2; //头像
--     optional string facebookId = 3; //fb头像
--     optional string nickName = 4; //昵称
--     optional int32 chairId = 5; //座位号
--     optional string robot = 6; //机器人名称
--     optional string frame = 7; //头像框
--   }

--   message TeamMissionSelect {
--     optional string udid = 1; //udid
--     optional int32 position = 2; //位置
--     optional int32 status = 3; //状态
--     repeated int32 chooses = 4; //选择信息
--     optional int32 status = 5; //状态
--     repeated int32 chooses = 6; //选择信息
--     optional string frame = 7; //头像框
--   }

--   message TeamMissionRoom {
--     repeated TeamMissionRank ranks = 1; //排行榜
--     repeated TeamMissionCollect collects = 2; //收集数据
--     optional string result = 3; //结算数据
--     optional string extra = 4; //其他信息
--     repeated TeamMissionSelect selects = 5; //选择数据
--     optional int32 status = 6; //房间状态 0默认、1已触发玩法
--     optional int64 triggerTime = 7; //玩法触发时间
--     optional int64 completeTime = 8; //玩法完成时间
--     optional int64 endTime = 9; //玩法结束时间
--     optional TeamMissionSet triggerPlayer = 10; //触发玩法的玩家
--   }

--   message TeamMissionRank {
--     optional string udid = 1; //udid
--     optional string head = 2; //头像
--     optional string facebookId = 3; //fb头像
--     optional int32 value = 4;
--     optional string frame = 5; //头像框
--   }

--   message TeamMissionCollect {
--     optional string udid = 1; //udid
--     optional string head = 2; //头像
--     optional string facebookId = 3; //fb头像
--     optional int64 coins = 4; //金币
--     optional int32 position = 5; //位置
--     optional int32 multiple = 6; //倍数
--     optional string nickName = 7; //昵称
--     optional string frame = 8; //头像框

--   }

function BaseRoomData:parseRoomData(data)
    local teamMissionData = {}
    teamMissionData.game = data.game -- 关卡
    teamMissionData.roomId = data.roomId -- 房间号

    teamMissionData.wins = {} --奖励箱信息
    for i, win in ipairs(data.wins) do
        local winData = {}
        winData.udid = win.udid -- udid
        winData.head = win.head -- 头像
        winData.facebookId = win.facebookId -- fb头像
        winData.robot = win.robot or "" -- 热更目录头像
        winData.coins = tonumber(win.coins) -- 金币
        winData.multiple =  win.multiple    -- 乘倍
        winData.frame = win.frame -- 头像框
        table.insert(teamMissionData.wins, winData)
    end

    teamMissionData.sets = {} -- 座位信息
    for i, set in ipairs(data.sets) do
        local setData = {}
        setData.udid = set.udid --udid
        setData.head = set.head -- 头像
        setData.facebookId = set.facebookId -- fb头像
        setData.robot = set.robot or "" -- 热更目录头像
        setData.chairId = set.chairId--座位号
        setData.frame = set.frame --头像框
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
        rankData.robot = rank.robot or "" -- 热更目录头像
        rankData.value = tonumber(rank.value)
        rankData.frame = rank.frame -- 头像框
        rankData.nickName = rank.nickName -- 昵称
        table.insert(teamMissionData.room.ranks, rankData)
    end

    teamMissionData.room.collects = {} --收集数据
    for i, collect in ipairs(data.room.collects) do
        local collectData = {}
        collectData.udid = collect.udid --udid
        collectData.head = collect.head -- 头像
        collectData.facebookId = collect.facebookId -- fb头像
        collectData.robot = collect.robot or "" -- 热更目录头像
        collectData.coins = tonumber(collect.coins)
        collectData.position = tonumber(collect.position)
        collectData.multiple = tonumber(collect.multiple)
        collectData.nickName = tostring(collect.nickName)   --昵称
        collectData.frame = collect.frame --头像框
        table.insert(teamMissionData.room.collects, collectData)
    end
    if data.room.result ~= "" then
        local resultData = cjson.decode(data.room.result) --json格式
        teamMissionData.room.result = resultData --结算数据
    end
    if data.room.extra then
        local temp = type(data.room.extra)
        if type(data.room.extra) == "string" and data.room.extra ~= "" then
            teamMissionData.room.extra = cjson.decode(data.room.extra)
        else
            teamMissionData.room.extra = data.room.extra
        end
        
    end

    --房间状态
    teamMissionData.room.status = data.room.status

    teamMissionData.room.selects = {}   
    for k,selectInfo in pairs(data.room.selects) do
        local temp = type(k)
        if type(k) == "number" then
            local info = {}
            info.udid = selectInfo.udid
            info.position = selectInfo.position
            info.status = selectInfo.status
            info.head = selectInfo.head
            info.frame = selectInfo.frame -- 头像框
            info.chooses = {}
            for index = 1,3 do
                info.chooses[index] = selectInfo.chooses[index]
            end 

            table.insert(teamMissionData.room.selects,#teamMissionData.room.selects + 1,info)
        end
        
    end

    --玩法触发时间
    if data.room.triggerTime then
        teamMissionData.room.triggerTime = cjson.decode(data.room.triggerTime)
    end

    if data.room.triggerPlayer then
        local triggerPlayer = {
            udid = data.room.triggerPlayer.udid, --udid
            head = data.room.triggerPlayer.head, --头像
            facebookId = data.room.triggerPlayer.facebookId, -- fb头像
            robot = data.room.triggerPlayer.robot or "" , -- 热更目录头像
            nickName = data.room.triggerPlayer.nickName or "",   --用户昵称
            frame = data.room.triggerPlayer.frame
        }
        teamMissionData.room.triggerPlayer = triggerPlayer
    end

    --玩法完成时间
    if data.room.completeTime then
        teamMissionData.room.completeTime = cjson.decode(data.room.completeTime)
    end

    --玩法结束时间
    if data.room.endTime then
        teamMissionData.room.endTime = cjson.decode(data.room.endTime)
    end
    dumpStrToDisk(teamMissionData,"------------> 房间数据 = ",50 )
    --其他信息
    self.m_teamData = teamMissionData
end

function BaseRoomData:getRoomPlayersInfo()
    if self.m_teamData then
        return self.m_teamData.sets
    end
end

function BaseRoomData:getWinSpots()
    if self.m_teamData then
        return self.m_teamData.wins
    end
end

function BaseRoomData:getMailWinCoins()
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

function BaseRoomData:getRoomEvent()
    if self.m_teamData then
        return self.m_teamData.events
    end
end

function BaseRoomData:getRoomRanks()
    if self.m_teamData then
        return self.m_teamData.room.ranks
    end
end

function BaseRoomData:getRoomCollects()
    if self.m_teamData then
        return self.m_teamData.room.collects
    end
end

function BaseRoomData:getSpotResult()
    if self.m_teamData then
        return self.m_teamData.room.result
    end
end

--[[
    获取房间数据
]]
function BaseRoomData:getRoomData()
    if self.m_teamData then
        return self.m_teamData.room
    end
end
function BaseRoomData:release()
    self.m_teamData = {}
end

return BaseRoomData

-- Global Var --
-- GD.PopRoomData = BaseRoomData:getInstance()