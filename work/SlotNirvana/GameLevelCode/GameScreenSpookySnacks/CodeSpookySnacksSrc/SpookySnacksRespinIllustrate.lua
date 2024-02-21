---
--xcyy
--2018年5月23日
--SpookySnacksRespinIllustrate.lua
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksRespinIllustrate = class("SpookySnacksRespinIllustrate",util_require("Levels.BaseLevelDialog"))


function SpookySnacksRespinIllustrate:initUI(params)

    self:createCsbNode("SpookySnacks_respin_tanban.csb")
    self.m_machine = params.machine
    self.m_endFunc = params.func
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
    end)
    self.m_machine:delayCallBack(210/60,function ()
        self:showOver()
    end)
end

--[[
    关闭界面
]]
function SpookySnacksRespinIllustrate:showOver()
    self:runCsbAction("over",false,function()
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end

        self:removeFromParent()
    end)
end


return SpookySnacksRespinIllustrate