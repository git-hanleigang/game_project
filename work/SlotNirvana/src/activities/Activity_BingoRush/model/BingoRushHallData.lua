-- bingo比赛 房间信息

local BaseActivityData = require "baseActivity.BaseActivityData"
local BingoRushHallData = class("BingoRushHallData", BaseActivityData)

function BingoRushHallData:ctor()
    BingoRushHallData.super.ctor(self)
    -- 玩家列表 房间数据
    self.roomId = nil
    self.curBetIndex = nil
    self.hall_data = {chairs = {}, roomData = {}}
    self.round3_startTime = nil
    self.round3_endTime = nil
end

--{
--    "betIndex": 0,    -- bet档位
--    "lostUser": false, -- 是否参与第三轮
--    "matchFail": false, -- 是否匹配失败
--    "chairs": {   -- 玩家列表
--        "0": {
--            "chairId": 0, -- 座位号
--            "expireAt": 1640938400925,    -- 保留时间 超时座位信息将失效 暂时没用到
--            "head": "",   -- fb头像
--            "facebookId": "" -- fbID
--            "nickName": "Guest1733",  -- 玩家昵称
--            "roomId": "1640578400957-78349",  -- 房间号 暂时没用
--            "udid": "TEST_2"
--        }
--    },
--    "roomData": {
--        "matchedTime": 1640578627590, -- 匹配成功时间
--        "firstRoundReadyExpireAt": 1640578628590, -- 第一轮开始spin时间
--        "firstRoundSpinExpireAt": 1640938628590,  -- 第一轮spin时间
--        "secondRoundReadyExpireAt": 1640938629590, -- 第二轮开始spin时间
--        "secondRoundSpinExpireAt": 1641298629590, -- 第二轮spin时间
--        "thirdRoundReadyExpireAt": 1641298629590, -- 第三轮开始时间
--        "thirdRoundSettleExpireAt": 1641298634590 -- 第三轮结束时间
--    },
--    "roomId": "1640578400957-78349"
--}
-- 解析房间数据
function BingoRushHallData:parseData(data)
    if not data then
        return
    end

    if data.error then
        return
    end

    if data.roomId then
        self.roomId = data.roomId
    end

    if data.betIndex then
        self.curBetIndex = data.betIndex
    else
        self.curBetIndex = -1
    end

    if not self.hall_data then
        self.hall_data = {}
    end

    if data.roomData then
        self:setRoundStartTime(0, data.roomData.firstRoundReadyExpireAt)
        self:setRoundEndTime(0, data.roomData.firstRoundSpinExpireAt)

        self:setRoundStartTime(1, data.roomData.secondRoundReadyExpireAt)
        self:setRoundEndTime(1, data.roomData.secondRoundSpinExpireAt)

        self:setRoundStartTime(2, data.roomData.thirdRoundReadyExpireAt)
        self:setRoundEndTime(2, data.roomData.thirdRoundSettleExpireAt)

        self.hall_data.readyTime = data.roomData.matchedContinue
        self.hall_data.matchingTime = data.roomData.matchExpireAt
    end

    if data.chairs then
        local round, bl_inHall = self:getCurRoundAndState()
        if bl_inHall == true and round == -1 then
            local new_players = self:setNewPlayers(data.chairs)
            if new_players then
                local round, bl_inHall = self:getCurRoundAndState()
                if round < 0 and bl_inHall then
                    self:pushPlayerMsg(new_players)
                end
            end
        end
        self.hall_data.chairs = data.chairs
    end
end

function BingoRushHallData:setNewPlayers(players)
    local isNewPlayer = false
    if not self.hall_data.chairs or table.nums(self.hall_data.chairs) <= 0 then
        isNewPlayer = true
    end
    local new_players = {}
    local myUdid = gLobalSendDataManager:getDeviceUuid()
    for _, player_data in pairs(players) do
        if isNewPlayer then
            if player_data.udid == myUdid then
                table.insert(new_players, player_data)
                break
            end
        else
            local idx = tostring(player_data.chairId)
            if not self.hall_data.chairs[idx] or self.hall_data.chairs[idx].udid ~= player_data.udid then
                self.hall_data.chairs[idx] = player_data
                table.insert(new_players, player_data)
            end
        end
    end
    return new_players
end

function BingoRushHallData:isTeamReady()
    if not self.hall_data.readyTime or self.hall_data.readyTime <= 0 then
        return false
    end
    local curTime = util_getCurrnetTime()
    local time_left = self.hall_data.readyTime / 1000 - curTime
    return time_left <= 0
end

function BingoRushHallData:getMatchTimeLeft()
    if not self.hall_data then
        return 0
    end
    local match_time = 0
    if self.hall_data.matchingTime then
        match_time = self.hall_data.matchingTime / 1000
    end

    if self.hall_data.readyTime ~= nil and self.hall_data.readyTime > 0 then
        match_time = self.hall_data.readyTime / 1000
    end
    local left_time = 0
    if match_time and match_time > 0 then
        local curTime = util_getCurrnetTime()
        left_time = match_time - curTime
    end
    return left_time
end

function BingoRushHallData:getRoundStartTime(_roundIdx)
    if not self.hall_data or not self.hall_data.p_expireAt then
        return 0
    end
    local round_time = self.hall_data.p_expireAt[_roundIdx]
    if not round_time then
        return 0
    end
    if round_time and round_time[1] then
        local time = math.ceil(round_time[1] / 1000)
        if _roundIdx == 2 then
            if self.round3_startTime then
                if self.round3_startTime > time then
                    return self.round3_startTime
                else
                    self.round3_startTime = nil
                end
            end
        end
        return time
    end
