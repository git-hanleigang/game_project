-- 集卡商城 管理器

local CardStoreNet = require("GameModule.Card.CardStore.net.CardStoreNet")
local CardStoreManager = class("CardStoreManager", BaseGameControl)

function CardStoreManager:ctor()
    CardStoreManager.super.ctor(self)
    self:setRefName(G_REF.CardStore)
    --self:addPreRef(G_REF.Card)
    self.m_CardStoreNet = CardStoreNet:getInstance()
end

-- 获取配置
function CardStoreManager:getConfig()
    if not self.p_config then
        self.p_config = require("GameModule.Card.CardStore.model.CardStoreConfig")
    end
    return self.p_config
end

-- 获得数据
function CardStoreManager:getData()
    if not self.p_store then
        local CardStoreData = require("GameModule.Card.CardStore.model.CardStoreData")
        if CardStoreData then
            self.p_store = CardStoreData:create()
        end
    end
    return self.p_store
end

-- 解析数据
function CardStoreManager:parseData(data)
    local store_data = self:getRunningData()
    if store_data then
        store_data:parseData(data)
    end
end

function CardStoreManager:getItemData(item_type, item_idx)
    if item_type == "NORMAL" then
        return self:getNormalDataByIndex(item_idx)
    elseif item_type == "GOLDEN" then
        return self:getGoldenDataByIndex(item_idx)
    elseif item_type == "BLIND" then
        return self:getBlindDataByIndex(item_idx)
    end
end

-- 根据数组下标获取普通商品数据
function CardStoreManager:getNormalDataByIndex(idx)
    local store_data = self:getRunningData()
    if store_data then
        local normal_data = store_data:getNormalItems()
        if normal_data and normal_data[idx] then
            return normal_data[idx]
        end
    end
end

-- 根据数组下标获取金色商品数据
function CardStoreManager:getGoldenDataByIndex(idx)
    local store_data = self:getRunningData()
    if store_data then
        local golden_data = store_data:getGoldenItems()
        if golden_data and golden_data[idx] then
            return golden_data[idx]
        end
    end
end

---- 根据数组下标获取盲盒数据
--function CardStoreManager:getBlindDataByIndex(idx)
--    local store_data = self:getRunningData()
--    if store_data then
--        local blind_data = store_data:getBlindItems()
--        if blind_data and blind_data[idx] then
--            return blind_data[idx]
--        end
--    end
--end

-- 弹出主界面
function CardStoreManager:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("CardStoreMainLayer") then
        return
    end

    local view = util_createView("GameModule.Card.CardStore.views.CardStoreMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 弹出玩法介绍界面
function CardStoreManager:showInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("CardStoreMainHelpLayer") then
        return
    end

    local view = util_createView("GameModule.Card.CardStore.views.CardStoreMainHelpLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

-- 弹出盲盒信息界面
--function CardStoreManager:showBlindInfoLayer()
--    if not self:isCanShowLayer() then
--        return
--    end
--    if gLobalViewManager:getViewByExtendData("CardStoreBlindHelpLayer") then
--        return
--    end

--    local view = util_createView("GameModule.Card.CardStore.views.CardStoreBlindHelpLayer")
--    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
--end

function CardStoreManager:showRewardLayer(data)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByExtendData("CardStoreRewardLayer") then
        return
    end

    local view = util_createView("GameModule.Card.CardStore.views.CardStoreRewardLayer", data)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

--function CardStoreManager:showBlindRewardLayer(data, item_type)
--    if not self:isCanShowLayer() then
--        return
--    end
--    if gLobalViewManager:getViewByExtendData("CardStoreBlindRewardLayer") then
--        return
--    end

--    local view = util_createView("GameModule.Card.CardStore.views.CardStoreBlindRewardLayer", data)
--    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
--end

function CardStoreManager:addRewardPops(pop_list)
    if not pop_list or table.nums(pop_list) <= 0 then
        return
    end

    if self.pop_list then
        printError("CardStoreManager 存在掉落列表残留")
        self.pop_list = nil
    end
    self.pop_list = pop_list
end

function CardStoreManager:popNext()
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

function CardStoreManager:sendToReset(refreshType)
    self.m_CardStoreNet:requestCardStoreReset(
        refreshType,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EVENT_CARD_STORE_RESET)
        end
    )
end

-- 领取接口
function CardStoreManager:sendToCollect()
    if not self:isCanShowLayer() then
        -- 资源没下载好，不领取金币，会不显示领奖界面
        return
    end

    self.m_CardStoreNet:requestCardStoreGiftCollect(
        function(data)
            if data.coins and tonumber(data.coins or 0) > 0 then
                data.rewardType = "COINS"
            elseif data.shopItemResultList and table.nums(data.shopItemResultList) > 0 then
                data.rewardType = "ITEM"
            end
            self:showRewardLayer(data)

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EVENT_CARD_STORE_REFRESH)

            -- 重新拉取一下集卡最新数据
            local yearID = CardSysRuntimeMgr:getCurrentYear()
            local albumId = CardSysRuntimeMgr:getCurAlbumID()
            local tExtraInfo = {year = yearID, albumId = albumId}
            CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo)
        end
    )
end

-- 兑换接口
function CardStoreManager:sendToExchange(item_id, item_num, item_type, item_cost)
    self.m_CardStoreNet:requestCardStoreExchange(
        item_id,
        item_num,
        item_type,
        function(result_data)
            -- 客户端自己维护缓存数据
            local data = self:getData()
            if item_type == "NORMAL" then
                data:setNormalChipPoints(data:getNormalChipPoints() - item_cost * item_num)
            elseif item_type == "GOLDEN" then
                data:setGoldenChipPoints(data:getGoldenChipPoints() - item_cost * item_num)
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EVENT_CARD_STORE_REFRESH)
            if item_type == "BLIND_BOX" then
                --self:showBlindRewardLayer(data, item_idx)
            else
                self:showRewardLayer(result_data)
            end

            -- 重新拉取info
            -- CardSysManager:requestCardCollectionSysInfo()
            -- 重新拉取赛季卡册
            local yearID = CardSysRuntimeMgr:getCurrentYear()
            local albumId = CardSysRuntimeMgr:getCurAlbumID()
            local tExtraInfo = {year = yearID, albumId = albumId}
            CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo)
        end
    )
end

-- 完成引导
function CardStoreManager:requestCardStoreGuide()
    self.m_CardStoreNet:requestCardStoreGuide()
end

function CardStoreManager:changeLogEnterType()
    self.m_hasChangeLogEnterType = true
    gLobalSendDataManager:getLogIap():setEntryType("Card")
end

function CardStoreManager:resetLogEnterType()
    if self.m_hasChangeLogEnterType then
        self.m_hasChangeLogEnterType = false
        gLobalSendDataManager:getLogIap():setLastEntryType()
    end
end

return CardStoreManager
