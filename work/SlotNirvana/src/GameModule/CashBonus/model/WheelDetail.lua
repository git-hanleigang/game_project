-- 每日轮盘/付费轮盘数据

local WheelDetail = class("WheelDetail")

--message WheelDetail {
--    optional string name = 1; //名字
--    repeated int64 values = 2; //轮盘数值
--    optional int64 coinsShowBase = 3; //滚动数值的基础值
--    optional int64 coinsShowMax = 4; //滚动数值的最大值
--    optional int32 coinsShowPerSecond = 5; //滚动数值每秒增长的量
--    optional int32 multiple = 6; //付费轮盘倍数
--    optional string price = 7; //付费点价格
--    optional string key = 8; //付费点
--    optional int64 value = 9; //轮盘滚动的结果
--    optional int32 coolDown = 10; //冷却时间，如果是0的话，代表可以领取
--    optional string vipMultiple = 11; //vip加成
--    optional string loginMultiple = 12; //login加成
--    optional int32 index = 13; //轮盘滚动结束的位置
--    optional int32 newJackpotIndex = 14; //付费轮盘中，新增的jackpot的位置
--    optional string arenaMultiple = 15; //竞技场加成
--    optional int32 division = 16;//竞技场段位
--    repeated WheelPayPrice prices = 17; // 三挡价格
--}
function WheelDetail:parseData(data, isPayWheel)
    self.p_name = data.name --名字
    self.p_values = {} --轮盘数值
    if data.values ~= nil then
        for i = 1, #data.values do
            self.p_values[i] = tonumber(data.values[i])
        end
    end

    self.p_coinsShowBase = tonumber(data.coinsShowBase) --滚动数值的基础值
    self.p_coinsShowMax = tonumber(data.coinsShowMax) --滚动数值的最大值
    self.p_coinsShowPerSecond = data.coinsShowPerSecond --滚动数值每秒增长的量
    self.p_multiple = data.multiple --付费轮盘倍数
    self.p_price = data.price --付费点价格
    self.p_key = data.key --付费点

    self.p_value = tonumber(data.value) --轮盘滚动的结果
    self.p_coolDown = data.coolDown -- 冷却时间
    if self.p_coolDown and self.p_coolDown > 0 then
        self.expireAt = data.coolDown + util_getCurrnetTime()
        self:updatTimer()
    end
    self.p_vipMultiple = tonumber(data.vipMultiple) or 1
    self.p_loginMultiple = tonumber(data.loginMultiple) or 1

    self.p_index = tonumber(data.index) or 1 --轮盘停止位置

    self.m_arenaMultiple = tonumber(data.arenaMultiple) or 0
    self.m_arneaDivision = data.division

    if data.prices and #data.prices > 0 then
        self:parsePayPrice(data.prices)
        local idx = self:getPayIdx()
        if not idx then
            idx = 3
        end
        self:setPayIdx(idx)
        if data.prices[idx] and data.prices[idx].values then
            self:setJackpotList(data.prices[idx].values, data.newJackpotIndex)
        end
    else
        if isPayWheel then
            if data and data.values then
                self:setJackpotList(data.values, data.newJackpotIndex)
            end
        end
    end
end

-- message WheelPayPrice {
--     repeated int64 values = 1; //轮盘数值
--     optional string price = 2; //付费点价格
--     optional string key = 3; //付费点
--     optional int64 value = 4; //轮盘滚动的结果
--     optional int32 index = 5; //轮盘滚动结束的位置
--     optional int64 coinsShowBase = 6; //滚动数值的基础值
--     optional int64 coinsShowMax = 7; //滚动数值的最大值
--     optional int32 coinsShowPerSecond = 8; //滚动数值每秒增长的量
--     optional int32 multiple = 9; // 免费和付费之间的倍数
-- }
function WheelDetail:parsePayPrice(data)
    if not self.pay_data then
        self.pay_data = {}
    end

    for idx, price_data in ipairs(data) do
        if price_data then
            local p_data = {}
            if price_data.values ~= nil then
                p_data.values = {}
                for i = 1, #price_data.values do
                    p_data.values[i] = tonumber(price_data.values[i])
                end
            end
            p_data.coinsShowBase = tonumber(price_data.coinsShowBase or 0)
            p_data.coinsShowMax = tonumber(price_data.coinsShowMax or 0)
            p_data.coinsShowPerSecond = tonumber(price_data.coinsShowPerSecond or 0)
            p_data.price = price_data.price
            p_data.key = price_data.key
            p_data.value = price_data.value
            p_data.index = price_data.index
            p_data.multiple = price_data.multiple
            self.pay_data[idx] = p_data
        end
    end
end

function WheelDetail:setPayIdx(idx)
    if idx and self.pay_data[idx] then
        self.select_idx = idx
        local p_data = self.pay_data[idx]
        if p_data.values then
            self.p_values = p_data.values
        end
        if p_data.coinsShowBase then
            self.p_coinsShowBase = p_data.coinsShowBase
        end
        if p_data.coinsShowMax then
            self.p_coinsShowMax = p_data.coinsShowMax
        end
        if p_data.coinsShowPerSecond then
            self.p_coinsShowPerSecond = p_data.coinsShowPerSecond
        end
        if p_data.price then
            self.p_price = p_data.price
        end
        if p_data.key then
            self.p_key = p_data.key
        end
        if p_data.value then
            self.p_value = p_data.value
        end
        if p_data.index then
            self.p_index = p_data.index
        end
        if p_data.multiple then
            self.p_multiple = p_data.multiple
        end
    end
