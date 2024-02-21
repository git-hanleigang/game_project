--[[
    @desc: 高倍场合成
    author:zhangkankan
    time:2021-07-26
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local ShopItem = util_require("data.baseDatas.ShopItem")
local MergeMaterial = util_require("activities.Activity_DeluxeMerge.model.MergeMaterial")
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local DeluxeMergeData = class("DeluxeMergeData", BaseActivityData)
function DeluxeMergeData:ctor()
    DeluxeMergeData.super.ctor(self)
    self.p_open = true
end

-- 解析数据
function DeluxeMergeData:parseData(data)
    DeluxeMergeData.super.parseData(self, data)

    -- 活动 是第几赛季
    self.p_activitySeason = data.activitySeason or 1

    self.p_curChapterId = data.curChapterId  --当前章节
    -- 章节信息
    if data.chapters and next(data.chapters) ~= nil then
        self.p_chapters = {}
        for i=1,#data.chapters do
            local chapters = self:parseChapterData(data.chapters[i])
            self.p_chapters[chapters.p_chapterId] = chapters
        end
    end
    -- 地图point 信息
    if data.map then
        if data.map.time then
            self.p_pointSaveTime = tonumber(data.map.time) / 1000
        end
        if data.map.cells and next(data.map.cells) ~= nil then
            self.p_cells = {}
            for i,cell in ipairs(data.map.cells) do
                local oneCell = {}
                oneCell.buildingType = cell.buildingType
                oneCell.buildingLevel = cell.buildingLevel
                oneCell.rowId = cell.rowId
                oneCell.tandemId = cell.tandemId
                local key = tonumber(oneCell.rowId ) *1000 + tonumber(oneCell.tandemId)
                self.p_cells[key] = oneCell
            end
        end
    end
    -- 不同等级礼包数量 [1级礼包数量，2级礼包数量 ...]
    if data.bags then
        self.p_bags = data.bags
    end

    self.p_props = data.props            --道具数量（紫水晶）
    self.p_collect = data.collect        --Spin能量
    self.p_collectMax = data.collectMax  --Spin最大能量
    self.p_zone = data.zone              --排行榜 赛区
    self.p_roomType = data.roomType      --排行榜 房间类型
    self.p_roomNum = data.roomNum        --排行榜 房间数
    self.p_rankUp = data.rankUp          --排行榜排名上升的幅度
    self.p_rank = data.rank              --排行榜排名
    self.p_points = data.points          --排行榜点数
    -- 促销
    if data.sale ~= nil then
        self.p_sale = self:parseSaleData(data.sale)
    end
    -- 商店
    if data.store then
        self.p_store = {}
        self.p_store.status = data.store.status  --商店是否开启
        self.p_store.level = data.store.level --等级
        self.p_store.props = data.store.props --需要而钻石（第二货币） 单价
        self.p_store.unitNeed = data.store.unitNeed --完成关卡还需要的单位数量
        -- 付费商城
        self.p_store.purchaseStore = self:parsePurchaseStore(data.store.purchaseStore)
    end
    self.p_finalCoins = data.finalCoins  --通关奖励金币
    if data.finalItems and next(data.finalItems) ~= nil then --通关奖励物品
        self.p_finalItems = {}
        for i=1,#data.finalItems do
            local itemData = ShopItem:create()
            itemData:parseData(data.finalItems[i],true)
            if globalData:isCardNovice() and itemData.p_type == "Package" then
                -- 新手集卡期不显示 集卡 道具
            else
                table.insert(self.p_finalItems, itemData)
            end
        end
    end
    --每日奖励刷新剩余时间
    if data.dailyRewardExpire then
        self.p_dailyRewardExpire =  data.p_dailyRewardExpire  
    end
    --每日奖励刷新过期时间
    if data.dailyRewardExpireAt then
        self.p_dailyRewardExpireAt =  data.dailyRewardExpireAt  
    end

    if data.oneClickChapterLimit then -- 一键合成 章节限制
        self.p_oneClickChapterLimit = data.oneClickChapterLimit  
    else
        self.p_oneClickChapterLimit = 4
    end
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.DeluxeClubMergeActivity}) --统一活动数据 更新就刷新小红点
end

