---
--xcyy
--2018年5月23日
--AliceView.lua

local AliceBonusCardItem = class("AliceBonusCardItem",util_require("base.BaseView"))

-- show  -开场的
-- idleframe
-- down  --点击
-- black --
-- 
local CARD_TYPE = {"A", "B", "C", "D", "E"}

function AliceBonusCardItem:initUI(data)
    self:createCsbNode("Alice_Bonuscard.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)
    self.isClick = false
    self.isShowItem = false

    self:runCsbAction("idleframe1")
    for i = 1, #CARD_TYPE, 1 do
        local type = CARD_TYPE[i]
        local card = self:findChild("card_"..type)
        card:setVisible(false)
        local grayCard = self:findChild("gray_card_"..type)
        grayCard:setVisible(false)
    end
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function AliceBonusCardItem:setClickFunc(func)
    self.m_func = func
end

function AliceBonusCardItem:showItemStart()
    self:runCsbAction("idle1", true)
end

function AliceBonusCardItem:showItemIdle( )
    self:runCsbAction("idleframe1")
end

function AliceBonusCardItem:showResult(result, func, callback)
    self.isShowItem = true
    self.isClick = true
    self:findChild("card_"..result):setVisible(true)
    
    self:runCsbAction("click", false, function()
        if func ~= nil then 
            func()
        end
        if callback ~= nil then
            callback()
        end
    end)
    -- gLobalSoundManager:playSound("AZTECSounds/music_AZTEC_item_open.mp3")
end

function AliceBonusCardItem:showSelected(result)
    self.isShowItem = true
    self.isClick = true
    local cardNode = self:findChild("card_"..result)
    if cardNode then
        cardNode:setVisible(true)
    end
    self:runCsbAction("idleframe2")
end


function AliceBonusCardItem:showUnselected(result)
    self.isShowItem = true
    self.isClick = true
    local cardNode = self:findChild("card_"..result)
    local grayCardNode = self:findChild("gray_card_"..result)
    if cardNode then
        cardNode:setVisible(true)
    end
    if grayCardNode then
        grayCardNode:setVisible(true)
    end
    self:runCsbAction("idle3")
end

function AliceBonusCardItem:onEnter()

end

function AliceBonusCardItem:onExit()

end


function AliceBonusCardItem:clickFunc(sender )
    if self.isClick or self.isShowItem then
        return
    end
    
    self.m_func(self.m_index)
end

return AliceBonusCardItem