end

function WheelDetail:getMultiple()
    return self.p_multiple
end

function WheelDetail:getPayIdx()
    return self.select_idx or 3
end

function WheelDetail:setJackpotList(netValues, newJackpotIndex)
    self.m_isSelectJackpot = false
    if newJackpotIndex == 0 then
        self.m_isSelectJackpot = true
    else
        -- 跟旧的jackpot比较
        if self.p_JackpotList and #self.p_JackpotList > 0 then
            for i = 1, #self.p_JackpotList do
                if self.p_JackpotList[i].index == newJackpotIndex + 1 then
                    self.m_isSelectJackpot = true
                    break
                end
            end
        end
    end

    self.p_JackpotList = {}
    local firstValue = tonumber(netValues[1])
    for i = 2, #netValues do
        local value = tonumber(netValues[i])
        if value == firstValue then
            local isNewJackpot = false
            if i == newJackpotIndex + 1 then
                isNewJackpot = true
            end
            self.p_JackpotList[#self.p_JackpotList + 1] = {index = i, value = value, isNewJackpot = isNewJackpot}
        end
    end
end

-- 根据时间步长 获取步长的金币间隔
function WheelDetail:updateStepCoinByStepT(stepTime)
    self.p_stepCoin = math.ceil(self.p_coinsShowPerSecond * stepTime)
end

function WheelDetail:recordWheelIdx()
    self.p_recordIdx = self.p_index
end

function WheelDetail:clearWheelIdx()
    self.p_recordIdx = nil
end

-- 返回轮盘滚动的结果索引
function WheelDetail:getResultCoinIndex()
    if self.p_recordIdx and self.p_recordIdx >= 0 then
        return self.p_recordIdx + 1
    end
    return self.p_index + 1
end

function WheelDetail:recordWheelReward()
    if not self.pay_data then
        return
    end
    for idx, p_data in ipairs(self.pay_data) do
        if not self.p_recordReward then
            self.p_recordReward = {}
        end
        self.p_recordReward[idx] = clone(p_data.value)
    end
end

-- 返回轮盘滚动的结果索引
function WheelDetail:getResultCoinReward()
    local idx = self:getPayIdx()
    if self.p_recordReward and table.nums(self.p_recordReward) > 0 and idx > 0 and self.p_recordReward[idx] then
        return self.p_recordReward[idx]
    end
    return self.p_value
end

function WheelDetail:clearWheelReward()
    self.p_recordReward = nil
end

function WheelDetail:recordJackpotIdx()
    self.p_recordJackpotList = {}
    local pay_data = self:getPayData()
    if not pay_data then
        return
    end
    for i = 1, #self.p_JackpotList do
        local jp_data = self.p_JackpotList[i]
        if not self.p_recordJackpotList[i] then
            self.p_recordJackpotList[i] = {}
        end
        local index = jp_data.index
        if index and pay_data[index] then
            self.p_recordJackpotList[i].index = index
            self.p_recordJackpotList[i].value = pay_data[index]
            self.p_recordJackpotList[i].isNewJackpot = jp_data.isNewJackpot
        end
    end
end

function WheelDetail:getJackpotList()
    local jp_list = {}
    if self.p_recordJackpotList and table.nums(self.p_recordJackpotList) > 0 then
        jp_list = self.p_recordJackpotList
    else
        jp_list = self.p_JackpotList
    end
    return jp_list
end

function WheelDetail:getNewJackpotIndex()
    local jp_list = self:getJackpotList()
    if jp_list and table.nums(jp_list) > 0 then
        for i = 1, #jp_list do
            local jackpot = jp_list[i]
            if jackpot.isNewJackpot == true then
                return jackpot.index
            end
        end
    end
    return 1
end

function WheelDetail:clearJackpotIdx()
    self.p_recordJackpotList = nil
end

function WheelDetail:isJackpotChange(index)
    return self.m_isSelectJackpot == true
end

function WheelDetail:getArenaMultiple()
    return self.m_arenaMultiple
end

function WheelDetail:getLeftTime()
    if self.expireAt then
        return self.expireAt - util_getCurrnetTime()
    end
    return 0
end

-- 检测是否需要倒计时检测更新
function WheelDetail:updatTimer()
    if not self.m_handler then
        self.m_handler =
            scheduler.scheduleGlobal(
            function()
                if self.expireAt and self.expireAt > 0 then
                    if self.expireAt >= util_getCurrnetTime() then
                        if self.m_handler ~= nil then
                            scheduler.unscheduleGlobal(self.m_handler)
                            self.m_handler = nil
                        end
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHBONUS_COLLECT_PUSH)
                    end
                end
            end,
            1
        )
    end
end

function WheelDetail:getPayData()
    return self.pay_data
end

return WheelDetail
