---
--xcyy
--2018年5月23日
--DragonParadeFreeMidView.lua

local DragonParadeFreeMidView = class("DragonParadeFreeMidView",util_require("Levels.BaseLevelDialog"))


function DragonParadeFreeMidView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("DragonParade_FG_mid.csb")

    local lightAni = util_createAnimation("DragonParade_tanban_guang.csb")
    self:findChild("tanban_guang"):addChild(lightAni)
    lightAni:runCsbAction("idleframe", true)


    util_setCascadeOpacityEnabledRescursion(self, true)
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

function DragonParadeFreeMidView:runDisAppear( )
    self:runCsbAction("shouji", false)
end

function DragonParadeFreeMidView:runIdle( )
    self:runCsbAction("idle", true)
end
--反馈
function DragonParadeFreeMidView:runFeedBack( )
    self:runCsbAction("actionframe", false, function()
        self:runIdle( )
    end)
end
--最终收集动画
function DragonParadeFreeMidView:runTriggerFinal( )
    self:runCsbAction("actionframe2", false, function()
        self:runCsbAction("idle2", true)
    end)
end

return DragonParadeFreeMidView