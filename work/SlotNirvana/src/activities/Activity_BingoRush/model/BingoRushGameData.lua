-- bingo比赛 bingo玩法数据

local BaseActivityData = require "baseActivity.BaseActivityData"
local BingoRushGameData = class("BingoRushGameData", BaseActivityData)

function BingoRushGameData:ctor()
    BingoRushGameData.super.ctor(self)

    self.roomId = nil
    -- bingo关 回合id
    self.bout_idx = 0
    self.bl_refresh = true
    -- 牌面信息
    self.balls = {}
    -- 中球列表
    self.player_data = {card = {}, balls_hit = {}}
    -- 玩家当前排名
    self.m_rank = 0
    -- 当前球信息
    self.cur_ball = nil
    -- 是否最后一个球 结算
    self.bl_isLastBout = false
    self.top_ten = nil
end

-- 解析bingo游戏数据
function BingoRushGameData:parseData(data)
    if not data then
        return
    end

    if data.error then
        return
    end

    -- 玩家数据
    self:parsePlayerData(data.detail)
    -- 出球列表
    self:parseBallData(data.balls)
    -- 玩家最终积分排名
    self:parseFinalRankData(data.finalRank)
    -- 前五名奖励显示
    self:parseTop10Data(data.userCoinsPool)
    if data and data.roomId then
        self.roomId = data.roomId
    end
end

--[{
--    "ball": 28, -- 出球号码
--    "daub": [[0,1,1]], -- 命中球的玩家 座位号 分数 数量
--    "bingo": [0,0,1] -- 玩家中bingo信息 座位号 分数 数量
--    "jackpot": [ [0,2520000,1] ],     -- 玩家中奖信息 座位号 分数 类型
--    "leftLines": 10, -- 剩余命中数 当剩余数到达临界值 会触发抢bingo玩法
--    "rank": [ -- 玩家积分排名列表 排名从上到下
--        [0,2520000], --座位号 积分
--        [1,0]
--    ],
--    "bingoUsers":[1,2,3] -- 触发抢bingo的玩家座位号
--}]
-- 解析出球列表
function BingoRushGameData:parseBallData(data)
    if not data then
        return
    end
    self.balls = data
end

function BingoRushGameData:getBallData()
    return self.balls
end

