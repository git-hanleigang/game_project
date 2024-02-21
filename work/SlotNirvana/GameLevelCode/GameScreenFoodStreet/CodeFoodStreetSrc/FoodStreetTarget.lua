---
--xcyy
--2018年5月23日
--FoodStreetTarget.lua

local FoodStreetTarget = class("FoodStreetTarget",util_require("base.BaseView"))


function FoodStreetTarget:initUI()

    self:createCsbNode("FoodStreet_zhujiemianjianzhu.csb")

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

    local index = 0
    while true do
        local name = self:getChildName(index)
        local house = self:findChild(name)
        if house ~= nil then
            house:setVisible(false)
        else
            break
        end
        index = index + 1
    end
end

function FoodStreetTarget:updateUI(id)
    if self.m_groupId ~= nil then
        self:findChild(self:getChildName(self.m_groupId)):setVisible(false)
    end
    self.m_groupId = id
    self:findChild(self:getChildName(self.m_groupId)):setVisible(true)
end

function FoodStreetTarget:getChildName(id)
    if id == 0 then
        return "DOG_0"
    else
        return "HOUSE_"..id
    end
end

function FoodStreetTarget:onEnter()

end

function FoodStreetTarget:onExit()
 
end

return FoodStreetTarget