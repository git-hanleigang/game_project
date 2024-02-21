---
--smy
--2018年5月24日
--MuchoChilliChooseView.lua
local MuchoChilliChooseView = class("MuchoChilliChooseView",util_require("base.BaseView"))
local PublicConfig = require "MuchoChilliPublicConfig"

function MuchoChilliChooseView:initUI()
    self.m_featureChooseIdx = 1
    self.m_clickHorseSpine = {}
    self.horseSkin = {"lan", "lv", "zi"}
    
    self:createCsbNode("MuchoChilli/Choose.csb")
    self:runCsbAction("start", false)

    self.m_clickHorseSpine[1] = util_spineCreate("MuchoChilliChoose_lan", true, true)
    self:findChild("Node_1"):addChild(self.m_clickHorseSpine[1], 3)

    self.m_clickHorseSpine[2] = util_spineCreate("MuchoChilliChoose_zi", true, true)
    self:findChild("Node_1"):addChild(self.m_clickHorseSpine[2], 1)

    self.m_clickHorseSpine[3] = util_spineCreate("MuchoChilliChoose_lv", true, true)
    self:findChild("Node_1"):addChild(self.m_clickHorseSpine[3], 2)

end

--[[
    开始播放
]]
function MuchoChilliChooseView:beginPlayEffect( )
    if self.m_isAuto then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_bonusFeature_selectView)
    else
        local random = math.random(1, 2)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_MuchoChilli_selectView_start"..random])
    end
    for index = 1, 3 do
        if not self.m_isAuto then
            self.m_Click = true
            --添加点击
            local clickBtn = self:findChild("Panel_"..index)
            self:addClick(clickBtn)
        end
        local actionframeName = "start"
        local idleframeName = "idleframe"
        if self.m_isAuto then
            self.m_clickHorseSpine[index]:setSkin(self.horseSkin[index])
            actionframeName = "start1"
            idleframeName = "idleframe5"
        end

        util_spinePlay(self.m_clickHorseSpine[index], actionframeName, false)
        util_spineEndCallFunc(self.m_clickHorseSpine[index], actionframeName ,function ()
            util_spinePlay(self.m_clickHorseSpine[index], idleframeName, true)
            if index == 1 then
                if self.m_isAuto then
                    self:playAutoEffect()
                else
                    self:playCanClickEffect()
                    self.m_Click = false
                end
            end
        end)
    end
end
--[[
    自动消失
]]
function MuchoChilliChooseView:playAutoEffect( )
    performWithDelay(self, function()
        self:closeUi(function()
            self:showReward()
        end)
    end, 0.5)
end
--[[
    随机播放可点击动画
]]
function MuchoChilliChooseView:playCanClickEffect( )
    if self.m_Click then
        return 
    end

    local random = math.random(1, 3)
    util_spinePlay(self.m_clickHorseSpine[random], "idleframe2", false)
    util_spineEndCallFunc(self.m_clickHorseSpine[random], "idleframe2" ,function ()
        util_spinePlay(self.m_clickHorseSpine[random], "idleframe", true)
        self:playCanClickEffect()
    end)

end

function MuchoChilliChooseView:onExit(  )
    gLobalNoticManager:removeAllObservers(self)
end


function MuchoChilliChooseView:checkAllBtnClickStates()
    local notClick = false

    if self.m_Click then
        notClick = true
    end

    return notClick
end

--默认按钮监听回调
function MuchoChilliChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self:checkAllBtnClickStates() then
        -- 网络消息回来之前 所有按钮都不允许点击
        return
    end

    self.m_Click = true

    if name == "Panel_1" then
        self:clickEffect(1)
    elseif name == "Panel_2" then
        self:clickEffect(2)
    elseif name == "Panel_3" then
        self:clickEffect(3)
    end
end

--[[
    点击之后的动效
]]
function MuchoChilliChooseView:clickEffect(_index)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_click)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_selectView_click_fankui)

    self:changeHorseSkin(_index)

    util_spinePlay(self.m_clickHorseSpine[_index], "actionframe")
    util_spineEndCallFunc(self.m_clickHorseSpine[_index], "actionframe", function()
        local random = math.random(1, 2)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_MuchoChilli_selectView_guangIdle_"..random])

        util_spinePlay(self.m_clickHorseSpine[_index], "idleframe4")
        
        performWithDelay(self, function()
            self:closeUi(function()
                self:showReward()
            end)
        end, 1)
    end)
    
    for index=1, 3 do
        if index ~= _index then
            self.m_clickHorseSpine[index]:setSkin(self.horseSkin[1])
            table.remove(self.horseSkin, 1)
            util_spinePlay(self.m_clickHorseSpine[index], "dark")
        end
    end
end

--[[
    设置马的皮肤
]]
function MuchoChilliChooseView:changeHorseSkin(_index)
    local reSpinMode = nil
    if self.m_machine.m_runSpinResultData and self.m_machine.m_runSpinResultData.p_selfMakeData and self.m_machine.m_runSpinResultData.p_selfMakeData.reSpinMode then
        reSpinMode = self.m_machine.m_runSpinResultData.p_selfMakeData.reSpinMode
    end
    local skinIndex = 1
    if reSpinMode == "bonusBoost" then
        skinIndex = 3
    elseif reSpinMode == "doubleSet" then
        skinIndex = 1
    elseif reSpinMode == "extraSpin" then
        skinIndex = 2
    end
    
    self.m_clickHorseSpine[_index]:setSkin(self.horseSkin[skinIndex])

    for i,v in ipairs(self.horseSkin) do
        if i == skinIndex then
            table.remove(self.horseSkin, i)
        end
    end
end

--弹出结算奖励
function MuchoChilliChooseView:showReward()
    if self.m_bonusEndCall then
        self.m_bonusEndCall()
    end
end

function MuchoChilliChooseView:setEndCall(machine, func, isAuto)
    self.m_machine = machine
    self.m_bonusEndCall = func
    self.m_isAuto = isAuto
end

function MuchoChilliChooseView:closeUi(func)
    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        1
    )
end
return MuchoChilliChooseView