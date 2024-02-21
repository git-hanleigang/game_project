---
--xcyy
--2018年5月23日
--GhostBlasterJackpotWinView.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterJackpotWinView = class("GhostBlasterJackpotWinView",util_require("Levels.BaseLevelDialog"))

function GhostBlasterJackpotWinView:initUI(params)
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_machine = params.machine

    self.m_jackpotIndex = 1

    self:createCsbNode("GhostBlaster/JackpotWinView.csb")

    local spine_btn = util_spineCreate("GhostBlaster_anniu_paopao",true,true)
    self:findChild("Node_pp"):addChild(spine_btn)
    util_spinePlay(spine_btn,"actionframe",true)

    self.m_spine_boss = util_spineCreate("Socre_GhostBlaster_super",true,true)
    self:findChild("Node_boss"):addChild(self.m_spine_boss)

    local light = util_createAnimation("GhostBlaster_superjackpot_guang.csb")
    self:findChild("Node_guang"):addChild(light)
    light:runCsbAction("idle",true)

    --创建分享按钮
    self:createGrandShare()
    
    
    self.m_allowClick = false

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then --自动spin 5s后自动点击一次按钮
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
function GhostBlasterJackpotWinView:showView(winCoin)
    gLobalSoundManager:playSound(PublicConfig.Music_Super_Jackpot_Start)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    util_spinePlay(self.m_spine_boss,"tb_start")
    util_spineEndCallFunc(self.m_spine_boss,"tb_start",function()
        
        util_spinePlay(self.m_spine_boss,"tb_idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 714
    })
end

--[[
    关闭界面
]]
function GhostBlasterJackpotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.Music_Super_Jackpot_Over)
    self:runCsbAction("over",false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:setVisible(false)
        performWithDelay(self,function()
            self:removeFromParent()
        end,1)
    end)

    util_spinePlay(self.m_spine_boss,"tb_over")
end

--[[
    金币跳动
]]
function GhostBlasterJackpotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.Music_Super_Jackpot_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.Music_Super_Jackpot_jump_coins_end --跳动结束音效
    self.m_jumpSoundEnd = jumpSoundEnd
    self.maxWidth = maxWidth

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动120次

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
function GhostBlasterJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
    

    if self:checkShareState() then
        return
    end

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
function GhostBlasterJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function GhostBlasterJackpotWinView:jumpCoinsFinish()
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
    self:updateLabelSize(info,self.maxWidth)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function GhostBlasterJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function GhostBlasterJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return GhostBlasterJackpotWinView