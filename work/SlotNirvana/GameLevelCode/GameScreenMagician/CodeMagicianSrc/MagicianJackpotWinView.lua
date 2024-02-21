---
--xcyy
--2018年5月23日
--MagicianJackpotWinView.lua

local MagicianJackpotWinView = class("MagicianJackpotWinView",util_require("Levels.BaseLevelDialog"))


function MagicianJackpotWinView:initUI(params)
    local viewType = params.viewType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    local nameToJackpotIndex = {
        Grand = 1,
        Major = 2,
        Minor = 3,
        Mini  = 4,
    }
    self.m_jackpotIndex = nameToJackpotIndex[viewType]

    self:createCsbNode("Magician/Jackpot.csb")

    self.m_node_mini = self:findChild("Node_mini")
    self.m_node_minor = self:findChild("Node_minor")
    self.m_node_major = self:findChild("Node_major")
    self.m_node_grand = self:findChild("Node_grand")

    self.m_node_mini:setVisible(viewType == "Mini")
    self.m_node_minor:setVisible(viewType == "Minor")
    self.m_node_major:setVisible(viewType == "Major")
    self.m_node_grand:setVisible(viewType == "Grand")

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

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin, self.m_jackpotIndex)
    self:createGrandShare(params.machine)
end


--[[
    显示界面
]]
function MagicianJackpotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    local spine = util_spineCreate("Magician_Juese",true,true)
    self:findChild("Node_ren"):addChild(spine)
    util_spinePlay(spine,"actionframe_tanban")
    util_spineEndCallFunc(spine,"actionframe_tanban",function(  )
        util_spinePlay(spine,"idleframe_tanban",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coin"),
        endCoins = winCoin,
        maxWidth = 668
    })
end

--[[
    关闭界面
]]
function MagicianJackpotWinView:showOver()
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
function MagicianJackpotWinView:jumpCoins(params)
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
    local jumpSound = "MagicianSounds/sound_Magician_jackpot_rise.mp3"
    local jumpSoundEnd = "MagicianSounds/sound_Magician_jackpot_rise_down.mp3"
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
function MagicianJackpotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound("MagicianSounds/sound_Magician_btn_click.mp3")

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self.m_isJumpOver = true
        self.m_isJumpCoins = false
        --停止所有跳动
        local label = self:findChild("m_lb_coin")
        label:stopAllActions()
        label:setString(util_formatCoins(self.m_winCoin,50))

        local info={label = label,sx = 1,sy = 1}
        self:updateLabelSize(info,668)
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
    self:jackpotViewOver(function()
        self:showOver()
    end)
end

--[[
    自动分享 | 手动分享
]]
function MagicianJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function MagicianJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function MagicianJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function MagicianJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return MagicianJackpotWinView