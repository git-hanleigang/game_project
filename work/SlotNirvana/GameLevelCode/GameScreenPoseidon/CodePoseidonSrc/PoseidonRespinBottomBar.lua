---
--island
--2018年4月12日
--PoseidonRespinBottomBar.lua
--
-- PoseidonRespinBottomBar top bar

local PoseidonRespinBottomBar = class("PoseidonRespinBottomBar", util_require("base.BaseView"))

PoseidonRespinBottomBar.m_totleCount = nil
PoseidonRespinBottomBar.m_leftCount = nil
-- 构造函数
function PoseidonRespinBottomBar:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Poseidon_Jp_Tip.csb"
    self:createCsbNode(resourceFilename)
    self.m_totleCount = 0
    self.m_leftCount = 0
end

function PoseidonRespinBottomBar:onEnter()

end

function PoseidonRespinBottomBar:setRespinCount(leftCount, totleCount)
    self.m_csbOwner["m_lb_num1"]:setString(leftCount)
    self.m_csbOwner["m_lb_num2"]:setString(totleCount)
    self.m_totleCount = totleCount
    self.m_leftCount = leftCount
end

function PoseidonRespinBottomBar:upRespinTotleCount( totleCount)
    self.m_csbOwner["m_lb_num2"]:setString(totleCount)

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_LiZi_boom.mp3")
    self:runCsbAction("actionframe1")
    self.m_totleCount = totleCount

end


function PoseidonRespinBottomBar:upRespinLeftCount(leftCount)
    self.m_csbOwner["m_lb_num1"]:setString(leftCount)
    -- if leftCount > 0 then
    --     gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_LiZi_boom.mp3")
    -- end
    
    -- self:runCsbAction("actionframe2")
    self.m_leftCount = leftCount
end
function PoseidonRespinBottomBar:leftCountEqualTotleCount()
    if self.m_leftCount == self.m_totleCount then
        return true
    else
        return false
    end
end

function PoseidonRespinBottomBar:onExit()
end
return PoseidonRespinBottomBar