---
--xcyy
--2018年5月23日
--OwlsomeWizardRespinBar.lua
local PublicConfig = require "OwlsomeWizardPublicConfig"
local OwlsomeWizardRespinBar = class("OwlsomeWizardRespinBar",util_require("base.BaseView"))


function OwlsomeWizardRespinBar:initUI()

    self:createCsbNode("OwlsomeWizard_respintotalwin.csb")

    self.m_respinBar = util_createAnimation("OwlsomeWizard_respin_bar.csb")
    self:findChild("Node_respin_bar"):addChild(self.m_respinBar)
    self.m_winCoins = 0
    self.m_totalCount = 0
end

--[[
    刷新spin次数
]]
function OwlsomeWizardRespinBar:updateRespinCount(curCount,totalCount,isInit)
    self.m_respinBar:findChild("m_lb_num1"):setString(curCount)
    self.m_respinBar:findChild("m_lb_num2"):setString(totalCount)

    if not isInit and totalCount > self.m_totalCount then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_add_wheel_spin_count)
        self.m_respinBar:runCsbAction("add")
        local csbNode = util_createAnimation("OwlsomeWizard_respin_bar_num.csb")
        self.m_respinBar:findChild("Node_shuzi"):addChild(csbNode)
        local addCount = totalCount - self.m_totalCount
        for index = 1,3 do
            local addNum = csbNode:findChild("OwlsomeWizard_zi"..index)
            if addNum then
                addNum:setVisible(index == addCount)
            end
        end
        csbNode:runCsbAction("add",false,function()
            csbNode:removeFromParent()
        end)
    end

    self.m_totalCount = totalCount
end

--[[
    刷新总赢钱
]]
function OwlsomeWizardRespinBar:updateTotalWin(winCoins,isInit,func)
    local m_lb_coins = self:findChild("m_lb_coins")
    if winCoins == 0 then
        m_lb_coins:setString("")
    else
        if isInit then
            m_lb_coins:setString(util_formatCoins(winCoins,50))
            local info = {label = m_lb_coins, sx = 1, sy = 1}
            self:updateLabelSize(info, 476)
        else
            local totalBet = globalData.slotRunData:getCurTotalBet()
            local rate = (winCoins - self.m_winCoins) / totalBet
            local time = 1.5
            if rate >= 5 and rate < 15 then
                time = 2.5
            elseif rate >= 15 then
                time = 4
            end
            self:jumpCoins({
                label = self:findChild("m_lb_coins"),
                startCoins = self.m_winCoins,
                endCoins = winCoins,
                duration = time,
                maxWidth = 476,
                endFunc = func
            })
        end
        
    end
    self.m_jumpEndFunc = func

    self.m_winCoins = winCoins

end

--[[
    金币跳动
]]
function OwlsomeWizardRespinBar:jumpCoins(params)
    local label = params.label
    if not label then
        return
    end

    self:runCsbAction("actionframe",true)
    --解析参数
    local startCoins = params.startCoins or 0 -- 起始金币
    local endCoins = params.endCoins or 0   --结束金币数
    local duration = params.duration or 1   --持续时间
    local maxWidth = params.maxWidth or 476 --lable最大宽度
    local perFunc = params.perFunc  --每次跳动回调
    local endFunc = params.endFunc  --结束回调
    local jumpSound = PublicConfig.SoundConfig.sound_OwlsomeWizard_jump_respin_coins --跳动音效
    local jumpSoundEnd --= PublicConfig.SoundConfig.sound_OwlsomeWizard_jump_coins_end --跳动结束音效

    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - startCoins) / (120  * duration)   --1秒跳动120次

    -- local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    -- coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = startCoins
    

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
            
            self:jumpEndFunc()
        else
            label:setString(util_formatCoins(curCoins,50))

            local info={label = label,sx = 1,sy = 1}
            self:updateLabelSize(info,maxWidth)
        end

    end,1 / 120)
end

--[[
    跳动结束
]]
function OwlsomeWizardRespinBar:jumpEndFunc()
    local label = self:findChild("m_lb_coins")
    label:stopAllActions()
    label:setString(util_formatCoins(self.m_winCoins,50))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,476)
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
    end

    self:runCsbAction("idle",true)
    --结束回调
    if type(self.m_jumpEndFunc) == "function" then
        self.m_jumpEndFunc()
        self.m_jumpEndFunc = nil
    end
end

--[[
    显示动画
]]
function OwlsomeWizardRespinBar:runShowAni(func)
    self:setVisible(true)
    self:runCsbAction("show",false,func)
end

--[[
    隐藏动画
]]
function OwlsomeWizardRespinBar:runOverAni(func)
    self:runCsbAction("over",false,function()
        self:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    结算动画
]]
function OwlsomeWizardRespinBar:runWinCoinsAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_show_respin_win_coins)
    self:runCsbAction("jiesuan",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end


return OwlsomeWizardRespinBar