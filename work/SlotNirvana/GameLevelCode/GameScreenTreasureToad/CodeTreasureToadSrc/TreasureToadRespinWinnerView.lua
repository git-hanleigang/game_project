---
--xcyy
--2018年5月23日
--TreasureToadRespinWinnerView.lua

local TreasureToadRespinWinnerView = class("TreasureToadRespinWinnerView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "TreasureToadPublicConfig"

TreasureToadRespinWinnerView.m_freespinCurrtTimes = 0


function TreasureToadRespinWinnerView:initUI()

    self:createCsbNode("TreasureToad_Respin_Winner.csb")

    self.curCoins = 0
end

function TreasureToadRespinWinnerView:updateCount(num1,num2,num3)
    if num1 > 0 then
        self:findChild("m_lb_num_0"):setString("X" .. num1)
        self:updateLabelSize({label=self:findChild("m_lb_num_0"),sx=0.65,sy=0.65}, 41)
    end
    if num2 > 0 then
        self:findChild("m_lb_num_1"):setString("X" .. num2)
        self:updateLabelSize({label=self:findChild("m_lb_num_1"),sx=0.65,sy=0.65}, 41)
    end
    if num3 > 0 then
        self:findChild("m_lb_num_1_0"):setString("X" .. num3)
        self:updateLabelSize({label=self:findChild("m_lb_num_1_0"),sx=0.65,sy=0.65}, 41)
    end
    
end

function TreasureToadRespinWinnerView:updateCoins(coins)
    
    self:runCsbAction("actionframe")
    -- local str = util_formatCoins(coins, 50)
    local addValue = coins - self.curCoins
    util_jumpNum(self:findChild("m_lb_coins"),self.curCoins,coins,addValue,0.05,{50},nil,nil,function ()
        self.curCoins = coins
    end,function ()
        local info1={label=self:findChild("m_lb_coins"),sx=0.65,sy=0.65}
        self:updateLabelSize(info1,642)
    end)

end

function TreasureToadRespinWinnerView:initCounts()
    self.curCoins = 0
    self:findChild("m_lb_num_0"):setString("X" .. 0)
    self:findChild("m_lb_num_1"):setString("X" .. 0)
    self:findChild("m_lb_num_1_0"):setString("X" .. 0)
    self:findChild("m_lb_coins"):setString("")
end

-- 更新并显示reSpin剩余次数
function TreasureToadRespinWinnerView:showWinner()
    
    
    self:runCsbAction("start")
    
end

--[[
    延迟回调
]]
function TreasureToadRespinWinnerView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return TreasureToadRespinWinnerView