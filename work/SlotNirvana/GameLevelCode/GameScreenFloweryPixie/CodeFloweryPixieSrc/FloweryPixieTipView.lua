---
--xcyy
--2018年5月23日
--FloweryPixieTipView.lua

local FloweryPixieTipView = class("FloweryPixieTipView",util_require("base.BaseView"))


function FloweryPixieTipView:initUI()

    self:createCsbNode("FloweryPixie_jackPoTip.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    self:addClick(self:findChild("Panel_1")) -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function FloweryPixieTipView:onEnter()
 

end

function FloweryPixieTipView:showAdd()
    
end
function FloweryPixieTipView:onExit()
 
end

function FloweryPixieTipView:clickFunc(sender)
    local name = sender:getName()

    if name == "Panel_1" then
        if self.m_isShow then
            self.m_isShow = false
            self:runCsbAction("over",false,function(  )
                
                self:setVisible(false)
            end)
            
        end
    end
  
end


return FloweryPixieTipView