--[[
    @desc: NewPass 数据
    author:csc
    time:2021-06-23 20:05:09
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local NewPassData = class("NewPassData", BaseActivityData)



local NewPassPointConfig = require("activities.Activity_NewPass.config.NewPassPointConfig")
local NewPassPayConfig = require("activities.Activity_NewPass.config.NewPassPayConfig")
local NewPassGemSaleConfig = require("activities.Activity_NewPass.config.NewPassGemSaleConfig")
local NewPassSeasonTaskConfig = require("activities.Activity_NewPass.config.NewPassSeasonTaskConfig")
local NewPassSafeBoxConfig = require("activities.Activity_NewPass.config.NewPassSafeBoxConfig")

-- protobuf 结构
-- optional int32 expire = 1; //剩余秒数
-- optional int64 expireAt = 2; //过期时间
-- optional string activityId = 3; //活动id
-- optional int32 season = 4;//赛季
-- optional int32 level = 5;//等级
-- optional int64 exp = 6;//经验
-- optional bool unlocked = 7;//付费奖励解锁标识
-- repeated PassPointData freePoints = 8;// 免费
-- repeated PassPointData payPoints = 9;
-- repeated int32 levelExps = 10;// 每一级的经验
-- optional PassPayConfig levelStores = 11; // 等级商店
-- optional PassPayConfig payPass = 12; // 购买pass   -- csc 2021年09月06日11:22:56 弃用
-- optional GemSaleConfig gemSale = 13; // 促销
-- optional PassTask task = 14;
-- optional PassBoxData passBox = 15; // 保险箱
-- repeated PassPayConfig unlockPrices = 18;// 新版解锁档位
-- optional string expMultiple = 19; // 积分加成活动，加成倍数
-- optional string highPayCoinMul = 20; // 付费金币奖励翻倍系数
-- optional string highPayItemMul = 21; // 高档位付费道具奖励数量翻倍系数
-- optional string lowPayCoinMul = 22; // 低档位付费金币奖励翻倍系数
-- optional string lowPayItemMul = 23; // 低档位付费道具奖励数量翻倍系数
-- optional bool highUnlocked = 24; // 高档位付费标志
-- repeated PassPointData popupDisplay = 25; // 付费道具弹窗
-- optional int32 popupCd = 26; // 付费道具cd
-- optional string highPayMiniGameMul = 27;//高档位付费miniGame奖励翻倍系数
-- optional string lowPayMiniGameMul = 28; // 低档位付费miniGame奖励翻倍系数
-- repeated PassPointData triplePoints = 29;
-- repeated PassPointData popupTriplexDisplay = 30;// triplex付费道具弹窗
-- optional int64 lastCouponDiscount = 31;//上期领取的pass优惠券折扣
function NewPassData:ctor()
    NewPassData.super.ctor(self)
    self.m_season = ""
    -- 等级
    self.m_level = 1
    -- 经验
    self.m_exp = 0
    -- 每一级的经验
    self.m_levelExpList = nil
    -- 解锁标识
    self.m_unlocked = true
    -- 免费点位信息配置
    self.m_freePointConfig = nil
    -- 付费点位信息配置
    self.m_payPointConfig = nil
    -- 付费点位信息配置 第三行
    self.m_triplePointConfig = nil
    -- 购买等级信息配置
    self.m_payLevelConfig = nil
    -- 购买pass ticket
    self.m_payPassConfig = nil
    -- pass gem buff促销
    self.m_payGemSaleConfig = NewPassGemSaleConfig:create()
    -- passTask
    self.m_passTask = NewPassSeasonTaskConfig:create()
    -- passBox
    self.m_safeBoxConfig = NewPassSafeBoxConfig:create()
    -- 引导idx
    self.m_guideIndex = 0
    -- 积分活动加成系数
    self.m_expMultiple = 0

    self.m_highPayCoinMul = 1
    self.m_highPayItemMul = 1
    self.m_lowPayCoinMul = 1
    self.m_lowPayItemMul = 1
    self.m_isHighUnlocked = false

    self.m_highPayMiniGameMul = 1
    self.m_lowPayMiniGameMul = 1
    
    -- 付费道具弹窗表
    self.m_popupDisplay = nil 
    --triplex付费道具弹窗
    self.m_popupTriplexDisplay = nil 
    -- 付费道具cd
    self.m_popupCd = 0
    self.m_lastCouponDiscount = 0
end

function NewPassData:parseData(data)
    if not data then
        return
    end

    NewPassData.super.parseData(self, data)
    -- 赛季
    self.m_season = data.season
    -- 等级
    self.m_level = data.level
    -- 经验
    self.m_exp = tonumber(data.exp) 
    -- 解锁标识
    self.m_unlocked = data.unlocked

    -- 每一级的经验
    self.m_levelExpList = {}
    for i = 1, #(data.levelExps or {}) do
        local _data = tonumber(data.levelExps[i]) 
        table.insert(self.m_levelExpList, _data)
    end
    -- 免费点位信息配置
    self.m_freePointConfig = {}
    for i = 1, #(data.freePoints or {}) do
        local _data = data.freePoints[i]
        local _pointInfo = NewPassPointConfig:create()
        _pointInfo:parseData(_data)
        table.insert(self.m_freePointConfig, _pointInfo)
    end
    -- 付费点位信息配置
    self.m_payPointConfig = {}
    for i = 1, #(data.payPoints or {}) do
        local _data = data.payPoints[i]
        local _pointInfo = NewPassPointConfig:create()
        _pointInfo:parseData(_data)
        table.insert(self.m_payPointConfig, _pointInfo)
    end

    -- 付费点位信息配置 第三行
    self.m_triplePointConfig = {}
    for i = 1, #(data.triplePoints or {}) do
        local _data = data.triplePoints[i]
        local _pointInfo = NewPassPointConfig:create()
        _pointInfo:parseData(_data)
        table.insert(self.m_triplePointConfig, _pointInfo)
    end
    if #self.m_triplePointConfig > 0 then
        self.m_isThreeLinePass = true
    end

    -- 购买等级
    self.m_payLevelConfig = {}
    for i = 1, #(data.levelStores or {}) do
        local _data = data.levelStores[i]
        local _pointInfo = NewPassPayConfig:create()
        _pointInfo:parseData(_data)
        table.insert(self.m_payLevelConfig, _pointInfo)
    end

    -- 购买pass ticket
    self.m_payPassConfig = {}
    for i = 1, #(data.unlockPrices or {}) do
        local _data = data.unlockPrices[i]
        local _pointInfo = NewPassPayConfig:create()
        _pointInfo:parseData(_data)
        table.insert(self.m_payPassConfig, _pointInfo)
    end
    -- pass gem buff促销
    self.m_payGemSaleConfig:parseData(data.gemSale) 

    self:parsePassTask(data.task)

    self.m_safeBoxConfig:parseData(data.passBox)

    self:initPassPointsInfo()

    self.m_guideIndex = data.guide

    -- 积分活动加成系数
    self.m_expMultiple = tonumber(data.expMultiple) or 0
    -- 付费金币奖励翻倍系数
    self.m_highPayCoinMul = tonumber(data.highPayCoinMul) or 1
    self.m_highPayItemMul = tonumber(data.highPayItemMul) or 1
    self.m_lowPayCoinMul = tonumber(data.lowPayCoinMul) or 1
    self.m_lowPayItemMul = tonumber(data.lowPayItemMul) or 1
    self.m_isHighUnlocked = data.highUnlocked or false

    self.m_highPayMiniGameMul = tonumber(data.highPayMiniGameMul) or 1
    self.m_lowPayMiniGameMul = tonumber(data.lowPayMiniGameMul) or 1

    self.m_popupDisplay = {}
    for i = 1, #(data.popupDisplay or {}) do
        local _data = data.popupDisplay[i]
        local _pointInfo = NewPassPointConfig:create()
        _pointInfo:parseData(_data)
        table.insert(self.m_popupDisplay, _pointInfo)
    end

    self.m_popupTriplexDisplay = {}
    for i = 1, #(data.popupTriplexDisplay or {}) do
        local _data = data.popupTriplexDisplay[i]
        local _pointInfo = NewPassPointConfig:create()
        _pointInfo:parseData(_data)
        table.insert(self.m_popupTriplexDisplay, _pointInfo)
    end
    -- 付费道具cd  下发的是小时
    self.m_popupCd = data.popupCd * 60 * 60

    self.m_lastCouponDiscount = tonumber(data.lastCouponDiscount)
    print("-----csc NewPassData parse over")
end

function NewPassData:getLevel()
    return self.m_level or 1
end

function NewPassData:getMaxLevel()
    return #self.m_levelExpList
end

-- 是否解锁
function NewPassData:isUnlocked()
    return self.m_unlocked
end

-- 获得赛季ID
function NewPassData:getSeasonId()
    return self.m_season or 1
end

-- 当前经验
function NewPassData:getCurExp()
    return tonumber(self.m_exp) or 0
end

function NewPassData:getFressPointsInfo()
    return self.m_freePointConfig
end

function NewPassData:getPayPointsInfo()
    return self.m_payPointConfig
end

function NewPassData:getTriplePointsInfo()
    return self.m_triplePointConfig
end

-- 获得购买等级商品信息
function NewPassData:getBuyLvGoodsInfo()
    return self.m_payLevelConfig
end

-- 获取pass ticket信息
function NewPassData:getPayPassTicketInfo()
    return self.m_payPassConfig
end

-- 获取 gems促销 信息
function NewPassData:getPayGemsSaleInfo()
    return self.m_payGemSaleConfig
end

-- 获取 pass 任务
function NewPassData:getPassTask()
    return self.m_passTask
end

function NewPassData:getLevelExpList()
    return self.m_levelExpList
end

function NewPassData:getSafeBoxConfig()
    return self.m_safeBoxConfig
end

function NewPassData:getGuideIndex()
    if self.m_guideIndex == 0 then
        self.m_guideIndex = 1
    end
    return self.m_guideIndex
end

function NewPassData:getIsOpen( )
    local openLevel = globalData.constantData.NEWPASS_OPEN_LEVEL --解锁等级
    if globalData.constantData.NEWUSERPASS_OPEN_SWITCH and globalData.constantData.NEWUSERPASS_OPEN_SWITCH > 0 then
        if self:isNewUserPass() then
            openLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
        else
            if globalData.userRunData.levelNum >= globalData.constantData.NEWUSERPASS_OPEN_LEVEL then
                openLevel = globalData.constantData.NEWPASS_OPEN_LEVEL
            else
                openLevel = globalData.constantData.NEWUSERPASS_OPEN_LEVEL
            end
        end
    end
    -- 第一层判断
    if  self:isRunning() and  globalData.userRunData.levelNum >= openLevel then 
        return true
    end
    return false
end

function NewPassData:parsePassTask(_data)
    -- passTask
    self.m_passTask:parseData(_data) 
end

-- 组装 reward界面滑动数据 付费跟免费的全部数据
function NewPassData:initPassPointsInfo()
    self.m_passPointsInfo = {}

    -- 先将标签数据加入
    self.m_passPointsInfo[#self.m_passPointsInfo + 1] = {tag = true} -- 标签节点

    -- 组装 免费 + 付费 信息 + 保险箱信息
    for i = 1,#self.m_levelExpList do
        local freeInfo = self.m_freePointConfig[i]
        local payInfo = self.m_payPointConfig[i]
        local tripleInfo = self.m_triplePointConfig[i]
        local data = {
            freeInfo = freeInfo,
            payInfo = payInfo,
            tripleInfo = tripleInfo,
        }
        table.insert(self.m_passPointsInfo,data)
    end

    self.m_passPointsInfo[#self.m_passPointsInfo + 1] = {safeBoxInfo = self:getSafeBoxConfig()} -- 保险箱节点
end

function NewPassData:getPassPointsInfo()
    if self.m_passPointsInfo == nil or #self.m_passPointsInfo == 0 then
        self:initPassPointsInfo()
    end
    return self.m_passPointsInfo
end

function NewPassData:getPassInfoByIndex(_index)
    if _index and self.m_passPointsInfo and #self.m_passPointsInfo > 0 then
        return self.m_passPointsInfo[_index]
    end
    return nil
end

-- 预览数据
function NewPassData:getPreviewIndex(_curIndex)
    if _curIndex ~= nil and self.m_passPointsInfo and #self.m_passPointsInfo > 0 then
        for i=1,#self.m_passPointsInfo do
            if i > _curIndex then
                local info = self.m_passPointsInfo[i]
                if info and info.freeInfo and info.freeInfo:getLabelColor() == "1" then
                    return i
                end
            end
        end
    end
    return nil
end

-- 获取升到下一级的总经验
function NewPassData:getLevelUpExp()
    local curLevel = self:getLevel()
    local curExp = self:getCurExp()
    local levelExpList = self:getLevelExpList()
    if curLevel >= self:getMaxLevel() then
        return levelExpList[curLevel]
    else
        return levelExpList[curLevel + 1]
    end
    return 0
end

--获取入口位置 1：左边，0：右边
function NewPassData:getPositionBar()
    return -1
end

function NewPassData:getDoubleActMultiple()
    return self.m_expMultiple
end

function NewPassData:getHighPayCoinMul()
    return self.m_highPayCoinMul
end

function NewPassData:getHighPayItemMul()
    return self.m_highPayItemMul
end

function NewPassData:getHighPayMiniGameMul()
    return self.m_highPayMiniGameMul
end

function NewPassData:getLowPayCoinMul()
    return self.m_lowPayCoinMul 
end

function NewPassData:getLowPayItemMul()
    return self.m_lowPayItemMul
end

function NewPassData:getLowPayMiniGameMul()
    return self.m_lowPayMiniGameMul
end

function NewPassData:getCurrIsPayHigh()
    return self.m_isHighUnlocked
end

function NewPassData:getPopUpDisplay()
    return self.m_popupDisplay
end

function NewPassData:getPopUpTriplexDisplay()
    return self.m_popupTriplexDisplay
end

function NewPassData:getPopUpCd()
    return self.m_popupCd
end

--是否是新手Pass
function NewPassData:setIsNewUserPass(isNewUserPass)
    self.m_isNewUserPass = isNewUserPass
    self:setNovice(isNewUserPass)
end

function NewPassData:isNewUserPass()
    return not not self.m_isNewUserPass
end

-- 是否是三行的pass
function NewPassData:isThreeLinePass()
    return not not self.m_isThreeLinePass
end

function NewPassData:getLastCouponDiscount()
    return self.m_lastCouponDiscount or 0
end

return NewPassData
