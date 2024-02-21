---
--xcyy
--2018年5月23日
--AliceView.lua

local AliceBonusHatItem = class("AliceBonusHatItem",util_require("base.BaseView"))

function AliceBonusHatItem:initUI(data)
    self:createCsbNode("Alice_Bonus_hat.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)
    self.m_index = data
    self.isClick = false
    self.isShowItem = false
    self.m_lab_win = self:findChild("m_lab_win")
    self.m_lab_lost = self:findChild("m_lab_lost")
    
    local index = 1
    while true do
        local cake = self:findChild("cake_"..index)
        if cake ~= nil then
            cake:setVisible(false)
        else
            break
        end
        index = index + 1
    end

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusHatItem:setClickFunc(func)
    self.m_func = func
end

function AliceBonusHatItem:showItemStart()

    self:runCsbAction("start", true)
end

function AliceBonusHatItem:showItemIdle( )
    self:runCsbAction("idleframe1")
end

function AliceBonusHatItem:showResult(result, func, callback)
    self.isShowItem = true
    self.isClick = true
    local animation = "click"
    self:findChild("cake_"..result):setVisible(true)
    self:runCsbAction(animation, false, function()
        if func ~= nil then 
            func()
        end
        if callback ~= nil then
            callback()
        end
    end)
    -- gLobalSoundManager:playSound("AZTECSounds/music_AZTEC_item_open.mp3")
end

function AliceBonusHatItem:showSelected(result)
    self.isShowItem = true
    self.isClick = true
    self:findChild("cake_"..result):setVisible(true)
    self:runCsbAction("idleframe2")
end


function AliceBonusHatItem:showUnselected(result)
    self.isShowItem = true
    self.isClick = true
    self:runCsbAction("actionframe3")
    self.m_lab_lost:setString("x"..result)
end

function AliceBonusHatItem:onEnter()

end

function AliceBonusHatItem:onExit()

end


function AliceBonusHatItem:clickFunc(sender )
    if self.isClick or self.isShowItem then
        return
    end
    self.m_func(self.m_index)
end

function AliceBonusHatItem:showItemStatus()
    return self.isShowItem
end

return AliceBonusHatItem