--"detail": {
--    "baseScore": 0,
--    "bingoPanel": [10,20,42,47,66,12,17,31,48,69,8,23,0,52,64,1,28,37,50,63,5,24,32,58,72],
--    "bingoScore": 0,
--    "boost": 0,
--    "buff1Positions": [1,2,3], -- 命中字块位置 0开始
--    "buff2Positions": {[1, 23],[2,24]}, -- 位置 球号 双号buff
--    "buff3Positions": [[1，2]，[3,4]], -- 关联位置
--    "chairId": 1,
--    "daubScore": 0,
--    "daubs": [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,[],[]],
--    "score": 0
--}
-- 解析玩家数据
function BingoRushGameData:parsePlayerData(data)
    if not data then
        return
    end

    if not self.player_data then
        self.player_data = {}
    end
    -- 座位号
    self.player_data.chairId = data.chairId
    -- 前两关累计分数
    self.player_data.baseScore = data.baseScore
    -- 中bingo的分数
    self.player_data.bingoScore = data.bingoScore
    -- 中一个球的分数
    self.player_data.daubScore = data.daubScore

    if data.jackpotScore then
        self.player_data.miniScore = data.jackpotScore[1]
        self.player_data.majorScore = data.jackpotScore[2]
        self.player_data.grandScore = data.jackpotScore[3]
    end

    self.m_rank = data.beforeRank or 0
    -- 总分数
    self.player_data.score = data.baseScore

    -- 获得的金钱
    self.player_data.winCoins = data.winCoins

    if not self.player_data.card then
        self.player_data.card = {}
    end

    if data.bingoPanel then
        self.player_data.bingoPanel = data.bingoPanel
        for idx, cell_num in ipairs(data.bingoPanel) do
            if not self.player_data.card[idx] then
                self.player_data.card[idx] = {}
            end
            self.player_data.card[idx].idx = idx
            self.player_data.card[idx].num = cell_num
            self.player_data.card[idx].row = math.ceil(idx / 5)
            self.player_data.card[idx].col = idx - (self.player_data.card[idx].row - 1) * 5
            self.player_data.card[idx].state = 0
            self.player_data.card[idx].buff_data = nil
        end
    end

    self.player_data.boost = data.boost

    -- buff相关数据 服务器是从0开始的 需要转换成从1开始的下标
    -- 随机daub位置
    self.player_data.buffDaub = {}
    if data.buff1Positions and table.nums(data.buff1Positions) then
        for i, pos in pairs(data.buff1Positions) do
            local idx = tonumber(pos) + 1
            table.insert(self.player_data.buffDaub, idx)
            if self.player_data.card and self.player_data.card[idx] then
                self.player_data.card[idx].buff_data = {type = "DAUB"}
            end
        end
    end
    self.player_data.buffDaubNums = data.buff1Num

    -- 双号daub位置
    self.player_data.buffDouble = {}
    if data.buff2Positions and table.nums(data.buff2Positions) then
        for pos, ball_num in pairs(data.buff2Positions) do
            local idx = tonumber(pos) + 1
            table.insert(self.player_data.buffDouble, {idx, ball_num})
            if self.player_data.card and self.player_data.card[idx] then
                self.player_data.card[idx].buff_data = {type = "DOUBLE", num = ball_num}
            end
        end
    end
    self.player_data.buffDoubleNums = table.nums(self.player_data.buffDouble)

    -- 关联daub位置
    self.player_data.buffLink = {}
    if data.buff3Positions and table.nums(data.buff3Positions) then
        for i, data in pairs(data.buff3Positions) do
            local idx = tonumber(data[1]) + 1
            local link_idx = tonumber(data[2]) + 1
            table.insert(self.player_data.buffLink, {idx, link_idx})
            if self.player_data.card and self.player_data.card[idx] then
                self.player_data.card[idx].buff_data = {type = "LINK", idx = link_idx, bl_linked = false}
            end
            if self.player_data.card and self.player_data.card[link_idx] then
                self.player_data.card[link_idx].buff_data = {type = "LINK", idx = idx, bl_linked = true}
            end
        end
    end
    self.player_data.buffLinkNums = table.nums(self.player_data.buffLink)

    if data.daubs then
        self.player_data.daubs = data.daubs
    end
end

function BingoRushGameData:getPlayerData()
    return self.player_data
end

-- 当前出球回合数
function BingoRushGameData:getBoutIdx()
    return self.bout_idx
end

function BingoRushGameData:setBoutIdx(idx)
    if idx and idx >= 0 then
        self.bout_idx = idx
        self.bl_refresh = false
        gLobalDataManager:setNumberByField("BingoRushBout_" .. self.roomId, idx)
    end
end

function BingoRushGameData:getMaxBouts()
    local max_bouts = table.nums(self.balls)
    return max_bouts
end

function BingoRushGameData:resetBout()
    self.bl_refresh = true
    -- bingo关 回合id
    self.bout_idx = 0
    -- 当前球信息
    self.cur_ball = nil
    -- 是否最后一个球 结算
    self.bl_isLastBout = false

    self:calcBout()
end

