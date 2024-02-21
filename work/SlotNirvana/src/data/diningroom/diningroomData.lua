--[[
    新版餐厅数据部分
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local diningroomData = class("diningroomData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"

function diningroomData:ctor()
    diningroomData.super.ctor(self)

    self.m_emptyBoxPos  = 0          -- 空礼盒的位置  0:没有空的位置
    self.m_oldGiftsData = nil        -- 老的礼盒数据
end

function diningroomData:parseData(_data)
    diningroomData.super.parseData(self,_data)
    
    self.p_curChapter = tonumber(_data.curChapter)      -- 当前章节
    self.p_chapterMax = tonumber(_data.chapterMax)      -- 最大章节
    self.p_curRound   = tonumber(_data.curRound)        -- 当前轮数
    self.p_pagNum     = tonumber(_data.pagNum)          -- 普通食材包数量
    self.p_pagMax     = tonumber(_data.pagMax)          -- 普通食材包累积上限
    self.p_wildPagNum = tonumber(_data.wildPagNum)      -- Wild食材包数量
    -- 现在没发上限这个值 先用当前数量代替
    self.p_wildPagMax = self.p_wildPagNum               -- wild食材包上限
    self.p_collect    = tonumber(_data.collect)         -- 收集能量
    self.p_collectMax = tonumber(_data.collectMax)      -- 最大收集能量
    self.p_roundCoins = tonumber(_data.roundCoins)      -- 轮次奖励金币

    self.p_point      = tonumber(_data.points)          -- 排行榜点数
    self.p_day        = tonumber(_data.day)             -- 活动天数
    
    self.p_guides        = self:parseGuidesData(_data.guides)       -- 引导步骤
    self.p_chaptersData  = self:parseChapterData(_data.chapters)    -- 章节数据
    self.p_surplusStuffs = self:parseStuffsData(_data.stuffs)       -- 剩余食材
    self.p_gifts         = self:parseGiftsData(_data.gifts)         -- 玩家礼物
    self.p_roundItems    = self:parseItemsData(_data.roundItems)    -- 轮次奖励物品    
    
    -- 数据刷新事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.DiningRoom})
    self:checkEmptyBoxPos()
    self:setRank(_data.rank)
end

function diningroomData:parseGuidesData(_guidesData)
    local guides = {}
    for i,v in ipairs(_guidesData) do
        local key = tostring(v)
        guides[key] = v
    end
    return guides
end

function diningroomData:parseChapterData(_chapterData)
    local chaptersData = {}
    if _chapterData and #_chapterData > 0 then 
        for i,v in ipairs(_chapterData) do
            local temp = {}
            temp.p_rewardCoins = v.coins                        -- 章节奖励基础金币
            temp.p_customerNum = v.customerNum                  -- 客人数量
            temp.p_completeNum = v.completeNum                  -- 已服务客人数量
            temp.p_rewardItems = self:parseItemsData(v.items)   -- 章节奖励物品
            if v.customers and #v.customers > 0 then 
                temp.p_customers = self:parseCustomersData(v.customers)     -- 客人列表
            end
            table.insert(chaptersData, temp)
        end
    end
    return chaptersData
end
-- 解析客人数据
function diningroomData:parseCustomersData(_data)
    local customersData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_customerId    = v.customerId     -- 客人Id
            temp.p_customerIndex = v.customerIndex  -- 客人位置
            temp.p_name          = v.name           -- 名字
            temp.p_resource      = v.resource       -- 美术资源
            temp.p_coins         = v.coins          -- 奖励金币
            temp.p_giftId        = v.giftId         -- 礼物Id
            temp.p_food          = {}               -- 菜品
            temp.p_food.p_name   = v.food.name      -- 菜品名称
            temp.p_food.p_level  = v.food.level     -- 菜品星级
            temp.p_food.p_stuffs = self:parseStuffsData(v.food.stuffs)  -- 食材
            temp.p_food.p_resourceLeft  = v.food.resourceLeft     -- 菜品完成前美术资源
            temp.p_food.p_resourceRight = v.food.resourceRight    -- 菜品完成后美术资源
            table.insert(customersData, temp)
        end
    end
    return customersData
end

function diningroomData:parseStuffsData(_data)
    local stuffsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_stuffId  = v.stuffId     -- 食材Id
            temp.p_name     = v.name        -- 食材名称
            temp.p_level    = v.level       -- 食材等级
            temp.p_resource = v.resource    -- 食材美术资源
            temp.p_process  = v.process     -- 食材占比
            temp.p_num      = tonumber(v.num)         -- 需要食材数量
            table.insert(stuffsData, temp)
        end
    end
    return stuffsData
end

function diningroomData:parseGiftsData(_data)
    local giftsData = {} 
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_giftId   = tonumber(v.giftId)    -- 礼盒Id
            temp.p_coins    = v.coins     -- 奖励金币
            temp.p_expire   = tonumber(v.expire)    -- 解锁剩余时间（秒）
            temp.p_expireAt = tonumber(v.expireAt)  -- 解锁时间
            temp.p_gems     = v.gems      -- 第二货币解锁
            temp.p_resource = v.resource  -- 美术资源
            temp.p_Items = self:parseItemsData(v.items)  -- 奖励物品
            table.insert(giftsData, temp)
        end
    end
    return giftsData
end
-- 解析道具数据
function diningroomData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function diningroomData:getChapterDataByIndex( idx )
    if self.p_chaptersData[idx] then
        return self.p_chaptersData[idx]
    end
end

-- 检查空盒子的位置
function diningroomData:checkEmptyBoxPos()
    self.m_emptyBoxPos  = 0          -- 空礼盒的位置  0:没有空的位置
    if not self.m_oldGiftsData then 
        self.m_oldGiftsData = clone(self.p_gifts)
        for i,v in ipairs(self.p_gifts) do
            if v.p_giftId <= 0 then 
                self.m_emptyBoxPos = i 
                return
            end
        end
    else 
        for i = 1, 3 do
            if self.m_oldGiftsData[i].p_giftId <= 0 or self.p_gifts[i].p_giftId <= 0 then 
                self.m_emptyBoxPos = i 
                self.m_oldGiftsData = clone(self.p_gifts)
                return
            end
        end
    end
end

function diningroomData:parseRankData(_data)
    self.p_rankConfig = BaseActivityRankCfg:create()
    self.p_rankConfig:parseData(_data)
    local myRankConfigInfo = self.p_rankConfig:getMyRankConfig()
    release_print("_result.myRank 4 is " .. tostring(myRankConfigInfo))
    self:setRank(myRankConfigInfo.p_rank)
end

-- 获得天数
function diningroomData:getDay() 
    return self.p_day or 1
end

-- 获得当前章节数
function diningroomData:getCurChapterNum()
    return self.p_curChapter
end

-- 获得当前章节数据
function diningroomData:getCurChapterData()
    return self.p_chaptersData[self.p_curChapter]
end
-- 获得当前章节客人列表
function diningroomData:getCustomerList()
    return self.p_chaptersData[self.p_curChapter].p_customers
end
-- 获得剩余食材数据
function diningroomData:getSurplusStuffs()
    return self.p_surplusStuffs
end
-- 获得礼盒数据
function diningroomData:getGifts()
    return self.p_gifts
end

-- 当前轮数
function diningroomData:getSequence()
    return self.p_curRound or 0
end

-- 当前章节数
function diningroomData:getCurrent()
    return self.p_curChapter or 0
end

-- 当前购买食材包数量
function diningroomData:getBags()
    return self.p_pagNum or 0
end

-- 当前购买食材包上限
function diningroomData:getBagsMax()
    return self.p_pagMax or 0
end

-- 当前购买wild食材包数量
function diningroomData:getWildBags()
    return self.p_wildPagNum or 0
end

-- 当前购买wild食材包上限
function diningroomData:getWildBagsMax()
    return self.p_wildPagMax or 0
end

-- 获得空礼盒位置
function diningroomData:getEmptyBoxPos()
    return self.m_emptyBoxPos
end
-- 获取章节列表数据
function diningroomData:getChapterData()
    return self.p_chaptersData
end

function diningroomData:getPigNum()
    return self.p_pagNum or 0
end

function diningroomData:getFinalPrize()
    local final_prize = {}
    final_prize.coins = self.p_roundCoins or 0
    final_prize.rewards = self.p_roundItems or {}
    return final_prize
end

--获取入口位置 1：左边，0：右边
function diningroomData:getPositionBar()
    return 1
end

-- 获得排行榜点数
function diningroomData:getPoint()
    return self.p_point
end
function diningroomData:setPoint(_point)
    self.p_point = _point
end

function diningroomData:getGuideStage()
    return self.p_guides
end

-- 计算还需多少食材
function diningroomData:getNeedStuffs()
    local needStuffs = {}
    local customersList = self:getCustomerList()
    local surplusStuffs = self:getSurplusStuffs()
    for i = 1, 3 do
        local customer = customersList[i]
        if customer and tonumber(customer.p_customerId) > 0 then
            for i,v in ipairs(customer.p_food.p_stuffs) do
                local isNeed = true
                for j,k in ipairs(surplusStuffs) do
                    if v.p_stuffId == k.p_stuffId and k.p_num >= v.p_num then 
                        isNeed = false
                        break
                    end
                end
    
                if isNeed then 
                    local isAdd = true
                    for n,m in ipairs(needStuffs) do
                        if m.p_stuffId == v.p_stuffId then 
                            m.p_num = m.p_num + v.p_num
                            isAdd = false
                            break
                        end
                    end
    
                    if isAdd then 
                        table.insert( needStuffs, v )
                    end
                end
            end
        end
    end

    return needStuffs
end

return diningroomData