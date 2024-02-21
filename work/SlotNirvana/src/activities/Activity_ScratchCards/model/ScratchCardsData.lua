--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-04-28 16:04:28
    describe:刮刮卡数据层
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local ScratchCardsData = class("ScratchCardsData", BaseActivityData)

function ScratchCardsData:ctor()
    ScratchCardsData.super.ctor(self)
    self.m_isGuide = nil
end

function ScratchCardsData:parseData(data)
    BaseActivityData.parseData(self, data)
    self.m_canFree = data.canFree
    self.m_defaultGearKey = data.defaultGearKey
    self.m_gearInfoList = self:parseGearInfoList(data.gearInfoList)
    self.m_gearPurchaseInboxResult = self:parseGearPurchaseInboxResult(data.gearPurchaseInboxResult)
    self.m_gearPurchaseResult = self:parseGearPurchaseResult(data.gearPurchaseResult)
    self.m_nextFreeTime = data.nextFreeTime
    self.m_showGuide = data.showGuide
    self.m_gearKey = ""

    --自定义数据
    if self.m_isGuide == nil then
        self.m_isGuide = self.m_showGuide
    end

    if self:isCanDelete() then
        self:setIgnoreExpire(false)
    else
        self:setIgnoreExpire(true)
    end
end

--解析主界面数据
function ScratchCardsData:parseGearInfoList(data)
    local infoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.first = v.first
        info.gearKey = v.gearKey
        info.gearTitle = v.gearTitle
        info.payInfoList = self:parsePayInfoList(v.payInfoList)
        info.remainingNum = v.remainingNum
        if info.gearTitle == "FREE" then --无限
            info.remainingNum = 99999999
        end
        info.winningPlayerList = self:parseWinningPlayerList(v.winningPlayerList)
        info.topRewardCoins = v.topRewardCoins
        table.insert(infoList, info)
    end
    return infoList
end

function ScratchCardsData:parsePayInfoList(data)
    local payInfoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.key = v.key
        info.keyId = v.keyId
        info.price = v.price
        info.num = v.num == 0 and "1" or v.num
        table.insert(payInfoList, info)
    end
    return payInfoList
end

function ScratchCardsData:parseWinningPlayerList(data)
    local playerList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.head = v.head
        info.name = v.name
        info.rank = v.rank
        info.udid = v.udid
        info.winningCoins = v.winningCoins
        table.insert(playerList, info)
    end
    return playerList
end

--解析邮件中刮刮卡数据
function ScratchCardsData:parseGearPurchaseInboxResult(data)
    return self:parseGearPurchaseResult(data)
end

--解析刮刮卡数据
function ScratchCardsData:parseGearPurchaseResult(data)
    local infoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.gearKey = v.gearKey
        info.expirationTime = v.expirationTime
        info.purchaseResultList = self:parsePurchaseResultList(v.purchaseResultList)
        table.insert(infoList, info)
    end
    return infoList
end

function ScratchCardsData:parsePurchaseResultList(data)
    local infoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.cardInfoList = self:parseCardInfoList(v.cardInfoList)
        info.coins = v.coins
        info.serialNumber = v.serialNumber
        info.winningIndexList = v.winningIndexList
        info.winningNumbers = v.winningNumbers
        table.insert(infoList, info)
    end
    return infoList
end

function ScratchCardsData:parseCardInfoList(data)
    local infoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.coins = v.coins
        info.number = tonumber(v.number)
        info.topReward = v.topReward
        table.insert(infoList, info)
    end
    return infoList
end

---------------------------------华丽分割线---------------------------------
function ScratchCardsData:isFree() --true-有免费次数
    return self.m_canFree or false
end

function ScratchCardsData:isTopReward(_inx, _sourceType) --是否是大奖
    local inx = _inx or 1
    local gearPurchase = self:getPurchaseResultListByIndex(inx, _sourceType)
    local cardInfo = gearPurchase and gearPurchase.cardInfoList or {}
    for i, v in ipairs(cardInfo) do
        if v.topReward then
            return true, i
        end
    end
    return false, nil
end

function ScratchCardsData:setGearKey(value) --设置付费标识的唯一key
    self.m_gearKey = tostring(value)
end

function ScratchCardsData:setCanFree(value)
    self.m_canFree = value
end

function ScratchCardsData:setIsGuide(value)
    self.m_isGuide = value
end

function ScratchCardsData:getIsGuide() --是否新手引导
    return self.m_isGuide or false
