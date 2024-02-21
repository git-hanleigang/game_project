---
--xcyy
--2018年5月23日
--StarryFestJackpotWinView.lua
local PublicConfig = require "StarryFestPublicConfig"
local StarryFestJackpotWinView = class("StarryFestJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    super = 2,
    maxi = 3,
    mega = 4,
    major = 5,
    minor = 6,
    mini = 7,
}
function StarryFestJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_mul = params.jackpotMul
    self.m_totalToins = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    self:createCsbNode("StarryFest/JackpotWinView.csb")

    --创建分享按钮
    self:createGrandShare()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("node_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end
    end

    local roleSpine = util_spineCreate("Socre_StarryFest_9",true,true)
    self:findChild("Node_juese"):addChild(roleSpine)
    util_spinePlay(roleSpine, "idleframe2", true)

    self.m_chengbeiNode = self:findChild("Node_chengbei")
    -- 乘倍node
    if self.m_mul > 1 then
        self.m_mulNode = util_createAnimation("StarryFest_Jackpot_chengbei.csb")
        self.m_mulNode:runCsbAction("idle", true)
        self.m_mulNode:findChild("sp_mul_2"):setVisible(self.m_mul==2)
        self.m_mulNode:findChild("sp_mul_3"):setVisible(self.m_mul==3)
        self.m_mulNode:findChild("sp_mul_5"):setVisible(self.m_mul==5)
        self.m_chengbeiNode:addChild(self.m_mulNode)
    end

    local yanhuaName = "actionframe_tbyh2"
    if jackpotIndex == 1 then
        yanhuaName = "actionframe_tbyh3"
    end
    local yanhuaSpine = util_spineCreate("StarryFest_guochang2",true,true)
    self:findChild("yanhua"):addChild(yanhuaSpine)
    util_spinePlay(yanhuaSpine, yanhuaName, true)

    self.m_allowClick = false

    self.m_winCoin = self.m_totalToins/self.m_mul
    self:showView(self.m_winCoin)
    local jackporSound = PublicConfig.SoundConfig.Music_Jackpot_Reward[jackpotIndex]
    if jackporSound then
        gLobalSoundManager:playSound(jackporSound)
    end
    if globalData.slotRunData.m_isAutoSpinAction then --自动spin 5s后自动点击一次按钮
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(self:findChild("Button_1"))
        end,5)
    end

    util_setCascadeOpacityEnabledRescursion(self, true)
end

--[[
    显示界面
]]
function StarryFestJackpotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({label = self:findChild("m_lb_coins"), endCoins = winCoin, maxWidth = 645})
end

--[[
    关闭界面
]]
function StarryFestJackpotWinView:showOver(_isMul)
    local overName = "over2"
    local delayTime = 0
    if _isMul then
        overName = "over"
        delayTime = 0.5
    end
    self.m_allowClick = false
    performWithDelay(self, function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Over)
        self:runCsbAction(overName,false,function()
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
            end
    
            self:removeFromParent()
        end)
    end, delayTime)
end

--[[
    金币跳动
]]
function StarryFestJackpotWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 4   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local isMul = params.isMul
    local jumpSound = PublicConfig.sound_StarryFest_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.sound_StarryFest_jump_coins_end --跳动结束音效
    self.m_jumpSoundEnd = jumpSoundEnd
    self.maxWidth = maxWidth

    self.m_isJumpCoins = true
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (60 * duration)   --1秒跳动120次

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    label:stopAllActions()

    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Jump_Coins)
    
    util_schedule(label,function()
        curCoins = curCoins + coinRiseNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if curCoins >= endCoins then
            self:jumpCoinsFinish(isMul)
            --结束
            if isMul then
                self:showOver(isMul)
            end
        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end, 1/60)
end

--[[
    点击按钮
]]
function StarryFestJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Normal_Click)

    if self:checkShareState() then
        return
    end

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver then
        self:jumpCoinsFinish()
        return
    end

    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end

    -- 1倍直接结束
    self.m_allowClick = false
    if self:judgeCurIsOver() then
        self:jackpotViewOver(function()
            self:showOver()
        end)
    else
        self:playJackpotMulEffect()
    end
end

-- 触发倍数
function StarryFestJackpotWinView:playJackpotMulEffect()
    self:runCsbAction("over_anniu", false, function()
        self:runCsbAction("idle2", true)
    end)

    if not self.m_mulNode then
        self.m_mulNode = util_createAnimation("StarryFest_Jackpot_chengbei.csb")
        self.m_mulNode:runCsbAction("idle", true)
        self.m_mulNode:findChild("sp_mul_2"):setVisible(self.m_mul==2)
        self.m_mulNode:findChild("sp_mul_3"):setVisible(self.m_mul==3)
        self.m_mulNode:findChild("sp_mul_5"):setVisible(self.m_mul==5)
        self.m_chengbeiNode:addChild(self.m_mulNode)
    end

    local effectNode = util_createAnimation("StarryFest_Jackpot_chengbei_tx.csb")
    self:findChild("Node_chengbei_tx"):addChild(effectNode)
    effectNode:setVisible(false)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Mul_Move)
    self.m_mulNode:runCsbAction("fly", false)
    local tblActionList = {}
    tblActionList[#tblActionList + 1] = cc.EaseOut:create(cc.MoveTo:create(12/60, cc.p(0, -60)), 1)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(4/60)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        effectNode:setVisible(true)
        effectNode:runCsbAction("actionframe", false)
        self:jumpCoins({label = self:findChild("m_lb_coins"), startCoins = self.m_winCoin, endCoins = self.m_totalToins, maxWidth = 645, duration = 1.0, isMul = true})
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(6/60)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        self.m_mulNode:setVisible(false)
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(46/60)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        effectNode:setVisible(false)
    end)
    local seq = cc.Sequence:create(tblActionList)
    self.m_chengbeiNode:runAction(seq)
end

-- 判断是否可以直接结束
function StarryFestJackpotWinView:judgeCurIsOver()
    if self.m_mul and self.m_mul > 1 then
        return false
    end
    return true
end

---------------------------------------------------------------------------------------------------------
--[[
    自动分享 | 手动分享
]]
function StarryFestJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function StarryFestJackpotWinView:jumpCoinsFinish(_isEnd)
    local endCoins = self.m_winCoin
    if self:judgeCurIsOver() or _isEnd then
        endCoins = self.m_totalToins
        if nil ~= self.m_grandShare then
            self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
        end
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoins(endCoins,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,self.maxWidth)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_Jump_Stop)
        self.m_soundId = nil
    end
end

function StarryFestJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function StarryFestJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return StarryFestJackpotWinView
