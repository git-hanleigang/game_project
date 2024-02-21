---
--xcyy
--2018年5月23日
--GhostBlasterFreeTotalWin.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterFreeTotalWin = class("GhostBlasterFreeTotalWin",util_require("Levels.BaseLevelDialog"))

function GhostBlasterFreeTotalWin:initUI(params)
    self.m_winCoins = 0
    self.m_winCoinList = {}
    self.m_winIndex = 0
    self.m_machine = params.machine
    self:createCsbNode("GhostBlaster_FreeWins.csb")

end


function GhostBlasterFreeTotalWin:showAni(func)
    local label = self:findChild("m_lb_coins")
    label:setString("")
    self:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.Music_Free_CollectPanel_Start)
    self:runCsbAction("start",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    重置赢钱数
]]
function GhostBlasterFreeTotalWin:resetWinCoins()
    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString("")
end

function GhostBlasterFreeTotalWin:hideAni(func)
    
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    重置赢钱列表
]]
function GhostBlasterFreeTotalWin:resetWinCoinList()
    self.m_winCoinList = {}
    self.m_winIndex = 0
    self.m_winCoins = 0
end

--[[
    更新赢钱数
]]
function GhostBlasterFreeTotalWin:updateWinCoins(coins)
    self.m_winCoinList[#self.m_winCoinList + 1] = {
        startCoins = self.m_winCoins,
        endCoins = self.m_winCoins + coins
    }
    self.m_winCoins  = self.m_winCoins + coins
end

--[[
    反馈动效
]]
function GhostBlasterFreeTotalWin:runFeedBackAni(coins,func)
    self.m_winIndex  = self.m_winIndex + 1
    local winData = self.m_winCoinList[self.m_winIndex]
    self:jumpCoins({
        startCoins = winData.startCoins,
        endCoins = winData.endCoins,
        duration = 0.2,
        maxWidth = 230
    })
    
    self:runCsbAction("actionframe",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    金币跳动
]]
function GhostBlasterFreeTotalWin:jumpCoins(params)
    local label = self:findChild("m_lb_coins")
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound --= PublicConfig.SoundConfig.sound_GhostBlaster_jump_coins --跳动音效
    local jumpSoundEnd --= PublicConfig.SoundConfig.sound_GhostBlaster_jump_coins_end --跳动结束音效

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动120次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label:stopAllActions()

    if jumpSound then
        self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    end

    label:setString(util_formatCoins(curCoins,3))
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            label:setString(util_formatCoins(endCoins,3))
            label:stopAllActions()
            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoins(curCoins,3))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

return GhostBlasterFreeTotalWin
