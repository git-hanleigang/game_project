---
--xcyy
--2018年5月23日
--WolfSmashBonusForTempView.lua

local WolfSmashBonusForTempView = class("WolfSmashBonusForTempView",util_require("Levels.BaseLevelDialog"))


function WolfSmashBonusForTempView:initUI(machine,index)

    self:createCsbNode("WolfSmash_tanban_pig.csb")
    self.m_machine = machine
    self.multiple = 0
    self.pigIndex = index
    self:addClick(self:findChild("Panel_1")) -- 非按钮节点得手动绑定监听
    self.m_Click = true
    self.pigSpine = nil

end

function WolfSmashBonusForTempView:addPigSpine(pigSpine)
    self.pigSpine = pigSpine
    self:findChild("Node_1"):addChild(pigSpine)
end

function WolfSmashBonusForTempView:setMultiple(multiple)
    self.multiple = multiple
end

function WolfSmashBonusForTempView:setClick(isClick)
    self.m_Click = isClick
end

function WolfSmashBonusForTempView:setIdle()
    if self.pigSpine then
        util_spinePlay(self.pigSpine, "idleframe2", true)
    end
    
end

--默认按钮监听回调
function WolfSmashBonusForTempView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self.m_Click then
        return
    end

    if name == "Panel_1" then
        self:showClickEffect()
    end
end

function WolfSmashBonusForTempView:showClickEffect()
    self.m_Click = false
        self.m_machine.guideNode:stopAllActions()
        if self.multiple ~= 0 then
            self.m_machine.m_guideClick = false
            if self.pigSpine then
                util_spinePlay(self.pigSpine, "shouji", false)
            end
            self.m_machine:showPointAndTipsForIndex(false,1)
            --真实小猪点击
            local realPig = self.m_machine.pigMultipleList[2]
            if realPig then
                realPig:showClickEffect()
            end
            --展示下一轮
            self:delayCallBack(1,function ()
                
                self.m_machine.curGuideIndex = 2
                self.m_machine:showGuideEffectForIndex()
                self:removeFromParent()
                
            end)
            
        end
end

--[[
    延迟回调
]]
function WolfSmashBonusForTempView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WolfSmashBonusForTempView