---
--xcyy
--2018年5月23日
--EgyptViewTip.lua

local EgyptViewTip = class("EgyptViewTip",util_require("base.BaseView"))


function EgyptViewTip:initUI()

    self:createCsbNode("Egypt_tips.csb")

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

    self.m_animationID = 1
    self:runCsbAction("idle"..self.m_animationID)

    schedule(self, function()
        self:showAnimation()
    end, 8)
end

function EgyptViewTip:onEnter()
 

end

function EgyptViewTip:showAnimation()
    self:runCsbAction("animation"..self.m_animationID, false, function()
        self.m_animationID = self.m_animationID + 1
        if self.m_animationID > 3 then
            self.m_animationID = 1
        end
        self:runCsbAction("idle"..self.m_animationID)
    end)
end

function EgyptViewTip:onExit()
 
end

--默认按钮监听回调
function EgyptViewTip:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return EgyptViewTip