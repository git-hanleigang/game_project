--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-30 19:56:56
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-30 20:36:10
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/views/IcebreakerSaleTimeUI.lua
Description: 新版 破冰促销 奖励UI
--]]
local IcebreakerSaleTimeUI = class("IcebreakerSaleTimeUI", BaseView)

function IcebreakerSaleTimeUI:getCsbName()
    return "Activity/csd/IcebreakerSale_Time.csb"
end

function IcebreakerSaleTimeUI:updateTimeUI(_tiemAt)
    local lbTime = self:findChild("lb_time")
    local curTime = util_getCurrnetTime()
    local disTime = math.floor(_tiemAt * 0.001) - curTime
    local timeStr = util_count_down_str(disTime)
    lbTime:setString(timeStr)

    self:setVisible(disTime > 0)
end

return IcebreakerSaleTimeUI