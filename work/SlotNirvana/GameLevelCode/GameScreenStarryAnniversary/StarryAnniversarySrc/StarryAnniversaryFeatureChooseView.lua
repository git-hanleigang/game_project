---
--smy
--2018年5月24日
--StarryAnniversaryFeatureChooseView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local StarryAnniversaryFeatureChooseView = class("StarryAnniversaryFeatureChooseView",util_require("base.BaseView"))
local PublicConfig = require "StarryAnniversaryPublicConfig"
StarryAnniversaryFeatureChooseView.m_choseFsCallFun = nil
StarryAnniversaryFeatureChooseView.m_choseRespinCallFun = nil
StarryAnniversaryFeatureChooseView.m_isTouch = nil
StarryAnniversaryFeatureChooseView.m_chooseList = {}
StarryAnniversaryFeatureChooseView.m_chooseRoleList = {9, 8, 7, 6}

function StarryAnniversaryFeatureChooseView:initUI()
    self.m_featureChooseIdx = 1
    
    self:createCsbNode("StarryAnniversary/ChooseLayer.csb")

    for index = 1, 4 do
        self.m_chooseList[index] = util_spineCreate("Socre_StarryAnniversary_"..self.m_chooseRoleList[index], true, true)
        self:findChild("Role"..index):addChild(self.m_chooseList[index])
        self:findChild("Role"..index):setZOrder(index)
        util_spinePlay(self.m_chooseList[index], "idleframe2", false)

        self.m_chooseList[index].guang = util_createAnimation("StarryAnniversary_ChooseLayer_effect.csb")
        self:findChild("Role"..index):addChild(self.m_chooseList[index].guang)
        self.m_chooseList[index].guang:findChild("Particle_1"):setVisible(false)
        performWithDelay(self, function()
            self:playRoleIdle(self.m_chooseList[index].guang)
        end, (index - 1) * 40/60)

        --添加点击
        local clickBtn = self:findChild("Panel_"..index)
        self:addClick(clickBtn)
        clickBtn:setTouchEnabled(false)

        util_setCascadeOpacityEnabledRescursion(self:findChild("Role"..index), true)
        util_setCascadeColorEnabledRescursion(self:findChild("Role"..index), true)
    end

end

--[[
    播放扫光
]]
function StarryAnniversaryFeatureChooseView:playRoleIdle(_node)
    if self.m_isTouch then
        return
    end
    
    _node:runCsbAction("idle", false)
    performWithDelay(self, function()
        self:playRoleIdle(_node)
    end, 4 * 40/60)
end

function StarryAnniversaryFeatureChooseView:onEnter()
    gLobalSoundManager:stopBgMusic()
end

function StarryAnniversaryFeatureChooseView:onExit(  )

end

-- 设置回调函数
function StarryAnniversaryFeatureChooseView:setChoseCallFun(choseFs, choseRespin)
    self.m_choseFsCallFun = choseFs
    self.m_choseRespinCallFun = choseRespin
end

-- 点击函数
function StarryAnniversaryFeatureChooseView:clickFunc(sender)

    if self.m_isTouch == true then
        return
    end
    self.m_isTouch = true
    
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end

-- 点击
function StarryAnniversaryFeatureChooseView:clickButton_CallFun(name)
    local tag
    if name == "Panel_1" then
        tag = 1
    elseif name == "Panel_2" then
        tag = 2
    elseif name == "Panel_3" then
        tag = 3
    elseif name == "Panel_4" then
        tag = 4
    end
    self.m_featureChooseIdx = tag

    for index = 1, 4 do
        if index == tag then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_StarryAnniversary_selectView_select"..index])
            self:findChild("Role"..index):setZOrder(10)
            util_spinePlay(self.m_chooseList[index], "actionframe2", false)
            performWithDelay(self, function()
                self:choseOver()
            end, 2)
            local Particle = self.m_chooseList[index].guang:findChild("Particle_1")
            if Particle then
                Particle:setVisible(true)
                Particle:resetSystem()
            end
            self.m_chooseList[index].guang:runCsbAction("actionframe", false)
        else
            util_spinePlay(self.m_chooseList[index], "dark", false)
            self.m_chooseList[index].guang:runCsbAction("idle1", false)
        end
    end

end

-- 点击结束
function StarryAnniversaryFeatureChooseView:choseOver( )
    self:initGameOver()
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function StarryAnniversaryFeatureChooseView:initViewData(_machine, _func)
    self.machine = _machine
    performWithDelay(self, function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_selectView_start)
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
            for index = 1, 4 do
                local clickBtn = self:findChild("Panel_"..index)
                clickBtn:setTouchEnabled(true)
            end
        end)
    end, 0.5)

    self.m_callFunc = _func
end

--初始化游戏结束状态 子类调用
function StarryAnniversaryFeatureChooseView:initGameOver()
    if self.m_callFunc then
        self.m_callFunc(self.m_featureChooseIdx)
    end
end

function StarryAnniversaryFeatureChooseView:closeView(_func)
    local guoChangCallBack = function()
        if _func then
            _func()
        end
        performWithDelay(self,function()      -- 下一帧 remove spine 不然会崩溃
            self:removeFromParent()
        end,0.1)
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_selectView_over)
    self:runCsbAction("over", false, function()
        guoChangCallBack()
    end)
end

return StarryAnniversaryFeatureChooseView