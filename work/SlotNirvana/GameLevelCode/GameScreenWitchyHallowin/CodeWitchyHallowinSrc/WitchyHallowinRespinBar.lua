---
--xcyy
--2018年5月23日
--WitchyHallowinRespinBar.lua
local PublicConfig = require "WitchyHallowinPublicConfig"
local WitchyHallowinRespinBar = class("WitchyHallowinRespinBar",util_require("Levels.BaseLevelDialog"))


function WitchyHallowinRespinBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("WitchyHallowin_Respin_bar.csb")
    self.m_item_three = {}
    self.m_item_four = {}
    self.m_maxCount = 3
    self.m_isComplete = false
    for index = 1,4 do
        if index <= 3 then
            local item_three = util_createAnimation("WitchyHallowin_RespinNum.csb")
            self:findChild("Node_2_"..index):addChild(item_three)
            self.m_item_three[#self.m_item_three + 1] = item_three
            item_three:runCsbAction("idle2")
            

            local item_four = util_createAnimation("WitchyHallowin_RespinNum.csb")
            self:findChild("Node_1_"..index):addChild(item_four)
            self.m_item_four[#self.m_item_four + 1] = item_four
            item_four:runCsbAction("idle2")

            for iCount = 1,4 do
                item_three:findChild("an_"..iCount):setVisible(index == iCount)
                item_three:findChild("liang_"..iCount):setVisible(index == iCount)
                item_four:findChild("an_"..iCount):setVisible(index == iCount)
                item_four:findChild("liang_"..iCount):setVisible(index == iCount)
            end
        else
            local item_four = util_createAnimation("WitchyHallowin_RespinNum.csb")
            self:findChild("Node_1_"..index):addChild(item_four)
            self.m_item_four[#self.m_item_four + 1] = item_four
            item_four:runCsbAction("idle2")
            for iCount = 1,4 do
                item_four:findChild("an_"..iCount):setVisible(index == iCount)
                item_four:findChild("liang_"..iCount):setVisible(index == iCount)
            end
        end
    end
    util_setCascadeOpacityEnabledRescursion(self,true)
end

--[[
    刷新当前次数
]]
function WitchyHallowinRespinBar:updateRespinCount(curCount,totalCount,isInit)
    if totalCount == 3 then
        for index = 1,3 do
            local item = self.m_item_three[index]
            item:findChild("liang_"..index):setVisible(curCount == index)
            item:runCsbAction("idle2")
        end
        if not isInit and curCount == totalCount then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_respin_add_times)
            local item = self.m_item_three[#self.m_item_three]
            item:runCsbAction("actionframe",false,function(  )
                item:runCsbAction("idle2")
            end)
        end
    else
        for index = 1,4 do
            local item = self.m_item_four[index]
            item:findChild("liang_"..index):setVisible(curCount == index)
            item:runCsbAction("idle2")
        end
        if not isInit and curCount == totalCount then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_respin_add_times)
            local item = self.m_item_four[#self.m_item_four]
            item:runCsbAction("actionframe",false,function(  )
                item:runCsbAction("idle2")
            end)
        end
    end
end

--[[
    显示3次
]]
function WitchyHallowinRespinBar:showThreeNumAni(func)
    local totalCount = self.m_machine.m_runSpinResultData.p_reSpinsTotalCount or 3
    local curCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount or 3
    if curCount > 3 then
        curCount = 3
    end
    self.m_maxCount = 3
    self:updateRespinCount(curCount,3,true)
    self:runCsbAction("idle1")
end

--[[
    显示4次
]]
function WitchyHallowinRespinBar:showFourNumAni(func)
    self:showThreeNumAni()
    self.m_maxCount = 4
    local totalCount = self.m_machine.m_runSpinResultData.p_reSpinsTotalCount
    local curCount = self.m_machine.m_runSpinResultData.p_reSpinCurCount
    self:updateRespinCount(curCount,totalCount,true)
    self:runCsbAction("actionframe",false,function(  )
        -- self:runCsbAction("idle2")
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    结束动画
]]
function WitchyHallowinRespinBar:completeAni(func)
    if self.m_isComplete then
        return
    end
    local aniName = "switch1"
    if self.m_maxCount == 4 then
        aniName = "switch2"
    end
    self.m_isComplete = true
    self:runCsbAction(aniName,false,function(  )
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    设置结束状态
]]
function WitchyHallowinRespinBar:setComplete(isComplete)
    self.m_isComplete = isComplete
end

return WitchyHallowinRespinBar