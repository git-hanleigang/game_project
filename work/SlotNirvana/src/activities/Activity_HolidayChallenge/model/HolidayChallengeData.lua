--[[
    HolidayChallengeData 
    author:{author}
    time:2021-01-25 19:59:00
]]
-- FIX IOS 139
local BaseActivityData = require("baseActivity.BaseActivityData")
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local HolidayChallengeRewardData = require("activities.Activity_HolidayChallenge.model.HolidayChallengeRewardData")
local HolidayChallengeTaskData = require("activities.Activity_HolidayChallenge.model.HolidayChallengeTaskData")
local HolidayChallengeLastSaleData = require("activities.Activity_HolidayChallenge.model.ChallengePassLastSaleData")
local HolidayChallengeWheelData = require("activities.Activity_HolidayChallenge.model.HolidayChallengeWheelData")

local HolidayChallengeData = class("HolidayChallengeData", BaseActivityData)

function HolidayChallengeData:ctor()
    HolidayChallengeData.super.ctor(self)
    -- expire 、expireAt、 activityId   ---> goto BaseActivityData 
    -- definition self params
    self.m_maxPoints = 0

    self.m_currentPoints = 0

    self.m_allPoints = 0

    self.m_phase = 1

    self.m_taskData = {}

    self.m_rewardData = {}  -- 免费奖励

    self.m_finishAll = false -- 针对整个活动是否已经完成手机了


    -- 新版聚合挑战字段
    self.m_unlocked = false  -- 但是是否解锁
    self.m_payRewardsDara = {} -- 付费奖励
    -- 付费相关字段
    self.m_payInfo = {}
    self.m_addVipPoints = 0

    self.m_passSwitch = false 
    self.m_plusDay = false

    self.m_lastSaleData = nil

    self.m_extraPointCoins = 0 --额外点数转换成的金币
    self.m_extraPoint = 0 --玩满后额外剩余点数

    self.m_wheelData = nil
    self.m_addFromPrice = ""
    self.m_addExpireAt = 0
    self.m_addPointForPriceMap = {}

    self.m_highUnlocked = false --高档位是否购买
end

function HolidayChallengeData:parseData(data)
    if not data then
        return
    end
    HolidayChallengeData.super.parseData(self, data)

    self.m_maxPoints = data.maxPoints
    self.m_currentPoints = data.currentPoints
    self.m_allPoints = data.allPoints
    self.m_phase = data.phase
    self.m_finishAll = data.finish
    -- parse Task
    self.m_taskData = {}
    for i = 1, #(data.tasks or {}) do
        local task = data.tasks[i]
        local taskData = HolidayChallengeTaskData:create()
        taskData:parseData(task)
        table.insert(self.m_taskData, taskData)
    end
    -- parse Reward
    self.m_rewardData = {}
    for k = 1, #(data.rewards or {}) do
        local rewards = data.rewards[k]
        local rewardData = HolidayChallengeRewardData:create()
        rewardData:parseData(rewards)
        table.insert(self.m_rewardData, rewardData)
    end

    self.m_unlocked = data.unlocked  -- 但是是否解锁
    self.m_payRewardsDara = {} -- 付费奖励
    for k = 1, #(data.passRewards or {}) do
        local rewards = data.passRewards[k]
        local rewardData = HolidayChallengeRewardData:create()
        rewardData:parseData(rewards)
        table.insert(self.m_payRewardsDara, rewardData)
    end
    -- 付费相关字段
    self.m_payInfo = {
        key =  data.key,
        keyId = data.keyId,
        price = data.price,
        vipPoint = tonumber(data.addVipPoints) 
    }

    if data.passSwitch then --服务器返回的是一个 string字符串的 true 跟 false 为了方便判断
        self.m_passSwitch = data.passSwitch == "TRUE" and true or false
    end
    self.m_plusDay = data.plusDay 

    -- 解析最后一天促销的数据
    if data.sale then
        local saleData = G_GetMgr(ACTIVITY_REF.ChallengePassLastSale):getData()
        if saleData then
            saleData:parseData(data.sale)
        end
        local DoubleSaleData = HolidayChallengeLastSaleData:create()
        DoubleSaleData:parseData(data.sale)
        self.m_doubleSaleData = DoubleSaleData
    end

    if data.unlockPrice then
        local UnlockHightSaleData = HolidayChallengeLastSaleData:create()
        UnlockHightSaleData:parseData(data.unlockPrice)
        if data.highUnlocked ~= nil then
            UnlockHightSaleData:setPay(data.highUnlocked)
            self.m_highUnlocked = data.highUnlocked
        end
        self.m_unlockHightSaleData = UnlockHightSaleData
    end
    -- 多余点数转换金币
    if data.coin then
        self.m_extraPointCoins = tonumber(data.coin.coins) 
        self.m_extraPoint  =  tonumber(data.coin.points)
    end

    -- 转盘
    if data.wheel then
        self.m_wheelData = HolidayChallengeWheelData:create()
        self.m_wheelData:parseData(data.wheel)
    end

    --[[
        message ChristmasTourPayAddPoint {
        optional string price = 1; //价格
        optional string key = 2; //价格key
        optional int32 point = 3; //赠送点数
        optional int32 expire = 4; //活动倒计时
        optional int64 expireAt = 5; //结束时间
        repeated ChristmasTourPayAddPricePoint payAddPricePoint = 6; // 价格对应点数
        }
    ]]--
    if data.payAddPoint then
        local addData = data.payAddPoint
        if addData.price then
            self.m_addFromPrice = addData.price
        end

        if addData.expireAt then
            self.m_addExpireAt = addData.expireAt
        end
        if addData.payAddPricePoint and #addData.payAddPricePoint > 0 then
            self.m_addPointForPriceMap = {}
            for i,v in ipairs(addData.payAddPricePoint) do
                self.m_addPointForPriceMap[v.price] = v.point
            end
        end
    end
