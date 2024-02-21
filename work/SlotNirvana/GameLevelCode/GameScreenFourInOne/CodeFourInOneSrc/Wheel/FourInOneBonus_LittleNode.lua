---
--xcyy
--2018年5月23日
--FourInOneBonus_LittleNode.lua

local FourInOneBonus_LittleNode = class("FourInOneBonus_LittleNode",util_require("base.BaseView"))


function FourInOneBonus_LittleNode:initUI(data)

    local csbpath =  data.csbName 
    self.m_posIndex =  data.posIndex 

    self:createCsbNode( "4in1_wheel_di_" .. csbpath .. ".csb")

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


function FourInOneBonus_LittleNode:onEnter()
 

end

function FourInOneBonus_LittleNode:showAdd()
    
end
function FourInOneBonus_LittleNode:onExit()
 
end

--默认按钮监听回调
function FourInOneBonus_LittleNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FourInOneBonus_LittleNode