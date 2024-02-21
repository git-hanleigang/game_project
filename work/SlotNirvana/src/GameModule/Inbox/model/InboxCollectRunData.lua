--[[--
]]
local BaseGroupMailData = util_require("GameModule.Inbox.model.mailData.BaseGroupMailData")
local BaseInboxRunData = util_require("GameModule.Inbox.model.BaseInboxRunData")
local InboxCollectRunData = class("InboxCollectRunData", BaseInboxRunData)

function InboxCollectRunData:ctor()
    BaseInboxRunData.ctor(self)

    self.m_localMailDatas = {} --本地邮件
    self.m_limitMax = 50 -- 显示的最大数量

    self.m_showMailDatas = {} -- 将分组视为一个邮件
end

function InboxCollectRunData:parseData(_netData)
    self.m_showMailDatas = {}
    self:initMailData(_netData)
    self:initShowMailServerData()
    self:updataLocalMail()
    self:initShowMailClientData()

    self:sortMailData()
end

function InboxCollectRunData:refreshLocalMail()
    self:updataLocalMail()
    self:initShowMailClientData()

    self:sortMailData()
end

function InboxCollectRunData:sortMailData()
    if not (self.m_showMailDatas and #self.m_showMailDatas > 1) then
        return
    end
    local function GetGroupZOrder(_type, _isGroup)
        if _isGroup then
            local cfgGroup = InboxConfig.getGroupCfgByName(_type)
            if cfgGroup and cfgGroup.zOrder and cfgGroup.zOrder > 0 then
                return cfgGroup.zOrder
            end
        end
        return 0
    end
    local function GetCategoryZOrder(_type, _netMail)
        local mapCfg = InboxConfig.getNameMapConfig(_type, _netMail)
        if mapCfg then
            return mapCfg.category or 0
        end
        return 0
    end
    local function sortGroupItemFunc(a, b)
        local aType = a:getType()
        local bType = b:getType()
        local aId = tonumber(a:getId())
        local bId = tonumber(b:getId())
        local aCategoryZOrder = GetCategoryZOrder(aType, a:isNetMail())
        local bCategoryZOrder = GetCategoryZOrder(bType, b:isNetMail())
        local aTicketId = tonumber(a.ticketId or 0)
        local bTicketId = tonumber(b.ticketId or 0)        
        local aExpireZOrder = a.getExpireTime and a:getExpireTime() or 0
        local bExpireZOrder = b.getExpireTime and b:getExpireTime() or 0
        if aCategoryZOrder == bCategoryZOrder then
            if aTicketId == bTicketId then
                if aExpireZOrder == bExpireZOrder then
                    return aId < bId
                else
                    return aExpireZOrder < bExpireZOrder
                end
            else
                return aTicketId < bTicketId
            end
        else
            return aCategoryZOrder < bCategoryZOrder
        end
    end
    local function sortFunc(a, b)
        local aType = a:getType()
        local bType = b:getType()
        local aId = tonumber(a:getId())
        local bId = tonumber(b:getId())
        local aGroupZOrder = GetGroupZOrder(aType, a:isGroup())
        local bGroupZOrder = GetGroupZOrder(bType, b:isGroup())
        local aCategoryZOrder = GetCategoryZOrder(aType, a:isNetMail())
        local bCategoryZOrder = GetCategoryZOrder(bType, b:isNetMail())
        if aGroupZOrder == bGroupZOrder then
            if aCategoryZOrder == bCategoryZOrder then
                return aId < bId
            else
                return aCategoryZOrder < bCategoryZOrder
            end
        else
            return aGroupZOrder < bGroupZOrder
        end
    end
    
    table.sort(self.m_showMailDatas, sortFunc)

    for i = 1, #self.m_showMailDatas do
        local mData = self.m_showMailDatas[i]
        if mData:isGroup() then
            local groupMailDatas = mData:getMailDatas()
            if groupMailDatas and #groupMailDatas > 1 then
                table.sort(groupMailDatas, sortGroupItemFunc)
            end
        end
    end    
end

-- 从网络邮件和本地邮件中组合分组数据，
-- 每次网络邮件和本地邮件改动都重新组合分组数据
function InboxCollectRunData:initShowMailServerData()
    if self.m_mailDatas and #self.m_mailDatas > 0 then
        for i = 1, #self.m_mailDatas do
            self:addShowMailData(self.m_mailDatas[i])
        end
    end
end

function InboxCollectRunData:initShowMailClientData()
    if self.m_localMailDatas and #self.m_localMailDatas > 0 then
        for i = 1, #self.m_localMailDatas do
            self:addShowMailData(self.m_localMailDatas[i])
        end
    end
end

function InboxCollectRunData:addGroupData(_groupName, _mailData)
    local id = InboxConfig.getGroupMailId(_groupName)
    local mData = self:getShowMailDataById(id)
    if not mData then
        mData = BaseGroupMailData:create()
        mData:parseData({id = id, groupName = _groupName, mailDatas = {}})
        table.insert(self.m_showMailDatas, mData)
    end
    mData:insertMailData(_mailData)
end

function InboxCollectRunData:addShowMailData(_mailData)
    local info = InboxConfig.getNameMapConfig(_mailData:getType(), _mailData:isNetMail())
    if info and info.category then
        -- 将分组视为一个邮件处理
        local groupCfg = InboxConfig.getGroupCfgByCategory(info.category)
        if groupCfg then
            self:addGroupData(groupCfg.name, _mailData)
        else
            table.insert(self.m_showMailDatas, _mailData)
        end
    else
        table.insert(self.m_showMailDatas, _mailData)
    end    
end

function InboxCollectRunData:removeShowMailData(_mailData)
    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = #self.m_showMailDatas, 1, -1 do
            local mData = self.m_showMailDatas[i]
            if tonumber(mData:getId()) == tonumber(_mailData:getId()) then
                table.remove(self.m_showMailDatas, i)
                break
            end
        end
    end
end

function InboxCollectRunData:removeShowMailDataById(_idList)
    if _idList and #_idList > 0 then
        for j = 1, #_idList do            
            for i = #self.m_showMailDatas, 1, -1 do
                local mData = self.m_showMailDatas[i]
                if tonumber(mData:getId()) == tonumber(_idList[j]) then
                    table.remove(self.m_showMailDatas, i)
                    break
                end
            end
        end
    end
end

-- type 有可能有重复的，遍历到底
function InboxCollectRunData:removeShowMailDataByType(_type)
    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = #self.m_showMailDatas, 1, -1 do
            local mData = self.m_showMailDatas[i]
            if mData:getType() == _type then
                table.remove(self.m_showMailDatas, i)
            end
        end
    end
end

function InboxCollectRunData:getShowMailDataById(_id)
    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = 1, #self.m_showMailDatas do
            local mData = self.m_showMailDatas[i]
            if tonumber(mData:getId()) == tonumber(_id) then
                return mData
            end
        end
    end
    return nil
end

function InboxCollectRunData:getShowMailDatas()
    return self.m_showMailDatas
end

function InboxCollectRunData:addLocalMailData(_localMailData)
    local dataName = nil
    local mailInfo = InboxConfig.InBoxLocalNameMap[_localMailData.m_type]
    if mailInfo and mailInfo.dataName then
        dataName = mailInfo.dataName
    else
        dataName = "BaseClientMailData"
    end
    local lMdata = util_require("GameModule.Inbox.model.mailData." .. dataName):create()
    lMdata:parseData(_localMailData)

    if self:isCanShowLocalMail(lMdata) then
        table.insert(self.m_localMailDatas, lMdata)
    else
        print("addLocalMailData", _localMailData.m_type)
    end
end

function InboxCollectRunData:getLocalMailDataById(_id)
    if self.m_localMailDatas and #self.m_localMailDatas > 0 then
        for i = 1, #self.m_localMailDatas do
            local lmData = self.m_localMailDatas[i]
            if tonumber(lmData:getId()) == tonumber(_id) then
                return lmData
            end
        end
    end
    return nil
end

function InboxCollectRunData:isCanShowLocalMail(_localMailData)
    if not _localMailData then
        return false
    end
    if _localMailData:isTimeLimit() and _localMailData:getLeftTime() <= 0 then
        return false
    end
    local mType = _localMailData:getType()
    if mType == nil then
        return false
    end
    local mapCfg = InboxConfig.getNameMapConfig(mType, false)
    if not mapCfg then
        return false
    end
    -- 检测Inbox_Collect资源
    if mapCfg.isDownLoad and not globalDynamicDLControl:checkDownloaded("Inbox_Collect") then
        return false
    end
    -- 关联资源检测
    if not self:checkRelRes(mapCfg.relRes) then
        return false
    end
    -- 促销券邮件
    if mapCfg.category == InboxConfig.CATEGORY.Coupon then
        if not self:isCouponEffective(_localMailData.ticketId) then
            return false
        end            
    end
    -- 通知类邮件
    if mapCfg.category == InboxConfig.CATEGORY.Notice then
        if _localMailData.getExpireTime then
            if not self:isCustomExpireAtEffective(_localMailData:getExpireTime()) then
                return false
            end
        end
    end
    return true
end

-- 促销券是否有效
function InboxCollectRunData:isCouponEffective(_ticketId)
    if not _ticketId then
        return false
    end
    local config = globalData.itemsConfig:getCommonTicket(_ticketId)
    if not config or not config:checkEffective() then --无数据或者过期了
        return false
    end
    return true
end

-- 通知类邮件的自定义倒计时是否有效
function InboxCollectRunData:isCustomExpireAtEffective(_expireAt)
    if _expireAt == nil then
        return false
    end
    if _expireAt <= 0 then
        return false
    end
    if _expireAt - util_getCurrnetTime() <= 0 then
        return false
    end
    return true
end

-- 获取mail提示数量
function InboxCollectRunData:getMailCount()
    -- local netNum = #self.m_mailDatas
    -- local localNum = #self.m_localMailDatas
    local mailNum = 0
    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = #self.m_showMailDatas, 1, -1 do
            local mData = self.m_showMailDatas[i]
            if mData:isGroup()then
                local mailDatas = mData:getMailDatas()
                mailNum = mailNum + #mailDatas
            else
                if mData:getType() ~= InboxConfig.TYPE_LOCAL.facebook then
                    mailNum = mailNum + 1
                end
            end
        end
    end    
    return math.min(self.m_limitMax, mailNum)
end

----------------------------------------------------------------------------------------------------
-- 客户端本地缓存邮件
-- 区分于服务器发送的邮件
function InboxCollectRunData:updataLocalMail()
    self:clearLocalActivityMail()
    self:updateAppChargePayMail()
    self:updateAppChargeFreeMail()
    self:updateQuestionnaireMail() -- 调查问卷
    self:updateTicketMail() -- 折扣券
    -- self:updataSendCouponMail()     -- 促销券
    self:updateFreeGameWatchMail() -- 激励视频 送 freeSpin 邮件
    self:updateFreeGameMail() -- free spin 免费次数
    self:updataFacebookMail()
    self:updataBindPhone()
    self:updateWatchRewardVideoMail()
    self:updataVersionMail()
    self:updataPokerMail()
    -- self:updatePiggyNoviceDiscountMial()
    self:updateSpinBonusMail()
    self:updataLevelRushMail()
    self:updateMiniGameLevelFishMail()
    self:updateBigRContactMail() -- 用户直接沟通
    self:updateStarPickMail()
    self:updatePokerRecallMail() -- PokerRecall
    self:updateMiniGameDuckShotMail()
    self:updateMiniGameTreasureSeekerMail()
    self:updateInviteMial()
    self:updateMiniGameCashMoneyMail()
    self:updatePiggyClickerMail()
    self:updateSurveyGameMail() -- 调查问卷
    self:updateScratchCardsMail()
    self:updateMiniGamePinBallGoMail()
    self:updateDartsGameMail()
    self:updateDartsGameNewMail()
    self:updateMiniGamePlinkoMail()
    self:updateYearEndSummaryMail()
    self:updateNewYearGiftMail()
    self:updateMiniGamePerLinkMail()
    self:updateLevelRoadGameMail() -- 等级里程碑小游戏
    self:updateMiniGameMythicGameMail()
    self:updateBoxSystemMail()
    self:updateNotificationReward()
end

function InboxCollectRunData:clearLocalActivityMail()
    InboxConfig.resetRepeatTypes()

    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = #self.m_showMailDatas, 1, -1 do
            local mData = self.m_showMailDatas[i]
            local mId = mData:getId()
            if mData:isGroup() then
                local gmData = mData:getMailDatas()
                if gmData and #gmData > 0 then
                    for j = #gmData, 1, -1 do
                        local gmId = gmData[j]:getId()
                        local lmData = self:getLocalMailDataById(gmId)
                        if lmData then
                            table.remove(gmData, j)
                        end
                    end
                    -- 如果分组中邮件列表空了，移除分组数据
                    if #gmData == 0 then
                        table.remove(self.m_showMailDatas, i)
                    end
                end
            else
                local lmData = self:getLocalMailDataById(mId)
                if lmData then
                    table.remove(self.m_showMailDatas, i)
                end
            end
        end
    end

    self.m_localMailDatas = {}
end

function InboxCollectRunData:updateAppChargePayMail()
    local data = G_GetMgr(G_REF.AppCharge):getRunningData()
    if data then
        local products = data:getProducts()
        local len = table.nums(products)
        if len > 0 then
            for k,pData in pairs(products) do
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.appChargePay, productId = pData:getId()})
            end
        end
    end
