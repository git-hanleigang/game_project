---
--xcyy
--2018年5月23日
--TheHonorOfZorroHumanNode.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroHumanNode = class("TheHonorOfZorroHumanNode",util_require("base.BaseView"))


function TheHonorOfZorroHumanNode:initUI(params)
    self.m_machine = params.machine
    self.m_spine = util_spineCreate("Socre_TheHonorOfZorro_juese",true,true)
    self:addChild(self.m_spine)

    self:runIdleAni()

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0,0)
    layout:setContentSize(CCSizeMake(display.width / 2,display.height * 0.4))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    --显示区域
    -- layout:setBackGroundColor(cc.c3b(255, 0, 0))
    -- layout:setBackGroundColorOpacity(255)
    -- layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
end

--[[
    idle动画
]]
function TheHonorOfZorroHumanNode:runIdleAni()
    -- local aniName = "idleframe"
    -- local randNum = math.random(1,10)
    -- if randNum <= 2 then
    --     aniName = "idleframe2"
    -- end
    -- self:stopAllActions()
    -- util_spinePlay(self.m_spine,aniName)

    -- local time = self.m_spine:getAnimationDurationTime(aniName)
    -- performWithDelay(self,function ()
    --     self:runIdleAni()
    -- end,time)
    util_spinePlay(self.m_spine,"idleframe",true)
end

--[[
    点击反馈动画
]]
function TheHonorOfZorroHumanNode:runClickFeedBackAni(func)
    self:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_click_human)
    util_spinePlay(self.m_spine,"actionframe")
    util_spineEndCallFunc(self.m_spine,"actionframe",function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    大赢时动作
]]
function TheHonorOfZorroHumanNode:runBigWinAction(func)
    self.m_isWaitting = true
    self:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_human_big_win_ani)
    if math.random(1,10) <= 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_human_big_win_ani_1)
    end
    util_spinePlay(self.m_spine,"actionframe2")
    util_spineEndCallFunc(self.m_spine,"actionframe2",function()
        self.m_isWaitting = false
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    预告中奖动画
]]
function TheHonorOfZorroHumanNode:runNoticeAni(keyFunc,endfunc)
    self.m_isWaitting = true
    self:stopAllActions()
    util_spinePlay(self.m_spine,"yugao")
    util_spineFrameCallFunc(self.m_spine,"yugao","shijian",function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
        self.m_machine:delayCallBack(10 / 30,function()
            if type(endfunc) == "function" then
                endfunc()
            end
        end)
    end,function()
        self.m_isWaitting = false
        self:runIdleAni()
        
    end)

    
end

--[[
    触发玩法时动作
]]
function TheHonorOfZorroHumanNode:runTriggerAni(func)
    self.m_isWaitting = true
    self:stopAllActions()
    util_spinePlay(self.m_spine,"actionframe3")
    util_spineEndCallFunc(self.m_spine,"actionframe3",function()
        self.m_isWaitting = false
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    free中获得jackpot时动作
]]
function TheHonorOfZorroHumanNode:getJackpotInFree(func)
    self.m_isWaitting = true
    self:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_human_out)
    util_spinePlay(self.m_spine,"over")
    util_spineEndCallFunc(self.m_spine,"over",function()
        self.m_isWaitting = false
        -- self:runIdleAni()
        self.m_spine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    获得jackpot后人物回来
]]
function TheHonorOfZorroHumanNode:humanBackAfterJackpot(func)
    self.m_spine:setVisible(true)
    self.m_isWaitting = true
    self:stopAllActions()
    util_spinePlay(self.m_spine,"start")
    util_spineEndCallFunc(self.m_spine,"start",function()
        self.m_isWaitting = false
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--默认按钮监听回调
function TheHonorOfZorroHumanNode:clickFunc(sender)
    if self.m_isWaitting then
        return
    end
    self.m_isWaitting = true

    self:runClickFeedBackAni(function()
        self:runIdleAni()
        self.m_isWaitting = false
    end)
end



return TheHonorOfZorroHumanNode