--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 21:18:39
--
local AdsItem = require "data.baseDatas.AdsItem"
local AdsRunData = class("AdsRunData")

AdsRunData.p_vecPopAdsInfo = nil
AdsRunData.p_vecAutoAdsInfo = nil
AdsRunData.p_currAdsInfo = nil
AdsRunData.p_isNull = nil
AdsRunData.p_haveCashBonusWheel = nil --解决同时弹广告冲突问题

AdsRunData.p_userPurchaseType = nil --用户付费类型
AdsRunData.p_leadTimes = nil --领取次数
AdsRunData.p_noCoinsMaxCoins = nil --没金币弹出广告金币价值
AdsRunData.p_firstCoins = nil --首次金币奖励
AdsRunData.p_noCoinsRealCoins = nil --没钱弹广告真实给予的金币

AdsRunData.m_isGuideAds = nil --是否正在播放引导激励视频

AdsRunData.m_publicCdTime = nil --统一的广告CD
AdsRunData.m_vecAutoAdsShowTime = nil --维护一个插屏广告点位 展示时间
--广告类型
local ADS_TYPE = {
    REWARD_ADS = "click",
    INTERSTITIAL_ADS = "insert"
}
--用户付费类型
local PURCHASE_TYPE = {
    NO_PURCHASE = "noPurchase",
    SMALL_PURCHASE = "smallPurchase",
    BIG_PURCHASE = "bigPurchase"
}

function AdsRunData:ctor()
    self.p_vecPopAdsInfo = {}
    self.p_vecAutoAdsInfo = {}
    self.p_isNull = true
    self.p_haveCashBonusWheel = false
end

function AdsRunData:parseAdsData(data)
    if not data or #data == 0 then
        --清空广告信息
        self.p_vecPopAdsInfo = {}
        self.p_vecAutoAdsInfo = {}
        self.m_vecAutoAdsShowTime = {}
        self.p_isNull = true
        return
    end
    local vecAdsInfo = {}
    for i = 1, #data, 1 do
        local info = data[i]
        local adsItem = AdsItem:create()
        adsItem:parseData(info)
        vecAdsInfo[i] = adsItem
    end
    self.p_vecPopAdsInfo = {}
    self.p_vecAutoAdsInfo = {}
    for i = 1, #vecAdsInfo, 1 do
        local info = vecAdsInfo[i]
        if info:getType() == ADS_TYPE.INTERSTITIAL_ADS then
            self.p_vecAutoAdsInfo[info:getPos()] = info
        else
            self.p_vecPopAdsInfo[info:getPos()] = info
        end
    end

    if next(self.p_vecPopAdsInfo) ~= nil then
        self.p_isNull = false
    end

    -- csc 2021年09月26日17:07:32 添加一个公用CD字段
    -- 因为结构问题,配表公用CD配置的是相同的值，所以只需要取一个点位的值出来 即可
    local nextK, nextV = next(self.p_vecAutoAdsInfo)
    if nextV ~= nil then
        -- local info = self.p_vecAutoAdsInfo[1]
        -- if info then
        --     self.m_publicCdTime = info.p_publicCd or 60
        -- end
        self.m_publicCdTime = nextV.p_publicCd or 60
        if self.m_vecAutoAdsShowTime == nil then
            self.m_vecAutoAdsShowTime = {}
        end

        -- 刷新展示时间 (如果没有存储过 or 点位展示时间比最新的展示时间小)
        for key, value in pairs(self.p_vecAutoAdsInfo) do
            local adsinfo = value
            local _lastShowTime = self.m_vecAutoAdsShowTime[adsinfo.p_position]
            if _lastShowTime == nil or _lastShowTime < adsinfo.p_showTime then
                self.m_vecAutoAdsShowTime[adsinfo.p_position] = adsinfo.p_showTime
            end
        end
    end
end

--额外广告相关数据
function AdsRunData:parseAdsExtraData(data)
    self.p_userPurchaseType = data.userPurchaseType --用户付费类型
    self.p_leadTimes = data.leadTimes --领取次数
    self.p_noCoinsMaxCoins = tonumber(data.noCoinsMaxCoins) --没金币弹出广告金币价值
    self.p_firstCoins = tonumber(data.firstCoins) --首次金币奖励

    if self.p_userPurchaseType then
        --sdk读取使用
        gLobalDataManager:setStringByField("USER_PURCHASE_TYPE", self.p_userPurchaseType)
    end
end

