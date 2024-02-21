--[[
    商城充值送缺卡
]]

local StoreSaleRandomCardMgr = class("StoreSaleRandomCardMgr", BaseActivityControl)

function StoreSaleRandomCardMgr:ctor()
    StoreSaleRandomCardMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.StoreSaleRandomCard)
end

------------------------------ 商城缺卡活动相关部分 ------------------------------
function StoreSaleRandomCardMgr:getShopRandomCardIsOpen()
    local pData = self:getRunningData()
    if pData and not globalDynamicDLControl:checkDownloading(pData:getThemeName()) then
        return true
    end
    return false
end

function StoreSaleRandomCardMgr:getShopRandomCardMaxDiscount()
    local data = self:getRunningData()
    if data then
        -- csc 2022-02-08 12:02:25 改为从商城最大档位获取
        local maxDiscount = data:getMaxDiscount()
        local coinsShopData , gemsShopData = globalData.shopRunData:getShopItemDatas()
        for i = #coinsShopData ,1,-1  do
            local coinData = coinsShopData[i]
            local shopCardDis = coinData:getShopCardDiscount()
            if shopCardDis > 0 then
                maxDiscount = shopCardDis
                break
            end
        end
        return maxDiscount
        -- return data:getMaxDiscount()
    end
    return 0
end

--获取卡片信息
function StoreSaleRandomCardMgr:getShopRandomCardInfoList()
    local data = self:getRunningData()
    if data then
        return data:getCardInfoList()
    end
    return nil
end

function StoreSaleRandomCardMgr:getShopRandomCardLastPurchasePos()
    local data = self:getRunningData()
    if data then
        return data:getLastPurchasePos()
    end
    return nil
end
function StoreSaleRandomCardMgr:createShopRandomCardLayer(_isBuy, _callback)
    local data = self:getRunningData()
    if data then
        local themeName = self:getThemeName()
        local path = themeName .. "/" .. themeName
        if themeName == "Activity_StoreSaleRandomCard" or themeName == "Activity_StoreSaleRandomCard_NoDisct" then
            path = data:getPopModule()
        end
        local layer = util_createView(path, {_isBuy = _isBuy})
        if layer ~= nil then
            layer:setOverFunc(
                function()
                    if _callback then
                        _callback()
                    end
                end
            )
            -- layer:updateFlag(_isBuy)
            gLobalViewManager:showUI(layer, ViewZorder.ZORDER_UI)
        else
            if _callback then
                _callback()
            end
        end
    else
        if _callback then
            _callback()
        end
    end
end


function StoreSaleRandomCardMgr:getLastPurchaseCardInfo()
    local data = self:getRunningData()
    if data then
        return data:getLastPurchaseCardInfo()
    end
    return nil
end

-- 宣传路径
function StoreSaleRandomCardMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    if themeName == "Activity_StoreSaleRandomCard" or
     themeName == "Activity_StoreSaleRandomCard_NoDisct" then
        return "Icons/" .. hallName .. "HallNode"
    end
    return themeName .. "/" .. hallName .. "HallNode"
end

function StoreSaleRandomCardMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    if themeName == "Activity_StoreSaleRandomCard" or
     themeName == "Activity_StoreSaleRandomCard_NoDisct" then
        return "Icons/" .. slideName .. "SlideNode"
    end
    return themeName .. "/" .. slideName .. "SlideNode"
end

function StoreSaleRandomCardMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    if themeName == "Activity_StoreSaleRandomCard" or
     themeName == "Activity_StoreSaleRandomCard_NoDisct" then
        return "Activity/" .. popName
    end
    return themeName .. "/" .. popName
end

return StoreSaleRandomCardMgr