end

function InboxCollectRunData:updateAppChargeFreeMail()
    -- todo    
end

function InboxCollectRunData:updateQuestionnaireMail()
    local queData = G_GetActivityDataByRef(ACTIVITY_REF.Questionnaire)
    if queData then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.questionnaire})
    end
end

--刷新saleTicketInbox
function InboxCollectRunData:updateTicketMail()
    -- pileUpTicketsIdList有堆积需求的优惠券Id列表(icon相同，ticketId不同，expireAt相同)  
    -- pileUpTicketsIdList结构 key = icon .. _Special {key1={expireAt1 = {},expireAt2 = {}}, key2={expireAt1 = {},expireAt2 = {}}}
    local pileUpTicketsIdList = {}
    local tickets = globalData.itemsConfig:getCommonTicketList()
    if tickets and #tickets > 0 then
        for i = 1, #tickets do
            local icon = tickets[i].p_icon
            if InboxConfig.TYPE_LOCAL[icon] then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL[icon], ticketId = tickets[i].p_id})
            else
                if string.find(icon, "VipCoupon") then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.vipTicket, ticketId = tickets[i].p_id})
                elseif string.find(icon, "CouponLevelUp") then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.rateMileStoneCoupon, ticketId = tickets[i].p_id})
                elseif string.find(icon, "Coupon_MC_Coin") or string.find(icon, "Coupon_MCS_Coin") then
                    local key = icon .. "_Special"
                    local expireAt = tickets[i].p_expireAt
                    local list = pileUpTicketsIdList[key]
                    if not list then
                        list = {}
                    end
                    local listExpireAt = list[tostring(expireAt)]
                    if not listExpireAt then
                        listExpireAt = {}
                    end
                    listExpireAt[#listExpireAt + 1] = tickets[i].p_id
                    list[tostring(expireAt)] = listExpireAt
                    pileUpTicketsIdList[key] = list
                elseif string.find(icon, "VCoupon") then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.VCoupon, ticketId = tickets[i].p_id})
                elseif string.find(icon, "Coupon") then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.ticket, ticketId = tickets[i].p_id})
                end
            end
        end
    end

    for icon, list in pairs(pileUpTicketsIdList) do
        for k, v in pairs(list) do
            if #v > 0 then
                self:addLocalMailData({m_type = icon, ticketId = v[1], ticketIdList = v})
            end
        end
    end
