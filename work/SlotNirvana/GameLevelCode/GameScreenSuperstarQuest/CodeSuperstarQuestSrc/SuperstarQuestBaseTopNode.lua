---
--xcyy
--2018年5月23日
--SuperstarQuestBaseTopNode.lua
local PublicConfig = require "SuperstarQuestPublicConfig"
local SuperstarQuestBaseTopNode = class("SuperstarQuestBaseTopNode", util_require("base.BaseView"))


function SuperstarQuestBaseTopNode:initUI(params)

    self.m_triggerSoundIndex = 1
    self.m_machine = params.machine
    self.m_jpType  = params.jpType
    self.m_isTrigger = false
    self:createCsbNode("SuperstarQuest_ShoujiBar_Base_"..self.m_jpType..".csb")

    if self.m_jpType ~= "Normal" then
        self.m_tip = util_createAnimation("SuperstarQuest_ShoujiBar_Base_wenzi.csb")
        self:findChild("Node_wenzi"):addChild(self.m_tip)
        self.m_tip:setVisible(false)
    end

    

    self:addClick(self:findChild("panel_click"))
    self.m_clickEnabled = true

    self.m_spineList = {}
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function SuperstarQuestBaseTopNode:initSpineUI()
    local triggerSpine
    if self.m_jpType == "Mega" then
        local Node_spine = self:findChild("Node_spine")
        local spine1 = util_spineCreate("SuperstarQuest_juese_1",true,true)
        local spine2 = util_spineCreate("SuperstarQuest_juese_1_2",true,true)
        local spine3 = util_spineCreate("SuperstarQuest_juese_1_3",true,true)

        Node_spine:addChild(spine1,10)
        Node_spine:addChild(spine2,5)
        Node_spine:addChild(spine3,1)

        self.m_spineList = {spine1,spine2,spine3}
    elseif self.m_jpType == "Major" then
        local Node_spine = self:findChild("Node_spine")
        local spine1 = util_spineCreate("SuperstarQuest_juese_2",true,true)
        local spine2 = util_spineCreate("SuperstarQuest_juese_2_2",true,true)
        local spine3 = util_spineCreate("SuperstarQuest_juese_2_3",true,true)

        Node_spine:addChild(spine1,10)
        Node_spine:addChild(spine2,5)
        Node_spine:addChild(spine3,1)

        self.m_spineList = {spine1,spine2,spine3}
    elseif self.m_jpType == "Minor" then
        local Node_spine = self:findChild("Node_spine")
        local spine1 = util_spineCreate("SuperstarQuest_juese_3",true,true)
        local spine2 = util_spineCreate("SuperstarQuest_juese_3_2",true,true)
        local spine3 = util_spineCreate("SuperstarQuest_juese_3_3",true,true)

        Node_spine:addChild(spine1,10)
        Node_spine:addChild(spine2,5)
        Node_spine:addChild(spine3,1)

        self.m_spineList = {spine1,spine2,spine3}
    end

    self.m_maxCount = self.m_machine:getMaxWildNum(string.lower(self.m_jpType))
    if self.m_tip then
        self.m_tip:findChild("m_lb_num_0"):setString(self.m_maxCount)
    end


    if self.m_jpType ~= "Normal" then
        self.m_triggerSpine = util_spineCreate("SuperstarQuest_ShoujiBar_Base_tx",true,true)
        self:findChild("Node_tx"):addChild(self.m_triggerSpine)
        self.m_triggerSpine:setVisible(false)
    end

    self:runSpineIdle()

    self.m_spine_feedback = util_spineCreate("SuperstarQuest_fankui",true,true)
    self:findChild("Node_fankui"):addChild(self.m_spine_feedback)
    
end

--[[
    idle
]]
function SuperstarQuestBaseTopNode:runSpineIdle()
    self.m_clickEnabled = true
    for index,spine in ipairs(self.m_spineList) do
        if not tolua.isnull(spine) then
            util_spinePlay(spine,"idleframe_base",true)
        end
    end
    
end

--[[
    刷新数量
]]
function SuperstarQuestBaseTopNode:updateCount(count)
    local m_lb_num = self:findChild("m_lb_num")
    m_lb_num:setString(count)

    if count > self.m_maxCount - 3 and self.m_jpType ~= "Normal" then
        if not self.m_tip:isVisible() then
            self.m_tip:setVisible(true)
            --显示必中玩法数量
            self.m_tip:runCsbAction("start",false,function()
                self.m_tip:runCsbAction("idle2",true)
            end)
        end
        
    else
        if self.m_tip then
            self.m_tip:setVisible(false)
        end
    end

    local scale = 0.83
    if self.m_jpType == "Mega" then
        scale = 0.92
    elseif self.m_jpType == "Major" then
        scale = 0.73
    elseif self.m_jpType == "Minor" then
        scale = 0.73
    end

    self:updateLabelSize({label=m_lb_num,sx=scale,sy=scale},111)    
    
end

--[[
    清空压黑
]]
function SuperstarQuestBaseTopNode:clearDarkAni()
    self:runCsbAction("idle")
end

--[[
    触发动画
]]
function SuperstarQuestBaseTopNode:runTriggerAni(func)
    local delayTime = 0
    self.m_isTrigger = true
    if self.m_jpType == "Mega" or self.m_jpType == "Minor" or self.m_jpType == "Major" then
        self.m_clickEnabled = false

        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_"..string.lower(self.m_jpType).."_trigger"])

        self.m_triggerSpine:setVisible(true)
        util_spinePlay(self.m_triggerSpine,"actionframe")
        util_spineEndCallFunc(self.m_triggerSpine,"actionframe",function()
            if not tolua.isnull(self.m_triggerSpine) then
                self.m_triggerSpine:setVisible(false)
            end
        end)

        for index,spine in ipairs(self.m_spineList) do
            if not tolua.isnull(spine) then
                util_spinePlay(spine,"actionframe_base")
                util_spineEndCallFunc(spine,"actionframe_base",function()
                    util_spinePlay(spine,"idleframe_base",true)
                end)
                local aniTime = spine:getAnimationDurationTime("actionframe_base")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end
        end

        
        self.m_machine:delayCallBack(delayTime,function()
            self.m_clickEnabled = true
            self.m_isTrigger = false
            if type(func) == "function" then
                func()
            end
        end)
        

        self:runCsbAction("darkstart",false,function()
            
        end)
        
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_SuperstarQuest_normal_wild_trigger_"..self.m_triggerSoundIndex])
        self.m_triggerSoundIndex  = self.m_triggerSoundIndex + 1
        if self.m_triggerSoundIndex > 2 then
            self.m_triggerSoundIndex = 1
        end
        self:runCsbAction("actionframe",false,function()
            self.m_isTrigger = false
            if type(func) == "function" then
                func()
            end
        end)
    end


    return delayTime
end

--默认按钮监听回调
function SuperstarQuestBaseTopNode:clickFunc(sender)
    if not self.m_clickEnabled then
        return
    end

    self.m_clickEnabled = false

    for index,spine in ipairs(self.m_spineList) do
        if not tolua.isnull(spine) then
            util_spinePlay(spine,"idleframe2_base")
            util_spineEndCallFunc(spine,"idleframe2_base",function()
                self:runSpineIdle()
            end)
        end
    end
end

--[[
    收集反馈动效
]]
function SuperstarQuestBaseTopNode:collectFeedBackAni()
    util_spinePlay(self.m_spine_feedback,"actionframe2")
    if not self.m_isTrigger then
        self:runCsbAction("shouji")
    end
    
end

return SuperstarQuestBaseTopNode