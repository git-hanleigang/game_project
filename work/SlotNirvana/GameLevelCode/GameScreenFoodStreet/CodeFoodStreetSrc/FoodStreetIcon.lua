---
--xcyy
--2018年5月23日
--FoodStreetIcon.lua

local FoodStreetIcon = class("FoodStreetIcon",util_require("base.BaseView"))


function FoodStreetIcon:initUI()

    self:createCsbNode("FoodStreet_touxiang.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

    self:runCsbAction("idle")
    self:findChild("symbol_92"):setVisible(false)
    local index = 0
    while true do
        local icon = self:findChild("symbol_"..index)
        if icon ~= nil then
            icon:setVisible(false)
        else
            break
        end
        index = index + 1
    end
end

function FoodStreetIcon:updateIcon(type)
    if self.m_currType ~= nil then
        self:findChild("symbol_"..self.m_currType):setVisible(false)
    end
    self.m_currType = type
    self:findChild("symbol_"..self.m_currType):setVisible(true)
end

function FoodStreetIcon:collectAnim()
    self:runCsbAction("shouji")
end

function FoodStreetIcon:onEnter()

end

function FoodStreetIcon:onExit()
 
end

return FoodStreetIcon