---
--xcyy
--2018年5月23日
--ChameleonRichesBugItem.lua
local PublicConfig = require "ChameleonRichesPublicConfig"
local ChameleonRichesBugItem = class("ChameleonRichesBugItem",util_require("base.BaseView"))


function ChameleonRichesBugItem:initUI(params)
    self.m_machine = params.machine

    self.m_spine = util_spineCreate("Socre_ChameleonRiches_Bonus_2",true,true)
    self:addChild(self.m_spine)

    self.m_csbNode_red = util_createAnimation("ChameleonRiches_bugs_red.csb")
    util_spinePushBindNode(self.m_spine,"shuzi",self.m_csbNode_red)

    self.m_csbNode_gold = util_createAnimation("ChameleonRiches_bugs_gold.csb")
    util_spinePushBindNode(self.m_spine,"shuzi_j",self.m_csbNode_gold)

    self.m_isBigWin = false
end

--[[
    初始化spine动画
]]
function ChameleonRichesBugItem:initSpineUI()
    
end

--[[
    设置金币显示
]]
function ChameleonRichesBugItem:setCoins(coins)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local winRatio = coins / lineBet
    local isBigWin = winRatio >= self.m_machine.m_BigWinLimitRate

    if isBigWin ~= self.m_isBigWin then
        self.m_isBigWin = isBigWin
        self.m_isIdle = false
        self:runIdleAni()
    end

    self.m_coins = coins


    self.m_csbNode_red:findChild("m_lb_coins"):setString(util_formatCoins(coins,3))
    self.m_csbNode_gold:findChild("m_lb_coins"):setString(util_formatCoins(coins,3))
end

--[[
    idle时间线
]]
function ChameleonRichesBugItem:runIdleAni()
    if self.m_isIdle then
        return
    end
    local aniName = "idleframe"
    if self.m_isBigWin then
        aniName = "idleframe_y"
    end
    self.m_isIdle = true
    util_spinePlay(self.m_spine,aniName,true)
end

--[[
    生成动画
]]
function ChameleonRichesBugItem:runStartAni(func)
    local aniName = "start"
    if self.m_isBigWin then
        aniName = "start_y"
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_gold_bug_in)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_red_bug_in)
    end
    self.m_isIdle = false
    util_spinePlay(self.m_spine,aniName)
    util_spineEndCallFunc(self.m_spine,aniName,function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
    local aniTime = self.m_spine:getAnimationDurationTime(aniName)
    return aniTime
end

--[[
    切换动画
]]
function ChameleonRichesBugItem:runSwitchAni(index,func)

    local aniName = "switch1"
    if index >= 5 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_bug_fly)
        aniName = "switch2"
    end
    if self.m_isBigWin then
        aniName = aniName.."_y"
    end
    self.m_isIdle = false
    util_spinePlay(self.m_spine,aniName)
    util_spineEndCallFunc(self.m_spine,aniName,function()
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_spine:getAnimationDurationTime(aniName)
    return aniTime
end


--[[
    收集时idle
]]
function ChameleonRichesBugItem:runCollectIdle()
    local aniName = "idleframe2"
    if self.m_isBigWin then
        aniName = "idleframe2_y"
    end
    util_spinePlay(self.m_spine,aniName,true)
end

return ChameleonRichesBugItem