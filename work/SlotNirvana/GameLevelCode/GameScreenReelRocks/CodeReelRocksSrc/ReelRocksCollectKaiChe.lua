---
--xcyy
--2018年5月23日
--ReelRocksCollectKaiChe.lua

local ReelRocksCollectKaiChe = class("ReelRocksCollectKaiChe",util_require("base.BaseView"))


function ReelRocksCollectKaiChe:initUI()

    self:createCsbNode("ReelRocks_kaiche_1.csb")
    self.m_coins = 0
end

function ReelRocksCollectKaiChe:showStart()
    self:runCsbAction("start",false,function (  )
        self:runCsbAction("idle",true)
    end)
end

function ReelRocksCollectKaiChe:onEnter()
 
end

function ReelRocksCollectKaiChe:onExit()
    if self.m_updateCoinHandlerID then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function ReelRocksCollectKaiChe:resetCoins( )
    
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    self:findChild("m_lb_coins"):setString("")
    self.m_coins = 0
end

function ReelRocksCollectKaiChe:setJackpotShow(type)
    for i=1,4 do
        self:findChild("jackpot_"..i):setVisible(false)
    end
    if type == 101 then
        self:findChild("jackpot_4"):setVisible(true)
    elseif type == 102 then
        self:findChild("jackpot_3"):setVisible(true)
    elseif type == 103 then
        self:findChild("jackpot_2"):setVisible(true)
    elseif type == 104 then
        self:findChild("jackpot_1"):setVisible(true)
    end
end

function ReelRocksCollectKaiChe:UpdateWinLabel(coins)
    
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    self.isOver = false
    -- self:findChild("m_lb_coins"):setString(self.m_coins)
    -- / (1.5 * 5)  -- 每秒30帧
    local coinRiseNum =  coins
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

            local node=self:findChild("m_lb_coins") 
            node:setString(util_formatCoins(curCoins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},426)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},426)
        end
    end)
end
-- function ReelRocksCollectKaiChe:setCoins(coins)
--     self.m_coins = coins
-- end

return ReelRocksCollectKaiChe