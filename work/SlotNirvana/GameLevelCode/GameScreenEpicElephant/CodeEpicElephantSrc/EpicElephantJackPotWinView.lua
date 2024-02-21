---
--xcyy
--2018年5月23日
--EpicElephantJackPotWinView.lua

local EpicElephantJackPotWinView = class("EpicElephantJackPotWinView",util_require("Levels.BaseLevelDialog"))


function EpicElephantJackPotWinView:initUI(params)
    local viewType = params.jackpotType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_machine = params.machine

    self:createCsbNode("EpicElephant/JackpotWinView.csb")

    self.m_jiaoSe = util_spineCreate("Socre_EpicElephant_juese",true,true)
    self:findChild("juese"):addChild(self.m_jiaoSe)
    self.m_jiaoSe:setSkin("base")

    self.m_allowClick = false

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(self:findChild("Button"))
        end,5)
    end
end


--[[
    显示界面
]]
function EpicElephantJackPotWinView:showView(winCoin)

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_jackpotView_start)

    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    util_spinePlay(self.m_jiaoSe, "start", false)
    util_spineEndCallFunc(self.m_jiaoSe, "start", function()
        -- util_spinePlay(self.m_jiaoSe, "idle", true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 831
    })

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(winCoin,1)
end

--[[
    关闭界面
]]
function EpicElephantJackPotWinView:showOver()
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
function EpicElephantJackPotWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 4   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_jackpotView_jump
    local jumpSoundEnd = self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_jackpotView_jumpEnd
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (60  * duration)   --1秒跳动60次

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
            local info={label = label,sx = 0.84,sy = 0.84}
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

            local info={label = label,sx = 0.84,sy = 0.84}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 60)
end

--[[
    点击按钮
]]
function EpicElephantJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_EpicElephant_click)

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self.m_isJumpOver = true
        self.m_isJumpCoins = false
        --停止所有跳动
        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoins(self.m_winCoin,50))

        local info={label = label,sx = 0.84,sy = 0.84}
        self:updateLabelSize(info,831)

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
        sender:setTouchEnabled(false)
    end
    self:showOver()
end


return EpicElephantJackPotWinView