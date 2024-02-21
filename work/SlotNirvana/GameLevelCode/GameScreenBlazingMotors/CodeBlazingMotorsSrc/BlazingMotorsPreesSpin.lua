---
--xcyy
--2018年5月23日
--BlazingMotorsPreesSpin.lua

local BlazingMotorsPreesSpin = class("BlazingMotorsPreesSpin",util_require("base.BaseView"))

BlazingMotorsPreesSpin.callfunc = nil

function BlazingMotorsPreesSpin:initUI()

    self:createCsbNode("BlazingMotors_PressToSpin.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    
    self.callfunc = nil


    -- self:addClick(self:findChild("BlazingMotors_Press")) -- 非按钮节点得手动绑定监听
    
    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function BlazingMotorsPreesSpin:onEnter()
 

end

function BlazingMotorsPreesSpin:initCallFunc(func)
    self.callfunc = func
end
function BlazingMotorsPreesSpin:onExit()
 
end

--默认按钮监听回调
function BlazingMotorsPreesSpin:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "BlazingMotors_Press" then

       if self.callfunc then
            self.callfunc()
       end 

       self:removeFromParent(true)
    end


end


return BlazingMotorsPreesSpin