function DeluxeMergeData:refreshBagsData(bags)
    -- 不同等级礼包数量 [1级礼包数量，2级礼包数量 ...]
    if bags then
        self.p_bags = bags
    end
end
function DeluxeMergeData:refreshBagNum(index,num)
    -- 不同等级礼包数量 [1级礼包数量，2级礼包数量 ...]
    if num and num >= 0 then
        if self.p_bags and self.p_bags[index] then
            self.p_bags[index] = self.p_bags[index] + num
        end
    end
end
function DeluxeMergeData:parseChapterData(data)
    local chapter = {}
    chapter.p_chapterId = data.chapterId
    chapter.p_chapterCoins = data.chapterCoins  --章节奖励金币
    --章节奖励物品
    if data.chapterItems and next(data.chapterItems) ~= nil then
        chapter.p_chapterItems = {}
        for i=1,#data.chapterItems do
            local itemData = ShopItem:create()
            itemData:parseData(data.chapterItems[i],true)
            if globalData:isCardNovice() and itemData.p_type == "Package" then
                -- 新手集卡期不显示 集卡 道具
            else
                table.insert(chapter.p_chapterItems, itemData)
            end
        end
    end
    --章节 过关 材料
    if data.materials and next(data.materials) ~= nil then
        chapter.p_materials = {}
        for i=1,#data.materials do
            chapter.p_materials[i] = MergeMaterial:create()
            chapter.p_materials[i]:parseData(data.materials[i])
        end
    end
    chapter.p_progressMax = data.progressMax  --章节进度总量
    chapter.p_progress = data.progress  --章节当前进度
    chapter.p_status = data.status --章节状态：0未开启、1已开启、2已完成
    chapter.p_type = data.type --章节类型：0普通章节、1排行榜章节
    chapter.p_dailyReward = data.dailyReward --每日奖励状态：0未开启、1未领取、2已领取
    chapter.p_dailyCoins = data.dailyCoins  --每日奖励金币
    -- 每日奖励物品
    if data.dailyItems and next(data.dailyItems) ~= nil then
        chapter.p_dailyItems = {}
        for i=1,#data.dailyItems do
            local itemData = ShopItem:create()
            itemData:parseData(data.dailyItems[i],true)
            if globalData:isCardNovice() and itemData.p_type == "Package" then
                -- 新手集卡期不显示 集卡 道具
            else
                table.insert(chapter.p_dailyItems, itemData)
            end
        end
    end
    chapter.p_treasureType = data.treasureType  --每日奖励宝箱类型

    if data.progressReward and next(data.progressReward) ~= nil  then
        chapter.p_progressReward = {}
        for i=1,#data.progressReward do
            chapter.p_progressReward[i] = self:parseRewardData(data.progressReward[i])
        end
        if #chapter.p_progressReward > 1 then
            table.sort( chapter.p_progressReward, function(a,b)
                if a.p_progress and b.p_progress then
                    return a.p_progress < b.p_progress
                end
                return false
            end )
        end
    end

    if data.materialReward and next(data.materialReward) ~= nil  then
        chapter.p_materialReward= {}
        for i=1,#data.materialReward do
            local oneReward = self:parseRewardData(data.materialReward[i])
            if not chapter.p_materialReward[oneReward.p_type] then
                chapter.p_materialReward[oneReward.p_type] = {}
            end
            chapter.p_materialReward[oneReward.p_type][#chapter.p_materialReward[oneReward.p_type] + 1] = oneReward
        end

        for k,array in pairs(chapter.p_materialReward) do
            if array and #array > 1 then
                table.sort( array, function(a,b)
                    return a.p_level < b.p_level
                end )
            end
        end
    end

    return chapter
end

function  DeluxeMergeData:parseRewardData(data)
    local reward = {}
    reward.p_type= data.type --材料类型
    reward.p_level= data.level --材料等级
    reward.p_progress= data.progress --进度
    reward.p_coins = data.coins  --奖励金币
    --奖励物品
    if data.items and next(data.items) ~= nil  then
        reward.p_tems = {}
        for i=1,#data.items do
            local itemData = ShopItem:create()
            itemData:parseData(data.items[i],true)
            if globalData:isCardNovice() and itemData.p_type == "Package" then
                -- 新手集卡期不显示 集卡 道具
            else
                table.insert(reward.p_tems, itemData)
            end
        end
    end
    reward.p_collected = data.collected --是否已领取
    return reward
end

function  DeluxeMergeData:parseMapData(data)
    local map = {}
    map.p_chapterId = data.chapterId
    --章节 过关 材料

    return map
end

function  DeluxeMergeData:parseSaleData(data)
    local sale = {}
    sale.p_expire = data.expire
    sale.p_expireAt = data.expireAt
    sale.p_status = data.status --促销状态：0未开启、1开启
    sale.p_gems = data.gems --需要而钻石（第二货币） 数量
    sale.p_level = data.level
    sale.p_type = data.type

    return sale
end

-- 解析排行榜信息
function DeluxeMergeData:parseRankData(_data)
    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
        self.p_rank = myRankConfigInfo.p_rank
    end
end

function  DeluxeMergeData:parseStoreData(data)
    local store = {}
    store.p_type = data.type  --材料类型
    store.p_level = data.level --等级
    store.p_gems = data.gems --需要而钻石（第二货币） 单价
    return store
end

function DeluxeMergeData:getCurChapterId()
    return self.p_curChapterId
end

function DeluxeMergeData:getPointSaveTime()
    return self.p_pointSaveTime or "0"
end

function DeluxeMergeData:getAllChaptersData()
    return self.p_chapters
end
function DeluxeMergeData:getChapterDataById(_chapterId)
    if not self.p_chapters then
        return
    end

    for i, chapterData in ipairs(self.p_chapters) do
        if chapterData.p_chapterId == _chapterId then
            return chapterData
        end
    end
end

function DeluxeMergeData:getAllPointsData()
    if not self.p_cells then
        self.p_cells = {}
    end
    return self.p_cells
end

function DeluxeMergeData:getAllSaleData()
    return self.p_sale
end

function DeluxeMergeData:getAllStoreData()
    return self.p_store
end

-- 当前持有的道具数量
function DeluxeMergeData:getProps()
    return self.p_props or 0
end

-- 未领取 的每日奖励数量
function DeluxeMergeData:getUnollectDailyRewardCount()
    if not self.p_chapters then
        return 0
    end

    local count = 0
    for i, chapterData in ipairs(self.p_chapters) do
        if chapterData.p_dailyReward == 1 then
            count = count + 1
        end
    end

    return count
end

-- 道具包数量
function DeluxeMergeData:getUncollectBagCount()
    if not self.p_bags then
        return 0
    end

    local count = 0
    for i, bagCount in ipairs(self.p_bags) do
        count = count + bagCount
    end

    return count
end

-- 活动入口小数点
function DeluxeMergeData:getActRedDotCount()
    return self:getProps() + self:getUnollectDailyRewardCount() + self:getUncollectBagCount()
end

-- 获取排行榜cfg
function DeluxeMergeData:getRankCfg()
    return self.p_rankCfg
end

-- 获取活动赛季
function DeluxeMergeData:getCurSeason()
    return self.p_activitySeason or 1
end

--清空地图点 
function DeluxeMergeData:clearCell()
    self.p_cells = {}
end

function DeluxeMergeData:parsePurchaseStore(_data)
    local saleData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_key = v.key
            tempData.p_keyId = v.keyId
            tempData.p_price = v.price
            tempData.p_disShow = v.disShow
            tempData.p_expireAt = tonumber(v.expireAt) or 0
            tempData.p_item = ShopItem:create()
            tempData.p_item:parseData(v.item)
            table.insert(saleData, tempData)
        end
    end
    return saleData
end

function DeluxeMergeData:getRankPoint()
    return self.p_points
end

return DeluxeMergeData
