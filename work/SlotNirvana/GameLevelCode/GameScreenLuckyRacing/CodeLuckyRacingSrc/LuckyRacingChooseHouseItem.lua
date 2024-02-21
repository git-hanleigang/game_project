---
--xcyy
--2018年5月23日
--LuckyRacingChooseHouseItem.lua

local LuckyRacingChooseHouseItem = class("LuckyRacingChooseHouseItem",util_require("base.BaseView"))


function LuckyRacingChooseHouseItem:initUI(params)
    self.m_index = params.index
    self.m_parentView = params.parent
    self.m_isSelected = false
    self:createCsbNode("LuckyRacing_ChooseHorse.csb")
    for index = 1,4 do
        self:findChild("choose_"..(index - 1)):setVisible(index == self.m_index)
    end

    self:runIdle()

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    local size = self:findChild("choose_"..(params.index - 1)):getContentSize()
    local scale = self:findChild("choose_"..(params.index - 1)):getScale()
    layout:setContentSize(CCSizeMake(size.width * scale,size.height * scale))
    layout:setTouchEnabled(true)
    self:addClick(layout)
end

--[[
    点击按钮
]]
function LuckyRacingChooseHouseItem:clickFunc(sender)
    if self.m_parentView:getCurHourse() == self.m_index or self.m_parentView.m_isRunChooseAni then
        return
    end

    gLobalSoundManager:playSound("LuckyRacingSounds/sound_LuckyRacing_click_select.mp3")
    self.m_parentView:updateChooseHourse(self.m_index)
end

--[[
    idle
]]
function LuckyRacingChooseHouseItem:runIdle()
    self.m_isSelected = false
    self:runCsbAction("idleframe",true)
end

--[[
    结束特效
]]
function LuckyRacingChooseHouseItem:overAni(func)
    self.m_isSelected = false
    self:runCsbAction("over",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    选中特效
]]
function LuckyRacingChooseHouseItem:runSelectAni(func)
    self.m_isSelected = true
    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("idleframe2",true)
        if type(func) == "function" then
            func()
        end
    end)
end

return LuckyRacingChooseHouseItem