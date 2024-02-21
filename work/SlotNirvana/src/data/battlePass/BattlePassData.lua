--[[
    BattlePass数据
    author:{author}
    time:2020-09-24 11:10:45
]]
-- FIX IOS 139
local BaseActivityData = require("baseActivity.BaseActivityData")
local BattlePassLvInfo = require("data.battlePass.BattlePassLvInfo")
local BattlePassBuyInfo = require("data.battlePass.BattlePassBuyInfo")

local BattlePassData = class("BattlePassData", BaseActivityData)

function BattlePassData:ctor()
    BattlePassData.super.ctor(self)
    -- 剩余秒数
    -- self.p_expire = 0
    -- 过期时间
    -- self.p_expireAt = 0
    -- 活动id
    -- self.p_activityId = ""
    -- 赛季
    self.p_season = ""
    -- 等级
    self.p_level = 1
    -- 经验
    self.p_exp = 0
    -- 触发升级需要经验值
    self.p_nextLevelExp = 0
    -- 付费解锁数据
    self.p_unlocks = {}
    -- 购买等级
    self.p_reaches = {}
    -- 等级数据
    self.p_levels = {}
    -- 解锁标识
    self.p_unlocked = true
end

function BattlePassData:parseData(data)
    if not data then
        return
    end

    BattlePassData.super.parseData(self, data)

    -- 剩余秒数
    -- self.p_expire = data.expire
    -- 过期时间
    -- self.p_expireAt = data.expireAt
    -- 活动id
    -- self.p_activityId = data.activityId
    -- 赛季
    self.p_season = data.season
    -- 等级
    self.p_level = data.level
    -- 经验
    self.p_exp = data.exp
    -- 触发升级需要经验值
    self.p_nextLevelExp = data.nextLevelExp
    -- 解锁标识
    self.p_unlocked = data.unlocked
    -- 引导进度 
    self.p_guideIndex = data.guide
    -- 付费解锁数据
    self.p_unlocks = {}
    for i = 1, #(data.unlocks or {}) do
        local _data = data.unlocks[i]
        local _unlockInfo = BattlePassBuyInfo:create()
        _unlockInfo:parseData(_data)
        table.insert(self.p_unlocks, _unlockInfo)
    end
    -- 购买等级
    self.p_reaches = {}
    for j = 1, #(data.reaches or {}) do
        local _data = data.reaches[j]
        local _reacheInfo = BattlePassBuyInfo:create()
        _reacheInfo:parseData(_data)
        table.insert(self.p_reaches, _reacheInfo)
    end
    -- 等级数据
    self.p_levels = {}
    for k = 1, #(data.levels or {}) do
        local _data = data.levels[k]
        local _levelInfo = BattlePassLvInfo:create()
        _levelInfo:parseData(_data)
        table.insert(self.p_levels, _levelInfo)
    end
    printInfo("=======")
end

function BattlePassData:getLevel()
    return self.p_level or 1
end

-- 是否解锁付费宝箱
function BattlePassData:isUnlocked()
    return self.p_unlocked
end

-- 
function BattlePassData:setUnlocked(value)
    self.p_unlocked = value
end

-- 获得赛季ID
function BattlePassData:getSeasonId()
    return self.p_season or 1
end

-- 当前经验
function BattlePassData:getCurExp()
    return tonumber(self.p_exp) or 0
end

-- 升级经验
function BattlePassData:getLvUpExp()
    return tonumber(self.p_nextLevelExp) or 1
end

-- 获得当前等级进度(0-100)
function BattlePassData:getCurLvProgerss()
    -- 当前进度
    local curExp = self:getCurExp()
    local lvUpExp = self:getLvUpExp()

    local percent = (curExp / lvUpExp) * 100
    return percent
end

-- 获得解锁宝箱商品信息
function BattlePassData:getUnlockBoxGoodsInfo()
    return self.p_unlocks or {}
end

-- 获得购买等级商品信息
function BattlePassData:getBuyLvGoodsInfo()
    return self.p_reaches or {}
end

-- 获得等级奖励
function BattlePassData:getRewardByLevel(nLv)
    if not nLv then
        return self.p_levels or {}
    else
        return self.p_levels[nLv]
    end
end

-- 获得免费箱子信息
function BattlePassData:getFreeBoxInfo(level)
    local reward = self:getRewardByLevel(level)

    if not reward then
        return nil
    end

    return reward:getFreeBoxInfo()
end

-- 获得付费箱子信息
function BattlePassData:getPayBoxInfo(level)
    local reward = self:getRewardByLevel(level)
    if not reward then
        return nil
    end

    return reward:getPayBoxInfo()
end

-- 获取最大等级
function BattlePassData:getMaxLevel( )
    return #self.p_levels
end

-- 获取当前引导到了第几步
function BattlePassData:getGuideIndex( )
    if self.p_guideIndex == 0 then
        self.p_guideIndex = 1
    end
    return self.p_guideIndex
end

-- 获取当前有多少个没有领取的箱子数量
function BattlePassData:getCanClaimNum( isAll)
    -- 需要判断是否要遍历全部等级
    local startLevel = self.p_level
    if isAll then
        startLevel = self:getMaxLevel()
    end
    local function checkState( info , pay )
        if info == nil then
            return false
        end
        local pState = false
        if not info:isPrized() then --当前没有被领取过 或者 付费已经解锁了并且有未领取的
            pState = true
            if pay and self.p_unlocked  == false then
                pState = false
            end
        end
        return pState
    end 
    local sumNoClaim = 0
    for i = 1, startLevel do 
        local freeBox = self:getFreeBoxInfo(i)
        local payBox = self:getPayBoxInfo(i)
        if checkState(freeBox) then
            sumNoClaim  = sumNoClaim + 1
        end
        if checkState(payBox,true) then
            sumNoClaim  = sumNoClaim + 1
        end
    end
    -- printf("------ 当前未领取的个数为 sumNoClaim "..sumNoClaim)
    return sumNoClaim
end

function BattlePassData:getIsOpen( )
    local openLevel = globalData.constantData.BATTLEPASS_OPEN_LEVEL or 25 --解锁等级
    -- 第一层判断
    if  self:isRunning() and  globalData.userRunData.levelNum >= openLevel then 
        return true
    end
    return false
end

--获取入口位置 1：左边，0：右边
function BattlePassData:getPositionBar( )
    return 1
end

return BattlePassData
