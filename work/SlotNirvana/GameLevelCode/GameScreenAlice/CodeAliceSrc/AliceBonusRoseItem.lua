---
--xcyy
--2018年5月23日
--AliceView.lua

local AliceBonusRoseItem = class("AliceBonusRoseItem",util_require("base.BaseView"))

-- show  -开场的
-- idleframe
-- down  --点击
-- black --
-- 


function AliceBonusRoseItem:initUI(data)
    self:createCsbNode("Alice_Bonusrose_rose.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)
    self.m_index = data
    self.isClick = false
    self.isShowItem = false
    self.m_lab_win = self:findChild("m_lab_win")
    self.m_lab_lost = self:findChild("m_lab_lost")

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusRoseItem:setClickFunc(func)
    self.m_func = func
end

function AliceBonusRoseItem:showItemStart()

    self:runCsbAction("start", true)
end

function AliceBonusRoseItem:showItemIdle( )
    self:runCsbAction("idleframe")
end

function AliceBonusRoseItem:showResult(result, func, callback)
    self.isShowItem = true
    self.isClick = true
    local animation = "actionframe1"
    if result ~= "Collect" then
        animation = "actionframe2"
        self.m_lab_win:setString("x"..result)
    else
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_collect.mp3")
    end
    
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

function AliceBonusRoseItem:showSelected(result)
    self.isShowItem = true
    self.isClick = true
    self:runCsbAction("idleframe2")
    self.m_lab_win:setString("x"..result)
end


function AliceBonusRoseItem:showUnselected(result)
    self.isShowItem = true
    self.isClick = true
    self.m_lab_lost:setString("x"..result)
    self.m_lab_win:setString("x"..result)
    self:runCsbAction("actionframe3")
end

function AliceBonusRoseItem:onEnter()

end

function AliceBonusRoseItem:onExit()

end


function AliceBonusRoseItem:clickFunc(sender )
    if self.isClick or self.isShowItem then
        return
    end
    
    self.m_func(self.m_index)
end

function AliceBonusRoseItem:showItemStatus()
    return self.isShowItem
end

return AliceBonusRoseItem