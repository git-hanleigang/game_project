---
--xcyy
--2018年5月23日
--GhostCaptainJackpotWinView.lua
local PublicConfig = require "GhostCaptainPublicConfig"
local GhostCaptainJackpotWinView = class("GhostCaptainJackpotWinView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}
function GhostCaptainJackpotWinView:initUI(params)
    --jackpot类型统一转化为小写
    local viewType = string.lower(params.jackpotType) 
    self.m_winCoin = params.winCoin
    self.m_wheelType = params.wheelType
    self.m_endFunc = params.func
    self.m_viewType = viewType
    self.m_machine = params.machine
    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex

    if self.m_jackpotIndex == 1 then
        self:createCsbNode("GhostCaptain/JackpotWinView_grand.csb")
    else
        self:createCsbNode("GhostCaptain/JackpotWinView.csb")
    end

    --创建分享按钮
    self:createGrandShare()
    
    --设置控件显示
    if self.m_jackpotIndex ~= 1 then
        for jpType,index in pairs(JACKPOT_INDEX) do
            local node = self:findChild("Node_"..jpType)
            if node then
                node:setVisible(viewType == jpType)
            end

            local nodeTitle = self:findChild("Node_title_"..jpType)
            if nodeTitle then
                nodeTitle:setVisible(viewType == jpType)
            end
        end
    end

    -- 成倍
    if self.m_wheelType and self.m_wheelType == 2 then
        self.m_chengbeiNode = util_createAnimation("GhostCaptain_tb_wenzi.csb")
        self:findChild("Node_wenzi"):addChild(self.m_chengbeiNode)

        self.m_chengbeiEffectNode = util_createAnimation("GhostCaptain_tb_chengbeiFK.csb")
        self:findChild("Node_12"):addChild(self.m_chengbeiEffectNode, 100)
    end

    -- 光
    self.m_guangNode = util_createAnimation("Socre_GhostCaptain_tb_guang2.csb")
    self:findChild("Node_guang"):addChild(self.m_guangNode)

    -- 按钮扫光
    self.m_btnGuangSpine = util_spineCreate("GhostCaptain_tb_sg",true,true)
    self:findChild("Node_sg"):addChild(self.m_btnGuangSpine)

    self.m_guangNode:runCsbAction("idleframe", true)
    util_spinePlay(self.m_btnGuangSpine, "idle2", true)

    self.m_viewBgSpine = util_spineCreate("GhostCaptain_tb_3",true,true)
    self:findChild("Node_ren"):addChild(self.m_viewBgSpine)
    if self.m_jackpotIndex ~= 1 then
        util_spinePlay(self.m_viewBgSpine, "5_start", false)
    else
        util_spinePlay(self.m_viewBgSpine, "3_start", false)
    end

    self.m_allowClick = false
    if self.m_wheelType and self.m_wheelType == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_GhostCaptain_jackpotView_start"..self.m_jackpotIndex])
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_GhostCaptain_jackpotView_start"..self.m_jackpotIndex])
    end
    
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
    播放成倍动画
]]
function GhostCaptainJackpotWinView:playChengBeiEffect(winCoin)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_wheel_jackpot_mul)
    self.m_chengbeiNode:runCsbAction("actionframe", false)
    local endPos = util_convertToNodeSpace(self:findChild("Node_12"), self.m_chengbeiNode:getParent())
    local seq = cc.Sequence:create({
        cc.EaseSineOut:create(cc.MoveTo:create(12/60, endPos)),
    })
    self.m_chengbeiNode:runAction(seq)
    performWithDelay(self,function(  )
        self.m_chengbeiEffectNode:runCsbAction("actionframe2", false)
        performWithDelay(self,function(  )
            self.m_allowClick = true
            self:jumpCoins({
                label = self:findChild("m_lb_coins"),
                startCoins = winCoin/2,
                endCoins = winCoin,
                maxWidth = 740
            })
        end,10/60)
    end,41/60)

    performWithDelay(self,function(  )
        self.m_chengbeiNode:setVisible(false)
    end,45/60)
end

--[[
    显示界面
]]
function GhostCaptainJackpotWinView:showView(winCoin)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
        if self.m_jackpotIndex ~= 1 then
            util_spinePlay(self.m_viewBgSpine, "5_idle", true)
        else
            util_spinePlay(self.m_viewBgSpine, "3_idle", true)
        end

        if self.m_wheelType and self.m_wheelType == 2 then
            self:playChengBeiEffect(winCoin)
        else
            self.m_allowClick = true
        end
    end)

    if self.m_wheelType and self.m_wheelType == 2 then
        local label = self:findChild("m_lb_coins")
        label:setString(util_formatCoins(winCoin/2,50))

        local info={label = label,sx = 0.85,sy = 0.85}
        self:updateLabelSize(info,764)
    else
        self:jumpCoins({
            label = self:findChild("m_lb_coins"),
            endCoins = winCoin,
            maxWidth = 740
        })
    end
end

--[[
    关闭界面
]]
function GhostCaptainJackpotWinView:showOver()
    self.m_allowClick = false
    if self.m_jackpotIndex ~= 1 then
        util_spinePlay(self.m_viewBgSpine, "5_over", false)
    else
        util_spinePlay(self.m_viewBgSpine, "3_over", false)
    end
    if self.m_wheelType and self.m_wheelType == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_jackpotView_double_over)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_jackpotView_over)
    end

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
function GhostCaptainJackpotWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.sound_GhostCaptain_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_GhostCaptain_jump_coins_end --跳动结束音效
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
            self:jumpCoinsFinish()
            --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end

        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 0.85,sy = 0.85}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    点击按钮
]]
function GhostCaptainJackpotWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    if PublicConfig.SoundConfig.sound_GhostCaptain_click then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_click)
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
function GhostCaptainJackpotWinView:createGrandShare()
    local parent      = self:findChild("Node_share")
    if parent then
        parent:removeAllChildren()
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", {machine = self.m_machine})
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function GhostCaptainJackpotWinView:jumpCoinsFinish()
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
    local info={label = label,sx = 0.85,sy = 0.85}
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

function GhostCaptainJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function GhostCaptainJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return GhostCaptainJackpotWinView