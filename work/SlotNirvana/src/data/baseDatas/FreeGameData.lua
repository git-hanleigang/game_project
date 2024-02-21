
-- free spin 奖券

local FreeGameTicket = class("FreeGameTicket")

--message FreeTicketGame {
--    optional int32 order = 1;    //编号
--    optional string gameId = 2;    //关卡ID
--    optional string game = 3;    //关卡名
--    optional int32 times = 4;    //免费次数
--    optional int64 bet = 5;    //游戏中的Bet
--    optional int32 expire = 6;    //剩余时间（秒）
--    optional int64 expireAt = 7;    //过期时间
--    optional string action = 8;    //来源
--    optional bool active = 9;    //是否激活
--    optional int32 leftTimes = 10;    //剩余次数
--}
function FreeGameTicket:parseData( data )
    self.order = data.order
    self.expireAt = math.floor(tonumber(data.expireAt) / 1000)
    self.levelID = tonumber(data.gameId)
    self.levelName = data.game
    self.times = data.times
    self.leftTimes = data.leftTimes
    self.bet = data.bet
    self.action = data.action
    self.active = data.active or false
end

function FreeGameTicket:isOverdue()
    if self:isActive() then
        return self:getCountsLeft() < 1
    end

    local cur_time = util_getCurrnetTime()
    return self.expireAt <= cur_time
end

function FreeGameTicket:getLevelId()
    return self.levelID
end

function FreeGameTicket:getLevelName()
    return self.levelName
end

function FreeGameTicket:getOrder()
    return self.order
end

function FreeGameTicket:getCounts()
    return self.times
end

function FreeGameTicket:getCountsLeft()
    return self.leftTimes or 0
end

function FreeGameTicket:setCountsLeft( counts )
    if counts and counts >= 0 then
        self.leftTimes = counts
    end
end

function FreeGameTicket:getAction()
    return self.action
end

function FreeGameTicket:isActive()
    return self.active
end





----------------------------------------------------------------------------
-- free spin 奖励数据

local FreeGameData = class("FreeGameData")

function FreeGameData:ctor()
    -- 奖励数据
    self.rewardsList = {}
end

function FreeGameData:parseData(data)
    if not self.onInit then
        self.onInit = true
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if params[1] == true then
                    local spinData = params[2]
                    if spinData.action == "SPIN" then
                        self:onSpinResult(spinData)
                    end
                end
            end,
            ViewEventType.NOTIFY_GET_SPINRESULT
        )
    end
    
    -- 清空数据
    self.rewardsList = {}
    if data and data.tickets and table.nums(data.tickets) >= 0 then
        for _, freeGameData in ipairs(data.tickets) do
            local ticket = FreeGameTicket:create()
            ticket:parseData(freeGameData)
            table.insert(self.rewardsList, ticket)
        end
    end

    --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
end

function FreeGameData:onSpinResult(spinData)
    local ticketData = spinData.freeGameCost
    if ticketData and ticketData.order then
        local ticket = self:getRewardsById(ticketData.order)
        if ticket then
            ticket:setCountsLeft(ticketData.leftTimes)
        end
    end
end

-- 检查数据是否过期
function FreeGameData:checkOverdue( data )
    local freeSpinRewards = {}
    if not data or table.nums(data) == 0 then
        return freeSpinRewards
    end

    for idx, rewardData in pairs( data ) do
        if rewardData then
            if not rewardData:isOverdue() then
                table.insert(freeSpinRewards, data[idx])
            end
        end
    end
    return freeSpinRewards
end

function FreeGameData:getRewards()
    return self:checkOverdue(self.rewardsList)
end

function FreeGameData:getRewardsById( order )
    local rewards = self:checkOverdue(self.rewardsList)
    if rewards and table.nums(rewards) > 0 then
        for idx, rewardData in pairs( rewards ) do
            if rewardData.order == order then
                return rewards[idx]
            end
        end
    end
end

function FreeGameData:getRewardsByAction(_action)
    local rewardsList = {}
    local rewards = self:checkOverdue(self.rewardsList)
    if rewards and table.nums(rewards) > 0 then
        for idx, rewardData in ipairs( rewards ) do
            if rewardData.action == _action then
                table.insert(rewardsList, rewardData)
            end
        end
    end
    return rewardsList
end

--  通过来源获取当前有效的 freegame 数据，并且获取当前的active 状态
function FreeGameData:getDataActive(_rewards)
    local active = false
    if _rewards and #_rewards > 0 then 
        for k , v in ipairs(_rewards) do
            if v:isActive() then
                active = true
                break
            end
        end
    end
    return active
end
return FreeGameData
 