---
--xcyy
--2018年5月23日
--DragonParadeWildLockNumView.lua

local DragonParadeWildLockNumView = class("DragonParadeWildLockNumView",util_require("Levels.BaseLevelDialog"))


function DragonParadeWildLockNumView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("DragonParade_base_zuo.csb")

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

function DragonParadeWildLockNumView:runIdle( )
    self:runCsbAction("idle", true)
end

function DragonParadeWildLockNumView:showView( )
    if self:isVisible() == false then
        self:setVisible(true)
        self:runCsbAction("start", false, function()
            self:runIdle( )
        end)
    end
end

function DragonParadeWildLockNumView:hideView( )
    self:runCsbAction("over", false, function()
        self:findChild("m_lb_num"):setString(3)
        self:setVisible(false)
    end)
end

function DragonParadeWildLockNumView:setNum( num )
    self:findChild("m_lb_num"):setString(num)
end

--设置num
function DragonParadeWildLockNumView:setNumWithAnim( num )
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", false, function()
        self:runIdle( )
    end)
    performWithDelay(self, function()
        self:setNum( num )
    end, 15/60)
end

return DragonParadeWildLockNumView