--[[
]]
local CouponMgr = class("CouponMgr", BaseActivityControl)

function CouponMgr:ctor()
    CouponMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Coupon)

    self.m_useNewPath = {
        ["Activity_Coupon_Zombie"] = true,
        ["Activity_Coupon_July4th23"] = true,
        ["Activity_Coupon_Cheers"] = true,
        ["Activity_Coupon_QuarterBack"] = true,
    }
end

function CouponMgr:getMaxDiscount()
    local data = self:getRunningData()
    if data then
        -- csc 2022-02-08 12:02:25 改为从商城最大档位获取
        local maxDiscount = data:getMaxDiscount()
        local coinsShopData, gemsShopData = globalData.shopRunData:getShopItemDatas()
        for i = #coinsShopData, 1, -1 do
            local coinData = coinsShopData[i]
            local shopCardDis = coinData:getCouponDiscount()
            if shopCardDis > 0 then
                maxDiscount = shopCardDis
                break
            end
        end
        return maxDiscount
    end
end

--处理三合一折扣
function CouponMgr:getMaxDiscount2()
    local data = self:getData()
    if data then
        -- csc 2022-02-08 12:02:25 改为从商城最大档位获取
        local maxDiscount = data:getMaxDiscount()
        local coinsShopData, gemsShopData = globalData.shopRunData:getShopItemDatas()
        for i = #coinsShopData, 1, -1 do
            local coinData = coinsShopData[i]
            local shopCardDis = coinData:getCouponDiscount()
            if shopCardDis > 0 then
                maxDiscount = shopCardDis
                break
            end
        end
        return maxDiscount
    end
end

function CouponMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return popName
    else
        return CouponMgr.super.getPopPath(self, popName)
    end
end

function CouponMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/Icons/" .. hallName .. "HallNode"
    else
        return CouponMgr.super.getHallPath(self, hallName)
    end
end

function CouponMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/Icons/" .. slideName .. "SlideNode"
    else
        return CouponMgr.super.getSlidePath(self, slideName)
    end    
end

return CouponMgr