end

function BingoRushHallData:setRoundStartTime(_roundIdx, time)
    if not self.hall_data.p_expireAt then
        self.hall_data.p_expireAt = {}
    end
    if not self.hall_data.p_expireAt[_roundIdx] then
        self.hall_data.p_expireAt[_roundIdx] = {}
    end
    local round_time = self.hall_data.p_expireAt[_roundIdx]
    if round_time and time then
        round_time[1] = time
    end
end

function BingoRushHallData:getRoundEndTime(_roundIdx)
    local round_time = self.hall_data.p_expireAt[_roundIdx]
    if round_time and round_time[2] then
        local time = math.ceil(round_time[2] / 1000)
        if _roundIdx == 2 then
            if self.round3_endTime then
                if self.round3_endTime > time then
                    return self.round3_endTime
                else
                    self.round3_endTime = nil
                end
            end
        end
        return time
    end
end

function BingoRushHallData:setRoundEndTime(_roundIdx, time)
    if not self.hall_data.p_expireAt then
        self.hall_data.p_expireAt = {}
    end
    if not self.hall_data.p_expireAt[_roundIdx] then
        self.hall_data.p_expireAt[_roundIdx] = {}
    end
    local round_time = self.hall_data.p_expireAt[_roundIdx]
    if round_time and time then
        if round_time[2] then
            printInfo("BingoRushHallData 重复设置 旧时间 " .. round_time[2] .. " 新时间 " .. time .. " 轮次 " .. _roundIdx)
        end
        round_time[2] = time
    end
end

function BingoRushHallData:getCurRoundAndState()
    local round = -1
    local bl_inHall = true
    if not self:isTeamReady() then
        return round, bl_inHall
    end

    local curTime = util_getCurrnetTime()

    local round1_startTime = self:getRoundStartTime(0)
    local round1_endTime = self:getRoundEndTime(0)

    local round2_startTime = self:getRoundStartTime(1)
    local round2_endTime = self:getRoundEndTime(1)

    local round3_startTime = self:getRoundStartTime(2)
    local round3_endTime = self:getRoundEndTime(2)

    -- 在三个阶段的持续时间内
    if (curTime >= round1_startTime and curTime < round1_endTime) or (curTime >= round2_startTime and curTime < round2_endTime) or (curTime >= round3_startTime and curTime < round3_endTime) then
        bl_inHall = false
    end
    if curTime < round1_endTime then
        round = 0
    elseif curTime < round2_endTime then
        round = 1
    elseif curTime < round3_endTime then
        round = 2
    end

    return round, bl_inHall
end

function BingoRushHallData:pushPlayerMsg(new_players)
    if not new_players or table.nums(new_players) <= 0 then
        return
    end

    local BingoRushConfig = G_GetMgr(ACTIVITY_REF.BingoRush):getConfig()
    local msg_type = BingoRushConfig.MSG_TYPE.HALL
    for _, player_data in ipairs(new_players) do
        G_GetMgr(ACTIVITY_REF.BingoRush):pushMsg(msg_type, player_data)
    end
end

function BingoRushHallData:pushRoundMsg(tipIdx, blStay)
    if blStay == nil then
        blStay = false
    end
    local BingoRushConfig = G_GetMgr(ACTIVITY_REF.BingoRush):getConfig()
    local msg_type = BingoRushConfig.MSG_TYPE.HALL

    G_GetMgr(ACTIVITY_REF.BingoRush):pushMsg(msg_type, {roundTip = tipIdx, bl_stay = blStay})
end

function BingoRushHallData:getPlayers()
    return self.hall_data.chairs
end

function BingoRushHallData:getPlayerDataById(chairId)
    if not chairId then
        return
    end

    local players = self:getPlayers()
    if players and table.nums(players) > 0 then
        for _, player_data in pairs(players) do
            if player_data.chairId ~= nil and tonumber(chairId) == player_data.chairId then
                return player_data
            end
        end
    end
end

function BingoRushHallData:getPlayerNums()
    local players = self:getPlayers()
    if players then
        return table.nums(players)
    end
    return 0
end

function BingoRushHallData:getBetIdx()
    return self.curBetIndex
end

function BingoRushHallData:clearData()
    self.roomId = nil
    self.curBetIndex = nil
    self.hall_data = {chairs = {}, roomData = {}}
    self.round3_startTime = nil
    self.round3_endTime = nil
end

-- 依据当前剩余时间重置轮次时间表
local bingoRoundTipKeepsTime = 20
function BingoRushHallData:resetFinalRoundTime()
    local curRound, bl_inHall = self:getCurRoundAndState()

    if curRound == 2 and bl_inHall == true then
        local curTime = util_getCurrnetTime()
        local round3_startTime = self:getRoundStartTime(2)
        local round3_endTime = self:getRoundEndTime(2)
        if round3_startTime > curTime and round3_startTime - curTime < bingoRoundTipKeepsTime then
            local time_offset = bingoRoundTipKeepsTime - (round3_startTime - curTime)
            local start_time = round3_startTime + time_offset
            local end_time = round3_endTime + time_offset

            self.round3_startTime = start_time
            self.round3_endTime = end_time
        end
    end
end

return BingoRushHallData
