---
--xcyy
--2018年5月23日
--HallowinRespinBar.lua

local HallowinRespinBar = class("HallowinRespinBar",util_require("base.BaseView"))


function HallowinRespinBar:initUI()

    self:createCsbNode("Hallowin_tishitiao.csb")

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
    self.m_labCount = self:findChild("m_lb_num")
    self:runCsbAction("idle1")
end

function HallowinRespinBar:respinChangePick(pickNum)
    self:runCsbAction("switch1")
    performWithDelay(self, function()
        self.m_labCount:setString(pickNum)
    end, 0.3)
    self.m_pickNum = pickNum
end

function HallowinRespinBar:changeCount(num)
    self:runCsbAction("idle1")
    self.m_labCount:setString(num)
end

function HallowinRespinBar:subPickNum()
    self.m_pickNum = self.m_pickNum - 1
    self.m_labCount:setString(self.m_pickNum)
end

function HallowinRespinBar:addPickNum(num)
    self:runCsbAction("add")
    self.m_pickNum = self.m_pickNum + num
    self.m_labCount:setString(self.m_pickNum)
end

function HallowinRespinBar:getEndNode()
    return self.m_labCount
end

function HallowinRespinBar:addRsTimes()
    self:runCsbAction("add2")
end

function HallowinRespinBar:getPickNum()
    return self.m_pickNum
end

function HallowinRespinBar:onEnter()

end

function HallowinRespinBar:onExit()
 
end

return HallowinRespinBar