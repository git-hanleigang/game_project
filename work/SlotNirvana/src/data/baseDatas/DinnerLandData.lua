

--
-- Author: 刘阳
-- Date: 2020-07-13
-- Desc: 餐厅活动的数据
-- 

local BaseActivityData = require "baseActivity.BaseActivityData"
local DinnerLandData = class("DinnerLandData",BaseActivityData)


function DinnerLandData:ctor()
    DinnerLandData.super.ctor( self )
    self.m_chapters = {}
end


function DinnerLandData:parseData( data )
    DinnerLandData.super.parseData(self,data)
    self.rewardCoins = data.rewardCoins -- 所有关卡完成奖励金币
    self.items = data.items -- 所有关卡完成奖励物品
    self.sequence = data.sequence -- 第几个轮回
    self.collect = data.collect -- 收集能量数量
    self.max = data.max -- 最大收集数量
    self.leftCookCoins = data.leftCookCoins -- 剩余厨师币
    self.cookCoinsLimit = data.cookCoinsLimit -- 剩余厨师币限制
    self.leftStuffs = data.leftStuffs -- 用户剩余食材
    self.current = data.current -- 当前章节
    self.chapters = data.chapters --章节配置
    self.bag = data.bag -- 食材包裹
    self.guideStep = data.guide -- 引导步骤
    self.day = data.day -- 活动当前第几天
    -- 发送消息 刷新数据
    gLobalNoticManager:postNotification( ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH,{ name = ACTIVITY_REF.DinnerLand } )
end

-- 获取章节数据
function DinnerLandData:getChapters( index )
    if index then
        return self.chapters[index]
    end
    return self.chapters
end

-- 所有关卡完成奖励金币
function DinnerLandData:getRewardCoins()
    return self.rewardCoins
end
-- 所有关卡完成奖励物品
function DinnerLandData:getItems()
    return self.items
end

-- 获取当前的厨师币
function DinnerLandData:getDinnerCoin()
    return self.leftCookCoins or 0
end

-- 收集的能量
function DinnerLandData:getCollect()
    return self.collect or 0
end

-- 最大的收集能量
function DinnerLandData:getMaxCollect()
    return self.max or 10000
end

function DinnerLandData:getCookCoinsLimit()
    return self.cookCoinsLimit or 20
end

-- 第几个轮回
function DinnerLandData:getSequence()
    return self.sequence
end

-- 当前章节
function DinnerLandData:getCurrent()
    return self.current
end

-- 活动当前第几天
function DinnerLandData:getDay()
    return self.day
end

-- 获取用户的剩余食材
function DinnerLandData:getLeftStuffs( stuffId )
    if stuffId then
        for i,v in ipairs( self.leftStuffs ) do
            if v.stuffId == stuffId then
                return v
            end
        end
        assert( false," !! not found stuff,stuffId = "..stuffId.." !! " )
    end
    return self.leftStuffs
end

-- 食材包裹
function DinnerLandData:getBag( index )
    if index then
        return self.bag[index]
    end
    return self.bag
end


-- 获取某个章节 某个食物的数据
function DinnerLandData:getFoodData( chapterIndex,foodId )
    assert( chapterIndex," !! chapterIndex is nil !! " )
    assert( foodId," !! foodId is nil !! " )
    local chapter = self:getChapters( chapterIndex )
    local foods = chapter.foods
    for i,v in ipairs( foods ) do
        if v.foodId == foodId then
            return v
        end
    end
end

------------------------------------ 关卡内收集厨师币和能量 Start ----------------------------

function DinnerLandData:setDinnerCoin( coin )
    self.leftCookCoins = coin
end

-- 当前收集的能量
function DinnerLandData:setCollect( num )
    self.collect = num
    if self.collect >= self.max then
        self.collect = 0
    end
end

-- 最大的收集能量
function DinnerLandData:setMaxCollect( max )
    self.max = max
end


------------------------------------ 关卡内收集厨师币和能量 End ----------------------------







------------------------------------ 促销相关数据 Start ----------------------------
-- 存储促销购买的Buff
function DinnerLandData:saveBuyBuff( index )
    if index == 3 then
        -- 菜品奖励Buff
        self.m_buyBuff = "DinnerFood"
    elseif index == 2 then
        -- 食材包Buff
        self.m_buyBuff = "DinnerPackage"
    elseif index == 1 then
        -- 能量进度buff
        self.m_buyBuff = "DinnerProgress"
    end
end

function DinnerLandData:clearBuyBuff()
    self.m_buyBuff = nil
end

function DinnerLandData:getBuyBuff()
    return self.m_buyBuff
end

-- 获取 能量进度buff 的剩余时间
function DinnerLandData:getBuffDinnerProgressLeftTime()
    local time = globalData.buffConfigData:getBuffLeftTimeByType( BUFFTYPY.BUFFTYPE_DINNERLAND_DINNERPROGRESS )
    if time < 0 then
        time = 0
    end
    return time
end

-- 获取 食材包Buff 的剩余时间
function DinnerLandData:getBuffDinnerPackageLeftTime()
    local time = globalData.buffConfigData:getBuffLeftTimeByType( BUFFTYPY.BUFFTYPE_DINNERLAND_DINNERPACKAGE )
    if time < 0 then
        time = 0
    end
    return time
end

-- 获取 菜品奖励Buff 的剩余时间
function DinnerLandData:getBuffDinnerFoodLeftTime()
    local time = globalData.buffConfigData:getBuffLeftTimeByType( BUFFTYPY.BUFFTYPE_DINNERLAND_DINNERFOOD )
    if time < 0 then
        time = 0
    end
    return time
end

------------------------------------ 促销相关数据 End ----------------------------





------------------------------------ 引导相关 Start ----------------------------

function DinnerLandData:getGuideStep()
    return self.guideStep
end

function DinnerLandData:isGuideFinish()
    return self.guideStep >= 5
end

function DinnerLandData:setNextGuideStep()
    self.guideStep = self.guideStep + 1
end

------------------------------------ 引导相关 End ----------------------------








-- 排行榜相关
function DinnerLandData:setRank(rank)
	-- 还没有初始化
	if not self.rank then
		self.rank = rank or 0
		return
	end

	if rank == self.rank then
		return
	end
	if self.rank ~= 0 and rank == 0 then
		return
	end
    self.rank = rank
end


--获取入口位置 1：左边，0：右边
function DinnerLandData:getPositionBar()
    -- 默认右边，修改重写该方法
    return 1
end


return DinnerLandData