end

function InboxCollectRunData:updataSendCouponMail()
    if globalData.sendCouponConfig:isExist() == true then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.sendCoupon})
    end
end

-- free spin 免费次数
function InboxCollectRunData:updateFreeGameMail()
    -- gLobalLevelRushManager是这个吗？
    -- if not gLobalLevelRushManager:isDownloadInbox() then
    --     return
    -- end

    local freeSpinRewardData = globalData.iapRunData:getFreeGameData()
    if freeSpinRewardData then
        local rewards = freeSpinRewardData:getRewards()
        if rewards and table_nums(rewards) > 0 then
            for _, rewardData in pairs(rewards) do
                -- csc 2021-12-15 新增 freeGameAds 类型 --- 需要区分当前是 ads邮件还是 普通回归赠送 freegame
                if rewardData:getAction() == "Ad" then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.freeGameAds, ticketId = rewardData.order})
                else
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.freeGame, ticketId = rewardData.order})
                end
            end
        end
    end
end

--刷新Facebook
function InboxCollectRunData:updataFacebookMail()
    if not globalData.userRunData.fbUdid or globalData.userRunData.fbUdid == "" then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.facebook})
    end
end

-- 刷新bindPhone
function InboxCollectRunData:updataBindPhone()
    local bindPhone = require("views.BindPhone.BindPhoneCtrl")
    if not bindPhone then
        return
    end
    local isRunning = bindPhone:getInstance():isRunning()
    if isRunning then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.bindPhone})
    end