function AdsRunData:CheckAdByPosition(position)
    --没有对用户分组不做限制
    if not self.p_userPurchaseType then
        return self:checkAds(position, self.p_vecPopAdsInfo)
    end
    --非大R用户
    if self.p_userPurchaseType == PURCHASE_TYPE.NO_PURCHASE then
        return self:checkAds(position, self.p_vecPopAdsInfo)
    elseif self.p_userPurchaseType == PURCHASE_TYPE.SMALL_PURCHASE then
        if self:isPlayRewardAds(position) then
            return self:checkAds(position, self.p_vecPopAdsInfo)
        end
    end
    return false
end

function AdsRunData:CheckAutoAdByPosition(position)
    --没有对用户分组不做限制
    if not self.p_userPurchaseType then
        return self:checkAds(position, self.p_vecAutoAdsInfo)
    end
    --只有普通未付费用户弹插屏
    if self.p_userPurchaseType == PURCHASE_TYPE.NO_PURCHASE or self.p_userPurchaseType == PURCHASE_TYPE.SMALL_PURCHASE then
        return self:checkAds(position, self.p_vecAutoAdsInfo)
    else
        return false
    end
end

function AdsRunData:checkAds(position, vecAdsInfos)
    if not self:checkLimitByDailyTimesByPos(position, vecAdsInfos) then
        return false
    end

    local info = vecAdsInfos["" .. position]
    if info then
        --屏蔽可能nil值
        local newLevel = globalData.userRunData.levelNum or 1
        local unLock = info.p_level or 15
        if newLevel < unLock then
            return false
        end
        -- 当前时间
        local nowTime = os.time()
        -- 下一次播放时间
        local nextTime = info.p_cdTime
        if info.p_type == ADS_TYPE.INTERSTITIAL_ADS then
            -- 插屏的公共限制CD，下一次可播放插屏的时间
            nextTime = gLobalAdsControl:getInterstitialCDTime()
            -- 满足统一CD的情况下 , 需要再判断每个点位自身的CD时间是否满足
            local showTime = self.m_vecAutoAdsShowTime[info.p_position] or info.p_showTime
            if nowTime >= nextTime then
                nextTime = showTime
            end
        end
        if (nextTime == -1 or nowTime >= nextTime) and info.p_open == true then
            return true
        else
            return false
        end
    end

    return false
end

function AdsRunData:checkLimitByDailyTimesByPos(pos, adsInfos)
    local playTimes = gLobalAdsControl:getOnePosTodayPlayAdTimes(pos)
    local dailyTimes = -1
    adsInfos = adsInfos or self.p_vecPopAdsInfo
    local info = adsInfos[tostring(pos)]
    if info then
        dailyTimes = info.p_dailyTimes
    end
    return dailyTimes == -1 or playTimes < dailyTimes
end

function AdsRunData:getCurrAutoAdsPos()
    if self.p_currAdsInfo == nil or self.p_currAdsInfo.p_type == ADS_TYPE.REWARD_ADS then
        return nil
    elseif self.p_currAdsInfo.p_position == PushViewPosType.LevelToLobby then
        return "lobby_interstitial_"
    elseif self.p_currAdsInfo.p_position == PushViewPosType.FirstLogin then
        return "login_interstitial_"
    elseif self.p_currAdsInfo.p_position == PushViewPosType.FreeSpin then
        return "freespin_interstitial_"
    elseif self.p_currAdsInfo.p_position == PushViewPosType.ReturnApp then
        return "return_interstitial_"
    elseif self.p_currAdsInfo.p_position == PushViewPosType.BigMegaWinClose then
        return "BigWinClose_interstitial_"
    elseif self.p_currAdsInfo.p_position == PushViewPosType.LevelUp then
        return "LevelUp_interstitial_"
    elseif self.p_currAdsInfo.p_position == PushViewPosType.CloseInbox then
        return "CloseInbox_interstitial_"
    end
end

function AdsRunData:setCurrAdsInfo(position, isAuto)
    self.p_currAdsInfo = self:getAdsInfoForPos(position, isAuto)
end

function AdsRunData:clearCurrAdsInfo()
    self.p_currAdsInfo = nil
end

function AdsRunData:getCurrAdsInfo()
    return self.p_currAdsInfo
end
--获取广告信息isAuto是否是插屏
function AdsRunData:getAdsInfoForPos(position, isAuto)
    if self:isNoAdsUser() then
        return nil
    end
    local adsInfo = nil
    if isAuto then
        adsInfo = self.p_vecAutoAdsInfo
    else
        adsInfo = self.p_vecPopAdsInfo
    end

    return adsInfo[tostring(position)]
end