end

function HolidayChallengeData:getMaxPoints( )
    return self.m_maxPoints
end

function HolidayChallengeData:getCurrentPoints( )
    if self.m_currentPoints > self.m_maxPoints then
        return self.m_maxPoints
    end
    return self.m_currentPoints
end

function HolidayChallengeData:getALLPoints( )
    return self.m_allPoints
end

function HolidayChallengeData:getPhase( )
    return self.m_phase
end

function HolidayChallengeData:getTaskData( )
    return self.m_taskData 
end

function HolidayChallengeData:getRewardData( )
    return self.m_rewardData
end

function HolidayChallengeData:getFinishAll( )
    return self.m_finishAll
end

-- 新版聚合挑战提供接口
function HolidayChallengeData:getPayRewardData( )
    return self.m_payRewardsDara
end

function HolidayChallengeData:getPassSwitch( )
    return self.m_passSwitch
end

function HolidayChallengeData:getPayInfo( )
    return self.m_payInfo
end

function HolidayChallengeData:getUnlocked( )
    return self.m_unlocked
end

function HolidayChallengeData:getHighUnlocked( )
    return self.m_highUnlocked
end

function HolidayChallengeData:getIsPlusDay( )
    return self.m_plusDay
end

function HolidayChallengeData:getExtraPointCoins()
    return self.m_extraPointCoins
end

function HolidayChallengeData:getExtraPoint()
    return self.m_extraPoint
end

function HolidayChallengeData:getWheelData()
    return self.m_wheelData
end

function HolidayChallengeData:getPopModule()
    local _filePath = "Activity/" .. self:getThemeName().."SendLayer"
    if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
        local _module, count = string.gsub(_filePath, "/", ".")
        return _module
    end
    return ""
end

function HolidayChallengeData:isSleeping()
    if self:getLeftTime() <= 2 then
        return true
    end

    return false
end

function HolidayChallengeData:getDoubleSaleData()
    return self.m_doubleSaleData
end

function HolidayChallengeData:getHighPriceSaleData()
    return self.m_unlockHightSaleData
end

--获取入口位置 1：左边，0：右边
function HolidayChallengeData:getPositionBar()
    return 1
end

function HolidayChallengeData:isOverMax()
    return self:getCurrentPoints() >= self:getMaxPoints()
end

-- 解析排行榜信息
function HolidayChallengeData:parseRankConfig(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

function HolidayChallengeData:getRankCfg()
    return self.p_rankCfg
end

function HolidayChallengeData:getAddActLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self.m_addExpireAt - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function HolidayChallengeData:getAddPointByPrice(price)
    if self:getAddActLeftTime() <= 0 then
        return 0
    end
    return  self.m_addPointForPriceMap[price] or 0
end

return HolidayChallengeData