end

function InboxCollectRunData:removeBindPhoneMail()
    self:removeShowMailDataByType(InboxConfig.TYPE_LOCAL.bindPhone)
end

--刷新版本更新
function InboxCollectRunData:updataVersionMail()
    if not util_isSupportVersion(G_GetMgr(G_REF.Inbox):getNewAppVer()) then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.version})
    end
end

--刷新LevelRush
function InboxCollectRunData:updataLevelRushMail()
    -- csc 如果当前已经进入了小游戏界面,不需要再更新邮件状态
    if gLobalLevelRushManager:getIsEnterGameView() then
        return
    end
    -- 设置当前数据来源
    gLobalLevelRushManager:setLevelRushSource("LevelRushInbox")
    local isDownloadInbox = gLobalLevelRushManager:isDownloadInbox()
    local levelRushGameData = gLobalLevelRushManager:pubGetLevelRushData(true)
    if isDownloadInbox and levelRushGameData then
        local gameDatas = levelRushGameData:getGameDatas()
        if gameDatas and table_nums(gameDatas) > 0 then
            for k, v in pairs(gameDatas) do
                local gameData = v
                local nLevel = globalData.userRunData.levelNum
                local bGameOver = gLobalLevelRushManager:pubGetGameOverByIndex(gameData:getGameIndex())

                if gameData:getGameEndLevel() <= nLevel and not bGameOver then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.LevelRush, nIndex = gameData:getGameIndex()})
                end
            end
        end
    end

    gLobalLevelRushManager:setLevelRushSource(nil)
