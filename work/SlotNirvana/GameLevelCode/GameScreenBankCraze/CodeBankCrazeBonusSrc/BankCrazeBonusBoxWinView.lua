---
--xcyy
--2018年5月23日
--BankCrazeBonusBoxWinView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeBonusBoxWinView = class("BankCrazeBonusBoxWinView",util_require("Levels.BaseLevelDialog"))

function BankCrazeBonusBoxWinView:initUI(params)

    -- 是否为金钱箱
    self.m_isGold = params.isGold
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_isManyCoin = params.isManyCoin
    self.m_hideCallFunc = params.hideCallFunc
    self.m_machine = params.machine

    self:createCsbNode("BankCraze/BaoxianguiTanban.csb")

    -- 光
    local lightAni = util_createAnimation("BankCraze_tanban_guang.csb")
    self:findChild("Node_guang"):addChild(lightAni)
    lightAni:runCsbAction("idle", true)

    -- 金银行
    if self.m_isGold then
        self.m_boxSpine = util_spineCreate("BankCraze_tanban_baoxiangui1",true,true)
    else
        self.m_boxSpine = util_spineCreate("BankCraze_tanban_baoxiangui2",true,true)
    end
    self:findChild("Node_spine"):addChild(self.m_boxSpine)

    util_spinePlay(self.m_boxSpine, "start", false)
    util_spineEndCallFunc(self.m_boxSpine, "start", function()
        if not tolua.isnull(self.m_boxSpine) then
            util_spinePlay(self.m_boxSpine, "idle", true)
        end
    end)

    self.m_lb_coins = cc.Label:createWithBMFont("BankCrazeFont/font_6.fnt", "")
    self:findChild("Node_coins"):addChild(self.m_lb_coins)

    self.m_allowClick = false

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

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
function BankCrazeBonusBoxWinView:showView(winCoin)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Show_BoxDialog)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
    end)

    self.maxWidth = 826
    -- 数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Box_Jump_Coins, true)
    self:jumpCoins({label = self.m_lb_coins, endCoins = winCoin, index = 0, totalTime = 0})
end

--[[
    关闭界面
]]
function BankCrazeBonusBoxWinView:showOver()
    self.m_allowClick = false
    if type(self.m_hideCallFunc) == "function" then
        self.m_hideCallFunc()
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Close_BoxDialog)
    self.m_machine:playBottomLight(self.m_winCoin, true)
    self:runCsbAction("over",false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)
end

--[[
    金币跳动
    1. 钱数从最后一位数开始落地，数字逐个出现，直到奖金完全展示出来。
    2. Nearmiss: 
    1）个位数起直到倒数第3位数的数字滚动较快，在1s内完成落地
    2）倒数第二位数滚动速度放缓，2s完成滚动
    3）倒数第一位数滚动速度最慢，3s完成滚动
]]
function BankCrazeBonusBoxWinView:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 2   --持续时间
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local m_index = params.index

    local length = math.floor(math.log10(endCoins)+1)
    
    -- label:setString(endCoins)
    local strlength = label:getStringLength()

    if m_index > length then
        label:stopAllActions()
        label:setString(util_formatCoinsLN(endCoins,50))
        for i=1, strlength do
            local BChar = label:getLetter(i-1)
            BChar:setColor(cc.c3b(255, 255, 255))
        end
        self:jumpCoinsFinish()
        return
    end

    local delayTime = 0
    local refreshTime = 1/60
    local interValTime = 3/(length-2)
    local offsetIndex = length - m_index
    if offsetIndex == length then
        delayTime = 50/60+interValTime
        refreshTime = 1/60
    elseif offsetIndex > 1 then
        delayTime = interValTime
        refreshTime = 1/60
    elseif offsetIndex == 1 then
        delayTime = 3
        refreshTime = 1/20
    end
    local totalTime = params.totalTime + delayTime
    -- local curCoins = 0
    label:stopAllActions()
    
    util_schedule(label,function()
        local totalNum = 0
        if m_index > 0 then
            totalNum = math.mod(endCoins, math.pow(10,(m_index)))

            local strlength = label:getStringLength()
            local curStr = util_formatCoinsLN(totalNum,50)
            local cryLength = strlength - #curStr + 1
            for i=cryLength, strlength do
                local BChar = label:getLetter(i-1)
                BChar:setColor(cc.c3b(255, 255, 255))
            end
        end

        for i=m_index+1, length do
            local randomNum = math.random(1, 9)
            totalNum = totalNum + randomNum* math.pow(10,(i-1))
        end
        
        local curCoins = totalNum

        --每次跳动回调
        if type(perFunc) == "function" then
            perFunc()
        end

        if m_index >= length then
            label:stopAllActions()
            label:setString(util_formatCoinsLN(endCoins,50))
        else
            label:setString(util_formatCoinsLN(curCoins,50))

            local info={label = label,sx = 0.915,sy = 0.915}
            self:updateLabelSize(info,self.maxWidth)

            if not self.m_changeColor then
                self.m_changeColor = true
                local strlength = label:getStringLength()
                for i=1, strlength do
                    local BChar = label:getLetter(i-1)
                    BChar:setColor(cc.c3b(255, 72, 0))
                end
            end
        end
    end, refreshTime)

    performWithDelay(self.m_scWaitNode, function()
        self:jumpCoins({label = label, endCoins = endCoins, index = m_index+1, totalTime = totalTime})
    end, delayTime)
end

--[[
    点击按钮
]]
function BankCrazeBonusBoxWinView:clickFunc(sender)
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

function BankCrazeBonusBoxWinView:jumpCoinsFinish()
    self.m_isJumpOver = true
    self.m_isJumpCoins = false

    local label = self.m_lb_coins
    label:stopAllActions()
    label:setString(util_formatCoinsLN(self.m_winCoin,50))
    local info={label = label,sx = 0.915,sy = 0.915}
    self:updateLabelSize(info,self.maxWidth)

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        --跳动结束音效
        self.m_soundId = nil
    end

    local actName = "actionframe1"
    local idleName = "idle2"
    if self.m_isManyCoin then
        actName = "actionframe2"
        idleName = "idle3"
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_Show_OpenBoxDialog)
    util_spinePlay(self.m_boxSpine, actName, false)
    util_spineEndCallFunc(self.m_boxSpine, actName, function()
        if not tolua.isnull(self.m_boxSpine) then
            util_spinePlay(self.m_boxSpine, idleName, true)
        end
    end)

    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle", true)
        self:playShowBtnAct()
    end)
end

function BankCrazeBonusBoxWinView:playShowBtnAct()
    self:runCsbAction("actionframe2", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle2", true)
    end)
end

return BankCrazeBonusBoxWinView