-- 计算当前回合数据
function BingoRushGameData:calcBout()
    local balls = self:getBallData()
    if not balls then
        return
    end
    local boutIdx = self:calcBoutIdx()
    local max_bouts = self:getMaxBouts()
    if boutIdx >= max_bouts then
        boutIdx = max_bouts
    end
    self:setIsLastBout(boutIdx >= max_bouts)

    local ball_data = balls[boutIdx]
    if not ball_data then
        return
    end
    self:setBoutIdx(boutIdx)

    --    "rank": [ -- 玩家积分排名列表 排名从上到下
    --        [0,2520000], --座位号 积分
    --        [1,0]
    --    ]
    local chairId = self.player_data.chairId
    if ball_data.rank and table.nums(ball_data.rank) > 0 and chairId then
        for rankIdx, data in ipairs(ball_data.rank) do
            if data[1] and data[1] == chairId then
                self.m_rank = rankIdx
                if data[2] and data[2] >= 0 then
                    self.player_data.score = data[2]
                end
            end
        end
    end

    local daubs = self.player_data.daubs[boutIdx]
    for daubIdx, state in ipairs(daubs) do
        self.player_data.card[daubIdx].state = state
    end

    self:refreshCurBall()
end

function BingoRushGameData:pushMsg()
    local balls = self:getBallData()
    if not balls then
        return
    end
    local idx = self:getBoutIdx()
    local ball_data = balls[idx]
    if not ball_data then
        return
    end
    --    "daub": [[0,1,1]], -- 命中球的玩家 座位号 分数 数量
    --    "bingo": [0,0,1] -- 玩家中bingo信息 座位号 分数 数量
    --    "jackpot": [ [0,2520000,1] ],     -- 玩家中奖信息 座位号 分数 类型
    --    "leftLines": 10, -- 剩余命中数 当剩余数到达临界值 会触发抢bingo玩法
    if ball_data.bingo and table.nums(ball_data.bingo) > 0 then
        for _, bingo_info in ipairs(ball_data.bingo) do
            self:pushGameMsg({msg_type = "bingo", data = bingo_info, bout_idx = idx})
            if ball_data.jackpot and table.nums(ball_data.jackpot) > 0 then
                local chair_id1 = bingo_info[1]
                if chair_id1 then
                    for __, jackpot_info in ipairs(ball_data.jackpot) do
                        local chair_id2 = jackpot_info[1]
                        if chair_id1 and chair_id2 and chair_id2 == chair_id1 then
                            self:pushGameMsg({msg_type = "jackpot", data = jackpot_info, bout_idx = idx})
                            break
                        end
                    end
                end
            end
        end
    end

    if ball_data.leftLines then
        self:pushGameMsg({msg_type = "leftLines", left_lines = ball_data.leftLines, bout_idx = idx, bl_stay = true})
    end

    if ball_data.daub and table.nums(ball_data.daub) > 0 then
        for _, daub_info in ipairs(ball_data.daub) do
            local chair_id = daub_info[1]
            self:pushBallMsg(chair_id)
        end
    end
end

function BingoRushGameData:getCardByRowAndCol(row, col)
    if not self.player_data.card then
        return
    end
    local idx = (row - 1) * 5 + col
    local card = self.player_data.card[idx]
    return card
end

-- 计算当前回合idx
function BingoRushGameData:calcBoutIdx()
    -- 根据时间 计算当前场上回合
    local new_bout = -1
    if self.bl_refresh == true then
        local bout_idx = gLobalDataManager:getNumberByField("BingoRushBout_" .. self.roomId, 0)
        printInfo("bingo 比赛 房间id " .. self.roomId)
        local act_mgr = G_GetMgr(ACTIVITY_REF.BingoRush)
        local hall_data = act_mgr:getHallData()
        if hall_data then
            local start_time = hall_data:getRoundStartTime(2)
            local cur_time = util_getCurrnetTime()
            local time_dif = cur_time - start_time
            local buff_time = act_mgr:getBuffTime()
            local bout_time = act_mgr:getBoutTime()
            if time_dif > buff_time then
                local time_idx = math.floor((time_dif - buff_time) / bout_time)
                bout_idx = math.max(bout_idx, time_idx)
            end
        end
        local max_bouts = self:getMaxBouts()
        printInfo("bingo 比赛 总回合数 " .. max_bouts)
        bout_idx = math.min(bout_idx, max_bouts)
        printInfo("bingo 比赛 当前回合数 " .. bout_idx)

        if bout_idx >= 0 then
            self:setBoutIdx(bout_idx)
            return bout_idx
        end
    end
    new_bout = self.bout_idx + 1
    return new_bout
