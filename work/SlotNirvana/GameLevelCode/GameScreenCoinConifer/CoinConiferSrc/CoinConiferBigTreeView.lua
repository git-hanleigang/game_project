---
--xcyy
--2018年5月23日
--CoinConiferBigTreeView.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConiferBigTreeView = class("CoinConiferBigTreeView",util_require("Levels.BaseLevelDialog"))


function CoinConiferBigTreeView:initUI(_machine)

    self:createCsbNode("CoinConifer_base_tree.csb")
    self.m_machine = _machine

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CoinConiferBigTreeView:initSpineUI()
    self.tree = util_spineCreate("CoinConifer_jackpot", true, true)
    self:findChild("Node_spine"):addChild(self.tree)
end

function CoinConiferBigTreeView:showBigTreeAct(actName,isloop,isCallFunc)
    if not tolua.isnull(self.tree) then
        util_spinePlay(self.tree,actName,isloop)
        if self.m_machine and self.m_machine.curTreeLevel == 3 then
            self:showParticle(true)
        else
            self:showParticle(false)
        end
        if isCallFunc ~= nil then
            util_spineEndCallFunc(self.tree,actName,function ()
                isCallFunc()
            end)
        end
    end
    
end

function CoinConiferBigTreeView:showParticle(isShow)
    local particle1 = self:findChild("Particle_1")
    local particle2 = self:findChild("Particle_2")
    local particle3 = self:findChild("Particle_3")
    if particle1 then
        particle1:setVisible(isShow)
    end
    if particle2 then
        particle2:setVisible(isShow)
    end
    if particle3 then
        particle3:setVisible(isShow)
    end
end


return CoinConiferBigTreeView