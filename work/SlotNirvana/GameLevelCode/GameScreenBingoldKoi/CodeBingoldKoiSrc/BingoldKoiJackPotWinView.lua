---
--xcyy
--2018年5月23日
--BingoldKoiJackPotWinView.lua

local BingoldKoiJackPotWinView = class("BingoldKoiJackPotWinView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "BingoldKoiPublicConfig"

function BingoldKoiJackPotWinView:initUI(params)
    local viewType = params.jackpotType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func

    self:createCsbNode("BingoldKoi/JackpotWinView.csb")

    self:findChild("Node_grand"):setVisible(viewType == "grand")
    self:findChild("Node_mega"):setVisible(viewType == "mega")
    self:findChild("Node_major"):setVisible(viewType == "major")
    self:findChild("Node_minor"):setVisible(viewType == "minor")
    self:findChild("Node_mini"):setVisible(viewType == "mini")
    self:findChild("zi_grand"):setVisible(viewType == "grand")
    self:findChild("zi_mega"):setVisible(viewType == "mega")
    self:findChild("zi_major"):setVisible(viewType == "major")
    self:findChild("zi_minor"):setVisible(viewType == "minor")
    self:findChild("zi_mini"):setVisible(viewType == "mini")

    self.m_jackpotIndex = 5
    if viewType == "grand" then
        self.m_jackpotIndex = 1
    elseif viewType == "mega" then
        self.m_jackpotIndex = 2
    elseif viewType == "major" then
        self.m_jackpotIndex = 3
    elseif viewType == "minor" then
        self.m_jackpotIndex = 4
    elseif viewType == "mini" then
        self.m_jackpotIndex = 5
    end

    self.m_allowClick = false

    local lightAni = util_createAnimation("BingoldKoi_lightJackpot.csb")
    self:findChild("guang"):addChild(lightAni)
    lightAni:runCsbAction("idle", true)
    util_setCascadeOpacityEnabledRescursion(self, true)

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(self:findChild("Button_1"), true)
        end,5)
    end
end


--[[
    显示界面
]]
function BingoldKoiJackPotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 746
    })
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)
end

--[[
    关闭界面
]]
function BingoldKoiJackPotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Over)
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
function BingoldKoiJackPotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.Music_Jackpot_Jump_Coins
    local jumpSoundEnd = PublicConfig.Music_Jackpot_Jump_End
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)

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
            local info={label = label,sx = 1.12,sy = 1.12}
            self:updateLabelSize(info,maxWidth)

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                if jumpSoundEnd then
                    gLobalSoundManager:playSound(jumpSoundEnd)
                end
                self.m_soundId = nil
            end

            label:stopAllActions()

            self.m_isJumpOver = true
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 1.12,sy = 1.12}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function BingoldKoiJackPotWinView:clickFunc(sender, _isAuto)
    if not self.m_allowClick then
        return
    end
    
    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self.m_isJumpOver = true
        self.m_isJumpCoins = false
        --停止所有跳动
        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoins(self.m_winCoin,50))

        local info={label = label,sx = 1.12,sy = 1.12}
        self:updateLabelSize(info,746)

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

    if sender and sender.setTouchEnabled then
        if not _isAuto then
            gLobalSoundManager:playSound(PublicConfig.Music_Click_Btn)
        end
        sender:setTouchEnabled(false)
    end
    self:showOver()
end


return BingoldKoiJackPotWinView