end

function BingoRushGameData:getIsLastBout()
    return self.bl_isLastBout
end

function BingoRushGameData:setIsLastBout(bl_last)
    self.bl_isLastBout = bl_last
end

function BingoRushGameData:getCurBoutData()
    return self.cur_ball
end

-- 获取当前回合数据
function BingoRushGameData:refreshCurBall()
    local bout_data = {}
    local bout_idx = self:getBoutIdx()

    -- 球数据
    local balls = self:getBallData()
    if balls and balls[bout_idx] then
        bout_data = balls[bout_idx]
    end

    -- 是否命中
    bout_data.hit = 0
    if bout_data.daub and table.nums(bout_data.daub) > 0 then
        local player_data = self:getPlayerData()
        for i, daub_data in ipairs(bout_data.daub) do
            local chairId = daub_data[1]
            if player_data.chairId == chairId then
                bout_data.hit = 1
                break
            end
        end
    end
    -- 当前回合数据
    --[{
    --    "ball": 28, -- 出球号码
    --    "daub": [[0,1,1]], -- 命中球的玩家 座位号 分数 数量
    --    "bingo": [ [0,0,1] ] -- 玩家中bingo信息 座位号 分数 数量
    --    "jackpot": [ [0,2520000,1] ],     -- 玩家中奖信息 座位号 分数 类型
    --    "leftLines": 10, -- 剩余命中数 当剩余数到达临界值 会触发抢bingo玩法
    --    "rank": [ -- 玩家积分排名列表 排名从上到下
    --        [0,2520000], --座位号 积分
    --        [1,0]
    --    ]
    --}]
    local ball_num = tonumber(bout_data.ball)
    if ball_num > 0 then
        bout_data.group = math.ceil(ball_num / 15)
    end

    for _, duab_data in ipairs(bout_data.daub) do
        if duab_data[1] == self.player_data.chairId then
            bout_data.daub_score = duab_data[2]
        end
    end

    bout_data.ball_ex = {bingo = false, jackpot = false}
    for _, bingo_data in ipairs(bout_data.bingo) do
        local player_id = bingo_data[1]
        if player_id == self.player_data.chairId then
            bout_data.ball_ex.bingo = true
            bout_data.ball_ex.bingo_score = bingo_data[2]
        end
    end
    for _, jackpot_data in ipairs(bout_data.jackpot) do
        local player_id = jackpot_data[1]
        if player_id == self.player_data.chairId then
            bout_data.ball_ex.jackpot = true

            local jp_data = {}
            jp_data.jackpot_score = jackpot_data[2]
            jp_data.jackpot_type = jackpot_data[3]
            if not bout_data.ball_ex.jackpot_data then
                bout_data.ball_ex.jackpot_data = {}
            end
            table.insert(bout_data.ball_ex.jackpot_data, jp_data)
        end
    end
    self.cur_ball = bout_data
end

function BingoRushGameData:getCellDataByIdx(idx)
    local player_data = self:getPlayerData()
    if player_data and player_data.card then
        return player_data.card[idx]
    end
end

function BingoRushGameData:getCellIdxByNum(num)
    if num == nil or tonumber(num) <= 0 then
        return
    end

    local player_data = self:getPlayerData()
    if player_data and player_data.card then
        local col_nums = 5
        local group_max = 15
        local group_idx = math.ceil(tonumber(num) / group_max)

        for idx = 1, 5 do
            local cell_idx = group_idx + (idx - 1) * col_nums
            if player_data.card[cell_idx].num == num then
                return cell_idx
            else
                local buff_data = player_data.card[cell_idx].buff_data
                if buff_data and buff_data.type == "DOUBLE" then
                    if buff_data.num == num then
                        return cell_idx
                    end
                end
            end
        end
    end
    printError("bingoRush 没找到对应数值的球 " .. num)
