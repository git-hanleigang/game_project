--
-- 袋鼠商店数据解析
--

local SendDataManager = require "network.SendDataManager"
local KangaroosShopData = class("KangaroosShopData")

KangaroosShopData.shopTitle = 
{
    "OutbackFrontierShop/Kangaroos_content1.png",
    "OutbackFrontierShop/Kangaroos_content2.png",
    "OutbackFrontierShop/Kangaroos_content3.png",
    "OutbackFrontierShop/Kangaroos_content4.png",
    "OutbackFrontierShop/Kangaroos_content5.png",
}

KangaroosShopData.m_shopData = nil
KangaroosShopData.m_preCollectCoins = nil

KangaroosShopData.m_requestPageIndex = nil
KangaroosShopData.m_requestPageCellIndex = nil

KangaroosShopData.m_netState = nil -- 正在请求数据
KangaroosShopData.isPlayingAction = nil -- 正在翻牌
KangaroosShopData.m_flyState = nil -- 正在播飞行动作
KangaroosShopData.m_freeSpinState = nil -- 触发freespin
KangaroosShopData.m_isCloseAction = nil -- 结束over动画
KangaroosShopData.m_pagesFree = {}
KangaroosShopData.m_enterFlag = nil
KangaroosShopData.m_bInShopView = nil

function KangaroosShopData:ctor()
end

function KangaroosShopData:release()
    self.m_shopData = nil
    self.m_preCollectCoins = nil
    self.m_requestPageIndex = nil
    self.m_requestPageCellIndex = nil
    self.m_netState = nil -- 正在请求数据
    self.isPlayingAction = nil -- 正在翻牌
    self.m_flyState = nil -- 正在播飞行动作
    self.m_freeSpinState = nil -- 触发freespin
    self.m_isCloseAction = nil -- 结束over动画
    self.m_pagesFree = {}
    self.m_enterFlag = nil
    self.m_bInShopView = nil
end

function KangaroosShopData:setEnterShopView(flag)
    self.m_bInShopView = flag
end

function KangaroosShopData:getEnterShopView()
    return self.m_bInShopView
end

function KangaroosShopData:setEnterFlag(flag)
    self.m_enterFlag = flag
end

function KangaroosShopData:getEnterFlag()
    return self.m_enterFlag
end

function KangaroosShopData:savePagesFree()
    self.m_pagesFree = {}
    for pageIndex=1,5 do
        local free = self:isPageFreeMore(pageIndex)
        local cellIndex = nil
        for j=1,9 do
            local status = self:getPageCellState(pageIndex, j)
            if status == "PageStatus_free" then
                cellIndex = j
                break
            end
        end
        self.m_pagesFree[pageIndex] = {free, cellIndex}
    end
end

function KangaroosShopData:getPagesFree()
    return self.m_pagesFree
end

function KangaroosShopData:setFreeSpinState(state)
    self.m_freeSpinState = state
end

function KangaroosShopData:getFreeSpinState()
    return not not self.m_freeSpinState
end

function KangaroosShopData:setFlyData( fly )
    self.m_flyState = fly
end

function KangaroosShopData:getFlyData(  )
    return self.m_flyState
end


function KangaroosShopData:setNetState(state)
    self.m_netState = state
end

function KangaroosShopData:getNetState()
    return self.m_netState
end

function KangaroosShopData:setExchangeEffectState(state)
    self.isPlayingAction = state
end

function KangaroosShopData:getExchangeEffectState()
    return self.isPlayingAction
end

function KangaroosShopData:setExCloseState(state)
    self.m_isCloseAction = state
end

function KangaroosShopData:getExCloseState()
    return self.m_isCloseAction
end

function KangaroosShopData:setRequestPageIndex(pageIndex)
    self.m_requestPageIndex = pageIndex
end

function KangaroosShopData:getRequestPageIndex()
    return self.m_requestPageIndex
end

function KangaroosShopData:setRequestPageCellIndex(pageCellIndex)
    self.m_requestPageCellIndex = pageCellIndex
end

function KangaroosShopData:getRequestPageCellIndex()
    return self.m_requestPageCellIndex
end

function KangaroosShopData:request_open(pageIndex, pageCellIndex)
    self:setNetState(true)
    self:setRequestPageIndex(pageIndex + 1)
    self:setRequestPageCellIndex(pageCellIndex + 1)
    local messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = {pageIndex = pageIndex, pageCellIndex = pageCellIndex}}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)    
end

