---
--xcyy
--2018年5月23日
--DazzlingDiscoJackpotWinView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoJackpotWinView = class("DazzlingDiscoJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 2,
    minor = 3,
    mini = 4
}

local JACKPOT_TYPE = {
    "grand",
    "mega",
    "major",
    "minor",
    "mini",
}
function DazzlingDiscoJackpotWinView:initUI(params)
    local viewType = params.jackpotType
    local machineRootScale = params.machineRootScale
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine

    --黑色遮罩
    self.m_mask = util_createAnimation("DazzlingDisco_mask.csb")
    self:addChild(self.m_mask)

    self.m_spineNode = util_spineCreate("DazzlingDiscoSpineView/JackpotWinView",true,true)
    self:addChild(self.m_spineNode)
    self.m_spineNode:setScale(machineRootScale)
    local skinName = string.upper(viewType)
    self.m_spineNode:setSkin(skinName)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_DazzlingDisco_show_jackpot_wins_"..viewType])

    --创建按钮
    self.m_btn_csb = util_createAnimation("DazzlingDisco_anniu.csb")
    util_spinePushBindNode(self.m_spineNode,"anniu2",self.m_btn_csb)
    -- self:addChild(self.m_btn_csb)

    self.m_node_share = cc.Node:create()
    util_spinePushBindNode(self.m_spineNode,"fenxiang",self.m_node_share)

    --创建角色
    local spine_juese = util_spineCreate("DazzlingDisco_bg",true,true)
    util_spinePlay(spine_juese,"idle5",true)
    util_spinePushBindNode(self.m_spineNode,"juese2",spine_juese)

    self.m_btn_csb:findChild("Button_jackpotstart"):setVisible(false)
    self.m_btn_csb:findChild("Button_socialover"):setVisible(false)
    local btn = self.m_btn_csb:findChild("Button_jackpotover")
    btn:setVisible(true)
    btn:setTouchEnabled(false)
    self:addClick(btn)

    self.m_mask:runCsbAction("animation0")

    local lbl_csb = util_createAnimation("DazzlingDisco_jackpot_coins.csb")
    util_spinePushBindNode(self.m_spineNode,"shuzi2",lbl_csb)
    self.m_lbl_coins = lbl_csb:findChild("m_lb_coins")

    util_spinePlay(self.m_spineNode,"start")
    util_spineEndCallFunc(self.m_spineNode,"start",function(  )
        util_spinePlay(self.m_spineNode,"idle",true)
        self.m_allowClick = true
        btn:setTouchEnabled(true)
    end)

    --创建分享按钮
    self:createGrandShare()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex
    
    self.m_allowClick = false

    self:jumpCoins({
        label = self.m_lbl_coins,
        endCoins = self.m_winCoin,
        maxWidth = 640
    })

    if globalData.slotRunData.m_isAutoSpinAction then
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(btn)
        end,5)
    end
end

--[[
    关闭界面
]]
function DazzlingDiscoJackpotWinView:showOver()
    self.m_allowClick = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_hide_jackpot_wins)
    
    util_spinePlay(self.m_spineNode,"over")
    util_spineEndCallFunc(self.m_spineNode,"over",function(  )
        self:setVisible(false)
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        performWithDelay(self,function(  )
            self:removeFromParent()
        end,0.1)
    end)
end

--[[
    金币跳动
]]
function DazzlingDiscoJackpotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.sound_DazzlingDisco_jackpot_jump_coins
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_DazzlingDisco_jackpot_jump_coins_end
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
function DazzlingDiscoJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    if self:checkShareState() then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)

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
function DazzlingDiscoJackpotWinView:createGrandShare()
    local parent      = self.m_node_share
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function DazzlingDiscoJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self.m_lbl_coins
    label:stopAllActions()
    label:setString(util_formatCoins(self.m_winCoin,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,640)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        if self.m_jumpSoundEnd then
            gLobalSoundManager:playSound(self.m_jumpSoundEnd)
        end
        self.m_soundId = nil
    end
end

function DazzlingDiscoJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function DazzlingDiscoJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return DazzlingDiscoJackpotWinView