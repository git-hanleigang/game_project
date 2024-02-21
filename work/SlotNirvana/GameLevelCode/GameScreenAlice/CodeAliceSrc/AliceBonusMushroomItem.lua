---
--xcyy
--2018年5月23日
--AliceView.lua

local AliceBonusMushroomItem = class("AliceBonusMushroomItem",util_require("base.BaseView"))

-- show  -开场的
-- idleframe
-- down  --点击
-- black --
-- 
local ARRAY_ANIMATION_NAME = {"win", "lost", "end", "all"}

function AliceBonusMushroomItem:initUI(data)
    self:createCsbNode("Alice_Bonus_mushroon.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)
    self.m_index = data.index
    self.m_iCol = data.col
    self.m_iRow = data.row
    self.isClick = true
    self.isShowItem = true
    self.m_lab_win = self:findChild("m_lab_win")
    self.m_lab_lost = self:findChild("m_lab_lost")

    self:runCsbAction("idleframe")

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusMushroomItem:setClickFunc(func)
    self.m_func = func
end

function AliceBonusMushroomItem:showItemStart()

    self:runCsbAction("start", true)
    self.isClick = false
    self.isShowItem = false
end

function AliceBonusMushroomItem:showItemIdle()
    self.isShowItem = true
    self.isClick = true
    self:runCsbAction("idleframe9")
end

function AliceBonusMushroomItem:showResult(result, func, callback)
    self.isShowItem = true
    self.isClick = true
    local animation = "click_win"
    if result == "WinAll" then
        animation = "click_all"
    elseif result == "0" then
        animation = "click_end"
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_collect.mp3")
    else
        self.m_lab_win:setString(result.."x")
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

function AliceBonusMushroomItem:showLostAnimtion(result)
    self.isShowItem = true
    self.isClick = true
    local animation = "over_lost"
    if result == "WinAll" then
        animation = "over_all"
    elseif result == "0" then
        animation = "over_end"
    else
        self.m_lab_lost:setString(result.."x")
    end
    self:runCsbAction(animation)
end

function AliceBonusMushroomItem:showSelected(result)
    self.isShowItem = true
    self.isClick = true
    local animation = "idleframe_win"
    if result == "WinAll" then
        animation = "idleframe_all"
    else
        self.m_lab_win:setString(result.."x")
    end
    self:runCsbAction(animation)
end


function AliceBonusMushroomItem:showUnselected(result)
    self.isShowItem = true
    self.isClick = true
    local animation = "over_idle_lost"
    if result == "WinAll" then
        animation = "over_idle_all"
    elseif result == "0" then
        animation = "over_idle_end"
    else
        self.m_lab_lost:setString(result.."x")
    end
    self:runCsbAction(animation)
end

function AliceBonusMushroomItem:onEnter()

end

function AliceBonusMushroomItem:onExit()

end


function AliceBonusMushroomItem:clickFunc(sender )
    if self.isClick or self.isShowItem then
        return
    end
    self.m_func(self.m_index)
end

function AliceBonusMushroomItem:getItemIndex()
    return self.m_index
end

function AliceBonusMushroomItem:getItemCol()
    return self.m_iCol
end

function AliceBonusMushroomItem:getItemRow()
    return self.m_iRow
end

return AliceBonusMushroomItem