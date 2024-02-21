--
-- 袋鼠商店数据解析
--

local SendDataManager = require "network.SendDataManager"
local WheelOfRomanceShopData = class("WheelOfRomanceShopData")

WheelOfRomanceShopData.m_shopData = {}
WheelOfRomanceShopData.m_preCollectCoins = nil

WheelOfRomanceShopData.m_requestPageIndex = nil
WheelOfRomanceShopData.m_requestPageCellIndex = nil
WheelOfRomanceShopData.m_requestPageLevel = nil
WheelOfRomanceShopData.m_requestPageNeedPoints = nil
WheelOfRomanceShopData.m_requestPageCellState = nil


WheelOfRomanceShopData.m_netState = nil -- 正在请求数据
WheelOfRomanceShopData.isPlayingAction = nil -- 正在翻牌
WheelOfRomanceShopData.m_flyState = nil -- 正在播飞行动作
WheelOfRomanceShopData.m_freeSpinState = nil -- 触发freespin
WheelOfRomanceShopData.m_pagesFree = {}
WheelOfRomanceShopData.m_enterFlag = nil
WheelOfRomanceShopData.m_bInShopView = nil

WheelOfRomanceShopData.ITEM_TYPE_DARK = "-2" -- 不可点击
WheelOfRomanceShopData.ITEM_TYPE_LOCK = "-1" -- 锁住
WheelOfRomanceShopData.ITEM_TYPE_IDLE = "0" -- 是可点击
WheelOfRomanceShopData.ITEM_TYPE_PORTRAIT_WHEEL = "2" -- 多个竖着的轮子
WheelOfRomanceShopData.ITEM_TYPE_CIRCULAR_WHEEL = "1" -- 是直接进大圆盘 
WheelOfRomanceShopData.ITEM_TYPE_CIRCULAR_COINS = "" -- > 0 金币钱

function WheelOfRomanceShopData:ctor()
    print("__ ctor")
end


function WheelOfRomanceShopData:setEnterShopView(flag)
    self.m_bInShopView = flag
end

function WheelOfRomanceShopData:getEnterShopView()
    return self.m_bInShopView
end

function WheelOfRomanceShopData:setEnterFlag(flag)
    self.m_enterFlag = flag
end

function WheelOfRomanceShopData:getEnterFlag()
    return self.m_enterFlag
end



--请求网络消息
function WheelOfRomanceShopData:setNetState(state)
    self.m_netState = state
end

function WheelOfRomanceShopData:getNetState()
    return self.m_netState
end

-- 播放动画
function WheelOfRomanceShopData:setExchangeEffectState(state)
    self.isPlayingAction = state
end

function WheelOfRomanceShopData:getExchangeEffectState()
    return self.isPlayingAction
end


-- BonusSpecial pageNo:从1开始 select:从1开始
function WheelOfRomanceShopData:request_open(pageIndex, pageCellIndex)
    self:setNetState(true)

    self:setRequestPageIndex(pageIndex)
    self:setRequestPageCellIndex(pageCellIndex)
    self:setRequestShopData( )



    --MSG_BONUS_SPECIAL messageData参数名字是统一的 pageIndex，pageCellIndex 底层固定了暂时只能这样
    local messageData = {msg = MessageDataType.MSG_BONUS_SPECIAL, data = {pageIndex = pageIndex, pageCellIndex = pageCellIndex}}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function WheelOfRomanceShopData:parseData(data)
    for k,v in pairs(data) do
        self.m_shopData[k] = v
    end
end


function WheelOfRomanceShopData:getShopData()
    return self.m_shopData
end

function WheelOfRomanceShopData:getShopCollectCoins()
    return self.m_shopData.points
end


function WheelOfRomanceShopData:getShopPageNum()
    return #self.m_shopData.cardDatas
end

function WheelOfRomanceShopData:getShopPageCellNum(_pageIndex)
    return #self.m_shopData.cardDatas[_pageIndex].cards
end

function WheelOfRomanceShopData:getPageNeedPoints( _pageIndex )
    return self.m_shopData.cardDatas[_pageIndex].needPoints
end

function WheelOfRomanceShopData:getCellDarkStaetes(_pageIndex )
    
    local needPoins = self:getPageNeedPoints( _pageIndex )

    local collectCoins = self:getShopCollectCoins( _pageIndex )

    local isDark = false

    if needPoins > collectCoins then
        isDark = true
    end

    return isDark
end

function WheelOfRomanceShopData:getCellPageLevel( _pageIndex )
    return self.m_shopData.cardDatas[_pageIndex].level
end

function WheelOfRomanceShopData:getShopPageInfo(_pageIndex)
    return self.m_shopData.cardDatas[_pageIndex].cards
end

-- 进入UI的时候默认选择的页数
function WheelOfRomanceShopData:getDefaultPageIndex()

    return 1

end


function WheelOfRomanceShopData:getPageCellState(pageIndex, cellIndex)

    local pageInfos = self:getShopPageInfo(pageIndex)
    local pageCellInfo = pageInfos[cellIndex]
    return pageCellInfo
    
end

--[[
    ***********
    本地存储的上一轮的数据    
--]]

-- 请求消息是是在哪个页面
function WheelOfRomanceShopData:setRequestPageIndex(pageIndex)
    self.m_requestPageIndex = pageIndex
end

function WheelOfRomanceShopData:getRequestPageIndex()
    return self.m_requestPageIndex
end

-- 请求消息的是哪个按钮
function WheelOfRomanceShopData:setRequestPageCellIndex(pageCellIndex)
    self.m_requestPageCellIndex = pageCellIndex
end

function WheelOfRomanceShopData:getRequestPageCellIndex()
    return self.m_requestPageCellIndex
end

-- 请求消息时的等级

function WheelOfRomanceShopData:setRequestShopData( )
    self.m_oldShopData = {}
    for k,v in pairs(self.m_shopData) do
        self.m_oldShopData[k] = v
    end
end

function WheelOfRomanceShopData:getRequestPageLevel(_pageIndex)
    return self.m_oldShopData.cardDatas[_pageIndex].level
end

function WheelOfRomanceShopData:getRequestPageNeedPoints( _pageIndex  )
    return self.m_oldShopData.cardDatas[_pageIndex].needPoints 
end

function WheelOfRomanceShopData:getRequestShopPageInfo(_pageIndex)
    return self.m_oldShopData.cardDatas[_pageIndex].cards
end

function WheelOfRomanceShopData:getRequestPageCellState(  _pageIndex, _pageCellIndex )

    local pageInfos = self:getRequestShopPageInfo(_pageIndex)

    local pageCellInfo = pageInfos[_pageCellIndex]

    return pageCellInfo

end

function WheelOfRomanceShopData:getRequestShopCollectCoins()
    return self.m_oldShopData.points
end

function WheelOfRomanceShopData:getRequestPageCellDarkStaetes(_pageIndex )
    
    local needPoins = self:getRequestPageNeedPoints( _pageIndex )

    local collectCoins = self:getRequestShopCollectCoins( _pageIndex )

    local isDark = false

    if needPoins > collectCoins then
        isDark = true
    end

    return isDark
end


return WheelOfRomanceShopData