end
-- 删除levelRush邮件 活动倒计时结束
function InboxCollectRunData:removeLevelRushMail()
    self:removeShowMailDataByType(InboxConfig.TYPE_LOCAL.LevelRush)
end

--刷新Level Dash 扑克游戏
function InboxCollectRunData:updataPokerMail()
    local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
    if
        levelDashData and levelDashData:getIsExist() == true and
            (levelDashData:getLevelDashStatus() == LEVEL_DASH_STATUS.GAME or levelDashData:getLevelDashStatus() == LEVEL_DASH_STATUS.REWARD or
                levelDashData:getLevelDashStatus() == LEVEL_DASH_STATUS.PLAY)
     then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.poker})
    end
end

-- function InboxCollectRunData:updatePiggyNoviceDiscountMial()
--     local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
--     if piggyBankData and piggyBankData:checkInNoviceDiscount() then
--         self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.piggyNoviceDiscount})
--     end
-- end

function InboxCollectRunData:updateSpinBonusMail()
    local spinBonusData = globalData.spinBonusData
    if spinBonusData and spinBonusData:isTaskOpen() then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.spinBonusReward})
    end
end

-- 添加激励视频条幅
function InboxCollectRunData:updateWatchRewardVideoMail()
    -- csc 2021-12-15 能否添加reward video 邮件新加判断
    local canAddRewardVideoMail = true
    local freeSpinData = globalData.iapRunData:getFreeGameData()
    if freeSpinData then
        local adsFreeGameData = freeSpinData:getRewardsByAction("Ad")
        if #adsFreeGameData > 0 and freeSpinData:getDataActive(adsFreeGameData) then
            canAddRewardVideoMail = false
        end
    -- canAddRewardVideoMail = #adsFreeGameData > 0 and  or true -- 有激活状态的情况下 可以添加视频邮件coin奖励
    end

    -- 如果存在watch 状态的freegame ads 邮件，也不能添加
    for i, v in ipairs(self.m_localMailDatas) do
        if v.m_type == InboxConfig.TYPE_LOCAL.freeGameAds and v.ticketId and v.ticketId == -1 then
            canAddRewardVideoMail = false -- 当前有 watch状态邮件的情况下不能添加
        end
    end

    if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.InboxReward) and canAddRewardVideoMail then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.watchVideo})
    end
end

--[[
    @desc: minigame LevelFish 游戏 
    author:csc
    time:2021-06-16 19:53:44
]]
function InboxCollectRunData:updateMiniGameLevelFishMail()
    -- csc 如果当前已经进入了小游戏界面,不需要再更新邮件状态
    if gLobalLevelRushManager:getIsEnterGameView() then
        return
    end
    local isDownloadInbox = gLobalLevelRushManager:isDownloadInbox()
    local gameDatas = gLobalMiniGameManager:getMiniGameByRef(gLobalMiniGameManager.MINIGAME_REF.MINIGAME_LEVELFISH)
    if isDownloadInbox and gameDatas then
        if gameDatas and table.nums(gameDatas) > 0 then
            -- 设置当前数据来源
            gLobalLevelRushManager:setLevelRushSource("MiniGame")
            for k, v in pairs(gameDatas) do
                local gameData = v.gameData
                local bGameOver = gLobalMiniGameManager:getGameOverByIndex(gameData:getGameIndex())

                if not bGameOver then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGameLevelFish, nIndex = gameData:getGameIndex()})
                end
            end
        end
    end
end

-- csc 2021年10月18日 用户直接反馈
function InboxCollectRunData:updateBigRContactMail()
    if globalData.userRunData:getUserCommunication() then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.bigRContact})
    end
end

