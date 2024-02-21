---
--xcyy
--2018年5月23日
--ReelRocksCollectKaiCheJin.lua

local ReelRocksCollectKaiCheJin = class("ReelRocksCollectKaiCheJin",util_require("base.BaseView"))


function ReelRocksCollectKaiCheJin:initUI()
    self:createCsbNode("ReelRocks_kaiche_2.csb")

    self.m_coins = 0
end

function ReelRocksCollectKaiCheJin:initTop(coins)
    self:findChild("m_lb_coins_2"):setString(util_formatCoins(coins,3))
end

function ReelRocksCollectKaiCheJin:changeCoins(coins)
    local node=self:findChild("m_lb_coins_1")
    node:setString(util_formatCoins(coins,50))
    self:updateLabelSize({label=node,sx=1,sy=1},426)
end

function ReelRocksCollectKaiCheJin:onEnter()
 
end


function ReelRocksCollectKaiCheJin:onExit()
    if self.m_updateCoinHandlerID then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function ReelRocksCollectKaiCheJin:resetCoins( )
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    self:findChild("m_lb_coins_1"):setString("")
    self.m_coins = 0
end

function ReelRocksCollectKaiCheJin:UpdateWinLabel(coins,isBonus)

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    -- self.m_coins = coins
    self.isOver = false
    -- self:findChild("m_lb_coins_1"):setString(self.m_coins) / (1.5 * 5)  -- 每秒30帧
    local coinRiseNum =  coins
    if isBonus then
        coinRiseNum =  coins / (1.5 * 5)  -- 每秒30帧
    end
    local str = string.gsub(tostring(coinRiseNum),"0", math.random(1,5) )
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = self.m_coins
    self.m_coins = self.m_coins + coins
    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        -- print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= self.m_coins then

            curCoins = self.m_coins

            local node=self:findChild("m_lb_coins_1")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},426)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
        else
            local node=self:findChild("m_lb_coins_1")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},426)
        end
    end)

end

function ReelRocksCollectKaiCheJin:setCoins(coins)
    self.m_coins = coins
end

return ReelRocksCollectKaiCheJin