---
--xcyy
--2018年5月23日
--FoodStreetBtnEffect.lua

local FoodStreetBtnEffect = class("FoodStreetBtnEffect",util_require("base.BaseView"))


function FoodStreetBtnEffect:initUI(data)

    local fileName = "FoodStreet_anniusaoguang_0.csb"
    if data ~= nil then
        fileName = "FoodStreet_anniusaoguang.csb"
    end
    self:createCsbNode(fileName)

    self:runCsbAction("actionframe", true) -- 播放时间线
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

end


function FoodStreetBtnEffect:onEnter()
 

end

function FoodStreetBtnEffect:onExit()
 
end

return FoodStreetBtnEffect