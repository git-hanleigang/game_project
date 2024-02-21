---
--xcyy
--2018年5月23日
--EpicElephantFreeCollectBar.lua
--freespin次数收集条

local EpicElephantFreeCollectBar = class("EpicElephantFreeCollectBar",util_require("Levels.BaseLevelDialog"))


function EpicElephantFreeCollectBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("EpicElephant_gualan.csb")
    
    self:runCsbAction("idle",true)

    -- mega
    self.m_mega = util_spineCreate("Socre_EpicElephant_Bonus_mega",true,true)
    self:findChild("Node_mega"):addChild(self.m_mega)
    util_spinePlay(self.m_mega, "idleframe3", false)

    -- major
    self.m_major = util_spineCreate("Socre_EpicElephant_Bonus_major",true,true)
    self:findChild("Node_major"):addChild(self.m_major)
    util_spinePlay(self.m_major, "idleframe3", false)

    -- minor
    self.m_minor = util_spineCreate("Socre_EpicElephant_Bonus_minor",true,true)
    self:findChild("Node_minor"):addChild(self.m_minor)
    util_spinePlay(self.m_minor, "idleframe3", false)

    -- mini
    self.m_mini = util_spineCreate("Socre_EpicElephant_Bonus_mini",true,true)
    self:findChild("Node_mini"):addChild(self.m_mini)
    util_spinePlay(self.m_mini, "idleframe3", false)
end

--[[
    刷新收集次数
]]
function EpicElephantFreeCollectBar:refreshCount(freeTimes, isScaleName)
    local delayTime = 0
    if isScaleName then
        delayTime = 8
    end
    self.m_machine:delayCallBack(delayTime/60,function()
        local name = {"mini","minor","major","mega"}
        for index = 1,#name do
            local label = self:findChild("m_lb_num_"..name[index])
            local count = freeTimes[index] or 0
            label:setString(count)
            local oldScale = label:getScale()
            if isScaleName == name[index] then
                --缩放动作
                local seq = cc.Sequence:create({
                    cc.ScaleTo:create(10/60,oldScale*1.2),
                    cc.ScaleTo:create(20/60,oldScale),
                }) 
                label:runAction(seq)
            end
        end
    end)
    
end

-- 触发free玩法 的特效
function EpicElephantFreeCollectBar:playTriEffect(symbolType)
    local name = {"minichufa","minorchufa","majorchufa","megachufa"}
    for i,vName in ipairs(name) do
        self:findChild(vName):setVisible(false)
    end

    local actionName = nil
    if symbolType == self.m_machine.SYMBOL_BONUS_MINI then
        actionName = self.m_mini
        self:findChild("minichufa"):setVisible(false)
    elseif symbolType == self.m_machine.SYMBOL_BONUS_MINOR then
        actionName = self.m_minor
        self:findChild("minorchufa"):setVisible(false)
    elseif symbolType == self.m_machine.SYMBOL_BONUS_MAJOR then
        actionName = self.m_major
        self:findChild("majorchufa"):setVisible(false)
    elseif symbolType == self.m_machine.SYMBOL_BONUS_MEGA then
        actionName = self.m_mega
        self:findChild("megachufa"):setVisible(false)
    else
        return
    end

    self:runCsbAction("actionframe3",false,function()
        self:runCsbAction("idle",true)
    end)

    util_spinePlay(actionName, "actionframe3", false)
    util_spineEndCallFunc(actionName, "actionframe3", function()
        util_spinePlay(actionName, "idleframe3", false)
    end)
end


return EpicElephantFreeCollectBar