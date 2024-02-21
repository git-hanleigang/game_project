---
--xcyy
--2018年5月23日
--SuperstarQuestFreeTopNode.lua
local PublicConfig = require "SuperstarQuestPublicConfig"
local SuperstarQuestFreeTopNode = class("SuperstarQuestFreeTopNode", util_require("base.BaseView"))


function SuperstarQuestFreeTopNode:initUI(params)

    self.m_machine = params.machine
    self.m_jpType  = params.jpType
    self:createCsbNode("SuperstarQuest_ShoujiBar_Free_"..self.m_jpType..".csb")

    self.m_spineList = {}

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function SuperstarQuestFreeTopNode:initSpineUI()
    local Node_spine = self:findChild("Node_juese")
    if self.m_jpType == "Mega" then
        local spine1 = util_spineCreate("SuperstarQuest_juese_1",true,true)
        local spine2 = util_spineCreate("SuperstarQuest_juese_1_2",true,true)
        local spine3 = util_spineCreate("SuperstarQuest_juese_1_3",true,true)

        Node_spine:addChild(spine1,10)
        Node_spine:addChild(spine2,5)
        Node_spine:addChild(spine3,1)

        self.m_spineList = {spine1,spine2,spine3}
    elseif self.m_jpType == "Major" then
        local spine1 = util_spineCreate("SuperstarQuest_juese_2",true,true)
        local spine2 = util_spineCreate("SuperstarQuest_juese_2_2",true,true)
        local spine3 = util_spineCreate("SuperstarQuest_juese_2_3",true,true)

        Node_spine:addChild(spine1,10)
        Node_spine:addChild(spine2,5)
        Node_spine:addChild(spine3,1)

        self.m_spineList = {spine1,spine2,spine3}
    elseif self.m_jpType == "Minor" then
        local spine1 = util_spineCreate("SuperstarQuest_juese_3",true,true)
        local spine2 = util_spineCreate("SuperstarQuest_juese_3_2",true,true)
        local spine3 = util_spineCreate("SuperstarQuest_juese_3_3",true,true)

        Node_spine:addChild(spine1,10)
        Node_spine:addChild(spine2,5)
        Node_spine:addChild(spine3,1)

        self.m_spineList = {spine1,spine2,spine3}
    else
        self:runCsbAction("idle2",true)
        local spine = util_spineCreate("SuperstarQuest_juese_4",true,true)
        Node_spine:addChild(spine)
        self.m_spineList = {spine}
    end 
end


--[[
    刷新数量
]]
function SuperstarQuestFreeTopNode:updateCount(count)
    local m_lb_num = self:findChild("m_lb_num")
    m_lb_num:setString(count)

    local scale = 1

    self:updateLabelSize({label=m_lb_num,sx=scale,sy=scale},111)    
    
end

function SuperstarQuestFreeTopNode:runIdleAni()
    if self.m_jpType ~= "Normal" then
        for index,spine in ipairs(self.m_spineList) do
            util_spinePlay(spine,"idleframe_free",true)
        end
    else
        for index,spine in ipairs(self.m_spineList) do
            util_spinePlay(spine,"idleframe",true)
        end
    end
end

--[[
    触发动画
]]
function SuperstarQuestFreeTopNode:runTriggerAni(func)
    local delayTime = 0
    if self.m_jpType == "Mega" or self.m_jpType == "Minor" or self.m_jpType == "Major" then
        for index,spine in ipairs(self.m_spineList) do
            if not tolua.isnull(spine) then
                util_spinePlay(spine,"actionframe_free")
                util_spineEndCallFunc(spine,"actionframe_free",function()
                    util_spinePlay(spine,"idleframe_free",true)
                end)
                local aniTime = spine:getAnimationDurationTime("actionframe_free")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end
        end
        
    else
        for index,spine in ipairs(self.m_spineList) do
            if not tolua.isnull(spine) then
                util_spinePlay(spine,"actionframe")
                util_spineEndCallFunc(spine,"actionframe",function()
                    util_spinePlay(spine,"idleframe",true)
                    if type(func) == "function" then
                        func()
                    end
                end)
                local aniTime = spine:getAnimationDurationTime("actionframe")
                if aniTime > delayTime then
                    delayTime = aniTime
                end
            end
        end
        
    end

    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,delayTime)
end


return SuperstarQuestFreeTopNode