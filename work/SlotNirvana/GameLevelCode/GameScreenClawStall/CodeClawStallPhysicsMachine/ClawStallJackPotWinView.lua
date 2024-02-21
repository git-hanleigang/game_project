---
--xcyy
--2018年5月23日
--ClawStallJackPotWinView.lua
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallJackPotWinView = class("ClawStallJackPotWinView",util_require("Levels.BaseLevelDialog"))

local BIRDS_RES = {
    "Socre_ClawStall_9",
    "Socre_ClawStall_7",
    "Socre_ClawStall_6",
    "Socre_ClawStall_5"
}

function ClawStallJackPotWinView:initUI(params)
    local rewardData = params.rewardData
    local viewType = rewardData[1]
    local birdType = rewardData[5] or 1
    self.m_winCoin = rewardData[4] - rewardData[3] * rewardData[2] or 0
    self.m_startCoin = self.m_winCoin / rewardData[2]
    self.m_endFunc = params.func
    local multi = rewardData[2] or 0

    self:createCsbNode("ClawStall/JackpotWinView.csb")

    local nodesName = {"Birds_hong","Birds_fen","Birds_lan","Birds_lv"}
    for index = 1,4 do
        local spine = util_spineCreate(BIRDS_RES[index],true,true)
        self:findChild(nodesName[index]):addChild(spine)

        local params = {}
        params[1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = spine,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            callBack = function(  )
                util_spinePlay(spine,"idle",true)
            end
        }
        util_runAnimations(params)

    end
    

    self:findChild("Grand"):setVisible(viewType == "grand")
    self:findChild("Major"):setVisible(viewType == "major")
    self:findChild("Minor"):setVisible(viewType == "minor")
    self:findChild("Mini"):setVisible(viewType == "mini")
    self:findChild("Sprite_grand"):setVisible(viewType == "grand")
    self:findChild("Sprite_major"):setVisible(viewType == "major")
    self:findChild("Sprite_minor"):setVisible(viewType == "minor")
    self:findChild("Sprite_mini"):setVisible(viewType == "mini")
    self:findChild("m_lb_Multiplier"):setString("X"..multi)

    self.m_allowClick = false

    self:showView(self.m_winCoin)
end


--[[
    显示界面
]]
function ClawStallJackPotWinView:showView(winCoin)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_jackpot_view)
    self:runCsbAction("start2",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    local label = self:findChild("m_lb_coins")
    label:setString(util_formatCoins(self.m_startCoin,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,746)

    
    performWithDelay(self,function(  )
        self:jumpCoins({
            startCoins = self.m_startCoin,
            label = self:findChild("m_lb_coins"),
            endCoins = winCoin,
            maxWidth = 746
        })
    end,65 / 60)

    
end

--[[
    关闭界面
]]
function ClawStallJackPotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_hide_jackpot_view)
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
function ClawStallJackPotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.sound_ClawStall_jackpot_jump
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_ClawStall_jackpot_jump_end
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
function ClawStallJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_click_btn)

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self.m_isJumpOver = true
        self.m_isJumpCoins = false
        --停止所有跳动
        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoins(self.m_winCoin,50))

        local info={label = label,sx = 1,sy = 1}
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
        sender:setTouchEnabled(false)
    end
    self:showOver()
end


return ClawStallJackPotWinView