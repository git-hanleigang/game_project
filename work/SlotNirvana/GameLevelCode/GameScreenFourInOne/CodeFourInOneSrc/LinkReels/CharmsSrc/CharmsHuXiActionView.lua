---
--xcyy
--2018年5月23日
--CharmsHuXiActionView.lua

local CharmsHuXiActionView = class("CharmsHuXiActionView",util_require("base.BaseView"))


function CharmsHuXiActionView:initUI()

    self:createCsbNode("LinkReels/CharmsLink/4in1_Socre_Charms_hx.csb")

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


function CharmsHuXiActionView:onEnter()
 

end

function CharmsHuXiActionView:showAdd()
    
end
function CharmsHuXiActionView:onExit()
 
end

return CharmsHuXiActionView