--[[--
    "selfData":{
        "freespinTimes":{
            "2x":15,
            "3x":15,
            "4x":15
        },
        "coinsPosition":{
            "12":5
        },
        "collectCoins":50
]]
function KangaroosShopData:parseData(data)
    self.m_shopData = data
end


-- collectCoins:5620
-- allCards:{}
-- selectResult:18355000
-- free:{}
function KangaroosShopData:parseExchangeData(data)
    -- dump(data, " ========================= parseExchangeData =", 5)
    for k,v in pairs(data) do
        self.m_shopData[k] = v
    end
end

function KangaroosShopData:parseSpinResultData(data)
    self.m_preCollectCoins = self.m_shopData.collectCoins
    if self.m_shopData.collectCoins ~= data.collectCoins then
        self.m_shopData.collectCoins = data.collectCoins
    end
end

function KangaroosShopData:getShopData()
    return self.m_shopData
end

-- "collectCoins":1216354
-- "needCoins":[3000,4500,6000,9000,12000],
-- "cards":9,
-- "round":0,
-- "level":5,
-- "free":[false,false,false,false,false],
-- "allCards":
-- [
--     ["-1","-1","-1","-1","-1","-1","-1","-1","-1"],
--     ["-1","-1","-1","-1","-1","-1","-1","-1","-1"],
--     ["-1","-1","-1","-1","-1","-1","-1","-1","-1"],
--     ["-1","-1","-1","-1","-1","-1","-1","-1","-1"],
--     ["-1","-1","-1","-1","-1","-1","-1","-1","-1"]
-- ]
function KangaroosShopData:getShopCollectCoins()
    return self.m_shopData.collectCoins
end

function KangaroosShopData:getShopNeedCoins()
    return self.m_shopData.needCoins
end

function KangaroosShopData:getShopPageNum()
    return self.m_shopData.level
end

function KangaroosShopData:getShopPageCellNum()
    return self.m_shopData.cards
end

function KangaroosShopData:getShopRound()
    return self.m_shopData.round
end

function KangaroosShopData:getShopFreeMore()
    return self.m_shopData.free
end

function KangaroosShopData:getShopPageInfo()
    return self.m_shopData.allCards
end


-- 进入UI的时候默认选择的页数
function KangaroosShopData:getDefaultPageIndex()
    if not self.m_shopData then
        return 1
    end

    if tonumber(self.m_shopData.round) == 0 then
        local pageInfos = self:getShopPageInfo()
        -- for i=#pageInfos,1,-1 do
        --     local pageData = pageInfos[i]
        --     for j=1,#pageData do
        --         if pageData[j] ~= "-1" then
        --             return math(i+1)
        --         end
        --     end            
        -- end
        -- return 1 -- 默认第一页

        local index = 1
        for i=1,#pageInfos do
            local isAllOpen = true
            for j=1,#pageInfos[i] do
                if pageInfos[i][j] == '-1' then
                    isAllOpen = false
                    break
                end
            end
            if isAllOpen then
                index = i + 1
            end
        end
        return index
    else
        -- -- 已经跟策划核对完毕 张俊涛
        -- return self.m_shopData.level
        -- 定位到上一次购买的位置
        return self:getRequestPageIndex() or self.m_shopData.level
    end
end

-- 判断此页是否解锁
-- 第一轮时只有前一页全部兑换完成才能解锁下一页
-- 第一轮完成后的轮次全部解锁
function KangaroosShopData:isPageIndexUnlock(pageIndex)
    if not self.m_shopData then
        return false
    end

    if tonumber(self.m_shopData.round) == 0 then
        -- 第一页永远解锁
        if pageIndex == 1 then
            return true
        end
        
        local pageInfos = self:getShopPageInfo()
        -- 此页有兑换数据说明已经解锁
        local cellDatas = pageInfos[pageIndex]
        for i=1,#cellDatas do
            if cellDatas[i] ~= "-1" then
                return true
            end
        end

        -- 此页没有兑换好的数据，并且前一页全部兑换完成，则此页已经解锁
        local prePageDown = true
        local cellDatas = pageInfos[pageIndex-1]
        for i=1,#pageInfos[pageIndex-1] do
            if cellDatas[i] == "-1" then
                prePageDown = false
                break
            end
        end
        if prePageDown == true then
            return true
        end

        return false
    else
        return true
    end
end

function KangaroosShopData:isPageFreeMore(pageIndex)
    local frees = self:getShopFreeMore()
    return frees[pageIndex]
end

-- 统一处理reward字段
function KangaroosShopData:getRewardType(reward)
    if reward ~= "-1" then
        if reward == '2x' then
            return "PageStatus_free"
        else
            return "PageStatus_opened", reward
        end
    else
        return "PageStatus_unopen"
    end
end

function KangaroosShopData:getPageCellState(pageIndex, cellIndex)
    if self:isPageIndexUnlock(pageIndex) then
        local pageInfos     = self:getShopPageInfo()
        local pageCellInfo  = pageInfos[pageIndex][cellIndex]
        return self:getRewardType(pageCellInfo)
    else
        return "PageStatus_unlock"
    end
end

function KangaroosShopData:isAllUnopen()
    local pageInfos = self:getShopPageInfo()
    for i=1,#pageInfos do
        for j=1,#pageInfos[i] do
            if pageInfos[i][j] ~= '-1' then
                return false
            end
        end
    end
    return true
end


return KangaroosShopData