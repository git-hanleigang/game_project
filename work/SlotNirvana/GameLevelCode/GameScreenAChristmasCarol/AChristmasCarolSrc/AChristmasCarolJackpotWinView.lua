---
--xcyy
--2018年5月23日
--AChristmasCarolJackpotWinView.lua
local PublicConfig = require "AChristmasCarolPublicConfig"
local AChristmasCarolJackpotWinView = class("AChristmasCarolJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}
function AChristmasCarolJackpotWinView:initUI(params)
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_machine = params.machine

    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    if jackpotIndex == 1 then
        self:createCsbNode("AChristmasCarol/JackpotGrandWinView.csb")
        -- 添加光
        local guangNode = util_createAnimation("AChristmasCarol/ReSpinOver_guang.csb")
        self:findChild("Node_guang"):addChild(guangNode)
        guangNode:runCsbAction("idle", true)
        
        -- 角色
        local roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
        self:findChild("Node_juese1"):addChild(roleSpine)
        util_spinePlay(roleSpine, "idleframe_tanban7", true)
        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_juese1"), true)
        util_setCascadeColorEnabledRescursion(self:findChild("Node_juese1"), true)

        local role2Spine = util_spineCreate("AChristmasCarol_base_npc2", true, true)
        self:findChild("Node_juese2"):addChild(role2Spine)
        util_spinePlay(role2Spine, "idleframe_tanban4", true)
        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_juese2"), true)
        util_setCascadeColorEnabledRescursion(self:findChild("Node_juese2"), true)
    else
        self:createCsbNode("AChristmasCarol/JackpotWinView.csb")

        -- 添加光
        local guangNode = util_createAnimation("AChristmasCarol/JackpotWinView_guang.csb")
        self:findChild("Node_guang"):addChild(guangNode)
        guangNode:runCsbAction("idle", true)

        self:findChild("Node_mini"):setVisible(jackpotIndex == 4)
        self:findChild("Node_minor"):setVisible(jackpotIndex == 3)
        self:findChild("Node_major"):setVisible(jackpotIndex == 2)

        -- 角色
        local roleSpine = util_spineCreate("AChristmasCarol_base_juese", true, true)
        self:findChild("Node_juese"..jackpotIndex):addChild(roleSpine)
        if jackpotIndex == 3 then
            util_spinePlay(roleSpine, "idleframe_tanban10", true)
        elseif jackpotIndex == 2 then
            util_spinePlay(roleSpine, "idleframe_tanban9", true)
        elseif jackpotIndex == 4 then
            util_spinePlay(roleSpine, "idleframe_tanban8", true)
        end
        
        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_juese"..jackpotIndex), true)
        util_setCascadeColorEnabledRescursion(self:findChild("Node_juese"..jackpotIndex), true)
    end
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_guang"), true)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_AChristmasCarol_jackpotView"..jackpotIndex])
    --创建分享按钮
    self:createGrandShare()

    self.m_allowClick = false

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then --自动spin 5s后自动点击一次按钮
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(self:findChild("Button"))
        end,10)
    end
end


--[[
    显示界面
]]
function AChristmasCarolJackpotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self:jumpCoins({
        label = self:findChild("m_lb_coins"),
        endCoins = winCoin,
        maxWidth = 628
    })
end

--[[
    关闭界面
]]
function AChristmasCarolJackpotWinView:showOver()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AChristmasCarol_jackpotView_over)

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
function AChristmasCarolJackpotWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = tonumber(tostring(params.startCoins)) or 0 -- 起始金币
    local endCoins = tonumber(tostring(params.endCoins)) or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local maxWidth = params.maxWidth or 600 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = PublicConfig.SoundConfig.sound_AChristmasCarol_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_AChristmasCarol_jump_coins_end --跳动结束音效
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
            label:setString(util_formatCoins(curCoins,30))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function AChristmasCarolJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    if PublicConfig.SoundConfig.sound_AChristmasCarol_click then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_AChristmasCarol_click)
    end
    

    if self:checkShareState() then
        return
    end

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then

        self:jumpCoinsFinish()
        if not globalData.slotRunData.m_isAutoSpinAction then
            return
        end
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
function AChristmasCarolJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function AChristmasCarolJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end

    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,self.m_jackpotIndex)

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoins(self.m_winCoin,30))
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

function AChristmasCarolJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function AChristmasCarolJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return AChristmasCarolJackpotWinView