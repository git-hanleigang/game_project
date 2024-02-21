---
--xcyy
--2018年5月23日
--JungleJauntFeatureTipControl.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntFeatureTipControl = class("JungleJauntFeatureTipControl")

function JungleJauntFeatureTipControl:initData_(_machine)
    self.m_machine = _machine
end

function JungleJauntFeatureTipControl:playFeatureTipFunc(_func)
    if self.m_machine:getFeatureGameTipChance() then
        local features = self.m_machine.m_runSpinResultData.p_features or {}
        local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
        local game_dice = selfData.game_dice or 0
        if game_dice > 0 then
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_27)
            --播放Base随机预告中奖动画
            self:playFeatureNoticeAni(
                function()
                    if type(_func) == "function" then
                        _func()
                    end
                end
            )
        elseif features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_40)
            -- 播放free触发预告动画
            self:playFreeFeatureNoticeAni(
                function()
                    if type(_func) == "function" then
                        _func()
                    end
                end
            )
        elseif features[2] == SLOTO_FEATURE.FEATURE_RESPIN then
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_81)
            -- 播放respin触发预告动画
            self:playRSFeatureNoticeAni(
                function()
                    if type(_func) == "function" then
                        _func()
                    end
                end
            )
        end
    else
        if type(_func) == "function" then
            _func()
        end
    end
end

function JungleJauntFeatureTipControl:playFreeFeatureNoticeAni(func)
    --动效执行时间
    local aniTime = 0
    --获取父节点
    local parentNode = self.m_machine:findChild("Node_yugao")
    self.m_machine.b_gameTipFlag = true
    --创建对应格式的spine
    if not self.m_freeYG then
        self.m_freeYG = util_spineCreate("JungleJaunt_yugao", true, true)
        parentNode:addChild(self.m_freeYG)
    end
    self.m_freeYG:setVisible(true)
    util_spinePlay(self.m_freeYG, "actionframe_yugao2")
    util_spineEndCallFunc(
        self.m_freeYG,
        "actionframe_yugao2",
        function()
            self.m_freeYG:setVisible(false)
        end
    )

    aniTime = self.m_freeYG:getAnimationDurationTime("actionframe_yugao2")

    self.m_machine:runCsbAction("actionframe_yugao")

    if self.m_machine.b_gameTipFlag then
        --计算延时,预告中奖播完时需要刚好停轮
        local delayTime = self.m_machine:getRunTimeBeforeReelDown()

        --预告中奖时间比滚动时间短,直接返回即可
        if aniTime <= delayTime then
            if type(func) == "function" then
                func()
            end
        else
            self.m_machine:delayCallBack(
                aniTime - delayTime,
                function()
                    if type(func) == "function" then
                        func()
                    end
                end
            )
        end
        return
    end

    if type(func) == "function" then
        func()
    end
end

function JungleJauntFeatureTipControl:playRSFeatureNoticeAni(func)
    --动效执行时间
    local aniTime = 0
    --获取父节点
    local parentNode = self.m_machine:findChild("Node_yugao")
    self.m_machine.b_gameTipFlag = true
    --创建对应格式的spine
    if not self.m_freeYG then
        self.m_freeYG = util_spineCreate("JungleJaunt_yugao", true, true)
        parentNode:addChild(self.m_freeYG)
    end
    self.m_freeYG:setVisible(true)
    util_spinePlay(self.m_freeYG, "actionframe_yugao")
    util_spineEndCallFunc(
        self.m_freeYG,
        "actionframe_yugao",
        function()
            self.m_freeYG:setVisible(false)
        end
    )

    aniTime = self.m_freeYG:getAnimationDurationTime("actionframe_yugao")

    self.m_machine:runCsbAction("actionframe_yugao")

    if self.m_machine.b_gameTipFlag then
        --计算延时,预告中奖播完时需要刚好停轮
        local delayTime = self.m_machine:getRunTimeBeforeReelDown()

        --预告中奖时间比滚动时间短,直接返回即可
        if aniTime <= delayTime then
            if type(func) == "function" then
                func()
            end
        else
            self.m_machine:delayCallBack(
                aniTime - delayTime,
                function()
                    if type(func) == "function" then
                        func()
                    end
                end
            )
        end
        return
    end

    if type(func) == "function" then
        func()
    end
end

function JungleJauntFeatureTipControl:playFeatureNoticeAni(func)
    --动效执行时间
    local aniTime = 0
    --获取父节点
    local parentNode = self.m_machine:findChild("Node_yugao")
    self.m_machine.b_gameTipFlag = true
    --创建对应格式的spine
    if not self.m_baseYG then
        self.m_baseYG = util_spineCreate("JungleJaunt_yujing", true, true)
        parentNode:addChild(self.m_baseYG)
    end
    self.m_baseYG:setVisible(true)
    util_spinePlay(self.m_baseYG, "actionframe")
    util_spineEndCallFunc(
        self.m_baseYG,
        "actionframe",
        function()
            self.m_baseYG:setVisible(false)
        end
    )

    aniTime = self.m_baseYG:getAnimationDurationTime("actionframe")

    if self.m_machine.b_gameTipFlag then
        --计算延时,预告中奖播完时需要刚好停轮
        local delayTime = self.m_machine:getRunTimeBeforeReelDown()

        --预告中奖时间比滚动时间短,直接返回即可
        if aniTime <= delayTime then
            if type(func) == "function" then
                func()
            end
        else
            self.m_machine:delayCallBack(
                aniTime - delayTime,
                function()
                    if type(func) == "function" then
                        func()
                    end
                end
            )
        end
        return
    end

    if type(func) == "function" then
        func()
    end
end

return JungleJauntFeatureTipControl