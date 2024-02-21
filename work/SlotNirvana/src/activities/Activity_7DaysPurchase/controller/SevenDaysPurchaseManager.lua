-- 气球挑战管理器

local SevenDaysPurchaseNet = require("activities.Activity_7DaysPurchase.net.SevenDaysPurchaseNet")
local SevenDaysPurchaseManager = class("SevenDaysPurchaseManager", BaseActivityControl)

-- 存一些本地数据
function SevenDaysPurchaseManager:ctor()
    SevenDaysPurchaseManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.SevenDaysPurchase)
    self.m_purchaseNet = SevenDaysPurchaseNet:getInstance()
    self.bl_itemEnable = true
end

------------------------------ 活动中用到的一些标记位 ------------------------------
function SevenDaysPurchaseManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_7DaysPurchase") == nil then
        local mainUI = util_createView("Activity.Activity_7DaysPurchase")
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end

function SevenDaysPurchaseManager:requestCollect(price)
    self.m_purchaseNet:requestCollect(price)
end

function SevenDaysPurchaseManager:hasRewards()
    local act_data = self:getRunningData()
    if act_data then
        return act_data:hasRewards()
    end
    return false
end

function SevenDaysPurchaseManager:recordRewardsList(data)
    local act_data = self:getRunningData()
    if not act_data then
        return
    end
    act_data:recordRewardsList(data)
end

function SevenDaysPurchaseManager:addRewardPops(pop_list)
    if not pop_list or table.nums(pop_list) <= 0 then
        return
    end

    if self.pop_list then
        printError("SevenDaysPurchaseManager 存在掉落列表残留")
        self.pop_list = nil
    end
    self.pop_list = pop_list
end

function SevenDaysPurchaseManager:popNext()
    if not self.pop_list then
        return
    end
    if table.nums(self.pop_list) <= 0 then
        self.pop_list = nil
        return
    end

    local popFunc = self.pop_list[1]
    table.remove(self.pop_list, 1)
    if popFunc and type(popFunc) == "function" then
        local bl_succ = popFunc()
        if not bl_succ then
            self:popNext()
        end
    end
end

-- 是否可显示展示页
function SevenDaysPurchaseManager:isCanShowHall()
    local isCanShow = SevenDaysPurchaseManager.super.isCanShowHall(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
        if not act_data.display then
            isCanShow = false
        end
    end
    return isCanShow
end

-- 是否可显示轮播页
function SevenDaysPurchaseManager:isCanShowSlide()
    local isCanShow = SevenDaysPurchaseManager.super.isCanShowSlide(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
        if not act_data.display then
            isCanShow = false
        end
    end
    return isCanShow
end

-- 是否可显示在hotnews里
function SevenDaysPurchaseManager:isCanShowInEntrance()
    local isCanShow = SevenDaysPurchaseManager.super.isCanShowInEntrance(self)
    if isCanShow then
        local act_data = self:getRunningData()
        if not act_data then
            isCanShow = false
        end
        if not act_data.display then
            isCanShow = false
        end
    end
    return isCanShow
end

function SevenDaysPurchaseManager:setItemTouchEnabled(bl_enable)
    self.bl_itemEnable = bl_enable
end

function SevenDaysPurchaseManager:getItemTouchEnabled()
    return self.bl_itemEnable
end

return SevenDaysPurchaseManager
