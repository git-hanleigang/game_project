-- 
-- 排行榜金币滚动
-- 

local Notifier = require("GameMVC.patterns.Notifier")
local BaseCoinsRollingControll = class("BaseCoinsRollingControll", Notifier)

function BaseCoinsRollingControll:ctor()
    BaseCoinsRollingControll.super.ctor(self)
    self.rolling_list = {}
    self:registEvents()
end

function BaseCoinsRollingControll:getInstance()
    if self.instance == nil then
        self.instance = BaseCoinsRollingControll.new()
    end
    return self.instance
end

function BaseCoinsRollingControll:getActKey(act_ref, ex_key)
    local data = self:getActDataByRef(act_ref)
    if data then
        local theme_name = data:getThemeName()
        local ending = data:getExpireAt()
        return theme_name .. ex_key .. ending
    end
end

function BaseCoinsRollingControll:regist(act_ref, ex_key, basal, bl_reset)
    if ex_key == nil then
        ex_key = ""
    end
    if bl_reset == nil then
        bl_reset = false
    end

    local act_key = self:getActKey(act_ref, ex_key)
    if not act_key then
        return
    end
    local rolling_key = act_ref .. ex_key
    if not self.rolling_list[rolling_key] then
        self.rolling_list[rolling_key] = {}
        self.rolling_list[rolling_key].ref_counts = 1
        self.rolling_list[rolling_key].act_ref = act_ref
        self.rolling_list[rolling_key].act_key = act_key
        self.rolling_list[rolling_key].ex_key = ex_key
        self.rolling_list[rolling_key].bl_reset = bl_reset
        self.rolling_list[rolling_key].basal = basal
        self.rolling_list[rolling_key].coins = self:getBeginCoins(act_ref, act_key, ex_key)
    else
        if self.rolling_list[rolling_key].act_key ~= act_key then
            assert(false, "同类型活动 存储数据使用的key不一致 " .. self.rolling_list[rolling_key].act_key .. "  " .. rolling_key)
        end
        self.rolling_list[rolling_key].ref_counts = self.rolling_list[rolling_key].ref_counts + 1
    end

    self:onTick()
end

function BaseCoinsRollingControll:unregist(act_ref, ex_key)
    if ex_key == nil then
        ex_key = ""
    end
    local coin_key = act_ref .. ex_key
    local rank_data = self.rolling_list[coin_key]
    if rank_data then
        rank_data.ref_counts = rank_data.ref_counts - 1
        if rank_data.ref_counts <= 0 then
            self:saveCoins(rank_data.act_key, rank_data.coins)
            self.rolling_list[coin_key] = nil
        end

        self:onTick()
    end
end

-- 获取基底
function BaseCoinsRollingControll:getBasal(act_ref, ex_key)
    local coin_key = act_ref .. ex_key
    if not self.rolling_list[coin_key] or not self.rolling_list[coin_key].basal then
        printError("BaseCoinsRollingControll:getBasal 获取基值失败 无法获得准确值")
        return 0
    end
    return self.rolling_list[coin_key].basal
end

function BaseCoinsRollingControll:getCoinsByType(act_ref, ex_key)
    if ex_key == nil then
        ex_key = ""
    end
    local coin_key = act_ref .. ex_key
    if self.rolling_list[coin_key] then
        if self:isRunning(act_ref) then
            return self.rolling_list[coin_key].coins
        end
    end
    return 0
end

function BaseCoinsRollingControll:getCoins_Record(act_key)
    local baseCoins = gLobalDataManager:getStringByField(act_key, "0")
    return toLongNumber(baseCoins)
end

-- 获取起始金币值 对比记录的金币值和活动下发的金币值 取最大值作为起始金币值
function BaseCoinsRollingControll:getBeginCoins(act_ref, act_key, ex_key)
    local coins = self:getCoins_Record(act_key)
    if self:isRunning(act_ref) then
        local besal = self:getBasal(act_ref, ex_key)
        local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(besal)
        if toLongNumber(coins) < toLongNumber(baseCoin) then
            coins:setNum(baseCoin)
        end
    end
    return coins
