---
--xcyy
--2018年5月23日
--TheHonorOfZorroCollectBar.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroCollectBar = class("TheHonorOfZorroCollectBar",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_TIP       =       1001

function TheHonorOfZorroCollectBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("TheHonorOfZorro_base_bar.csb")
    self.m_lockStatus = false

    --粒子动画
    self.m_particle = self:findChild("Particle_1")
    if self.m_particle then
        self.m_particle:setVisible(false)
    end

    --收集进度点
    self.m_collectItems = {}
    for index = 1,5 do
        local item = util_createAnimation("TheHonorOfZorro_basebar_collect.csb")
        self:findChild("Node_collect_"..index):addChild(item)
        self.m_collectItems[index] = item

        for iCount = 1,2 do
            local particle = item:findChild("Particle_"..iCount)
            if particle then
                particle:setVisible(false)
            end
        end
    end

    --锁定背景
    self.m_lockBg = util_spineCreate("TheHonorOfZorro_basebar_jindutiao",true,true)
    self:findChild("Node_bu"):addChild(self.m_lockBg)

    self.m_helpBtn = util_createAnimation("TheHonorOfZorro_basebar_i.csb")
    self:findChild("Node_i"):addChild(self.m_helpBtn)
    local btn = self.m_helpBtn:findChild("Button_1")
    btn:setTag(BTN_TAG_TIP)
    self:addClick(btn)

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(550,80))
    layout:setTouchEnabled(true)
    layout:setTag(BTN_TAG_TIP)
    self:addClick(layout)

    
end

function TheHonorOfZorroCollectBar:onEnter()
    TheHonorOfZorroCollectBar.super.onEnter(self)
    self.m_tip = util_createAnimation("TheHonorOfZorro_basebar_tips.csb")
    local pos = util_convertToNodeSpace(self.m_helpBtn:findChild("Node_1"),self.m_machine.m_effectNode)
    self.m_machine.m_effectNode:addChild(self.m_tip)
    self.m_tip:setPosition(pos)
    self.m_tip:setVisible(false)
end

--[[
    刷新UI
]]
function TheHonorOfZorroCollectBar:updateUI(count)
    for index = 1,5 do
        local item = self.m_collectItems[index]
        if index <= count then
            item:runCsbAction("idle2")
        -- elseif count == 4 and index == 5 then
        --     item:runCsbAction("idle3",true)
        else
            item:runCsbAction("idle1")
        end
    end
end

--[[
    增加进度动画
]]
function TheHonorOfZorroCollectBar:showAddProcessAni(count,isSuperFree,func)
    local item = self.m_collectItems[count]
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_add_collect_num)
    
    item:runCsbAction("actionframe",false,function()
        if isSuperFree then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_super_free_collect_full)
            self:runCsbAction("actionframe2",false,func)
        else
            if type(func) == "function" then
                func()
            end
        end
    end)

    
    self.m_machine:delayCallBack(27 / 60,function()
        for iCount = 1,2 do
            local particle = item:findChild("Particle_"..iCount)
            if particle then
                particle:setVisible(true)
                particle:resetSystem()
            end
        end
    end)
end

--[[
    初始化锁定状态
]]
function TheHonorOfZorroCollectBar:initLockStatus(isLocked)
    self.m_lockStatus = isLocked
    self:findChild("Node_unlock"):setVisible(not isLocked)
    self:findChild("Node_lock"):setVisible(isLocked)
    if isLocked then
        self:runCsbAction("idle",true)
        util_spinePlay(self.m_lockBg,"idle",true)
    else
        self:runCsbAction("idle2",true)
    end
end

--[[
    刷新锁定状态
]]
function TheHonorOfZorroCollectBar:updateLockStatus(betLevel)
    local isLocked = betLevel == 0
    if self.m_lockStatus == isLocked then
        return
    end
    self.m_lockStatus = isLocked
    self:findChild("Node_unlock"):setVisible(betLevel == 1)
    
    self:stopAllActions()
    if isLocked then
        self:runCsbAction("suoding")
        self:findChild("Node_lock"):setVisible(true)
        util_spinePlay(self.m_lockBg,"suoding")
        performWithDelay(self,function()
            self:runCsbAction("idle",true)
            
        end,58 / 60)
    else
        self:runCsbAction("jiesuo")
        util_spinePlay(self.m_lockBg,"jiesuo")
        performWithDelay(self,function()
            self:runCsbAction("idle2",true)
            self:findChild("Node_lock"):setVisible(false)
        end,50 / 60)
    end
end

--默认按钮监听回调
function TheHonorOfZorroCollectBar:clickFunc(sender)
    if self.m_isWaitting then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_btn_click)
    if tag == BTN_TAG_TIP then      --显示提示
        self:clickHelp()
    end
end

--[[
    显示提示
]]
function TheHonorOfZorroCollectBar:clickHelp()
    if self.m_isWaitting or not self.m_machine:collectBarClickEnabled() then
        return
    end
    
    self.m_isWaitting = true

    if self.m_lockStatus then
        self.m_machine.m_bottomUI:changeBetCoinNumToHight()
        if self.m_tip:isVisible() then
            self:hideTip()
        end
        self.m_isWaitting = false
        return
    end

    if self.m_tip:isVisible() then
        self:hideTip()
    else
        self.m_tip:setVisible(true)
        self.m_tip:runCsbAction("start",false,function()
            self.m_isWaitting = false
            performWithDelay(self.m_tip,function()
                self.m_isWaitting = true
                self:hideTip()
            end,2.5)
        end)
    end
end

function TheHonorOfZorroCollectBar:hideTip()
    self.m_tip:stopAllActions()
    if self.m_tip:isVisible() then
        self.m_tip:runCsbAction("over",false,function()
            self.m_isWaitting = false
            self.m_tip:setVisible(false)
        end)
    end
end


return TheHonorOfZorroCollectBar