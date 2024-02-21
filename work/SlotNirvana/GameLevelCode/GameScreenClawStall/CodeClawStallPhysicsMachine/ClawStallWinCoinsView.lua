---
--xcyy
--2018年5月23日
--ClawStallWinCoinsView.lua
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallWinCoinsView = class("ClawStallWinCoinsView",util_require("Levels.BaseLevelDialog"))


function ClawStallWinCoinsView:initUI()
    self.m_curCoins = 0
    self:createCsbNode("ClawStall_Machine_Winner.csb")

    self.m_lbl_coins = self:findChild("m_lb_coins")
end

--[[
    显示界面
]]
function ClawStallWinCoinsView:showView(func)
    self:setVisible(true)
    self.m_lbl_coins:setVisible(false)
    self.m_curCoins = 0
    self:updateCoins(0)
    self:setPosition(cc.p(0,0))

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_winner_coins)
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    隐藏界面
]]
function ClawStallWinCoinsView:hideView(func)
    performWithDelay(self,function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_hide_winner_coins)
        self:runCsbAction("over",false,function(  )
            self:setVisible(false)
            if type(func) == "function" then
                func()
            end
        end)
        self:runAction(cc.MoveTo:create(25 / 60,cc.p(0,-15)))
    end,1)
end

--[[
    刷新金币显示
]]
function ClawStallWinCoinsView:updateCoins(coins)
    if coins ~= 0 then
        self.m_lbl_coins:setVisible(true)
        self:jumpCoins(self.m_curCoins,coins,function(  )
            self.m_curCoins = coins
        end)
    end
    
    -- local str = util_formatCoins(coins,50)
    -- self:findChild("m_lb_coins"):setString(str)
    -- self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=1,sy=1},775)
end


function ClawStallWinCoinsView:jumpCoins(startCoins,coins,func)

    local node = self.m_lbl_coins
    self.m_lbl_coins:setString(util_formatCoins(startCoins,4))

    local coinRiseNum =  (coins - startCoins) / 10

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 3 ))
    coinRiseNum = tonumber(str)

    local curCoins = startCoins
    node:stopAllActions()
    
    util_schedule(node,function()

        curCoins = curCoins + coinRiseNum
        curCoins = math.ceil(curCoins)

        if curCoins >= coins then

            curCoins = coins

            self.m_lbl_coins:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.m_lbl_coins,sx=1,sy=1},775)

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            node:stopAllActions()
            if type(func) == "function" then
                func()
            end
        else
            self.m_lbl_coins:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=self.m_lbl_coins,sx=1,sy=1},775)
        end
    end,1 / 60)
end

return ClawStallWinCoinsView