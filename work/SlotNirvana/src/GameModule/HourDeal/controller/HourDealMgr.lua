--[[
    限时抽奖
]]

local HourDealNet = require("GameModule.HourDeal.net.HourDealNet")
local HourDealMgr = class("HourDealMgr", BaseGameControl)

function HourDealMgr:ctor()
    HourDealMgr.super.ctor(self)

    self.m_hourDealNet = HourDealNet:getInstance()
    self.m_saleType = 0
    self:setRefName(G_REF.HourDeal)
end

function HourDealMgr:parseData(_data)
    if not _data then
        return
    end

    local gameData = self:getData()
    if not gameData then
        gameData = require("GameModule.HourDeal.model.HourDealData"):create()
        gameData:parseData(_data)
        gameData:setRefName(G_REF.HourDeal)
        self:registerData(gameData)
    else
        gameData:parseData(_data)
    end
end

function HourDealMgr:showMainLayer(_params)
    local _data = self:getRunningData()
    if not _data then
        return
    end

    if not self:isDownloadRes("Promotion_HourDeal") then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Promotion_HourDeal") == nil then
        view = util_createView("Promotion_HourDeal.Activity.Promotion_HourDeal", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function HourDealMgr:showTimesSaleLayer(_params)
    local _data = self:getRunningData()
    if not _data then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Promotion_HourDealTimesSale") == nil then
        view = util_createView("Promotion_HourDeal.Activity.Promotion_HourDealTimesSale", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function HourDealMgr:showExtendSaleLayer(_params)
    local _data = self:getRunningData()
    if not _data then
        return
    end

    local view = util_createView("Promotion_HourDeal.Activity.Promotion_HourDealExtendSale", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function HourDealMgr:showCollectLayer(_params)
    local _data = self:getRunningData()
    if not _data then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Promotion_HourDealCollect") == nil then
        view = util_createView("Promotion_HourDeal.Activity.Promotion_HourDealCollect", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function HourDealMgr:showRewardLayer(_params)
    local _data = self:getRunningData()
    if not _data then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Promotion_HourDealRewardLayer") == nil then
        view = util_createView("Promotion_HourDeal.Activity.Promotion_HourDealRewardLayer", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function HourDealMgr:canShowHallNode()
    local _data = self:getRunningData()
    if not _data then
        return false
    end

    if not self:isDownloadRes("Promotion_HourDeal") then
        return false
    end

    local count = _data:getNoExtractCount()
    if count <= 0 then
        return false
    end

    return true
end

function HourDealMgr:createEntryNode()
    local _data = self:getRunningData()
    if not _data then
        return
    end

    if not self:isDownloadRes("Promotion_HourDeal") then
        return
    end

    local count = _data:getNoExtractCount()
    if count <= 0 then
        return
    end

    local view = util_createView("Promotion_HourDeal.Activity.Promotion_HourDealEntryNode")
    return view
end

function HourDealMgr:parseSpinData(_spinData)
    local data = self:getData()
    if data then 
        data:parseSpinData(_spinData)
    end
end

function HourDealMgr:clearSpinData()
    local data = self:getData()
    if data then 
        data:clearSpinData()
    end
end

function HourDealMgr:isDownloadRes(refName)
    if not self:checkRes(refName) then
        return false
    end

    local isDownloaded = self:checkDownloaded(refName)
    if not isDownloaded then
        return false
    end

    return true
end

function HourDealMgr:setEntryNode(_node)
    self.m_node_entry = _node
end

-- 关卡内入口节点位置
function HourDealMgr:getLevelEntryNodePos()
    local worldPos = cc.p(0, 0)
    -- 获取要飞到的坐标
    local _node = gLobalActivityManager:getEntryNode("HourDealEntryNode")
    if tolua.isnull(_node) then
        return gLobalActivityManager:getEntryArrowWorldPos()
    end

    local _isVisible = gLobalActivityManager:getEntryNodeVisible("HourDealEntryNode")
    if _isVisible then 
        worldPos = _node:getParent():convertToWorldSpace(cc.p(_node:getPosition()))
    else
        -- 隐藏图标的时候使用箭头坐标
        worldPos = gLobalActivityManager:getEntryArrowWorldPos()
    end
    return worldPos
end

function HourDealMgr:checkHourDealOpen()
    local view = nil
    local data = self:getRunningData()
    if data then
        local isUnlock = data:isUnlock()
        if isUnlock then
            view = self:showMainLayer()
        else
            local newTimes = data:getNewTimes()
            if newTimes > 0 then
                view = self:showCollectLayer()
            end
        end
    end
    self:clearSpinData()
    return view
end

function HourDealMgr:sendGetReward(_index)
    self.m_hourDealNet:sendGetReward(_index)
end

function HourDealMgr:buySale(_data, _type)
    self.m_saleType = _type
    self.m_hourDealNet:buySale(_data, _type)
end

function HourDealMgr:getSaleType()
    return self.m_saleType
end

return HourDealMgr
