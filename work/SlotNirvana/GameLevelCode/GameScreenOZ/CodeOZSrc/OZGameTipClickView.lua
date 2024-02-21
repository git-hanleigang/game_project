---
--xcyy
--2018年5月23日
--OZGameTipClickView.lua

local OZGameTipClickView = class("OZGameTipClickView",util_require("base.BaseView"))


function OZGameTipClickView:initUI()

    self:createCsbNode("OZ_jackPoTip_3.csb")

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


function OZGameTipClickView:onEnter()
 

end

function OZGameTipClickView:onExit()
 
end

function OZGameTipClickView:setOverCallFunc( func )
    self.m_Call = func
end

--默认按钮监听回调
function OZGameTipClickView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_1" then

        if self.m_Call then
            self.m_Call()
        end

        self:removeFromParent()

    end

end


return OZGameTipClickView