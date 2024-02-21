---
--island
--2018年4月12日
--PoseidonFreeSpinBar.lua
--
-- PoseidonFreeSpinBar top bar

local PoseidonFreeSpinBar = class("PoseidonFreeSpinBar", util_require("base.BaseView"))
-- 构造函数
function PoseidonFreeSpinBar:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Poseidon_FreeSpin_Bar_remain.csb"
    self:createCsbNode(resourceFilename)
end

function PoseidonFreeSpinBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

---
-- 更新freespin 剩余次数
--
function PoseidonFreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function PoseidonFreeSpinBar:updateFreespinCount(leftCount)
    if leftCount == 1 then
        self.m_csbOwner["m_lb_num"]:setString(leftCount)

    elseif leftCount == 0 then
        self.m_csbOwner["m_lb_num"]:setString("")

    else
        self.m_csbOwner["m_lb_num"]:setString(leftCount)

    end

    if leftCount > 1 then
        self.m_csbOwner["m_lb_tip"]:setPositionX(134)
        self.m_csbOwner["m_lb_tip"]:setString("FREE SPINS REMAINING")
    elseif leftCount == 1 then
        self.m_csbOwner["m_lb_tip"]:setPositionX(134)
        self.m_csbOwner["m_lb_tip"]:setString("FREE SPIN REMAINING")
    else
        self.m_csbOwner["m_lb_tip"]:setPositionX(109)
        self.m_csbOwner["m_lb_tip"]:setString("LAST SPIN")
    end
    -- self:runCsbAction("actionframe")
end

function PoseidonFreeSpinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
return PoseidonFreeSpinBar