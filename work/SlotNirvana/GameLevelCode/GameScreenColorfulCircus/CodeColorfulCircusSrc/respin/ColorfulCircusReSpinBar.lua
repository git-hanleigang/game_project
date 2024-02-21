---
--island
--2018年4月12日
--ColorfulCircusReSpinBar.lua
local ColorfulCircusReSpinBar = class("ColorfulCircusReSpinBar", util_require("Levels.BaseLevelDialog"))
ColorfulCircusReSpinBar.m_bar = 0
ColorfulCircusReSpinBar.m_rewordview = 1
function ColorfulCircusReSpinBar:initUI(data)

    local resourceFilename = "ColorfulCircus_respin_bar.csb"
    self:createCsbNode(resourceFilename)

end
function ColorfulCircusReSpinBar:onEnter()
    ColorfulCircusReSpinBar.super.onEnter(self)
end

function ColorfulCircusReSpinBar:onExit()
    ColorfulCircusReSpinBar.super.onExit(self)
end

function ColorfulCircusReSpinBar:updateView(curNum,sumNum)
    local showNum = sumNum - curNum
    self:findChild("m_lb_num"):setString(showNum)
    self:findChild("m_lb_num2"):setString(sumNum)
    self:updateLabelSize({label=self:findChild("m_lb_num"),sx=0.75,sy=0.75},69)
    self:updateLabelSize({label=self:findChild("m_lb_num2"),sx=0.75,sy=0.75},67)
end

function ColorfulCircusReSpinBar:updateShowStates(_state )

    self:findChild("Node_bar"):setVisible(false) -- 总收集赢钱
    self:findChild("Node_win"):setVisible(false) -- respin剩余次数显示

    if _state == self.m_bar then
        self:findChild("Node_bar"):setVisible(true) -- respin剩余次数显示
    elseif _state == self.m_rewordview then
        self:findChild("Node_win"):setVisible(true) -- 总收集赢钱
    end
end

function ColorfulCircusReSpinBar:updateRewordCoins( _coins,lastNum)
    if lastNum then
        self:jumpCoins({label = self:findChild("m_lb_coins"),
            startCoins = lastNum ,
            endCoins = _coins,
            duration = 0.1,
            maxWidth = 1013,

        })
    else

        if _coins == 0 then
            self:findChild("m_lb_coins"):setString("")
        else
            self:findChild("m_lb_coins"):setString(_coins)
            self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=0.8,sy=0.8},447)
        end
    end
    
end

function ColorfulCircusReSpinBar:showView()
    self:setVisible(true)
    self:updateRewordCoins("")
end

function ColorfulCircusReSpinBar:hideView()
    self:setVisible(false)
    self:updateRewordCoins("")
end

--[[
    金币跳动
]]
function ColorfulCircusReSpinBar:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120* duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label:stopAllActions()

    -- if jumpSound then
    --     self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    -- end
    
    self:findChild("m_lb_coins"):setString(util_formatCoins(startCoins,50))
    self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=0.8,sy=0.8},447)
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        -- if type(perFunc) == "function" then
        --     perFunc()
        -- end

        if curCoins >= endCoins then

            curCoins = endCoins
            label:setString(util_formatCoins(curCoins,50))
            local info={label = label,sx = 0.8,sy = 0.8}
            self:updateLabelSize(info,447)

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

            local info={label = label,sx = 0.8,sy = 0.8}
            self:updateLabelSize(info,447)
        end

    end,1 / 120)
end

function ColorfulCircusReSpinBar:showDouble()
    -- self:findChild("Particle_1_0"):resetSystem()
end

return ColorfulCircusReSpinBar
