---
--xcyy
--2018年5月23日
--BunnysLockJackPotWinView.lua

local BunnysLockJackPotWinView = class("BunnysLockJackPotWinView",util_require("Levels.BaseLevelDialog"))


function BunnysLockJackPotWinView:initUI(params)
    local viewType = params.jackpotType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func

    self:createCsbNode("BunnysLock/JackpotWinView.csb")

    self:createGrandShare(params.machine)
    if viewType == "grand" then
        self.m_jackpotIndex = 1
    elseif viewType == "major" then
        self.m_jackpotIndex = 2
    elseif viewType == "minor" then
        self.m_jackpotIndex = 3
    elseif viewType == "mini" then
        self.m_jackpotIndex = 4
    end 

    self.m_node_mini = self:findChild("Node_mini")
    self.m_node_minor = self:findChild("Node_minor")
    self.m_node_major = self:findChild("Node_major")
    self.m_node_grand = self:findChild("Node_grand")

    self.m_node_mini:setVisible(viewType == "mini")
    self.m_node_minor:setVisible(viewType == "minor")
    self.m_node_major:setVisible(viewType == "major")
    self.m_node_grand:setVisible(viewType == "grand")

    self.m_allowClick = false

    local spine = util_spineCreate("BunysLock_dajuese",true,true)
    self:findChild("Node_jackpot_tuzi"):addChild(spine)
    util_spinePlay(spine,"idleframe_tb",true)

    --背景光
    local shine = util_createAnimation("BunnysLock/BonusStart_tanban_shine.csb")
    self:findChild("Node_guang"):addChild(shine)
    shine:runCsbAction("idleframe",true)

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_colorful_win_jp_"..viewType..".mp3")
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
function BunnysLockJackPotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 782
    })
end

--[[
    关闭界面
]]
function BunnysLockJackPotWinView:showOver()
    self.m_allowClick = false
    local bShare = self:checkShareState()
    if not bShare then
        self:jackpotViewOver(function()
            self:runCsbAction("over",false,function()
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc()
                end
        
                self:removeFromParent()
            end)
        end)
    end
end

--[[
    金币跳动
]]
function BunnysLockJackPotWinView:jumpCoins(params)
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
    local jumpSound = "BunnysLockSounds/sound_BunnysLock_jackpot_rise.mp3"
    local jumpSoundEnd = "BunnysLockSounds/sound_BunnysLock_jackpot_rise_down.mp3"
    self.m_jumpSoundEnd = jumpSoundEnd

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动60次

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
            self:jumpCoinsFinish()

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
function BunnysLockJackPotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self.m_isJumpOver = true
        self.m_isJumpCoins = false
        --停止所有跳动
        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoins(self.m_winCoin,50))

        local info={label = label,sx = 1,sy = 1}
        self:updateLabelSize(info,782)
        self:jumpCoinsFinish()

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

--[[
    自动分享 | 手动分享
]]
function BunnysLockJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function BunnysLockJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function BunnysLockJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function BunnysLockJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return BunnysLockJackPotWinView