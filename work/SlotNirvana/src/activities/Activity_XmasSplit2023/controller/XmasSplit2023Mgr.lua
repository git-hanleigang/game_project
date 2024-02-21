
--local XmasSplit2023Net = require("activities.Activity_XmasSplit2023.net.XmasSplit2023Net")
local XmasSplit2023Mgr = class(" XmasSplit2023Mgr", BaseActivityControl)

-- 构造函数
function XmasSplit2023Mgr:ctor()
    XmasSplit2023Mgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.XmasSplit2023)
    -- self.m_XmasSplit2023Net = XmasSplit2023Net:getInstance()
end

function XmasSplit2023Mgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function XmasSplit2023Mgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function XmasSplit2023Mgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName .. "MainLayer"
end

function XmasSplit2023Mgr:showMainLayer(_autoPop, _overcall)
    if not self:isCanShowLayer() then
        return nil
    end

    local data = self:getRunningData()
    local _poolIndex = {}
    if data then
        _poolIndex = data:getGainPoolIndex()
    end

    if _poolIndex == {} or table.nums(_poolIndex) == 0 then
        return nil
    end

    local refName = self:getRefName()
    local themeName = self:getThemeName(refName)
    local uiView = util_createView(themeName .. "/" .. themeName .. "MainLayer", _poolIndex, _overcall, _autoPop)
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end
function XmasSplit2023Mgr:showCouponLayer(_overcall)
    if not self:isCanShowLayer() then
        if _overcall then
            _overcall()
        end
        return nil
    end

    local data = self:getRunningData()
    local _poolIndex = {}
    local couponData
    local couponInfo
    local pools = {}
    local minPrice
    local discount = 0
    if data then
        _poolIndex = data:getGainPoolIndex()
        pools = data:getPools()

        couponData = pools[_poolIndex[#_poolIndex]].items[1]
        if not couponData then
            if _overcall then
                _overcall()
            end
            return
        end
        couponInfo = couponData:getItemInfo()

        discount = couponData.p_num
        local linkId = couponInfo.p_linkId
        local priceList = string.split(linkId, ";")
        if priceList and #priceList > 1 then
            local price = priceList[1]
            local sub = string.sub(price, 2)
            local num = tonumber(sub)
            minPrice = num - 0.01
        end
        

    end

    if _poolIndex == {} or table.nums(_poolIndex) == 0 then
        if _overcall then
            _overcall()
        end
        return
    end

    local refName = self:getRefName()
    local themeName = self:getThemeName(refName)
    local uiView = util_createView(themeName .. "/" .. themeName .. "CouponLayer", _overcall, discount, minPrice)
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    else
        if _overcall then
            _overcall()
        end
    end
    return uiView
end

-- 圣诞充值分奖领奖界面
function XmasSplit2023Mgr:showRewardLayer(themeName, coins, poolIndex, userCoins)
    -- local refName = self:getRefName()
    -- local themeName = self:getThemeName(refName)
    -- themeName 由邮件传过来
    -- 放到Inbox下了
                                --  InBox/Activity_XmasSplit2023CollectLayer.lua
    local uiView = util_createView("InBox/Activity_XmasSplit2023CollectLayer", coins, poolIndex, userCoins)
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
    return uiView
end

return XmasSplit2023Mgr
