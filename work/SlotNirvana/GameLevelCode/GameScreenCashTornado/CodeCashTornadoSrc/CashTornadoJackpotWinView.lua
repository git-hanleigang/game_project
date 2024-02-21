---
--xcyy
--2018年5月23日
--CashTornadoJackpotWinView.lua
local PublicConfig = require "CashTornadoPublicConfig"
local CashTornadoJackpotWinView = class("CashTornadoJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    mega  = 2,
    major = 3,
    minor = 4,
    mini = 5
}
function CashTornadoJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self.m_isMultiplication = params.mul    --是否有成倍显示

    self:createCsbNode("CashTornado/JackpotWinView.csb")

    --创建分享按钮
    self:createGrandShare()

    local light1 = util_createAnimation("CashTornado/JackpotWinView_g.csb")
    self:findChild("Node_g"):addChild(light1)
    light1:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_g"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_g"), true)

    local light2 = util_createAnimation("CashTornado/JackpotWinView_g2.csb")
    self:findChild("Node_g2"):addChild(light2)
    light2:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_g2"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_g2"), true)

    local jvese = util_spineCreate("CashTornado_juese", true, true)
    self:findChild("Node_spine"):addChild(jvese)
    util_spinePlay(jvese,"idleframe_tanban1",true)

    self.m_coinbonus = cc.Node:create()
    self:addChild(self.m_coinbonus)

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("node_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end
    end

    if self.m_isMultiplication then
        for jpType,index in pairs(JACKPOT_INDEX) do
            local node = self:findChild("Node_chengbei_"..jpType)
            if node then
                node:setVisible(viewType == jpType)
            end
        end
    else
        for jpType,index in pairs(JACKPOT_INDEX) do
            local node = self:findChild("Node_chengbei_"..jpType)
            if node then
                node:setVisible(false)
            end
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

function CashTornadoJackpotWinView:showJackpotViewSound()
    if self.m_jackpotIndex == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_jackpotView_grand)
    elseif self.m_jackpotIndex == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_jackpotView_mega)
    elseif self.m_jackpotIndex == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_jackpotView_major)
    elseif self.m_jackpotIndex == 4 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_jackpotView_minor)
    elseif self.m_jackpotIndex == 5 then  
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_jackpotView_mini) 
    end
end


--[[
    显示界面
]]
function CashTornadoJackpotWinView:showView(winCoin)
    self:showJackpotViewSound()
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 659
    })
end

--[[
    关闭界面
]]
function CashTornadoJackpotWinView:showOver()
    self.m_allowClick = false
    local overActName = nil
    if self.m_isMultiplication then
        overActName = "over2"
    else
        overActName = "over"
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_jackpotView_hide) 
    self:runCsbAction(overActName,false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)
end

--[[
    金币跳动
]]
function CashTornadoJackpotWinView:jumpCoins(params)
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
    local isMul = params.isMul or false
    local jumpSound = PublicConfig.SoundConfig.sound_CashTornado_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_CashTornado_jump_coins_end --跳动结束音效
    self.m_jumpSoundEnd = jumpSoundEnd
    self.maxWidth = maxWidth

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动120次

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
            self:jumpCoinsFinish(isMul)
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoinsLN(curCoins,30))

            local info={label = label,sx = 0.96,sy = 0.96}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function CashTornadoJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    if PublicConfig.SoundConfig.sound_CashTornado_click then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_click)
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

    if self.m_isMultiplication then
        self.m_allowClick = false
        self:showMultiplicationAct(function ()
            self:jackpotViewOver(function(  )
                self:showOver()
            end)
        end)
    else
        self:jackpotViewOver(function(  )
            self:showOver()
        end)
    end
    
    
end

--有成倍，点击关闭时先展示成倍砸下，1s后关闭
function CashTornadoJackpotWinView:showMultiplicationAct(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_chengbei_za)
    self:runCsbAction("actionframe")
    local lizi1 = self:findChild("ef_lizi01_"..self.m_viewType)
    local lizi2 = self:findChild("ef_lizi02_"..self.m_viewType)
    --粒子
    self.m_machine:delayCallBack(22/60,function ()
        if lizi1 then
            lizi1:resetSystem()
        end
        if lizi2 then
            lizi2:resetSystem()
        end
    end)
    self.m_machine:delayCallBack(24/60,function ()
        if self.m_coinbonusUpdateAction then
            self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
            self.m_coinbonusUpdateAction = nil
        end
        self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_jump_coins,true)
        local showTime = 1.5
        local coinRiseNum = self.m_winCoin / (showTime * 60)  -- 每秒60帧
    
        local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
        coinRiseNum = tonumber(str)
        coinRiseNum = math.ceil(coinRiseNum)
        local node = self:findChild("m_lb_coins")
        local m_currShowCoins = self.m_winCoin
    
        self.m_coinbonusUpdateAction = schedule(self.m_coinbonus,function()
            m_currShowCoins = m_currShowCoins + coinRiseNum
            
            node:setString(string.format("+%s", util_getFromatMoneyStr(m_currShowCoins)) )
            if m_currShowCoins >= self.m_winCoin * 2 then
                if self.m_coinbonusUpdateAction then
                    self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
                    self.m_coinbonusUpdateAction = nil
                end
                self:jumpCoinsFinish(true)
                self.m_machine:delayCallBack(0.5,function ()
                    if func then
                        func()
                    end
                end)
                
            end
        end,1/60)
    end)

    
end

---------------------------------------------------------------------------------------------------------
--[[
    自动分享 | 手动分享
]]
function CashTornadoJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function CashTornadoJackpotWinView:jumpCoinsFinish(isMul)
    if self.m_isMultiplication then
        -- if not isMul then
            if nil ~= self.m_grandShare then
                self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
            end
        -- end
    else
        if nil ~= self.m_grandShare then
            self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
        end
    end
    
    
    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    if isMul then
        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoinsLN(self.m_winCoin * 2,30))
        local info={label = label,sx = 1,sy = 1}
        self:updateLabelSize(info,self.maxWidth)
    else
        --通知jackpot
        globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

        local label = self:findChild("m_lb_coins")
        label:stopAllActions()
        label:setString(util_formatCoinsLN(self.m_winCoin,30))
        local info={label = label,sx = 1,sy = 1}
        self:updateLabelSize(info,self.maxWidth)
    end
    

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function CashTornadoJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function CashTornadoJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
    
end

function CashTornadoJackpotWinView:onExit()
    CashTornadoJackpotWinView.super.onExit(self)      -- 必须调用不予许删除
    if self.m_coinbonusUpdateAction then
        self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
        self.m_coinbonusUpdateAction = nil
    end
end


return CashTornadoJackpotWinView