end

function BingoRushGameData:getTotalWinCoins()
    local act_data = G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
    if not act_data then
        return 0
    end
    local cur_score = self:getMyScore()
    local bet_Data = act_data:getCurBetData()
    return (cur_score - self.player_data.baseScore) * tonumber(bet_Data.transCoins)
end

function BingoRushGameData:getCoinsByScore(score)
    local act_data = G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
    if not act_data then
        return 0
    end
    local bet_Data = act_data:getCurBetData()
    return score * tonumber(bet_Data.transCoins)
end

function BingoRushGameData:pushBallMsg(daub_data)
    local BingoRushConfig = G_GetMgr(ACTIVITY_REF.BingoRush):getConfig()
    local msg_type = BingoRushConfig.MSG_TYPE.BALL
    G_GetMgr(ACTIVITY_REF.BingoRush):pushMsg(msg_type, daub_data)
end

function BingoRushGameData:pushGameMsg(msg_data)
    local BingoRushConfig = G_GetMgr(ACTIVITY_REF.BingoRush):getConfig()
    local msg_type = BingoRushConfig.MSG_TYPE.GAME
    G_GetMgr(ACTIVITY_REF.BingoRush):pushMsg(msg_type, msg_data)
end

--{
--    "chairId": 0,     -- 座位号
--    "rate": 2.00,     -- 积分
--    "rankNum":1,      -- 名次
--    "coins":0         -- 获得奖励
--}
function BingoRushGameData:parseFinalRankData(data)
    if not data then
        return
    end
    self.rank_data = data
end

function BingoRushGameData:getFinalRankData()
    return self.rank_data
end

--{
--    "chairId": 0,     -- 座位号
--    "coins":0         -- 获得奖励
--}
function BingoRushGameData:parseTop10Data(data)
    if not data then
        return
    end
    self.top_ten = data
end

function BingoRushGameData:getTop10Data()
    return self.top_ten
end

function BingoRushGameData:getMyRank()
    return self.m_rank
end

function BingoRushGameData:getMyScore()
    return self.player_data.score
end

function BingoRushGameData:getWinCoins()
    return self.player_data.winCoins or 0
end

function BingoRushGameData:getBoost()
    return self.player_data.boost or 0
end

function BingoRushGameData:getBuffs()
    return {
        ["DAUB"] = self.player_data.buffDaub,
        ["DAUB_NUM"] = self.player_data.buffDaubNums,
        ["DOUBLE"] = self.player_data.buffDouble,
        ["DOUBLE_NUM"] = self.player_data.buffDoubleNums,
        ["LINK"] = self.player_data.buffLink,
        ["LINK_NUM"] = self.player_data.buffLinkNums
    }
end

-- 是否触发抢bingo
function BingoRushGameData:getInGrab()
    local player_data = self:getPlayerData()
    local bout_data = self:getCurBoutData()
    if bout_data.bingoUsers and table.nums(bout_data.bingoUsers) > 0 then
        for k, chair_id in pairs(bout_data.bingoUsers) do
            if chair_id == player_data.chairId then
                return true
            end
        end
    end
    return false
end

function BingoRushGameData:clearData()
    self.roomId = nil
    -- bingo关 回合id
    self.bout_idx = 0
    self.bl_refresh = true
    -- 牌面信息
    self.balls = {}
    -- 中球列表
    self.player_data = {card = {}, balls_hit = {}}
    -- 玩家当前排名
    self.m_rank = 0
    -- 当前球信息
    self.cur_ball = nil
    -- 是否最后一个球 结算
    self.bl_isLastBout = false
    self.top_ten = nil
end

return BingoRushGameData
