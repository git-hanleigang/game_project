---
--xcyy
--2018年5月23日
--StarryFestCollectBar.lua

local PublicConfig = require "StarryFestPublicConfig"
local StarryFestCollectBar = class("StarryFestCollectBar",util_require("Levels.BaseLevelDialog"))
StarryFestCollectBar.m_lastCount = 0
StarryFestCollectBar.m_totalCount = 10

function StarryFestCollectBar:initUI(params)

    self.m_machine = params.machine
    self.m_tips = params.m_tips
    self:createCsbNode("StarryFest_collectBar.csb")

    self.m_isLocked = false
    self.m_isExplainClick = true

    self.m_tips:setVisible(false)

    local lightSpine = util_spineCreate("StarryFest_shouji",true,true)
    self:findChild("Node_light"):addChild(lightSpine)
    util_spinePlay(lightSpine, "idle", true)

    self.m_superSpine = util_spineCreate("StarryFest_shouji",true,true)
    self:findChild("Node_super"):addChild(self.m_superSpine)
    util_spinePlay(self.m_superSpine, "idleframe2", true)

    self.m_lockSpine = util_spineCreate("StarryFest_shouji",true,true)
    self:findChild("suoding"):addChild(self.m_lockSpine, -1)
    util_spinePlay(self.m_lockSpine, "idleframe", true)
    self.m_lockSpine:setVisible(false)

    self.m_collectItems = {}
    for index = 1, self.m_totalCount do
        local item = util_spineCreate("StarryFest_shouji_0",true,true)
        self:findChild("Node_shouji_"..index):addChild(item, 10)
        item:setVisible(false)
        self.m_collectItems[#self.m_collectItems + 1] = item
    end

    self:addClick(self:findChild("Panel_click"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

--默认按钮监听回调
function StarryFestCollectBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if (name == "Button_1" or name == "Panel_click") and self.m_isExplainClick then
        if self.m_machine:tipsBtnIsCanClick() then
            if self.m_machine.m_iBetLevel == 0 then
                if globalData.betFlag then
                    self.m_machine.m_bottomUI:changeBetCoinNumToUnLock(1)
                    -- self.m_isExplainClick = false
                    -- self:showTips()
                end
            else
                self.m_isExplainClick = false
                self:showTips()
            end
        end
    end
end

--[[
    刷新收集进度
]]
function StarryFestCollectBar:refreshCollectCount(curCount, _onEnter, _callFunc)
    local callFunc = _callFunc
    if curCount > self.m_totalCount or self.m_isLocked then
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    if _onEnter then
        for index = 1,#self.m_collectItems do
            self.m_collectItems[index]:setVisible(index <= curCount)
            util_spinePlay(self.m_collectItems[index],"idleframe",true)
            self.m_lastCount = curCount
        end
    else
        if curCount > self.m_lastCount then
            self.m_lastCount = self.m_lastCount + 1
            self.m_collectItems[self.m_lastCount]:setVisible(true)
            local actName = "actionframe"
            if curCount == self.m_totalCount then
                actName = "actionframe2"
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_SuperCollect_Add)
            util_spinePlay(self.m_collectItems[self.m_lastCount],actName,false)
            util_spineEndCallFunc(self.m_collectItems[self.m_lastCount], actName, function()
                self.m_collectItems[self.m_lastCount]:setVisible(true)
                util_spinePlay(self.m_collectItems[self.m_lastCount],"idleframe",true)
                if self.m_lastCount == self.m_totalCount then
                    globalMachineController:playBgmAndResume(PublicConfig.SoundConfig.Music_SuperFg_Trigger, 3, 0, 1)
                    util_spinePlay(self.m_superSpine,"actionframe3",false)
                    util_spineEndCallFunc(self.m_superSpine, "actionframe3", function()
                        self:refreshCollectCount(curCount, false, callFunc)
                    end)
                else
                    self:refreshCollectCount(curCount, false, callFunc)
                end
            end)
        else
            self.m_lastCount = curCount
            if type(callFunc) == "function" then
                callFunc()
            end
        end
    end
end

--[[
    锁定动画(bet不足)
]]
function StarryFestCollectBar:lockAni()
    if self.m_isLocked then
        return
    end
    self:spinCloseTips()
    self.m_lockSpine:setVisible(true)
    self.m_isLocked = true
    util_spinePlay(self.m_lockSpine, "actionframe_sd", false)
    util_spineEndCallFunc(self.m_lockSpine,"actionframe_sd",function()
        for i=1, self.m_totalCount do
            self.m_collectItems[i]:setVisible(false)
        end
        util_spinePlay(self.m_lockSpine, "idleframe", false)
    end)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe_sd", false, function()
        self:runCsbAction("idle", true)
    end)
end

--[[
    解锁动画
]]
function StarryFestCollectBar:unLockAni()
    if not self.m_isLocked then
        return
    end
    self.m_isLocked = false
    util_spinePlay(self.m_lockSpine, "actionframe_js", false)
    util_spineEndCallFunc(self.m_lockSpine,"actionframe_js",function()
        self.m_lockSpine:setVisible(false)
    end)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe_js", false, function()
        self:runCsbAction("idle2", true)
    end)
end

function StarryFestCollectBar:spinCloseTips()
    if self.tipsState == true then
        self:showTips()
    end
end

function StarryFestCollectBar:showTips()
    util_resetCsbAction(self.m_tips.m_csbAct)
    self.m_tips:stopAllActions()
    local function closeTips()
        if self.tipsState then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_PlayRule_Close)
            self.tipsState = false
            self.m_tips:runCsbAction("over",false, function()
                self.m_isExplainClick = true
                self.m_tips:setVisible(false)
            end)
        end
    end

    if not self.tipsState then
        self.tipsState = true
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Jackpot_PlayRule_Open)
        self.m_tips:setVisible(true)
        self.m_tips:runCsbAction("start",false, function()
            self.m_isExplainClick = true
            self.m_tips:runCsbAction("idle",true)
        end)
    else
        closeTips()
    end
    performWithDelay(self.m_tips, function ()
	    closeTips()
    end, 5.0)
end

return StarryFestCollectBar