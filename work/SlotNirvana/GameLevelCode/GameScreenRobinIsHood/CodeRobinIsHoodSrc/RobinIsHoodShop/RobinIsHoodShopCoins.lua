---
--xcyy
--2018年5月23日
--RobinIsHoodShopCoins.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodShopCoins = class("RobinIsHoodShopCoins",util_require("base.BaseView"))


function RobinIsHoodShopCoins:initUI(params)
    --当前本地时间戳
    self.m_timeStamp = 0
    self.m_discountLeftTime = 0 --折扣券剩余时间
    self.m_machine = params.machine
    self:createCsbNode("RobinIsHood_shop_price_discount.csb")
    self:idleWithOutDiscountAni()
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function RobinIsHoodShopCoins:initSpineUI()
    
end

--[[
    设置金币数量
]]
function RobinIsHoodShopCoins:setCoins(coins)
    local label = self:findChild("m_lb_coins")
    label:setString(util_formatCoins(coins,5))

    local info = {label = label, sx = 1, sy = 1}
    self:updateLabelSize(info, 160)
end


--[[
    更新折扣券显示
]]
function RobinIsHoodShopCoins:updateDisCountShow(hour,minute,second)
    local Time_S = self:findChild("Time_S")
    local Time_M = self:findChild("Time_M")
    local Time_H = self:findChild("Time_H")
    Time_S:setString(second)
    Time_M:setString(minute)
    Time_H:setString(hour)
end

--[[
    折扣券倒计时结束
]]
function RobinIsHoodShopCoins:runOverAni()
    self:runCsbAction("over",false,function()
        self:idleWithOutDiscountAni()
    end)
end

--[[
    idle 带折扣券
]]
function RobinIsHoodShopCoins:idleWithDiscountAni()
    self:runCsbAction("idle",true)
end

--[[
    idle 不带折扣券
]]
function RobinIsHoodShopCoins:idleWithOutDiscountAni()
    self:runCsbAction("idle2",true)
end


return RobinIsHoodShopCoins