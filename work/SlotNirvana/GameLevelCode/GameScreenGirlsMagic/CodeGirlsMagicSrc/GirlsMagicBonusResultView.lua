---
--xcyy
--2018年5月23日
--GirlsMagicBonusResultView.lua

local GirlsMagicBonusResultView = class("GirlsMagicBonusResultView",util_require("base.BaseView"))


function GirlsMagicBonusResultView:initUI(params)
    self:createCsbNode("GirlsMagic/BonusResult.csb")

    self.m_machine = params.machine

    self.m_progress_color = util_createAnimation("GirlsMagic_progress_color.csb")
    self.m_progress_bag = util_createAnimation("GirlsMagic_progress_accessory.csb")
    self.m_progress_pattern = util_createAnimation("GirlsMagic_progress_pattern.csb")

    --集满后下次结果显示的进度条
    self.m_progress_color_0 = util_createAnimation("GirlsMagic_progress_color_0.csb")
    self.m_progress_bag_0 = util_createAnimation("GirlsMagic_progress_accessory_0.csb")
    self.m_progress_pattern_0 = util_createAnimation("GirlsMagic_progress_pattern_0.csb")

    local Node_progress_1 = self:findChild("Node_progress_1")
    local Node_progress_2 = self:findChild("Node_progress_2")
    local Node_progress_3 = self:findChild("Node_progress_3")

    Node_progress_1:addChild(self.m_progress_color)
    Node_progress_2:addChild(self.m_progress_bag)
    Node_progress_3:addChild(self.m_progress_pattern)

    Node_progress_1:addChild(self.m_progress_color_0)
    Node_progress_2:addChild(self.m_progress_bag_0)
    Node_progress_3:addChild(self.m_progress_pattern_0)

    self.m_progress_color_0:setVisible(false)
    self.m_progress_bag_0:setVisible(false)
    self.m_progress_pattern_0:setVisible(false)

    --适配
    local pos1 = self:convertToNodePos(Node_progress_1,140)
    Node_progress_1:setPosition(pos1)
    Node_progress_2:setPosition(cc.p(pos1.x,pos1.y - 70))
    Node_progress_3:setPosition(cc.p(pos1.x,pos1.y - 140))

    self:findChild("Node_PlayerDress"):setPositionY(260 * (1 + 1 - self.m_machine.m_machineRootScale))
end

function GirlsMagicBonusResultView:convertToNodePos(node,height)
    local worldPos   = cc.p(337,display.height - height)
    worldPos.y = worldPos.y * (1 + 1 - self.m_machine.m_machineRootScale)
    return worldPos
end


function GirlsMagicBonusResultView:onEnter()
   
end

function GirlsMagicBonusResultView:onExit()

end

--[[
    获取进度条位置节点
]]
function GirlsMagicBonusResultView:getProgressPosNode(matchType)
    if matchType == "color" then
        return self:findChild("Node_progress_1")
    elseif matchType == "bag" then
        return self:findChild("Node_progress_2")
    else
        return self:findChild("Node_progress_3")
    end
end

--[[
    进度条进入动画
]]
function GirlsMagicBonusResultView:progressStartAni()
    self.m_progress_color:runCsbAction("start",false,function(  )
        self.m_progress_color:runCsbAction("idle")
    end)
    self.m_progress_bag:runCsbAction("start",false,function(  )
        self.m_progress_bag:runCsbAction("idle")
    end)
    self.m_progress_pattern:runCsbAction("start",false,function(  )
        self.m_progress_pattern:runCsbAction("idle")
    end)

    self.m_progress_color_0:runCsbAction("start",false,function(  )
        self.m_progress_color_0:runCsbAction("idle")
    end)
    self.m_progress_bag_0:runCsbAction("start",false,function(  )
        self.m_progress_bag_0:runCsbAction("idle")
    end)
    self.m_progress_pattern_0:runCsbAction("start",false,function(  )
        self.m_progress_pattern_0:runCsbAction("idle")
    end)
end

--[[
    进度条集满光效
]]
function GirlsMagicBonusResultView:fullLightAni(matchType,func)
    local target
    local function endFunc(  )
        target:runCsbAction("idle3")
        if type(func) == "function" then
            func()
        end
    end
    if matchType == "color" then
        target = self.m_progress_color
    elseif matchType == "bag" then
        target = self.m_progress_bag
    else
        target = self.m_progress_pattern
    end
    target:findChild("Particle_1"):resetSystem()
    target:findChild("Particle_1_0"):resetSystem()

    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_progress_turn_to_gold.mp3")
    target:runCsbAction("change_gold",false,endFunc)