--大R不显示广告
function AdsRunData:isNoAdsUser()
    if not self.p_userPurchaseType then
        return true
    end
    if self.p_userPurchaseType == PURCHASE_TYPE.BIG_PURCHASE then
        return true
    end
    return false
end

--是否有播放次数限制
function AdsRunData:isPlayRewardAds(position)
    if self:isNoAdsUser() then
        return false
    end
    if not self:checkLimitByDailyTimesByPos(position) then
        return false
    end
    --未分组或小R用户检测是否用播放次数限制
    if self.p_userPurchaseType == PURCHASE_TYPE.NO_PURCHASE or self.p_userPurchaseType == PURCHASE_TYPE.SMALL_PURCHASE then
        local playTimes = gLobalAdsControl:getADSWacthTime()
        local adsPlayCount = 0
        local info = self.p_vecPopAdsInfo[tostring(position)]
        if info then
            adsPlayCount = info.p_playTimes
        end

        return adsPlayCount == -1 or playTimes < adsPlayCount
    else
        return true
    end
end

function AdsRunData:getRewardVieoPlayTimes(position)
    if position and self.p_vecPopAdsInfo then
        local info = self.p_vecPopAdsInfo[tostring(position)]
        if info then
            return info.p_playTimes
        end
    end
    -- 暂定，如果没有从数据中找到剩余次数默认为0次
    return 0
end

--引导激励视频奖励翻倍
function AdsRunData:isGuidePlayAds()
    if self.p_leadTimes and self.p_leadTimes == 0 then
        return true
    else
        return false
    end
end
--设置当前激励视频为引导激励视频
function AdsRunData:setGuideAds(flag)
    self.m_isGuideAds = flag
end
function AdsRunData:getGuideAds()
    return self.m_isGuideAds
end

--是否有可以播放的银库广告（名字用的铜库）
function AdsRunData:isBronzeVedio()
    local isPlayBronzeVedio = gLobalDataManager:getNumberByField("isPlayBronzeVedio", 0)
    if isPlayBronzeVedio == 2 then
        --不能领取
        return false
    end
    if self:isGuidePlayAds() then
        -- 如果当前不是第一次引导激励视频的话才可以看银库视频
        return false
    end
    if self.p_isNull == false and self:isPlayRewardAds(PushViewPosType.VaultSpeedup) then
        local isPlay = self:CheckAdByPosition(PushViewPosType.VaultSpeedup) and gLobalAdsControl:getRewardLoadFlag()
        return isPlay
    end
    return false
end

--检测根据位置是否可以播放广告position 位置,skipInfo弃用,isPlayAdType是否检测同时弹窗
function AdsRunData:isPlayRewardForPos(position, skipInfo, isPlayAdType)
    if util_isLow_endMachine(true) then
        return false
    end
    if self.p_isNull == false and self:isPlayRewardAds(position) then
        local isPlay = self:CheckAdByPosition(position) and gLobalAdsControl:getRewardVideoStatus()
        return isPlay
    end
    return false
end
--插屏
function AdsRunData:isPlayAutoForPos(position, skipInfo, isPlayAdType)
    if util_isLow_endMachine(true) then
        return false
    end
    if self.p_isNull == false then
        local isPlay = self:CheckAutoAdByPosition(position) and gLobalAdsControl:getVideoStatus()
        if isPlay and isPlayAdType and gLobalAdsControl:getPlayAdType() ~= nil then
            isPlay = false
        end
        return isPlay
    end
    return false
end

function AdsRunData:getPublicAdsCD()
    return self.m_publicCdTime or 60
end

function AdsRunData:hasInterstitialAdsInfo()
    -- cxc 2021年11月30日20:14:08 rateus(设置界面中)开启标志  0： 都不打开 1： ios打开 2： 安卓打开 3： 都打开
    if globalData.constantData.RATEUS_SWITCH_SETTINGS then
        if globalData.constantData.RATEUS_SWITCH_SETTINGS == 0 then
            return true
        elseif globalData.constantData.RATEUS_SWITCH_SETTINGS == 1 and device.platform ~= "ios" then
            return true
        elseif globalData.constantData.RATEUS_SWITCH_SETTINGS == 2 and device.platform ~= "android" then
            return true
        end
    end

    return self:isInterstitialAds()
end

function AdsRunData:isInterstitialAds()
    if not next(self.p_vecAutoAdsInfo) then
        return false
    end
    return true
end

function AdsRunData:updateAutoAdsShowTime(_postion, _newTime)
    if self.m_vecAutoAdsShowTime[_postion] then
        self.m_vecAutoAdsShowTime[_postion] = _newTime
    end
end
return AdsRunData
