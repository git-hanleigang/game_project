---
--xcyy
--2018年5月23日
--FrozenJewelryMysteryView.lua

local FrozenJewelryMysteryView = class("FrozenJewelryMysteryView",util_require("Levels.BaseLevelDialog"))


function FrozenJewelryMysteryView:initUI(params)
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_machine = params.machine

    self:createCsbNode("FrozenJewelry/MysteryPrize.csb")

    self.m_allowClick = false

    self.m_light = util_createAnimation("FrozenJewelry/MysteryPrize_tx.csb")
    self:findChild("Node_tx"):addChild(self.m_light)
    self.m_light:setVisible(false)

    self.m_isRunLightAni = false

    self:showView(self.m_winCoin)
end


--[[
    显示界面
]]
function FrozenJewelryMysteryView:showView(winCoin)
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_mystery_win.mp3")
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        duration = 150 / 60,
        maxWidth = 815
    })
end

--[[
    关闭界面
]]
function FrozenJewelryMysteryView:showOver()
    self.m_allowClick = false
    self:runCsbAction("over",false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)
end

--[[
    金币跳动
]]
function FrozenJewelryMysteryView:jumpCoins(params)
    local label = params.label
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
    local jumpSound = "FrozenJewelrySounds/sound_FrozenJewelry_mystery_rise_num.mp3"
    local jumpSoundEnd = "FrozenJewelrySounds/sound_FrozenJewelry_mystery_rise_num_down.mp3"
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (50  * duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str) 
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0
    label:stopAllActions()

    if jumpSound then
        self.m_soundId = gLobalSoundManager:playSound(jumpSound,true)
    end
    
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then

            curCoins = endCoins
            label:setString(util_formatCoins(curCoins,50))
            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                if jumpSoundEnd then
                    gLobalSoundManager:playSound(jumpSoundEnd)
                end
                self.m_soundId = nil
            end

            label:stopAllActions()

            self:lightAni()

            self.m_isJumpOver = true
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function FrozenJewelryMysteryView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_btn_click.mp3")

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self.m_isJumpOver = true
        self.m_isJumpCoins = false
        --停止所有跳动
        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoins(self.m_winCoin,50))

        self:lightAni()

        local info={label = label,sx = 1,sy = 1}
        self:updateLabelSize(info,815)

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            --跳动结束音效
            if self.m_jumpSoundEnd then
                gLobalSoundManager:playSound(self.m_jumpSoundEnd)
            end
            self.m_soundId = nil
        end
        return
    end

    -- gLobalSoundManager:playSound("MagicianSounds/sound_Magician_btn_click.mp3")

    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    self:showOver()
end

--[[
    扫光特效
]]
function FrozenJewelryMysteryView:lightAni(func)
    if self.m_isRunLightAni then
        return
    end
    self.m_isRunLightAni = true
    self.m_light:setVisible(true)
    self.m_light:runCsbAction("actionframe",false,func)
end

return FrozenJewelryMysteryView