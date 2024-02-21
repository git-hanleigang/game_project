--[[
    转动结束光圈
]]

local DailybonusResultLight1 = class("DailybonusResultLight1", util_require("base.BaseView"))

function DailybonusResultLight1:initUI()
    self:createCsbNode("Hourbonus_new3/DailyBonusWheelResultLight1.csb")  
end

function DailybonusResultLight1:playIdleAction()
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusWheelItemSelect.mp3")
    self:runCsbAction("idle",true)
end

function DailybonusResultLight1:showState(bShow)
    self:setVisible(bShow)
end

return DailybonusResultLight1