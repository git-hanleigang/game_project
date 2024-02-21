---
--smy
--2018年4月26日
--AZTECBonusItem.lua

local AZTECBonusItem = class("AZTECBonusItem",util_require("base.BaseView"))

-- show  -开场的
-- idleframe
-- down  --点击
-- black --
-- 


function AZTECBonusItem:initUI(data)
    self:createCsbNode("AZTEC_jinbi.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)
    self.m_index = data
    self:setClickEnabled(true)
    self.isShowItem = false
end

function AZTECBonusItem:setClickFunc(func)
    self.m_func = func
end

function AZTECBonusItem:showItemStart()

    self:runCsbAction("idleframe", true)
end

function AZTECBonusItem:showFly()
    self:runCsbAction("fly", false, function ()
        self:runCsbAction("fly")
    end)
end

function AZTECBonusItem:showResult(result, func, callback)
    self.isShowItem = true
    self:setClickEnabled(false)
    
    self:runCsbAction("turn"..result, false, function()
        if func ~= nil then 
            func()
        end
        if callback ~= nil then
            callback()
        end
    end)
    if result == "Super" then
        performWithDelay(self, function()
            gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_super_appear.mp3")
        end, 0.5)
    end
    -- gLobalSoundManager:playSound("AZTECSounds/music_AZTEC_item_open.mp3")
end

function AZTECBonusItem:showSelected(result)
    self.isShowItem = true
    self:setClickEnabled(false)
    self:runCsbAction("idle"..result)
end

function AZTECBonusItem:runDelete(result)
    self.isShowItem = true
    self:setClickEnabled(false)
    self:runCsbAction("turn"..result.."2")
end

function AZTECBonusItem:showDelete(result)
    self.isShowItem = true
    self:setClickEnabled(false)
    self:runCsbAction("animation"..result)
end

function AZTECBonusItem:showReward(result)
    self:runCsbAction(result.."_zj")
end

function AZTECBonusItem:showSuper(func)
    self:runCsbAction("Super_zj", false, function()
        self:runCsbAction("idleSuper")
        if func ~= nil then 
            func()
        end
    end)
end

function AZTECBonusItem:onEnter()

end

function AZTECBonusItem:onExit()

end


function AZTECBonusItem:clickFunc(sender)
    if self.isClick or self.isShowItem then
        return
    end
    self.m_func(self.m_index)
end

function AZTECBonusItem:setClickEnabled(isEnable)
    self.isClick = not isEnable
end


return AZTECBonusItem