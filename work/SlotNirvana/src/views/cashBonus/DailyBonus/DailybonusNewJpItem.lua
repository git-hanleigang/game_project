--[[
    --购买轮盘后添加一个jp选项
]]

local DailybonusNewJpItem = class("DailybonusNewJpItem", util_require("base.BaseView"))

function DailybonusNewJpItem:initUI()

    self:createCsbNode("Hourbonus_new3/DailyBonusJP.csb")  
end

function DailybonusNewJpItem:playNewJpAnimation()
    
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusItemChangeJp.mp3")
    self:runCsbAction("tojackpot")
end

function DailybonusNewJpItem:playIdleAnimation()
    self:runCsbAction("jackpot_idle")
end


return DailybonusNewJpItem