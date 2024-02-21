--[[
    author:JohnnyFred
    time:2020-06-17 21:13:24
]]
local BaseRankTitleUI = class("BaseRankTitleUI", util_require("base.BaseView"))

function BaseRankTitleUI:initUI(closeCallBack)
    self.closeCallBack = closeCallBack
    BaseRankTitleUI.super.initUI(self)
    self:runCsbAction("idle", true)
    self:initJackpotCoinTimer()
    self:updateCoinUI()
    self:addClickSound({"btnClose", "btn_close"}, SOUND_ENUM.MUSIC_BTN_CLICK)
end

function BaseRankTitleUI:initCsbNodes()
    self.coinIcon = self:findChild("Sprite_2")
    self.lbCoins = self:findChild("lbCoins")
end

function BaseRankTitleUI:updateCoinUI()
    local rankConfig = self:getRankCfg()
    if rankConfig ~= nil then
        self.lbCoins:setVisible(true)
        self.lbCoins:setString(util_formatCoins(rankConfig.p_prizePool or 0, 12))
        util_alignCenter(
            {
                {node = self.coinIcon},
                {node = self.lbCoins, alignX = 5}
            }
        )
    else
        self.lbCoins:setVisible(false)
    end
end

function BaseRankTitleUI:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btnInfo" or senderName == "btn_info" then
        sender:setTouchEnabled(false)
        performWithDelay(
            self,
            function()
                sender:setTouchEnabled(true)
            end,
            0.2
        )
        self:openRankHelpUI()
    elseif senderName == "btnClose" or senderName == "btn_close" then
        if self.closeCallBack ~= nil then
            sender:setTouchEnabled(false)
            self.closeCallBack()
        end
    end
end

function BaseRankTitleUI:openRankHelpUI()
    local uiView = util_createFindView(self:getRankHelpName())
    if uiView ~= nil then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
    end
end

function BaseRankTitleUI:getJackpotBeginCoins()
    local beginCoins = "0"
    local activityConfig = self:getActivityConfig()
    if activityConfig ~= nil and activityConfig.getExpireAt ~= nil and activityConfig:getExpireAt() then
        beginCoins = gLobalDataManager:getStringByField(self:getJackpotBeginCoinKey() .. tostring(activityConfig:getExpireAt()), beginCoins)
    end
    return beginCoins
end

function BaseRankTitleUI:getBeginRunCoins(baseCoin)
    local activityConfig = self:getActivityConfig()
    local beginRunCoins = activityConfig:getRankJackpotCoins()
    local coins = self:getJackpotBeginCoins()
    beginRunCoins = toLongNumber(coins) <= toLongNumber(baseCoin) and baseCoin or coins

    return toLongNumber(beginRunCoins)
end

function BaseRankTitleUI:removeJackpotTimer()
    if self.jackpotCoinTimer ~= nil then
        self:stopAction(self.jackpotCoinTimer)
        self.jackpotCoinTimer = nil
    end
end

function BaseRankTitleUI:initJackpotCoinTimer()
    local activityConfig = self:getActivityConfig()
    local rankConfig = self:getRankCfg()
    local lbCoins = self.lbCoins
    if self.jackpotCoinTimer == nil and activityConfig ~= nil and rankConfig ~= nil then
        local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = BaseRankTitleUI.getJackpotRateInfo(rankConfig.p_prizePool)
        local jackpotCurCoin = self:getBeginRunCoins(baseCoin)
        local coinIcon = self.coinIcon

        lbCoins:setVisible(true)
        lbCoins:setString(util_formatCoins(jackpotCurCoin, 12))
        --self:updateLabelSize({label = lbCoins}, 580)
        activityConfig:setRankJackpotCoins(jackpotCurCoin)
        util_alignCenter(
            {
                {node = coinIcon},
                {node = lbCoins, alignX = 5}
            }
        )

        local perAddCount = 0
        local perAdd1 = perAdd * 0.08
        local perAdd2 = topMaxperAdd * 0.08
        self.jackpotCoinTimer =
            schedule(
            lbCoins,
            function()
                --判断更新增量
                if jackpotCurCoin <= maxCoin then
                    if perAddCount ~= perAdd1 then
                        perAddCount = perAdd1
                    end
                elseif jackpotCurCoin < topMaxCoin then
                    if perAddCount ~= perAdd2 then
                        perAddCount = perAdd2
                    end
                end
                jackpotCurCoin = jackpotCurCoin + perAddCount
                if jackpotCurCoin >= topMaxCoin then
                    jackpotCurCoin = topMaxCoin
                    self:removeJackpotTimer()
                end
                activityConfig:setRankJackpotCoins(jackpotCurCoin)
                lbCoins:setString(util_formatCoins(jackpotCurCoin, 12))
                --self:updateLabelSize({label = lbCoins}, 580)
                util_alignCenter(
                    {
                        {node = coinIcon},
                        {node = lbCoins, alignX = 5}
                    }
                )
            end,
            0.08
        )

        self.jackpotSaveCoinTimer =
            schedule(
            self.coinIcon,
            function()
                self:saveJackpotCoins(jackpotCurCoin)
            end,
            5
        )
        self:saveJackpotCoins(jackpotCurCoin)
    end

    if not rankConfig then
        lbCoins:setVisible(false)
    end
end

function BaseRankTitleUI:saveJackpotCoins(coins)
    local _coins = coins
    if iskindof(coins, "LongNumber") then
        _coins = coins.lNum
    end
    local activityConfig = self:getActivityConfig()
    if activityConfig and activityConfig.getExpireAt ~= nil and activityConfig:getExpireAt() then
        gLobalDataManager:setStringByField(self:getJackpotBeginCoinKey() .. tostring(activityConfig:getExpireAt()), tostring(_coins))
    end
end

function BaseRankTitleUI:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if not tolua.isnull(self) and self.getActivityRefName then
                if data and data.refName == self:getActivityRefName() then
                    self:initJackpotCoinTimer()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    )
end

function BaseRankTitleUI:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
---------------------------------------------子类重写---------------------------------
function BaseRankTitleUI:getCsbName()
    return nil
end

-- 活动引用名
function BaseRankTitleUI:getActivityRefName()
    assert(false, "-------- 子类必须重新 ---------")
end

function BaseRankTitleUI:getActivityConfig()
    return nil
end

function BaseRankTitleUI:getRankCfg()
    return nil
end

function BaseRankTitleUI:getRankHelpName()
    return nil
end

function BaseRankTitleUI:getJackpotBeginCoinKey()
    return nil
end
---------------------------------------------子类重写---------------------------------
function BaseRankTitleUI.getJackpotRateInfo(coin)
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
return BaseRankTitleUI
