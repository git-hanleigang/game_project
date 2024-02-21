---
--xcyy
--2018年5月23日
--CoinConiferDarkView.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConiferDarkView = class("CoinConiferDarkView",util_require("Levels.BaseLevelDialog"))


function CoinConiferDarkView:initUI(params)

    self:createCsbNode("CoinConifer/FreeSpin_beijing.csb")
    self.m_machine = params.machine
    

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CoinConiferDarkView:initSpineUI()
    --树
    self.tree = util_spineCreate("CoinConifer_jackpot", true, true)
    self:findChild("Node_tree"):addChild(self.tree)
end

function CoinConiferDarkView:showBigTreeActForChoose()
    
    util_spinePlay(self.tree,"start_tanban",false)
    util_spineEndCallFunc(self.tree,"start_tanban",function()
        util_spinePlay(self.tree,"idle_tanban",true)
    end)
end

function CoinConiferDarkView:showIdleForReset()
    self:runCsbAction("idle2")
end

function CoinConiferDarkView:showStartView()
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
    end)
end

function CoinConiferDarkView:showOverView(func)
    self:runCsbAction("over",false,function ()
        if func then
            func()
        end
    end)
end


return CoinConiferDarkView