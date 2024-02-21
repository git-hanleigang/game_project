---
--xcyy
--2018年5月23日
--BankCrazeBonusBagWinView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeBonusBagWinView = class("BankCrazeBonusBagWinView",util_require("Levels.BaseLevelDialog"))

function BankCrazeBonusBagWinView:initUI(params)

    -- 是否为金钱袋
    self.m_isGold = params.isGold
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_hideCallFunc = params.hideCallFunc
    self.m_machine = params.machine

    self:createCsbNode("BankCraze/QiandaiTanban.csb")

    -- 光
    local lightAni = util_createAnimation("BankCraze_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(lightAni)
    lightAni:runCsbAction("idle", true)

    -- 金银行
    if self.m_isGold then
        self.m_badSpine = util_spineCreate("BankCraze_tanban_qiandai1",true,true)
    else
        self.m_badSpine = util_spineCreate("BankCraze_tanban_qiandai2",true,true)
    end
    self:findChild("Node_spine"):addChild(self.m_badSpine)

    util_spinePlay(self.m_badSpine, "start", false)
    util_spineEndCallFunc(self.m_badSpine, "start", function()
        if not tolua.isnull(self.m_badSpine) then
            util_spinePlay(self.m_badSpine, "idle", true)
        end
    end)

    self.m_allowClick = false

    self:showView(self.m_winCoin)

    if globalData.slotRunData.m_isAutoSpinAction then --自动spin 5s后自动点击一次按钮
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            wait_node:removeFromParent()
            self:clickFunc(self:findChild("Button"))
        end,5)
    end

    util_setCascadeOpacityEnabledRescursion(self, true)
end

--[[
    显示界面
]]
function BankCrazeBonusBagWinView:showView(winCoin)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Show_BadDialog)
    self:runCsbAction("start",false,function()
        self.m_allowClick = true
        self:runCsbAction("idle",true)
    end)

    self.maxWidth = 826
    self:jumpCoinsFinish()
    -- self:jumpCoins({label = self:findChild("m_lb_coins"), endCoins = winCoin, maxWidth = 826})
end

--[[
    关闭界面
]]
function BankCrazeBonusBagWinView:showOver()
    self.m_allowClick = false
    if type(self.m_hideCallFunc) == "function" then
        self.m_hideCallFunc()
    end
    self.m_machine:playBottomLight(self.m_winCoin, true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Close_BadDialog)
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
function BankCrazeBonusBagWinView:jumpCoins(params)
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
    local jumpSound = PublicConfig.SoundConfig.sound_BankCraze_jump_coins --跳动音效
    local jumpSoundEnd = PublicConfig.SoundConfig.sound_BankCraze_jump_coins_end --跳动结束音效
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

    -- 数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Box_Jump_Coins)
    
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
            local info={label = label,sx = 0.915,sy = 0.915}
            self:updateLabelSize(info,maxWidth)
        end
    end, 1/60)
end

--[[
    点击按钮
]]
function BankCrazeBonusBagWinView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    --点击音效
    if PublicConfig.SoundConfig.sound_BankCraze_click then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BankCraze_click)
    end

    --跳动金币数还没跳完
    if self.m_isJumpCoins and not self.m_isJumpOver  then

        self:jumpCoinsFinish()
        return
    end

    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end

    self:showOver()
end

---------------------------------------------------------------------------------------------------------

function BankCrazeBonusBagWinView:jumpCoinsFinish()
    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoinsLN(self.m_winCoin,50))
    local info={label = label,sx = 0.915,sy = 0.915}
    self:updateLabelSize(info,self.maxWidth)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        self.m_soundId = nil
    end
end

return BankCrazeBonusBagWinView
