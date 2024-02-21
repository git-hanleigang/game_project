---
--xcyy
--2018年5月23日
--JuicyHolidayMultiBar.lua
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayMultiBar = class("JuicyHolidayMultiBar",util_require("base.BaseView"))

local MULTI_CONFIG = {1,2,3,5,10,25}

function JuicyHolidayMultiBar:initUI()

    self:createCsbNode("JuicyHoliday_allwinBar.csb")

    self.m_items = {}
    for index = 1,#MULTI_CONFIG do
        local multi = MULTI_CONFIG[index]
        local item = util_createAnimation("JuicyHoliday_jackpotkuang_cishu_dian.csb")
        self:findChild("Node_"..multi):addChild(item)

        local itemLight = util_createAnimation("JuicyHoliday_jackpotkuang_cishu_dian_tx.csb")
        item:findChild("Node_"..multi.."x"):addChild(itemLight)
        item.m_light = itemLight

        for iMulti = 1,#MULTI_CONFIG do
            item:findChild("Node_bg_"..MULTI_CONFIG[iMulti]):setVisible(MULTI_CONFIG[iMulti] == multi)
            item:findChild("Node_"..MULTI_CONFIG[iMulti]):setVisible(MULTI_CONFIG[iMulti] == multi)
            item:findChild("sp_bg_"..MULTI_CONFIG[iMulti]):setVisible(MULTI_CONFIG[iMulti] == multi)
            item:findChild("sp_highLight_"..MULTI_CONFIG[iMulti]):setVisible(false)
            item:findChild("sp_zi_low_"..MULTI_CONFIG[iMulti]):setVisible(MULTI_CONFIG[iMulti] == multi)
            item:findChild("sp_zi_high_"..MULTI_CONFIG[iMulti]):setVisible(false)
            item:findChild("idle2_"..MULTI_CONFIG[iMulti]):setVisible(MULTI_CONFIG[iMulti] == multi)
        end

        self.m_items[tostring(multi)] = item
    end

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JuicyHolidayMultiBar:initSpineUI()
    for index = 1,#MULTI_CONFIG do
        local multi = MULTI_CONFIG[index]
        local item = self.m_items[tostring(multi)]

        --倍数提示光效
        local tipLight = util_spineCreate("JuicyHoliday_jackpotkuang_cishu",true,true)
        item:findChild("Node_"..multi.."x"):addChild(tipLight)
        item.m_tipLight = tipLight
        tipLight:setVisible(false)
        -- if multi == 25 then
        --     util_spinePlay(tipLight,"actionframe_25x",true)
        -- else
        --     util_spinePlay(tipLight,"actionframe",true)
        -- end
    end
end

--[[
    刷新倍数显示
]]
function JuicyHolidayMultiBar:updateMultiShow(multi)
    for key,item in pairs(self.m_items) do
        item:findChild("sp_highLight_"..key):setVisible(multi == tonumber(key))
        item:findChild("sp_zi_high_"..key):setVisible(multi == tonumber(key))
        item:runCsbAction("idle")
        if multi == tonumber(key) then
            item.m_light:setVisible(false)
        elseif multi < tonumber(key) then
            item.m_light:setVisible(true)
            item.m_light:runCsbAction("idle",true)
        end
        if not tolua.isnull(item.m_tipLight) then
            item.m_tipLight:setVisible(false)
        end
    end
    self.m_curMulti = multi
end

--[[
    刷新倍数显示
]]
function JuicyHolidayMultiBar:updateMultiShowWithAni(multi)
    if multi == self.m_curMulti then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_update_cur_multi"])
    local targetItem,preItem
    local zOrder = 10
    for key,item in pairs(self.m_items) do
        item:findChild("sp_highLight_"..key):setVisible(multi == tonumber(key))
        item:findChild("sp_zi_high_"..key):setVisible(multi == tonumber(key))
        if multi == tonumber(key) then
            targetItem = item
            item:getParent():setLocalZOrder(100)
        else
            item:getParent():setLocalZOrder(tonumber(key))
        end
        zOrder  = zOrder + 1

        if self.m_curMulti == tonumber(key) then
            preItem = item
        end
    end

    
    if targetItem then
        local aniName = "actionframe_2x3x"
        if multi == 5 or multi == 10 then
            aniName = "actionframe_5x10x"
        elseif multi > 10 then
            aniName = "actionframe_25x"
        end

        local tempLight = util_createAnimation("JuicyHoliday_jackpotkuang_cishu_dian_tx_1.csb")
        targetItem:findChild("Node_"..multi.."x_0"):addChild(tempLight)
        tempLight:runCsbAction(aniName,false,function()
            if not tolua.isnull(tempLight) then
                tempLight:removeFromParent()
            end
            
        end)
    end

    if preItem then
        preItem.m_light:setVisible(true)
        preItem.m_light:runCsbAction("idle2",false,function()
            -- if not tolua.isnull(preItem.m_light) then
            --     preItem.m_light:runCsbAction("idle",true)
            -- end
        end)
    end

    self.m_curMulti = multi
end

--[[
    显示倍数提示
]]
function JuicyHolidayMultiBar:showMultiTipAni()
    for key,multiItem in pairs(self.m_items) do
        if tonumber(key) ~= self.m_curMulti then
            multiItem:getParent():setLocalZOrder(tonumber(key))
        else
            multiItem:getParent():setLocalZOrder(100)
        end
        
    end
    local item = self.m_items[tostring(self.m_curMulti)]
    if not tolua.isnull(item) then
        local aniName = "actionframe2"
        if self.m_curMulti > 5 then
            aniName = "actionframe"
        end

        item:runCsbAction("actionframe",true)
        if not tolua.isnull(item.m_tipLight) then
            item.m_tipLight:setVisible(true)
            util_spinePlay(item.m_tipLight,aniName,true)
        end
    end
end

return JuicyHolidayMultiBar