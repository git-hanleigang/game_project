---
--xcyy
--2018年5月23日
--JungleJauntJackpotWinView.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntJackpotWinView = class("JungleJauntJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5
}
function JungleJauntJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self:createCsbNode("JungleJaunt/JackpotWinView.csb")

    self:findChild("m_lb_coins"):setString("")

    local glow = util_createAnimation("JungleJaunt/jungleJaunt_tb_glow.csb")
    self:findChild("Node_glow"):addChild(glow)
    glow:runCsbAction("idle",true)
    --创建分享按钮
    self:createGrandShare()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    if viewType == "grand" then
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_70)
    elseif viewType == "mega" then
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_69)  
    elseif viewType == "major" then
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_68)  
    elseif viewType == "minor" then
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_67)  
    elseif viewType == "mini" then
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_66)    
    end

    
    
    --设置控件显示
    local node = self:findChild(viewType)
    node:setVisible(true)
    local nodeMan = self:findChild(viewType.."man")
    nodeMan:setVisible(true)

    self.m_allowClick = false

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then --自动spin 5s后自动点击一次按钮
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()

            --跳动金币数还没跳完
            if self.m_isJumpCoins and not self.m_isJumpOver  then
                self:jumpCoinsFinish()
            end

            self:clickFunc(self:findChild("Button_1"))
        end,5)
    end
end


--[[
    显示界面
]]
function JungleJauntJackpotWinView:showView(winCoin)
    self:findChild("Button_1"):setTouchEnabled(false)
    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 656
    })


    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
        self:findChild("Button_1"):setTouchEnabled(true)
    end)

    
end

--[[
    关闭界面
]]
function JungleJauntJackpotWinView:showOver()
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_73)
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
function JungleJauntJackpotWinView:jumpCoins(params)
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

    local jumpSound = PBC.SoundConfig.JUNGLEJAUNT_SOUND_71 --跳动音效
    local jumpSoundEnd = PBC.SoundConfig.JUNGLEJAUNT_SOUND_72 --跳动结束音效
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
            label:setString(util_formatCoinsLN(curCoins,50))

            local info={label = label,sx = 0.91,sy = 0.91}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function JungleJauntJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    
    --点击音效
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)
    

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
function JungleJauntJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
    self.m_grandShare:setVisible(false)
    if self.m_jackpotIndex and self.m_jackpotIndex == 1 then
        self.m_grandShare:setVisible(true)
    end
end

function JungleJauntJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoinsLN(self.m_winCoin,50))
    local info={label = label,sx = 0.91,sy = 0.91}
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

function JungleJauntJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function JungleJauntJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return JungleJauntJackpotWinView