end

function ScratchCardsData:getGearKey() --获得付费标识的唯一key
    return self.m_gearKey or ""
end

function ScratchCardsData:getNextFreeTime() --下次免费领取时间戳
    return self.m_nextFreeTime / 1000 or 0
end

function ScratchCardsData:getGearInfoByIndex(_inx) --获得档位信息
    local inx = _inx or 1
    return self.m_gearInfoList[inx]
end

function ScratchCardsData:getGearPurchaseByIndex(_inx, _sourceType) --获得刮刮卡数据
    local inx = _inx or 1
    local gearInfo = self:getGearInfoByIndex(inx)
    local gearKey = gearInfo.gearKey
    local gearPurchaseResult = self.m_gearPurchaseResult
    if _sourceType == "inbox" or _sourceType == "all" then
        gearPurchaseResult = self.m_gearPurchaseInboxResult
    end
    for k, v in ipairs(gearPurchaseResult) do
        if gearKey == v.gearKey then
            return v
        end
    end
    if _sourceType == "default" then --走到这已经数据不正常了，再去邮件中找一下
        for k, v in ipairs(self.m_gearPurchaseInboxResult) do
            if gearKey == v.gearKey then
                return v
            end
        end
    end
    local errorMessage = "scratchCards getGearPurchaseByIndex ===== " .. "index: " .. _inx .. ", sourceType: " .. _sourceType .. ", gearKey: " .. gearKey
    release_print(errorMessage)
    return nil
end

function ScratchCardsData:getPurchaseResultListByIndex(_inx, _sourceType) --获得单张刮刮卡数据
    local inx = _inx or 1
    local gearPurchase = self:getGearPurchaseByIndex(inx, _sourceType)
    if gearPurchase and #gearPurchase.purchaseResultList > 0 then
        return gearPurchase.purchaseResultList[1]
    end
    return nil
end

function ScratchCardsData:getCardNumByIndex(_inx, _sourceType) --获得刮刮卡数量
    if _sourceType == "all" then
        return self:getUserLastCards()
    end
    local inx = _inx or 1
    local gearPurchase = self:getGearPurchaseByIndex(inx, _sourceType)
    if gearPurchase and gearPurchase.purchaseResultList then
        return #gearPurchase.purchaseResultList
    end
    return 0
end

function ScratchCardsData:getIndexByGearKey(_gearKey) --获得索引通过档位(不传默认推荐档位)
    local inx = 1
    local gearKey = _gearKey or self.m_defaultGearKey
    for i, v in ipairs(self.m_gearInfoList) do
        if gearKey == v.gearKey then
            return tonumber(i)
        end
    end
    return inx
end

--------------------- 邮件数据 ---------------------
function ScratchCardsData:getGearPurchaseInbox()
    return self.m_gearPurchaseInboxResult
end

function ScratchCardsData:getUserLastCards(_sourceType)
    local lastNum = 0
    local gearPurchaseResult = self.m_gearPurchaseInboxResult
    if _sourceType == "default" then
        gearPurchaseResult = self.m_gearPurchaseResult
    end
    for i, v in ipairs(gearPurchaseResult) do
        local num = #v.purchaseResultList
        lastNum = lastNum + num
    end
    return lastNum
end

-- 活动刮刮卡邮件数据中最大档位
function ScratchCardsData:getInboxMaxGear(_sourceType)
    local gearInfoList = self.m_gearInfoList
    local gearPurchaseResult = self.m_gearPurchaseInboxResult
    if _sourceType == "default" then
        gearPurchaseResult = self.m_gearPurchaseResult
    end
    for i = #gearInfoList, 1, -1 do
        for k, v in ipairs(gearPurchaseResult) do
            local gearInfo = gearInfoList[i]
            if gearInfo.gearKey == v.gearKey and #v.purchaseResultList > 0 then
                return tonumber(i)
            end
        end
    end
    return 0
end

--------------------- 派生方法 ---------------------
function ScratchCardsData:isCanDelete()
    local gearPurchase = self:getGearPurchaseInbox()
    if gearPurchase then
        for i, v in ipairs(gearPurchase) do
            if #v.purchaseResultList > 0 then
                return false
            end
        end
    end
    return true
end

-- 睡眠中
function ScratchCardsData:isSleeping()
    if self:getLeftTime() <= 2 then
        return true
    end

    return false
end

return ScratchCardsData
