---
--xcyy
--2018年5月23日
--AliceView.lua

local AliceBonusTreeItem = class("AliceBonusTreeItem",util_require("base.BaseView"))

-- show  -开场的
-- idleframe
-- down  --点击
-- black --
-- 


function AliceBonusTreeItem:initUI(data)
    self:createCsbNode("Alice_Bonuscup_1.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)
    self.m_index = data
    self.isClick = false
    self.isShowItem = false
    self.m_lab_win = self:findChild("labMultip")
    self.m_node_key = self:findChild("key")
    
    local index = 1
    while true do
        local cup = self:findChild("cup"..index)
        if cup ~= nil then
            if index ~= data then
                cup:setVisible(false)
            end
        else
            break
        end
        index = index + 1
    end

    self.m_animationType = 2
    
    if data == 1 or data == 3 or data == 7 or data == 10 then
        self.m_animationType = 1
        self:findChild("cup2_an"):setVisible(false)
    else
        self:findChild("cup1_an"):setVisible(false)
    end
    
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusTreeItem:setClickFunc(func)
    self.m_func = func
end

function AliceBonusTreeItem:showItemStart()

    self:runCsbAction("start"..self.m_animationType, true)
end

function AliceBonusTreeItem:showItemIdle( )
    self:runCsbAction("idleframe")
end

function AliceBonusTreeItem:showResult(result, func, callback)
    self.isShowItem = true
    self.isClick = true
    local animation = "click"..self.m_animationType
    if result == nil then
        self.m_lab_win:setVisible(false)
    else
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_collect.mp3")
        self.m_lab_win:setString("x"..result)
        self.m_node_key:setVisible(false)
    end
    -- labMultip
    -- key
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

function AliceBonusTreeItem:showSelected()
    self.isShowItem = true
    self.isClick = true
    self.m_lab_win:setVisible(false)
    self:runCsbAction("idleframe1")
end


function AliceBonusTreeItem:showUnselected()
    self.isShowItem = true
    self.isClick = true
    self.m_lab_win:setVisible(false)
    self:runCsbAction("over1")
end

function AliceBonusTreeItem:onEnter()

end

function AliceBonusTreeItem:onExit()

end


function AliceBonusTreeItem:clickFunc(sender )
    if self.isClick or self.isShowItem then
        return
    end
    
    self.m_func(self.m_index)
end

function AliceBonusTreeItem:showItemStatus()
    return self.isShowItem
end

return AliceBonusTreeItem