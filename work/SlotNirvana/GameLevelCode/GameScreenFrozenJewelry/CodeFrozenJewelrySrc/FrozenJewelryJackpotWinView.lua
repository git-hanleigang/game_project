---
--xcyy
--2018年5月23日
--FrozenJewelryJackpotWinView.lua

local FrozenJewelryJackpotWinView = class("FrozenJewelryJackpotWinView",util_require("Levels.BaseLevelDialog"))


function FrozenJewelryJackpotWinView:initUI(params)
    local viewType = params.viewType
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    local nameToJackpotIndex = {
        grand = 1,
        major = 2,
        minor = 3,
        mini  = 4,
    }
    self.m_jackpotIndex = nameToJackpotIndex[viewType]

    self:createCsbNode("FrozenJewelry/JackpotWinView.csb")

    self.m_node_mini = self:findChild("board_mini")
    self.m_node_minor = self:findChild("board_minor")
    self.m_node_major = self:findChild("board_major")
    self.m_node_grand = self:findChild("board_grand")

    self.m_node_mini:setVisible(viewType == "mini")
    self.m_node_minor:setVisible(viewType == "minor")
    self.m_node_major:setVisible(viewType == "major")
    self.m_node_grand:setVisible(viewType == "grand")

    self.m_allowClick = false

    self.m_spine = util_spineCreate("Socre_FrozenJewelry_tanban1",true,true)
    self:findChild("ren"):addChild(self.m_spine)

    self:showView(self.m_winCoin)

    local light = util_createAnimation("FrozenJewelry_jackpto_g.csb")
    self:findChild("guang"):addChild(light)
    light:runCsbAction("idle",true)
    
    self:createGrandShare(params.machine)
end


--[[
    显示界面
]]
function FrozenJewelryJackpotWinView:showView(winCoin)
    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_show_jackpot_win.mp3")
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    util_spinePlay(self.m_spine,"start")
    util_spineEndCallFunc(self.m_spine,"start",function()
        util_spinePlay(self.m_spine,"idleframe",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 815
    })
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(winCoin, self.m_jackpotIndex)
end

--[[
    关闭界面
]]
function FrozenJewelryJackpotWinView:showOver()
    self.m_allowClick = false
    self:runCsbAction("over",false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)
    util_spinePlay(self.m_spine,"over")
end

--[[
    金币跳动
]]
function FrozenJewelryJackpotWinView:jumpCoins(params)
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
    local jumpSound = "FrozenJewelrySounds/sound_FrozenJewelry_jackpot_rise_num.mp3"
    local jumpSoundEnd = "FrozenJewelrySounds/sound_FrozenJewelry_jackpot_rise_num_down.mp3"
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
function FrozenJewelryJackpotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end 
    if not self.m_allowClick then
        return
    end

    gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_btn_click.mp3")

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then
        self.m_isJumpOver = true
        self.m_isJumpCoins = false
        --停止所有跳动
        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoins(self.m_winCoin,50))

        local info={label = label,sx = 1,sy = 1}
        self:updateLabelSize(info,815)
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
function FrozenJewelryJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function FrozenJewelryJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function FrozenJewelryJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function FrozenJewelryJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return FrozenJewelryJackpotWinView