end


--[[
    显示进度条
]]
function GirlsMagicBonusResultView:showProgress(matchType,percentData,func)
    --获取当前显示的进度条
    local color = self.m_progress_color
    if not self.m_progress_color:isVisible() then
        color = self.m_progress_color_0
    end

    local bag = self.m_progress_bag
    if not self.m_progress_bag:isVisible() then
        bag = self.m_progress_bag_0
    end

    local pattern = self.m_progress_pattern
    if not self.m_progress_pattern:isVisible() then
        pattern = self.m_progress_pattern_0
    end
    if matchType == "color" then
        color:runCsbAction("start2",false,function(  )
            color:runCsbAction("idle2")
            if type(func) == "function" then
                func()
            end
        end)

        
        bag:runCsbAction("dark",false,function(  )
            bag:runCsbAction("idle4")
        end)

        
        pattern:runCsbAction("dark",false,function(  )
            pattern:runCsbAction("idle4")
        end)

        
    elseif matchType == "bag" then
        color:runCsbAction("over2",false,function(  )
            color:runCsbAction("idle4")
        end)
        bag:runCsbAction("start3",false,function(  )
            bag:runCsbAction("idle2")
            if type(func) == "function" then
                func()
            end
        end)
        pattern:runCsbAction("idle4")

    else
        color:runCsbAction("idle4")
        bag:runCsbAction("over2",false,function(  )
            bag:runCsbAction("idle4")
        end)

        pattern:runCsbAction("start3",false,function(  )
            pattern:runCsbAction("idle2")
            if type(func) == "function" then
                func()
            end
        end)
    end
end

--[[
    最后一个进度条回复置黑状态
]]
function GirlsMagicBonusResultView:resetPatternAni()
    local pattern = self.m_progress_pattern
    if not self.m_progress_pattern:isVisible() then
        pattern = self.m_progress_pattern_0
    end
    pattern:runCsbAction("over2",false,function(  )
        pattern:runCsbAction("idle4")
    end)
end

--[[
    重置进度条进度
]]
function GirlsMagicBonusResultView:resetProgress(data)
    local progress = {self.m_progress_color,self.m_progress_bag,self.m_progress_pattern}
    local progress_0 = {self.m_progress_color_0,self.m_progress_bag_0,self.m_progress_pattern_0}
    for index = 1,#data do
        local item = progress[index]
        progress[index]:setVisible(data[index].before < 100)
        progress_0[index]:setVisible(data[index].before >= 100)
        --上次进度集满显示金色进度条
        if data[index].before >= 100 then
            item = progress_0[index]
        end

        local LoadingBar_0 = item:findChild("LoadingBar_0")
        LoadingBar_0:setPercent(data[index].before)

        local LoadingBar_2 = item:findChild("LoadingBar_2")
        LoadingBar_2:setPercent(data[index].before)
    end
end

--[[
    改变进度条进度
]]
function GirlsMagicBonusResultView:changeProgress(matchType,data,func)
    local progress = {self.m_progress_color,self.m_progress_bag,self.m_progress_pattern}

    local index = 1
    if matchType == "color" then
        index = 1
    elseif matchType == "bag" then
        index = 2
    else
        index = 3
    end

    local LoadingBar_0 = progress[index]:findChild("LoadingBar_0")
    self:addPercentAni(LoadingBar_0,data[index].before,data[index].after,function(  )
        if data[index].after >= 100 then
            gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_progress_full.mp3")
            progress[index]:runCsbAction("jiman",false,function(  )
                if type(func) == "function" then
                    func()
                end
            end)
        else
            if type(func) == "function" then
                func()
            end
        end
        
    end)

    local LoadingBar_2 = progress[index]:findChild("LoadingBar_2")
    LoadingBar_2:setPercent(data[index].after)
end

--[[
    定时增加进度条进度
]]
function GirlsMagicBonusResultView:addPercentAni(barItem,startValue,endValue,func)
    local addTimes = 0
    local delay = 0
    barItem:onUpdate(function(dt)
        delay = delay + dt
        if addTimes >= 10 then
            barItem:unscheduleUpdate()
            if type(func) == "function" then
                func()
            end
            return
        end
        addTimes = addTimes + 1
        barItem:setPercent(startValue + (endValue - startValue) / 10 * addTimes)
    end)
end

return GirlsMagicBonusResultView