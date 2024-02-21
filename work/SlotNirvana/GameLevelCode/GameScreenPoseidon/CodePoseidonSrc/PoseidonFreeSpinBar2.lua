---
--island
--2018年4月12日
--PoseidonFreeSpinBar2.lua
--
-- PoseidonFreeSpinBar2 top bar

local PoseidonFreeSpinBar2 = class("PoseidonFreeSpinBar2", util_require("base.BaseView"))
PoseidonFreeSpinBar2.m_freeSpinCount = nil
PoseidonFreeSpinBar2.m_scatterAnima = nil

-- 构造函数
function PoseidonFreeSpinBar2:initUI(machine)
    self.m_machine=machine
    self.m_freeSpinCount = 0
    self.m_scatterAnima = nil
    local resourceFilename="Poseidon_FreeSpin_Bar.csb"
    self:createCsbNode(resourceFilename)
    self:addScatterAddAnima()
end

function PoseidonFreeSpinBar2:onEnter()
    -- gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
    --     self:changeFreeSpinByCount(params)
    -- end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function PoseidonFreeSpinBar2:addScatterAddAnima()
    self.m_scatterAnima = self.m_machine:getSlotNodeBySymbolType(10008)
    self.m_csbOwner["node_anima"]:addChild(self.m_scatterAnima)
end

function PoseidonFreeSpinBar2:addFreespinCount(addNum)
    self.m_freeSpinCount = self.m_freeSpinCount + addNum
    self:setFreeSpinNum(self.m_freeSpinCount)
    self:runCsbAction("actionframe")
    self.m_scatterAnima:runAnim("actionframe")
end
function PoseidonFreeSpinBar2:setfreeSpinCount(num)
    self.m_freeSpinCount = num
end
function PoseidonFreeSpinBar2:setFreeSpinNum(num)

    if num ~= "" then
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_LiZi_boom.mp3")
    end
    
    self.m_csbOwner["m_lb_num"]:setString(self.m_freeSpinCount)

end

function PoseidonFreeSpinBar2:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
return PoseidonFreeSpinBar2