---
--xcyy
--2018年5月23日
--TheHonorOfZorroJackPotWinView.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroJackPotWinView = class("TheHonorOfZorroJackPotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}
function TheHonorOfZorroJackPotWinView:initUI(params)
    local viewType = string.lower(params.jackpotType) 
    self.m_multi = params.multi
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self:createCsbNode("TheHonorOfZorro/JackpotWinView.csb")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_TheHonorOfZorro_show_jackpot_view_"..viewType])

    --创建分享按钮
    self:createGrandShare()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    self.m_node_mini = self:findChild("Node_mini")
    self.m_node_minor = self:findChild("Node_minor")
    self.m_node_major = self:findChild("Node_major")
    self.m_node_grand = self:findChild("Node_grand")

    self.m_node_mini:setVisible(viewType == "mini")
    self.m_node_minor:setVisible(viewType == "minor")
    self.m_node_major:setVisible(viewType == "major")
    self.m_node_grand:setVisible(viewType == "grand")
    self:findChild("sp_multi"):setVisible(self.m_multi > 1)

    local particle = self:findChild("Particle_2")
    if particle then
        particle:setVisible(false)
    end


    self.m_allowClick = false

    --角色
    local spine = util_spineCreate("Socre_TheHonorOfZorro_juese",true,true)
    self:findChild("Node_juese"):addChild(spine)
    util_spinePlay(spine,"start_tanban")
    util_spineEndCallFunc(spine,"start_tanban",function()
        util_spinePlay(spine,"idle_tanban",true)
    end)

    --背景光
    local light = util_createAnimation("TheHonorOfZorro_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(light)
    light:runCsbAction("idle2",true)

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(self:findChild("Button_1"))
        end,5)
    end
end


--[[
    显示界面
]]
function TheHonorOfZorroJackPotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        if self.m_multi > 1 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_multi_jackpot_coins)
            --乘倍后再跳动数字
            self:runCsbAction("fly",false,function()
                self.m_allowClick = true
                self:runCsbAction("idle",true)
            end)

            local wait_node = cc.Node:create()
            self:addChild(wait_node)
            performWithDelay(wait_node,function(  )
                wait_node:removeFromParent()

                local particle = self:findChild("Particle_2")
                if particle then
                    particle:setVisible(true)
                    particle:resetSystem()
                end

                self:jumpCoins({
                    label = self:findChild("m_lb_coins"),
                    startCoins = math.floor(winCoin / self.m_multi),
                    endCoins = winCoin,
                    maxWidth = 616
                })
            end,53 / 60)
        else
            self.m_allowClick = true
            self:runCsbAction("idle",true)
        end
    end)

    if self.m_multi == 1 then
        self:jumpCoins({
            label = self:findChild("m_lb_coins"),
            endCoins = winCoin,
            maxWidth = 616
        })
    else
        local label = self:findChild("m_lb_coins")
        label:setString(util_formatCoins(math.floor(winCoin / self.m_multi),50))

        local info={label = label,sx = 1,sy = 1}
        self:updateLabelSize(info,616)
    end
end

--[[
    关闭界面
]]
function TheHonorOfZorroJackPotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_hide_jackpot_view)
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
function TheHonorOfZorroJackPotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.sound_TheHonorOfZorro_jump_jackpot_coins
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_TheHonorOfZorro_jump_jackpot_coins_end
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动60次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
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
            self:jumpCoinsFinish()
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
function TheHonorOfZorroJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    if self:checkShareState() then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_btn_click)

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then

        self:jumpCoinsFinish()
        return
    end

    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end

    self:jackpotViewOver(function(  )
        self:showOver()
    end)
    
end

---------------------------------------------------------------------------------------------------------
--[[
    自动分享 | 手动分享
]]
function TheHonorOfZorroJackPotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function TheHonorOfZorroJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoins(self.m_winCoin,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,616)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function TheHonorOfZorroJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function TheHonorOfZorroJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return TheHonorOfZorroJackPotWinView