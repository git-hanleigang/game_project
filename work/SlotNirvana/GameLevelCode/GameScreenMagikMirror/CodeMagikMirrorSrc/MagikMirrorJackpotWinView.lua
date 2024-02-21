---
--xcyy
--2018年5月23日
--MagikMirrorJackpotWinView.lua
local PublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorJackpotWinView = class("MagikMirrorJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini  = 4
}
function MagikMirrorJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self:createCsbNode("MagikMirror/JackpotWinView.csb")

    local lighting = util_createAnimation("MagikMirror_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(lighting)
    lighting:runCsbAction("idle",true)

    self.juese = util_spineCreate("Socre_MagikMirror_9", true, true)
    self:findChild("juese"):addChild(self.juese)

    --创建分享按钮
    self:createGrandShare()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("Node_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end
    end

    self.m_allowClick = false

    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_1"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_1"), true)

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

function MagikMirrorJackpotWinView:showJackpotSoundForIndex()
    if self.m_jackpotIndex == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_jackpotWin_grand)
    elseif self.m_jackpotIndex == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_jackpotWin_major)
    elseif self.m_jackpotIndex == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_jackpotWin_minor)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_jackpotWin_mini)
    end
end

--[[
    显示界面
]]
function MagikMirrorJackpotWinView:showView(winCoin)
    
    self:showJackpotSoundForIndex()
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)
    util_spinePlay(self.juese, "jackpot_start")
    util_spineEndCallFunc(self.juese, "jackpot_start", function ()
        util_spinePlay(self.juese, "jackpot_idle",true)
    end)
    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 641
    })
end

--[[
    关闭界面
]]
function MagikMirrorJackpotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_jackpotWin_hide)
    util_spinePlay(self.juese, "jackpot_over")
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
function MagikMirrorJackpotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.sound_MagikMirror_jackpot_num_jump --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_MagikMirror_jackpot_num_jumpOver --跳动结束音效
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
function MagikMirrorJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    if PublicConfig.SoundConfig.sound_MagikMirror_click then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_click)
    end
    

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
function MagikMirrorJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MagikMirrorJackpotWinView:jumpCoinsFinish()
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

function MagikMirrorJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MagikMirrorJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return MagikMirrorJackpotWinView