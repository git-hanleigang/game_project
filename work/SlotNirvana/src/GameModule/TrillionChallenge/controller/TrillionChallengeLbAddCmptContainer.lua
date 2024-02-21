local TrillionChallengeLbAddCmptContainer = class("TrillionChallengeLbAddCmptContainer")

function TrillionChallengeLbAddCmptContainer:ctor()
    self.m_saveDataCD = 5 -- 保存金币cd
    self.m_dt = 0.08 --定时器dt
    self.m_curAddCount = 0 -- 金币增加数量
    self.m_perAddMore = 0 -- 金币增加数量 多
    self.m_perAddLess = 0 -- 金币增加数量 少

    self.m_showCoinsNumber = 0 -- 显示金币
    self.m_maxCoinSmall = 0
    self.m_maxCoinBig = 0 -- 最大金币

    self.m_curGrandPrize = 0 -- 存储的大奖数

    self.m_containerList = {}
    self.m_curScene = display:getRunningScene()
end

function TrillionChallengeLbAddCmptContainer:updateData()
    self.m_data = G_GetMgr(G_REF.TrillionChallenge):getData()
    self.m_grandPrizeSaveKey = self.m_data:getSaveGrandPrizeKey()
    self.m_curGrandPrize = self.m_data:getPrizePool()

    --获取上次登录的时间
    local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(self.m_curGrandPrize)
    self.m_curAddCount = 0 -- 金币增加数量
    self.m_perAddMore = perAdd * self.m_dt
    self.m_perAddLess = topMaxperAdd * self.m_dt
    self.m_showCoinsNumber = baseCoin
    self:setGrandPrize(baseCoin)
    self.m_maxCoinSmall = maxCoin
    self.m_maxCoinBig = topMaxCoin
end

function TrillionChallengeLbAddCmptContainer:addComponent(_lb, _maxUIW, _limitStrCount)
    if not _lb then
        return
    end

    self:updateData()

    local info = {target = _lb, maxUIW = _maxUIW, limitStrCount = _limitStrCount, scale = _lb:getScaleX()}
    table.insert(self.m_containerList, info)

    self:initLabelUI(info)

    self:updateScheduler()
end

function TrillionChallengeLbAddCmptContainer:updateSec()
    if self.m_showCoinsNumber >= self.m_maxCoinBig then
        self:setGrandPrize(self.m_maxCoinBig)
        self:clearScheduler()
        return
    end

    self.m_saveDataCD = self.m_saveDataCD - self.m_dt
    if self.m_saveDataCD < 0 then
        self.m_saveDataCD = 5
        self:setGrandPrize(math.min(self.m_showCoinsNumber, self.m_maxCoinBig))
    end

    --判断更新增量
    if self.m_showCoinsNumber <= self.m_maxCoinSmall then
        if self.m_curAddCount ~= self.m_perAddMore then
            self.m_curAddCount = self.m_perAddMore
        end
    elseif self.m_showCoinsNumber < self.m_maxCoinBig then
        if self.m_curAddCount ~= self.m_perAddLess then
            self.m_curAddCount = self.m_perAddLess
        end
    end

    self.m_showCoinsNumber = math.min(self.m_curAddCount + self.m_showCoinsNumber, self.m_maxCoinBig)

    for k, info in pairs(self.m_containerList) do
        for i = 1, 1 do
            local label = info.target
            if tolua.isnull(label) then
                self.m_containerList[k] = nil
                break
            end

            self:updateLabelUI(info)
        end
    end

    if table.nums(self.m_containerList) <= 0 then
        self:setGrandPrize(self.m_showCoinsNumber)
        self:clearScheduler()
    end
end

function TrillionChallengeLbAddCmptContainer:initLabelUI(_info)
    if not next(_info) then
        return
    end

    local label = _info.target
    local maxUIW = _info.maxUIW
    local scale = _info.scale or 1
    local limitStrCount = _info.limitStrCount or 20
    label:setString(util_formatCoins(math.min(self.m_showCoinsNumber, self.m_maxCoinBig), limitStrCount))
    if maxUIW and maxUIW > 0 then
        util_scaleCoinLabGameLayerFromBgWidth(label, maxUIW, scale)
    end
end

function TrillionChallengeLbAddCmptContainer:updateLabelUI(_info)
    if not next(_info) then
        return
    end

    local label = _info.target
    local limitStrCount = _info.limitStrCount or 20
    label:setString(util_formatCoins(self.m_showCoinsNumber, limitStrCount))
end

-- 获取金币滚动速率最大值等
function TrillionChallengeLbAddCmptContainer:getRateInfo(_pool)
    local bottomRate = globalData.constantData.QUEST_JACKPOT_POOL_BOTTOM or 1
    local topRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP or 1
    local perRate = globalData.constantData.QUEST_JACKPOT_POOL_ADD or 0
    local topMaxRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP_MAX or 1
    local topMaxSpeed = globalData.constantData.QUEST_JACKPOT_POOL_TOP_SPEED_MAX or 0

    local baseCoin = _pool * bottomRate
    local maxCoin = _pool * topRate
    local perAdd = _pool * perRate
    local topMaxCoin = _pool * topMaxRate
    local topMaxperAdd = _pool * topMaxSpeed
    return math.max(baseCoin, self:getGrandPrize()), maxCoin, perAdd, topMaxCoin, topMaxperAdd
end

-- 奖池金币数据 (存储)
function TrillionChallengeLbAddCmptContainer:setGrandPrize(_grandPrize)
    if not _grandPrize then
        return
    end

    local expireAt = self.m_data:getExpireAt()
    gLobalDataManager:setNumberByField(self.m_grandPrizeSaveKey .. expireAt, _grandPrize)
end
-- 奖池金币数据 (获取)
function TrillionChallengeLbAddCmptContainer:getGrandPrize()
    local expireAt = self.m_data:getExpireAt()
    local beginCoins = gLobalDataManager:getNumberByField(self.m_grandPrizeSaveKey .. expireAt, 0)
    return beginCoins
end

function TrillionChallengeLbAddCmptContainer:updateScheduler()
    if tolua.isnull(self.m_curScene) then
        self.m_curScene = display:getRunningScene()
    end
    if tolua.isnull(self.m_scheduler) then
        self.m_scheduler = schedule(self.m_curScene, handler(self, self.updateSec), 0.08)
    end
end

function TrillionChallengeLbAddCmptContainer:clearScheduler()
    if not tolua.isnull(self.m_scheduler) and not tolua.isnull(self.m_curScene) then
        self.m_curScene:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

return TrillionChallengeLbAddCmptContainer
