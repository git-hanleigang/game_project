---
--xcyy
--2018年5月23日
--GoldenMammothLeftBar.lua

local GoldenMammothLeftBar = class("GoldenMammothLeftBar",util_require("base.BaseView"))

GoldenMammothLeftBar.m_labCount = nil

function GoldenMammothLeftBar:initUI()

    self:createCsbNode("GoldenMammoth_leftbar.csb")
    self.m_labCount = self:findChild("lab_count")
    
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
    self:runCsbAction("idle")
end

function GoldenMammothLeftBar:onEnter()
 

end

function GoldenMammothLeftBar:onExit()
 
end

function GoldenMammothLeftBar:showLeftBar()
    self:runCsbAction("show")
end

function GoldenMammothLeftBar:hideLeftBar()
    self:runCsbAction("over")
end

function GoldenMammothLeftBar:showCountChange(count)
    self:runCsbAction("actionframe")
    performWithDelay(self, function ()
	    self:updateCountNum(count)
    end, 0.5)
end

function GoldenMammothLeftBar:updateCountNum(count)
    self.m_labCount:setString(count)
end

return GoldenMammothLeftBar