---
--island
--2018年4月12日
--ZeusGameBg.lua
--
-- ZeusGameBg top bar

local ZeusGameBg = class("ZeusGameBg", util_require("base.BaseView"))
-- 构造函数
function ZeusGameBg:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Zeus/GameScreenZeusBg_0.csb"
    self:createCsbNode(resourceFilename)

end

function ZeusGameBg:onEnter()
    
end

function ZeusGameBg:onExit()

end



return ZeusGameBg