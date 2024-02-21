---
--xcyy
--2018年5月23日
--FoodStreetBuilding.lua

local FoodStreetBuilding = class("FoodStreetBuilding",util_require("base.BaseView"))

FoodStreetBuilding.m_groupId = nil
function FoodStreetBuilding:initUI(groupId)

    self:createCsbNode("FoodStreet_yanwu.csb")

    self.m_groupId = groupId

    for i=1,4 do
        local house = self:findChild("house_"..i)
        if house then
            house:setVisible(false)
        end
    end


    self:runAnim()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function FoodStreetBuilding:runAnim()
    self:runCsbAction("actionframe", false, function()
        if self.m_func ~= nil then

            local house = self:findChild("house_"..self.m_groupId)
            if house then
                house:setVisible(true) 
            end


            self:runCsbAction("actionframe1", false, function()
                self.m_func()
                self.m_func = nil
            end)
        else
            self:runAnim()
        end
    end)
end

function FoodStreetBuilding:setCallFunc(func)
    self.m_func = func
end

function FoodStreetBuilding:onEnter()

end

function FoodStreetBuilding:onExit()
 
end

--默认按钮监听回调
function FoodStreetBuilding:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FoodStreetBuilding