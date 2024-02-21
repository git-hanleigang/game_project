---
--xcyy
--2018年5月23日
--QuickSpinView.lua

local QuickSpinView = class("QuickSpinView",util_require("base.BaseView"))


function QuickSpinView:initUI()

    self:createCsbNode("QuickSpin_Jackpot_zi.csb")

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

end


function QuickSpinView:onEnter()
 

end

function QuickSpinView:runAnimation(animation, loop, func)
    self:runCsbAction(animation, loop)
end

function QuickSpinView:setFreespinNum(num)
    if num == 0 then
        self:runAnimation("idle4", true)
    elseif leftFsCount == 1 then
        self:runAnimation("idle3", true)
    end
    self:findChild("freespin_times"):setString(num)
end

function QuickSpinView:onExit()
 
end

--默认按钮监听回调
function QuickSpinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return QuickSpinView