-- 第二任务线小游戏
function InboxCollectRunData:updateStarPickMail()
    -- 设置当前数据来源
    local gPickMgr = G_GetMgr(G_REF.GiftPickBonus)
    local gPickData = gPickMgr:getData()
    if gPickData then
        local gameDatas = gPickData:getPickGameDatas()
        if gameDatas and table_nums(gameDatas) > 0 then
            for k, gameData in pairs(gameDatas) do
                if not gameData:isFinished() then
                    local gameId = gameData:getId()
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.GiftPickBonusGame, nIndex = gameId})
                end
            end
        end
    end
end

function InboxCollectRunData:updateFreeGameWatchMail()
    -- 基础 watch状态的freegameAds 邮件
    -- 检测条件
    --1.当天有这个点位的广告
    local hasRewardVideo = globalData.adsRunData:isPlayRewardForPos(PushViewPosType.InboxFreeSpin)
    --2.当前 freegame数据中没有 ‘Ad’来源的数据
    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local adsFreeGameData = freeSpinData:getRewardsByAction("Ad")
    local hasAdsFreeGameTicket = #adsFreeGameData > 0 and true or false
    --3.已经跨天 即上次添加的时间
    local hasNewDay = false
    local lastAddTimeCd = tonumber(gLobalDataManager:getStringByField("inboxAddFreeGameAdsWatchTimeCd", "0"))
    --4.当前不能是第一次看激励视屏
    local fisrtGuideAds = globalData.adsRunData:isGuidePlayAds()
    --逻辑部分
    --需要检测是否是否跨天,同时当前是否有已经激活过的券
    if util_getTimeIsNewDay(lastAddTimeCd) then
        -- 如果当前跨天了，清空这个cd值
        gLobalDataManager:setStringByField("inboxAddFreeGameAdsWatchTimeCd", "0")
        lastAddTimeCd = 0
    end
    if lastAddTimeCd == 0 then
        hasNewDay = true
    -- gLobalDataManager:setStringByField("inboxAddFreeGameAdsWatchTimeCd", tostring(globalData.userRunData.p_serverTime))
    end

    -- 没有激励视频 或者 有已经激活了的券 或者没跨天 或者当前没看过激励视频 都不能展示出来
    if not hasRewardVideo or hasAdsFreeGameTicket or not hasNewDay or fisrtGuideAds then
    else
        -- -1 状态表示当前是watch 邮件
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.freeGameAds, ticketId = -1})
    end
end

-- PokerRecall
function InboxCollectRunData:updatePokerRecallMail()
    -- 设置当前数据来源
    local gPokerRecallMgr = G_GetMgr(G_REF.PokerRecall)
    local gPokerRecallData = gPokerRecallMgr:getData()
    if gPokerRecallData then
        local gameDatas = gPokerRecallData:getPokerRecallGameDatas()
        if gameDatas and table_nums(gameDatas) > 0 then
            for k, gameData in pairs(gameDatas) do
                if not gameData:getIsPlaying() and math.floor(util_getLeftTime(gameData:getExpireAt())) > 0 then
                    local gameId = gameData:getGameId()
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.PokerRecall, nIndex = gameId})
                end
            end
        end
    end
end

function InboxCollectRunData:updateMiniGameDuckShotMail()
    local gameDatas = G_GetMgr(ACTIVITY_REF.DuckShot):getData()
    if gameDatas then
        local list = gameDatas:getList()
        for k, v in pairs(list) do
            local gameData = v.gameData
            local nIndex = v.gameIndex
            if gameData:isInit() and gameData:isRunning() then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGameDuckShot, nIndex = nIndex})
            end
        end
    end
end

function InboxCollectRunData:updateMiniGamePinBallGoMail()
    local gameDatas = G_GetMgr(ACTIVITY_REF.PinBallGo):getData()
    if gameDatas then
        local list = gameDatas:getList()
        for k, gameData in pairs(list) do
            local nIndex = gameData:getIndex()
            if gameData:isRunning() then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGamePinBallGo, nIndex = nIndex})
            end
        end
    end
end

--刷新鲨鱼游戏的邮箱
function InboxCollectRunData:updateMiniGameTreasureSeekerMail()
    -- 设置当前数据来源
    local data = G_GetMgr(G_REF.TreasureSeeker):getData()
    if data then
        local gameDatas = data:getAllGameDatas()
        if gameDatas and table_nums(gameDatas) > 0 then
            for k, gameData in pairs(gameDatas) do
                local gameId = gameData:getId()
                if gameData:isInited() and math.floor(util_getLeftTime(gameData:getExpireAt())) > 0 then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.TreasureSeeker, nIndex = gameId})
                end
            end
        end
    end
