--
-- 袋鼠商店数据解析
--

local SendDataManager = require "network.SendDataManager"
local FortuneCatsShopData = class("FortuneCatsShopData")

FortuneCatsShopData.m_shopData = {}
FortuneCatsShopData.m_preCollectCoins = nil

FortuneCatsShopData.m_requestPageIndex = nil
FortuneCatsShopData.m_requestPageCellIndex = nil

FortuneCatsShopData.m_netState = nil -- 正在请求数据
FortuneCatsShopData.isPlayingAction = nil -- 正在翻牌
FortuneCatsShopData.m_flyState = nil -- 正在播飞行动作
FortuneCatsShopData.m_freeSpinState = nil -- 触发freespin
FortuneCatsShopData.m_pagesFree = {}
FortuneCatsShopData.m_enterFlag = nil
FortuneCatsShopData.m_bInShopView = nil

function FortuneCatsShopData:ctor()
end

function FortuneCatsShopData:release()
    self.m_shopData = nil
    self.m_preCollectCoins = nil
    self.m_requestPageIndex = nil
    self.m_requestPageCellIndex = ni
    self.m_netState = nil -- 正在请求数据
    self.isPlayingAction = nil -- 正在翻牌
    self.m_flyState = nil -- 正在播飞行动作
    self.m_freeSpinState = nil -- 触发freespin
    self.m_pagesFree = {}
    self.m_enterFlag = nil
    self.m_bInShopView = nil
end

function FortuneCatsShopData:setEnterShopView(flag)
    self.m_bInShopView = flag
end

function FortuneCatsShopData:getEnterShopView()
    return self.m_bInShopView
end

function FortuneCatsShopData:setEnterFlag(flag)
    self.m_enterFlag = flag
end

function FortuneCatsShopData:getEnterFlag()
    return self.m_enterFlag
end

function FortuneCatsShopData:savePagesFree()
    self.m_pagesFree = {}
    for pageIndex = 1, 4 do
        local free = self:isPageFreeMore(pageIndex)
        local cellIndex = nil
        for j = 1, 9 do
            local status = self:getPageCellState(pageIndex, j)
            if status == "PageStatus_free" then
                cellIndex = j
                break
            end
        end
        self.m_pagesFree[pageIndex] = {free, cellIndex}
    end
end

function FortuneCatsShopData:getPagesFree()
    return self.m_pagesFree
end

function FortuneCatsShopData:setFreeSpinState(state)
    self.m_freeSpinState = state
end

function FortuneCatsShopData:getFreeSpinState()
    return not (not self.m_freeSpinState)
end

function FortuneCatsShopData:setFlyData(fly)
    self.m_flyState = fly
end

function FortuneCatsShopData:getFlyData()
    return self.m_flyState
end

function FortuneCatsShopData:setNetState(state)
    self.m_netState = state
end

function FortuneCatsShopData:getNetState()
    return self.m_netState
end

function FortuneCatsShopData:setExchangeEffectState(state)
    self.isPlayingAction = state
end

function FortuneCatsShopData:getExchangeEffectState()
    return self.isPlayingAction
end

function FortuneCatsShopData:setRequestPageIndex(pageIndex)
    self.m_requestPageIndex = pageIndex
end

function FortuneCatsShopData:getRequestPageIndex()
    return self.m_requestPageIndex
end

function FortuneCatsShopData:setRequestPageCellIndex(pageCellIndex)
    self.m_requestPageCellIndex = pageCellIndex
end

function FortuneCatsShopData:getRequestPageCellIndex()
    return self.m_requestPageCellIndex
end

function FortuneCatsShopData:request_open(pageIndex, pageCellIndex)
    self:setNetState(true)
    self:setRequestPageIndex(pageIndex + 1)
    self:setRequestPageCellIndex(pageCellIndex + 1)
    --MSG_BONUS_SPECIAL messageData参数名字是统一的 pageIndex，pageCellIndex 底层固定了暂时只能这样
    local messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = {pageIndex = pageIndex, pageCellIndex = pageCellIndex}}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function FortuneCatsShopData:parseData(data)
    self.m_shopData = data
end

function FortuneCatsShopData:parseExchangeData(data)
    for k, v in pairs(data) do
        self.m_shopData[k] = v
    end
end

function FortuneCatsShopData:parseSpinResultData(data)
    self.m_preCollectCoins = self.m_shopData.scoreTotal
    if self.m_shopData.scoreTotal ~= data.scoreTotal then
        self.m_shopData.scoreTotal = data.scoreTotal
    end
end

function FortuneCatsShopData:getShopData()
    return self.m_shopData
end

