---
--xcyy
--2018年5月23日
--FourInOne_FS_LogoBGView.lua

local FourInOne_FS_LogoBGView = class("FourInOne_FS_LogoBGView",util_require("base.BaseView"))


function FourInOne_FS_LogoBGView:initUI()

    self:createCsbNode("FourInOne_bg_guang.csb")

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


function FourInOne_FS_LogoBGView:onEnter()
 

end

function FourInOne_FS_LogoBGView:showAdd()
    
end
function FourInOne_FS_LogoBGView:onExit()
 
end

--默认按钮监听回调
function FourInOne_FS_LogoBGView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FourInOne_FS_LogoBGView