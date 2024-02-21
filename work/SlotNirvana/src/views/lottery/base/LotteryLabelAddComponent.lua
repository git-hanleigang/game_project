--[[
Author: cxc
Date: 2021-11-20 16:10:26
LastEditTime: 2021-11-20 16:10:27
LastEditors: your name
Description: 乐透 金币滚动 组件
FilePath: /SlotNirvana/src/views/lottery/base/LotteryLabelAddComponent.lua
--]]
local LotteryLabelAddComponent = {
    __enabled = true,
    m_limitCount = 20
}

--------------------------- 组件 生命周期 ---------------------------
function LotteryLabelAddComponent:onEnter()
    self:setName("LabelAddComponent")
    self:initData()

    self:updateLbUI()
end

function LotteryLabelAddComponent:onExit()
    self:setGrandPrize(self.m_showCoinsNumber)
end
--------------------------- 组件 生命周期 ---------------------------

-- 初始化组件数据
function LotteryLabelAddComponent:initData()
    self.m_data = G_GetMgr(G_REF.Lottery):getData()
    self.m_grandPrizeSaveKey = self.m_data:getSaveGrandPrizeKey()
    self.m_curGrandPrize = self.m_data:getGrandPrize()

    self.m_lbCoins = self:getOwner()
    self.m_lbCoinsScale = self.m_lbCoins:getScaleX()
end

-- 获取金币滚动速率最大值等
function LotteryLabelAddComponent:getRateInfo(pool)
    local bottomRate = globalData.constantData.QUEST_JACKPOT_POOL_BOTTOM or 1
    local topRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP or 1
    local perRate = globalData.constantData.QUEST_JACKPOT_POOL_ADD or 0
    local topMaxRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP_MAX or 1
    local topMaxSpeed = globalData.constantData.QUEST_JACKPOT_POOL_TOP_SPEED_MAX or 0

    local baseCoin = pool * bottomRate
    local maxCoin = pool * topRate
    local perAdd = pool * perRate
    local topMaxCoin = pool * topMaxRate
    local topMaxperAdd = pool * topMaxSpeed
    return math.max(baseCoin, self:getGrandPrize()), maxCoin, perAdd, topMaxCoin, topMaxperAdd
end

function LotteryLabelAddComponent:updateLbUI()
    --获取上次登录的时间
    local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(self.m_curGrandPrize)
    local dt = 0.08
    local saveDataCD = 5
    local perAddCount = 0
    local perAdd1 = perAdd * dt
    local perAdd2 = topMaxperAdd * dt
    self.m_showCoinsNumber = baseCoin
    self:setGrandPrize(baseCoin)
    self.m_lbCoins:setString(util_formatCoins(math.min(self.m_showCoinsNumber, topMaxCoin), self.m_limitCount))
    if self.m_maxUIW and self.m_maxUIW > 0 then
        util_scaleCoinLabGameLayerFromBgWidth(self.m_lbCoins, self.m_maxUIW, self.m_lbCoinsScale)
    end

    self:clearScheduler()
    self.m_coinAddScheduler =
        schedule(
        self.m_lbCoins,
        function()
            if self.m_showCoinsNumber >= topMaxCoin then
                self:setGrandPrize(topMaxCoin)
                self:clearScheduler()
                return
            end

            saveDataCD = saveDataCD - dt
            if saveDataCD < 0 then
                saveDataCD = 5
                self:setGrandPrize(math.min(self.m_showCoinsNumber, topMaxCoin))
            end

            --判断更新增量
            if self.m_showCoinsNumber <= maxCoin then
                if perAddCount ~= perAdd1 then
                    perAddCount = perAdd1
                end
            elseif self.m_showCoinsNumber < topMaxCoin then
                if perAddCount ~= perAdd2 then
                    perAddCount = perAdd2
                end
            end

            self.m_showCoinsNumber = math.min(perAddCount + self.m_showCoinsNumber, topMaxCoin)
            self.m_lbCoins:setString(util_formatCoins(self.m_showCoinsNumber, self.m_limitCount))
        end,
        dt
    )
end

-- 奖池金币数据 (存储)
function LotteryLabelAddComponent:setGrandPrize(_grandPrize)
    if not _grandPrize then
        return
    end

    local curTimeNumber = self.m_data:getCurTimeNumber()
    gLobalDataManager:setNumberByField(self.m_grandPrizeSaveKey .. curTimeNumber, _grandPrize)
end
-- 奖池金币数据 (获取)
function LotteryLabelAddComponent:getGrandPrize()
    local curTimeNumber = self.m_data:getCurTimeNumber()
    local beginCoins = gLobalDataManager:getNumberByField(self.m_grandPrizeSaveKey .. curTimeNumber, 0)
    return beginCoins
end

function LotteryLabelAddComponent:clearScheduler()
    if self.m_coinAddScheduler then
        self:getOwner():stopAction(self.m_coinAddScheduler)
        self.m_coinAddScheduler = nil
    end
end

--------------------------- 组件供外部 调用函数 ---------------------------
-- 设置label 显示的最大UI宽度
function LotteryLabelAddComponent:setMaxUIW(_maxUIW)
    self.m_maxUIW = _maxUIW or 0
end
-- 设置label 显示的保留位数
function LotteryLabelAddComponent:setCoinFormatLimitCount(_count)
    self.m_limitCount = _count or 20
end
--------------------------- 组件供外部 调用函数 ---------------------------

return LotteryLabelAddComponent