end

function InboxCollectRunData:updateYearEndSummaryMail()
    local activityDatas = G_GetMgr(ACTIVITY_REF.YearEndSummary):getRunningData()
    if activityDatas then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.YearEndSummary})
    end
end

--拉新
function InboxCollectRunData:updateInviteMial()
    local data = G_GetMgr(G_REF.Invite):getData()
    if not data then
        return
    end
    local mail_data = G_GetMgr(G_REF.Invite):getMail()
    if mail_data and #mail_data > 0 then
        for k, v in ipairs(mail_data) do
            self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.Invite, count = v})
        end
    end
end
-- 刷新CashMoney的邮件
function InboxCollectRunData:updateMiniGameCashMoneyMail()
    local gameDatas = G_GetMgr(G_REF.CashMoney):getData()
    if gameDatas then
        local list = gameDatas:getGameList()
        for k, v in pairs(list) do
            local gameData = v.gameData
            local gameId = v.gameId
            local source = gameData:getSource()
            if source ~= "CashBonus" then
                if not gameData:getGameStatus() and math.floor(util_getLeftTime(gameData:getExpireAt())) > 0 then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGameCashMoney, gameId = gameId})
                end
            end
        end
    end
end

function InboxCollectRunData:updateSurveyGameMail()
    local data = G_GetMgr(ACTIVITY_REF.SurveyinGame):getRunningData()
    if data then
        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.SurveyGame})
    end
end

--刷新刮刮卡邮件数据
function InboxCollectRunData:updateScratchCardsMail()
    -- 设置当前数据来源
    local data = G_GetMgr(ACTIVITY_REF.ScratchCards):getData()
    if data then
        local gearPurchase = data:getGearPurchaseInbox()
        if gearPurchase then
            for i, v in ipairs(gearPurchase) do
                local inx = data:getIndexByGearKey(v.gearKey)
                if #v.purchaseResultList > 0 then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.ScratchCards, m_index = inx, m_num = #v.purchaseResultList})
                end
            end
        end
    end
end

function InboxCollectRunData:updateMiniGamePlinkoMail()
    local mgr = G_GetMgr(G_REF.Plinko)
    if mgr and mgr:isCanShowLayer() then
        local data = mgr:getData()
        if data then
            local gameDatas = data:getGames()
            if gameDatas and table.nums(gameDatas) > 0 then
                for k, v in pairs(gameDatas) do
                    if v:isCollect() == false and v:getLeftTime() > 0 then
                        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.Plinko, nIndex = v:getIndex()})
                    end
                end
            end
        end
    end
end
--leveldashLink 小游戏
function InboxCollectRunData:updateMiniGamePerLinkMail()
    local mgr = G_GetMgr(G_REF.LeveDashLinko)
    if mgr and globalDynamicDLControl:checkDownloaded("Activity_LevelRush") then
        local data = mgr:getData()
        if data then
            local gameDatas = data:getGames()
            if gameDatas and table.nums(gameDatas) > 0 then
                for k, v in pairs(gameDatas) do
                    if v:isCollect() == false and v:getLeftTime() > 0 and v:getGameStatus() == "INIT" then
                        self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.PerLinko, nIndex = v:getIndex()})
                    end
                end
            end
        end
    end
end

-- 刷新快速点击小游戏邮件
function InboxCollectRunData:updatePiggyClickerMail()
    local gameDatas = G_GetMgr(ACTIVITY_REF.PiggyClicker):getData()
    if gameDatas then
        local list = gameDatas:getAllGameDataList()
        for k, _gameData in pairs(list) do
            if _gameData and _gameData:checkCanPlay() then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGamePiggyClicker, gameData = _gameData})
            end
        end
    end
end

-- 刷新快速点击小游戏邮件
function InboxCollectRunData:removePiggyClickerMail(_gameIdx)
    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = #self.m_showMailDatas, 1, -1 do
            local mData = self.m_showMailDatas[i]
            if mData:getType() == InboxConfig.TYPE_LOCAL.miniGamePiggyClicker then
                if mData.gameData and mData.gameData:getGameIdx() == _gameIdx then
                    table.remove(self.m_showMailDatas, i)
                end
            end
        end
    end
end

function InboxCollectRunData:updateDartsGameMail()
    local gameDatas = G_GetMgr(ACTIVITY_REF.DartsGame):getData()
    if gameDatas then
        local list = gameDatas:getGameList()
        for k, _gameData in pairs(list) do
            if _gameData and _gameData:canPlay() then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGameDarts, gameData = _gameData})
            end
        end
    end
