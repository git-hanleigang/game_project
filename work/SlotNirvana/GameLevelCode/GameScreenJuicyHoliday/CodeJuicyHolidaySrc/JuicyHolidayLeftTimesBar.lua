---
--xcyy
--2018年5月23日
--JuicyHolidayLeftTimesBar.lua
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayLeftTimesBar = class("JuicyHolidayLeftTimesBar",util_require("base.BaseView"))


function JuicyHolidayLeftTimesBar:initUI()

    self:createCsbNode("JuicyHoliday_cishuBar.csb")
    self:runCsbAction("idle",true)

    self.m_items = {}
    for index = 1,3 do
        local item = util_createAnimation("JuicyHoliday_jackpotkuang_base_dian.csb")
        self:findChild("Node_"..index):addChild(item)
        self.m_items[index] = item
        for iTimes = 1,3 do
            item:findChild("Node_"..iTimes):setVisible(index == iTimes)
            item:findChild("sp_high_light_"..iTimes) :setVisible(false)
        end
    end
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function JuicyHolidayLeftTimesBar:initSpineUI()
    
end

--[[
    刷新剩余次数
]]
function JuicyHolidayLeftTimesBar:updateTimes(curTimes,isInit)
    for index = 1,3 do
        local item = self.m_items[index]
        item:findChild("sp_high_light_"..index) :setVisible(curTimes >= index)
    end
    self.m_curTimes = curTimes
end

--[[
    重置次数动画
]]
function JuicyHolidayLeftTimesBar:resetTimesAni(curTimes,func)
    if curTimes >= 3 then
        if type(func) == "function" then
            func()
        end
        return
    end

    if curTimes < 0 then
        curTimes = 0
    end
    local aniItem = self.m_items[curTimes + 1]
    local aniName = "actionframe2"
    -- if curTimes == 2 then
    --     aniName = "actionframe2"
    -- end
    aniItem:runCsbAction(aniName)

    local light = util_createAnimation("JuicyHoliday_jackpotkuang_base_dian_2.csb")
    aniItem:findChild("Node_dian_2"):addChild(light)
    light:runCsbAction(aniName,false,function()
        if not tolua.isnull(light) then
            light:removeFromParent()
        end
    end)

    performWithDelay(self,function()
        --切换数字
        for index = 1,3 do
            local item = self.m_items[index]
            item:findChild("sp_high_light_"..index) :setVisible(curTimes + 1 >= index)
        end
    end,8 / 60)

    -- performWithDelay(self,function()
    --     self:resetTimesAni(curTimes + 1,func)
    -- end,15 / 60)
    self:resetTimesAni(curTimes + 1,func)
end

return JuicyHolidayLeftTimesBar