end

function BaseCoinsRollingControll:getActDataByRef(act_ref)
    if act_ref then
        local act_mgr = G_GetMgr(act_ref)
        if act_mgr then
            local act_data = act_mgr:getRunningData()
            return act_data
        end
    end
end

function BaseCoinsRollingControll:isRunning(act_ref)
    local act_data = self:getActDataByRef(act_ref)
    if act_data and act_data:isRunning() then
        return true
    end
end

-- 刷新金币值 做金币滚动效果用
function BaseCoinsRollingControll:onTick()
    local tick_timer = 5 / 60
    local tick_counts = math.ceil(5 / tick_timer) -- 每隔5秒钟写一次文件 记录金币值
    self.cur_tickCount = 0

    if table.nums(self.rolling_list) <= 0 then
        if self.tick_timer then
            scheduler.unscheduleGlobal(self.tick_timer)
            self.tick_timer = nil
        end
        return
    end

    if not self.tick_timer then
        self.tick_timer =
            scheduler.scheduleGlobal(
            function()
                self.cur_tickCount = self.cur_tickCount + 1
                for rolling_key, rolling_data in pairs(self.rolling_list) do
                    local act_ref = rolling_data.act_ref
                    if self:isRunning(act_ref) then
                        local besal = self:getBasal(act_ref, rolling_data.ex_key)
                        local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(besal)
                        --判断更新增量
                        local perAddCount = toLongNumber(0)
                        if toLongNumber(rolling_data.coins) <= toLongNumber(maxCoin) then
                            perAddCount = perAdd * tick_timer
                        elseif toLongNumber(rolling_data.coins) < toLongNumber(topMaxCoin) then
                            perAddCount = topMaxperAdd * tick_timer
                        end

                        rolling_data.coins = rolling_data.coins + perAddCount
                        if toLongNumber(rolling_data.coins) >= toLongNumber(topMaxCoin) then
                            if rolling_data.bl_reset then
                                rolling_data.coins:setNum(baseCoin)
                            else
                                rolling_data.coins:setNum(topMaxCoin)
                            end
                        end
                        if self.cur_tickCount >= tick_counts then
                            self:saveCoins(rolling_data.act_key, rolling_data.coins)
                        end
                    end
                end
                if self.cur_tickCount >= tick_counts then
                    self.cur_tickCount = 0
                end
            end,
            5 / 60
        )
    end
end

function BaseCoinsRollingControll:saveCoins(act_key, coins)
    if not act_key or not coins or toLongNumber(coins) < toLongNumber(0) then
        return
    end
    --local coins = math.ceil(coins)
    coins = tostring(coins)
    gLobalDataManager:setStringByField(act_key, coins)
end

-- 旧的算法 计算金币随时间的变化值
function BaseCoinsRollingControll:getRateInfo(coin)
    local bottomRate = globalData.constantData.QUEST_JACKPOT_POOL_BOTTOM or 1
    local topRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP or 1
    local perRate = globalData.constantData.QUEST_JACKPOT_POOL_ADD or 0
    local topMaxRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP_MAX or 1
    local topMaxSpeed = globalData.constantData.QUEST_JACKPOT_POOL_TOP_SPEED_MAX or 0

    local baseCoin = coin * bottomRate
    local maxCoin = coin * topRate
    local perAdd = coin * perRate
    local topMaxCoin = coin * topMaxRate
    local topMaxperAdd = coin * topMaxSpeed

    return baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd
end

function BaseCoinsRollingControll:registEvents()
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            for act_ref, data in pairs(self.rolling_list) do
                if param and param.refName == act_ref then
                    local baseCoins = self:getBeginCoins(act_ref, data.act_key, data.ex_key)
                    if baseCoins > self.rolling_list[act_ref].coins then
                        self.rolling_list[act_ref].coins = baseCoins
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    )
end

return BaseCoinsRollingControll