function FortuneCatsShopData:getShopCollectCoins()
    return self.m_shopData.scoreTotal
end

function FortuneCatsShopData:getShopIsTriggerPick()
   
    if  self.m_shopData.triggerPick and self.m_shopData.triggerPick == 1 then
        return true
    else
        return false
    end
   
end

function FortuneCatsShopData:IsClickPick2()
   
    if self.m_shopData.pick2 and self.m_shopData.pick2 == 1 then
        return true
    else
        return false
    end
end

function FortuneCatsShopData:setShopCollectCoins(score)
    self.m_shopData.scoreTotal = score
end

function FortuneCatsShopData:getShopNeedCoins()
    return self.m_shopData.scoreLimit
end

function FortuneCatsShopData:getShopPageNum()
    return 4
end

function FortuneCatsShopData:getShopPageCellNum()
    return self.m_shopData.cards
end

function FortuneCatsShopData:getShopRound()
    return self.m_shopData.roundTag
end

function FortuneCatsShopData:getShopFreeMore()
    return self.m_shopData.free
end

function FortuneCatsShopData:getShopPageInfo()
    return self.m_shopData.collect
end

-- 进入UI的时候默认选择的页数
function FortuneCatsShopData:getDefaultPageIndex()
    if not self.m_shopData then
        return 1
    end
    -- if tonumber(self.m_shopData.roundTag) == 0 then --0,1说明开完一轮了 剩下的可以随便页数开了
        local pageInfos = self:getShopPageInfo()
        local index = 1
        for i = 1, #pageInfos do
            local isAllOpen = true
            for j = 1, #pageInfos[i] do
                if pageInfos[i][j][1] == 1 then --1代表没开 2代表开了
                    isAllOpen = false
                    break
                end
            end
            if isAllOpen then
                index = i + 1
            end
        end
        if index > 4 then
            index = 1
        end
        return index
    -- else
    --     return self:getRequestPageIndex() or self.m_shopData.level
    -- end
end

-- 判断此页是否解锁
-- 第一轮时只有前一页全部兑换完成才能解锁下一页
-- 第一轮完成后的轮次全部解锁
function FortuneCatsShopData:isPageIndexUnlock(pageIndex)
    if not self.m_shopData then
        return false
    end
    -- if tonumber(self.m_shopData.roundTag) == 0 then
        -- 第一页永远解锁
        if pageIndex == 1 then
            return true
        end

        local pageInfos = self:getShopPageInfo()
        -- 此页有兑换数据说明已经解锁
        local cellDatas = pageInfos[pageIndex]
        for i = 1, #cellDatas do
            if cellDatas[i][1] ~= 1 then
                return true
            end
        end

        -- 此页没有兑换好的数据，并且前一页全部兑换完成，则此页已经解锁
        local prePageDown = true
        local cellDatas = pageInfos[pageIndex - 1]
        for i = 1, #pageInfos[pageIndex - 1] do
            if cellDatas[i][1] == 1 then
                prePageDown = false
                break
            end
        end
        if prePageDown == true then
            return true
        end

        return false
    -- else
    --     return true
    -- end
end

-- 此页是否开完
function FortuneCatsShopData:isPageLockAllOpenIndex(pageIndex)
    if not self.m_shopData then
        return false
    end

    local pageInfos = self:getShopPageInfo()
    -- 此页有一个没开则说明还未开完
    local cellDatas = pageInfos[pageIndex]
    for i = 1, #cellDatas do
        if cellDatas[i][1] == 1 then
            return false
        end
    end
    return true
end

function FortuneCatsShopData:isPageFreeMore(pageIndex)
    -- local frees = self:getShopFreeMore()
    -- return frees[pageIndex]
    return false
end

-- 统一处理reward字段
function FortuneCatsShopData:getRewardType(reward)
    if reward[3] == 1 then
        local a = 0
    end
    if reward[1] ~= 1 then
        return "PageStatus_opened"
    else
        return "PageStatus_unopen"
    end
end

function FortuneCatsShopData:getPageCellState(pageIndex, cellIndex)
    if self:isPageIndexUnlock(pageIndex) then
        local pageInfos = self:getShopPageInfo()
        local pageCellInfo = pageInfos[pageIndex][cellIndex]
        return self:getRewardType(pageCellInfo)
    else
        return "PageStatus_unlock"
    end
end

function FortuneCatsShopData:isAllUnopen()
    local pageInfos = self:getShopPageInfo()
    for i = 1, #pageInfos do
        for j = 1, #pageInfos[i] do
            if pageInfos[i][j] ~= 1 then
                return false
            end
        end
    end
    return true
end

return FortuneCatsShopData
