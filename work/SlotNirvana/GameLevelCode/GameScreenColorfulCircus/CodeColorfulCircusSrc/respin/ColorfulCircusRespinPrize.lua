---
--island
--2018年4月12日
--ColorfulCircusRespinPrize.lua
local ColorfulCircusRespinPrize = class("ColorfulCircusRespinPrize", util_require("Levels.BaseLevelDialog"))

local m_lb_coins_scaleX = 0.75
local m_lb_coins_scaleY = 0.75
local m_lb_coins_width = 447
function ColorfulCircusRespinPrize:initUI(data)

    local resourceFilename = "ColorfulCircus_respin_prize.csb"
    self:createCsbNode(resourceFilename)
    
end
function ColorfulCircusRespinPrize:updateView(curNum,lastNum)
    if lastNum then
        self:jumpCoins({label = self:findChild("m_lb_coins"),
            startCoins = lastNum ,
            endCoins = curNum,
            duration = 3/30,
            maxWidth = 1087,

        })
    else
        -- if tonumber(curNum) > 0 then
        --     self:playCollect()
        -- end
        if curNum == 0 then
            self:findChild("m_lb_coins"):setString("")
        else
            self:findChild("m_lb_coins"):setString(util_formatCoins(curNum, 20))
            self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=m_lb_coins_scaleX,sy=m_lb_coins_scaleY},m_lb_coins_width)
        end
    end
    
    
end

function ColorfulCircusRespinPrize:onEnter()
    ColorfulCircusRespinPrize.super.onEnter(self)
end

function ColorfulCircusRespinPrize:onExit()
    ColorfulCircusRespinPrize.super.onExit(self)
end

function ColorfulCircusRespinPrize:repeatChangBig( )
    self:runCsbAction("star",false,function (  )
        -- self:runCsbAction("repeatidle")
    end)
    gLobalSoundManager:playSound("ColorfulCircusSounds/sound_ColorfulCircus_bonusCollectStart.mp3")
end

function ColorfulCircusRespinPrize:resetSize( )
    self:runCsbAction("over", false)
end

function ColorfulCircusRespinPrize:hideView()
    self:setVisible(false)
end

--[[
    金币跳动
]]
function ColorfulCircusRespinPrize:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    -- local perFunc = params.perFunc  --每次跳动回调
    -- local endFunc = params.endFunc  --结束回调
    -- local jumpSound = "MagicianSounds/sound_Magician_jackpot_rise.mp3"
    -- local jumpSoundEnd = "MagicianSounds/sound_Magician_jackpot_rise_down.mp3"
    -- self.m_jumpSoundEnd = jumpSoundEnd

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label:stopAllActions()

    -- if jumpSound then
    --     self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    -- end
    
    self:findChild("m_lb_coins"):setString(util_formatCoins(startCoins, 20))
    self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=m_lb_coins_scaleX,sy=m_lb_coins_scaleY},m_lb_coins_width)
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        -- if type(perFunc) == "function" then
        --     perFunc()
        -- end

        if curCoins >= endCoins then

            curCoins = endCoins
            label:setString(util_formatCoins(curCoins,50))

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                -- if jumpSoundEnd then
                --     gLobalSoundManager:playSound(jumpSoundEnd)
                -- end
                self.m_soundId = nil
            end

            label:stopAllActions()

            self.m_isJumpOver = true
            --结束回调
            -- if type(endFunc) == "function" then
            --     endFunc()
            -- end

        else
            label:setString(util_formatCoins(curCoins,50))
        end

        local info={label = label,sx = m_lb_coins_scaleX,sy = m_lb_coins_scaleY}
        self:updateLabelSize(info,m_lb_coins_width)

    end,1 / 120)
end


return ColorfulCircusRespinPrize
