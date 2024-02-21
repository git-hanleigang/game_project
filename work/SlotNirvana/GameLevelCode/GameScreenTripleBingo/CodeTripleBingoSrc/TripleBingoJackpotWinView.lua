---
--xcyy
--2018年5月23日
--TripleBingoJackpotWinView.lua
local PublicConfig = require "TripleBingoPublicConfig"
local TripleBingoJackpotWinView = class("TripleBingoJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}
function TripleBingoJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine
    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    self:createCsbNode("TripleBingo/JackpotWinView.csb")

    --创建分享按钮
    self:createGrandShare()
    --背光
    self.m_lightCsb = util_createAnimation("Socre_TripleBingo_guang.csb")
    self:findChild("Node_guang"):addChild(self.m_lightCsb)
    self.m_lightCsb:runCsbAction("idleframe", true)
    --
    self.m_spine = util_spineCreate("TripleBingo_jackpot_tanban", true, true)
    self:findChild("Node_juese"):addChild(self.m_spine)
    local bGrand = 1 == self.m_jackpotIndex
    local startName = bGrand and "start2" or "start"
    local idleName  = bGrand and "idle2"  or "idle"
    util_spinePlay(self.m_spine, startName, false)
    util_spineEndCallFunc(self.m_spine, startName, function()
        util_spinePlay(self.m_spine, idleName, true)
    end)
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("Node_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end
    end

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
function TripleBingoJackpotWinView:showView(winCoin)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_25)

    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins_1"),
        endCoins = winCoin,
        maxWidth = 673
    })
end

--[[
    关闭界面
]]
function TripleBingoJackpotWinView:showOver()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_28)
    

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
function TripleBingoJackpotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_26 --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_27 --跳动结束音效
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
            self:upDateJackpotViewCoinsLab(curCoins)
        end

    end,1 / 120)
end

function TripleBingoJackpotWinView:upDateJackpotViewCoinsLab(_coins)
    for _jpIndex=1,4 do
        local labCoins = self:findChild( string.format("m_lb_coins_%d", _jpIndex) )
        labCoins:setString(util_formatCoins(_coins,50))
        self:updateLabelSize({label = labCoins, sx = 1, sy = 1}, self.maxWidth)
    end
end

--[[
    点击按钮
]]
function TripleBingoJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_6)
    
    

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
function TripleBingoJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function TripleBingoJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins_1")
    label:stopAllActions()
    self:upDateJackpotViewCoinsLab(self.m_winCoin)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function TripleBingoJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function TripleBingoJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return TripleBingoJackpotWinView