end

function InboxCollectRunData:removeDartsGameMail(_gameIdx)
    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = #self.m_showMailDatas, 1, -1 do
            local mData = self.m_showMailDatas[i]
            if mData:getType() == InboxConfig.TYPE_LOCAL.miniGameDarts then
                if mData.gameData and mData.gameData:getIndex() == _gameIdx then
                    table.remove(self.m_showMailDatas, i)
                end
            end
        end
    end
end

function InboxCollectRunData:updateDartsGameNewMail()
    local gameDatas = G_GetMgr(ACTIVITY_REF.DartsGameNew):getData()
    if gameDatas then
        local list = gameDatas:getGameList()
        for k, _gameData in pairs(list) do
            if _gameData and _gameData:canPlay() then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGameDartsNew, gameData = _gameData})
            end
        end
    end
end

function InboxCollectRunData:removeDartsGameNewMail(_gameIdx)
    if self.m_showMailDatas and #self.m_showMailDatas > 0 then
        for i = #self.m_showMailDatas, 1, -1 do
            local mData = self.m_showMailDatas[i]
            if mData:getType() == InboxConfig.TYPE_LOCAL.miniGameDartsNew then
                if mData.gameData and mData.gameData:getIndex() == _gameIdx then
                    table.remove(self.m_showMailDatas, i)
                end
            end
        end
    end
end

function InboxCollectRunData:updateNewYearGiftMail()
    local mgr = G_GetMgr(ACTIVITY_REF.NewYearGift)
    if mgr and mgr:isCanShowLayer() and mgr:isSubmited() == false then
        local data = mgr:getData()
        if data then
            local address = data:getAddress()
            if address and address ~= "" then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.NewYearGift})
            end
        end
    end
end

function InboxCollectRunData:removeNewYearGiftMail()
    for i = #self.m_mailDatas, 1, -1 do
        local data = self.m_mailDatas[i]
        if data.m_type == InboxConfig.TYPE_LOCAL.NewYearGift then
            if G_GetMgr(ACTIVITY_REF.NewYearGift):isSubmited() then
                table.remove(self.m_mailDatas, i)
            end
        end
    end    
end

function InboxCollectRunData:updateMiniGameMythicGameMail()
    local data = G_GetMgr(G_REF.MythicGame):getData()
    if data then
        local gameDatas = data:getAllGameDatas()
        if gameDatas and table_nums(gameDatas) > 0 then
            for k, gameData in pairs(gameDatas) do
                local gameId = gameData:getId()
                if gameData:isInited() or gameData:isPlaying() then
                    self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.MythicGame, nIndex = gameId})
                end
            end
        end
    end
end

-- 等级里程碑小游戏
function InboxCollectRunData:removeLevelRoadGameMail(_gameIdx)
    for i = #self.m_mailDatas, 1, -1 do
        local data = self.m_mailDatas[i]
        if data.m_type == InboxConfig.TYPE_LOCAL.miniGameLevelRoad then
            if data.m_type == InboxConfig.TYPE_LOCAL.miniGameLevelRoad and data.gameData and data.gameData:getIndex() == _gameIdx then
                table.remove(self.m_mailDatas, i)
            end
        end
    end 
end

-- 等级里程碑小游戏
function InboxCollectRunData:updateLevelRoadGameMail()
    local gameDatas = G_GetMgr(ACTIVITY_REF.LevelRoadGame):getData()
    if gameDatas then
        local list = gameDatas:getGameList()
        for k, _gameData in pairs(list) do
            if _gameData and _gameData.p_status ~= "END" then -- END 状态为领奖之后，不用在邮箱中显示
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.miniGameLevelRoad, gameData = _gameData})
            end
        end
    end
end

function InboxCollectRunData:updateBoxSystemMail()
    local boxList = G_GetMgr(G_REF.BoxSystem):getBoxGroupList()
    if boxList and table.nums(boxList) > 0 then
        for k, v in pairs(boxList) do
            if v:getNum() > 0 then
                self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.BoxSystem, groupData = v})
            end
        end
    end
end

-- 推送奖励
function InboxCollectRunData:updateNotificationReward()
    if util_isSupportVersion("1.9.4", "android") or util_isSupportVersion("1.9.9", "ios") then
        local hasReward = G_GetMgr(ACTIVITY_REF.Notification):hasReward()
        if hasReward then
            self:addLocalMailData({m_type = InboxConfig.TYPE_LOCAL.NotificationReward})
        end
    end
end

return InboxCollectRunData
