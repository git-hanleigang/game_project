--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-14 17:38:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-14 17:38:20
FilePath: /SlotNirvana/src/views/gameviews/DealTopFirstSaleGiftNode.lua
Description: 商城入口处 促销入口 倒计时标签
--]]
local DealTopFirstSaleGiftNode = class("DealTopFirstSaleGiftNode", BaseView)
function DealTopFirstSaleGiftNode:initUI()
    DealTopFirstSaleGiftNode.super.initUI(self)

    local actName = "idle"
    if globalData.constantData.FIRST_COMMON_SALE_HIDE_TIME then
        actName = "idle_no_time"
    end
    self:runCsbAction(actName, true)
end

function DealTopFirstSaleGiftNode:getCsbName()
    local csbName = "GameNode/DealChang_superSale.csb"
    if globalData.slotRunData.isPortrait then
        csbName = "GameNode/DealChang_superSale_Portrait.csb"
    end
    return csbName
end

function DealTopFirstSaleGiftNode:initCsbNodes()
    DealTopFirstSaleGiftNode.super.initCsbNodes(self)

    self._lbTime = self:findChild("shuzi")
end

function DealTopFirstSaleGiftNode:updateCountDown(time)
    self._lbTime:setString(util_count_down_str(time))
end

return DealTopFirstSaleGiftNode