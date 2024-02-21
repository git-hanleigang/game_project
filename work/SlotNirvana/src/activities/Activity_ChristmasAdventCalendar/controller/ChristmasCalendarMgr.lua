-- 圣诞节台历 控制器

local ShopItem = require "data.baseDatas.ShopItem"
local ChristmasCalendarNet = require("activities.Activity_ChristmasAdventCalendar.net.ChristmasCalendarNet")
local ChristmasCalendarMgr = class("ChristmasCalendarMgr", BaseActivityControl)

function ChristmasCalendarMgr:ctor()
    ChristmasCalendarMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChristmasCalendar)

    self.m_net = ChristmasCalendarNet:getInstance()
end

function ChristmasCalendarMgr:showLastDayLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("ChristmasAdventCalendarLastDayLayer") == nil then
        local mainUI = util_createFindView("Activity/ChristmasAdventCalendarLastDayLayer")
        if mainUI ~= nil then
            gLobalViewManager:showUI(mainUI, ViewZorder.ZORDER_UI)
        end
    end
end

function ChristmasCalendarMgr:sendToSign()
    local onSuccess = function(data)
        local itemList = {}

        local coins = tonumber(data.coins) or 0
        if coins and coins > 0 then
            local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
            table.insert(itemList, itemData)
        end

        local items = data.itemList
        if items and #items > 0 then
            for i, item_data in ipairs(items) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data, true)
                table.insert(itemList, shopItem)
            end
        end

        local end_call = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMAS_CALENDER_SIGN, true)
        end
        self:setPops(itemList, end_call)
        local rewardLayer =
            gLobalItemManager:createRewardLayer(
            itemList,
            function()
                self:popNext()
            end,
            tonumber(coins),
            true,
            "Christmas2022"
        )
        if not tolua.isnull(rewardLayer) then
            gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMAS_CALENDER_SIGN, true)
        end
    end
    local onFailed = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHRISTMAS_CALENDER_SIGN, false)
    end
    self.m_net:sendToSign(onSuccess, onFailed)
end

function ChristmasCalendarMgr:setPops(reward_data, end_call)
    if not reward_data or #reward_data <= 0 then
        if end_call then
            end_call()
        end
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        return
    end

    local pop_list = {
        [1] = function()
            if CardSysManager:needDropCards("Christmas Advent Calendar") == true then
                -- 集卡
                gLobalNoticManager:addObserver(
                    self,
                    function(target, func)
                        self:popNext()
                    end,
                    ViewEventType.NOTIFY_CARD_SYS_OVER
                )
                CardSysManager:doDropCards("Christmas Advent Calendar")
                return true
            end
            return false
        end,
        [2] = function()
            local lottery_counts = 0
            for i = 1, #reward_data do
                local data = reward_data[i]
                if data.p_icon == "Lottery_icon" then
                    lottery_counts = data:getNum()
                    break
                end
            end

            if lottery_counts > 0 then
                -- 抽奖券
                G_GetMgr(G_REF.Lottery):showTicketView(
                    nil,
                    function()
                        self:popNext()
                    end,
                    lottery_counts
                )
                return true
            end
            return false
        end,
        [3] = function()
            -- 高倍场
            globalDeluxeManager:dropExperienceCardItemEvt(
                function()
                    self:popNext()
                end
            )
            return true
        end,
        [4] = function()
            if end_call then
                end_call()
            end
            return true
        end
    }
    self:addRewardPops(pop_list)
end

function ChristmasCalendarMgr:addRewardPops(pop_list)
    if not pop_list or table.nums(pop_list) <= 0 then
        return
    end

    if self.pop_list then
        printError("ChristmasCalendarMgr 存在掉落列表残留")
        self.pop_list = nil
    end
    self.pop_list = pop_list
end

function ChristmasCalendarMgr:popNext()
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

function ChristmasCalendarMgr:sendToCollect()
    local onSuccess = function(data)
        local itemList = {}

        local coins = tonumber(data.coins) or 0
        if coins and coins > 0 then
            local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
            table.insert(itemList, itemData)
        end

        local items = data.itemList
        if items and #items > 0 then
            for i, item_data in ipairs(items) do
                local shopItem = ShopItem:create()
                shopItem:parseData(item_data, true)
                table.insert(itemList, shopItem)
            end
        end

        local end_call = function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
        self:setPops(itemList, end_call)
        local rewardLayer =
            gLobalItemManager:createRewardLayer(
            itemList,
            function()
                self:popNext()
            end,
            tonumber(coins),
            true,
            "Christmas2022"
        )
        gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
    end
    local onFailed = function()
    end
    self.m_net:sendToCollect(onSuccess, onFailed)
end

return ChristmasCalendarMgr
