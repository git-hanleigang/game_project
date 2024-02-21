---
--xcyy
--2018年5月23日
--JackpotElvesBigWinShowCoinsView.lua

local JackpotElvesBigWinShowCoinsView = class("JackpotElvesBigWinShowCoinsView",util_require("Levels.BaseLevelDialog"))


function JackpotElvesBigWinShowCoinsView:initUI()

    self:createCsbNode("JackpotElves_bigwin_zi.csb")
    self.curCoins = 0
end

function JackpotElvesBigWinShowCoinsView:setSpinCoins(coins)
    self.curCoins = coins
end

function JackpotElvesBigWinShowCoinsView:updateCoins()
    self:runCsbAction("actionframe")
    self:delayCallBack(30/60,function ()
        self:jumpCoins({
            label = self:findChild("m_lb_coins"),
            endCoins = self.curCoins,
            maxWidth = 399
        })
    end)
    
end

function JackpotElvesBigWinShowCoinsView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    label:setString("+0")
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 0.5   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动120次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
    label:stopAllActions()

    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum


        if curCoins >= endCoins then
            label:stopAllActions()
            label:setString("+"..util_formatCoins(endCoins,50))
            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
            return
        else
            label:setString("+"..util_formatCoins(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    延迟回调
]]
function JackpotElvesBigWinShowCoinsView:delayCallBack(time, func)
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

return JackpotElvesBigWinShowCoinsView