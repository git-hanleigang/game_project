--[[
    圣诞聚合 -- 商店
]]

local HolidayStoreConfig = require("activities.Activity_HolidayNewChallenge.HolidayStore.config.HolidayStoreConfig")
local HolidayStoreNet = require("activities.Activity_HolidayNewChallenge.HolidayStore.net.HolidayStoreNet")
local HolidayStoreMgr = class("HolidayStoreMgr", BaseActivityControl)

function HolidayStoreMgr:ctor()
    HolidayStoreMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayStore)
    --self:addPreRef(ACTIVITY_REF.Holiday)
    self.m_net = HolidayStoreNet:getInstance()
end

-- function HolidayStoreMgr:showMainLayer(_data)
--     local view = self:createPopLayer(_data)
--     if view then
--         self:showLayer(view, ViewZorder.ZORDER_UI)
--     end
--     return view
-- end

function HolidayStoreMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function HolidayStoreMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function HolidayStoreMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

--显示商店窗口
function HolidayStoreMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("Activity_HolidayStore") ~= nil then
        return 
    end
    local themeName = self:getThemeName() --创建
    local view = util_createView(themeName ..".Activity" ..".Activity_HolidayStore",{show = true})
    if view then --显示
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function HolidayStoreMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("HolidayInfoLayer") ~= nil then
        return 
    end
    local themeName = self:getThemeName() --创建
    local view = util_createView(themeName ..".InfoLayer" .. ".HolidayInfoLayer")
    if view then --显示
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--兑换
function HolidayStoreMgr:storeExchange(_data)
    local success = function (_result)
        gLobalViewManager:removeLoadingAnima()
        -- 更新
        --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_STORE_EXCHANGE)
        -- 弹领奖弹板
        self:popItemRewardLayer(_data)
    end
    local failed = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end
    self.m_net:storeExchange(_data,success,failed)
end

--领奖
function HolidayStoreMgr:popItemRewardLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("HolidayRewardLayer") ~= nil then
        return 
    end
	local itemData = data.data:getItems()
    local rewardData = data.rewardData
    local coins = data.data:getCoins()
    -- local itemNode = nil
    -- local coins = data.data:getCoins()
    -- if itemData and #itemData >0 then
    --     local shopItem = itemData[#itemData]
    --     rewardData = gLobalItemManager:createLocalItemData(shopItem.p_icon, data.num, shopItem)
    -- elseif coins and coins ~= "" and toLongNumber(coins) > toLongNumber(0) then
    --     rewardData = gLobalItemManager:createLocalItemData("Coins", self.m_coins)
    -- end
    if rewardData then
        local themeName = self:getThemeName() --创建
        local view = util_createView(themeName ..".RewardLayer".. ".HolidayRewardLayer",
        data, function()
			if CardSysManager:needDropCards("HollyWishesFair") then
				gLobalNoticManager:addObserver(self, function(sender, func)
					gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
					gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_STORE_EXCHANGE,{seq = data.data:getSeq()})
				end,ViewEventType.NOTIFY_CARD_SYS_OVER)
				CardSysManager:doDropCards("HollyWishesFair")
			else
				gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_STORE_EXCHANGE,{seq = data.data:getSeq()})
			end
            -- 刷新高倍场点数
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
		end , toLongNumber(coins))
        if view then --显示
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
        return view
    end
    return nil
end

-- 确认兑换弹窗
function HolidayStoreMgr:showTipsLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("HolidayTipsLayer") ~= nil then
        return 
    end
    local themeName = self:getThemeName() --创建
    local view = util_createView(themeName .. ".TipsLayer" ..".HolidayTipsLayer",data)
    if view then --显示
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 点数不足提示
function HolidayStoreMgr:openNoEnoughTips()
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("NoEnoughTipsLayer") ~= nil then
        return 
    end
    local themeName = self:getThemeName() --创建
    local view = util_createView(themeName .. ".TipsLayer" ..".NoEnoughTipsLayer")
    if view then --显示
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 任务弹板
function HolidayStoreMgr:showHolidayTaskLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("HolidayTaskLayer") ~= nil then
        return 
    end
    local themeName = self:getThemeName() --创建
    local view = util_createView(themeName .. ".TipsLayer" ..".HolidayTaskLayer",data)
    if view then --显示
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 弹商店 完成任务解锁金色奖励
function HolidayStoreMgr:showtriggerHolidayStore(callBackfun)
    if not self:isCanShowLayer() then
        return 
    end
    local actData = self:getRunningData()
    if not actData then
        return
    end
    --是否存在被解锁的商品
    if not actData:isExist() then
        return
    end
    local view = gLobalViewManager:getViewByExtendData("Activity_HolidayStore") 
    if view ~= nil then
        local sale = gLobalViewManager:getViewByExtendData("HolidaySaleLayer") 
        if sale then
            sale:closeUI()
        end
        view:updateList()
        view:setCallBack(callBackfun)
        return view
    end

    local themeName = self:getThemeName() 
    local view = util_createView(themeName ..".Activity" ..".Activity_HolidayStore",
    {unlock = true,callback = callBackfun})
    if view then --显示
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 购买促销
function HolidayStoreMgr:buySale(data,succFun)
    globalData.iapRunData.p_contentId = tostring(data.key)
    local successFunc = function(_netData) 
        gLobalViewManager:removeLoadingAnima()
        succFun()
    end
    
    local fileFunc = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_SALE_BUY)
    end
    gLobalViewManager:addLoadingAnima()
    self.m_net:buySale(data,successFunc, fileFunc)
end

-- 购买促销
function HolidayStoreMgr:openSale()
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("HolidaySaleLayer") ~= nil then
        return 
    end
    local themeName = self:getThemeName() --创建
    local view = util_createView(themeName .. ".Sale" ..".HolidaySaleLayer")
    if view then --显示
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

return HolidayStoreMgr
