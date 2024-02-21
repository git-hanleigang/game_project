---
--xcyy
--2018年5月23日
--DragonsBallWildLabView.lua

local DragonsBallWildLabView = class("DragonsBallWildLabView", util_require("base.BaseView"))

function DragonsBallWildLabView:initUI()
    self:createCsbNode("Dragons_longzhuLab.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
end

function DragonsBallWildLabView:onEnter()
end

function DragonsBallWildLabView:playBallLabWildEffect(_num)
    local lab = self:findChild("m_lb_Num") -- 获得子节点
    lab:setString("X" .. _num)
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    ) -- 播放时间线
end

function DragonsBallWildLabView:playBallLabOveeEffect()
    self:runCsbAction(
        "over",
        false,
        function()
        end
    ) -- 播放时间线
end

function DragonsBallWildLabView:onExit()
end


return DragonsBallWildLabView
