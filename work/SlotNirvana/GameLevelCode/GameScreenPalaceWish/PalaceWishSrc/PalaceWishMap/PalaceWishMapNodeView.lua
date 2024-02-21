---
--xcyy
--2018年5月23日
--PalaceWishMapNodeView.lua

local PalaceWishMapNodeView = class("PalaceWishMapNodeView",util_require("Levels.BaseLevelDialog"))

PalaceWishMapNodeView.townIndexList = {1, 6, 12, 19}

function PalaceWishMapNodeView:initUI(csbName, index)
    self.m_index = index
    self:createCsbNode(csbName..".csb")

    
    if self:isBigNode() then

    else
        --勾
        self.m_tick = util_spineCreate("PalaceWish_ditudagou", true, true)
        self:findChild("Node_5"):addChild(self.m_tick)
        self.m_tick:setVisible(false)
    end
    
    
end

function PalaceWishMapNodeView:isBigNode()
    if self.m_index == self.townIndexList[1] then
        return true
    elseif self.m_index == self.townIndexList[2] then
        return true
    elseif self.m_index == self.townIndexList[3] then
        return true
    elseif self.m_index == self.townIndexList[4] then
        return true
    else
        return false
    end

    return false
end

--点触发动画
function PalaceWishMapNodeView:runTrigger(func)
    if self:isBigNode() then
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_map_big_trigger.mp3")

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_juese_language_1.mp3")
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("yaan", true)
        end)
        performWithDelay(self, function()
            if func then
                func()
            end
        end, 60/60 + 0.5)
    else

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_map_small_trigger.mp3")

        self.m_tick:setVisible(true)
        util_spinePlay(self.m_tick, "actionframe", false)
        local spineEndCallFunc = function()
            util_spinePlay(self.m_tick, "idleframe", true)
            
        end
        util_spineEndCallFunc(self.m_tick, "actionframe", spineEndCallFunc)

        performWithDelay(self, function()
            if func then
                func()
            end
        end, 10/30 + 0.5)
    end
end

--设置idle动画
function PalaceWishMapNodeView:runIdle(lockStr)
    if self:isBigNode() then
        if lockStr == "lock" then
            self:runCsbAction("idleframe", true)
        else
            self:runCsbAction("yaan", true)
        end
        
    else
        if lockStr == "lock" then
            self.m_tick:setVisible(false)
        else
            self.m_tick:setVisible(true)
            util_spinePlay(self.m_tick, "idleframe", true)
        end
    end
end

function PalaceWishMapNodeView:onEnter()
    PalaceWishMapNodeView.super.onEnter(self)

end

function PalaceWishMapNodeView:onExit()
    PalaceWishMapNodeView.super.onExit(self)
end


return PalaceWishMapNodeView