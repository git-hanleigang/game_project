---
--xcyy
--2018年5月23日
--WestJackPotBarView.lua

local WestJackPotBarView = class("WestJackPotBarView",util_require("base.BaseView"))

local GrandName = "GRAND"
local MajorName = "MAJOR"
local MinorName = "MINOR"
local MiniName = "MINI" 

function WestJackPotBarView:initUI()

    self:createCsbNode("West_jackpot.csb")

    self:runCsbAction("idle1")
end

---
-- 更新freespin 剩余次数
--
function WestJackPotBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WestJackPotBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    
end


function WestJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function WestJackPotBarView:onEnter()

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function WestJackPotBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

-- 更新jackpot 数值信息
--
function WestJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function WestJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.75,sy=0.75}
    local info2={label=label2,sx=0.75,sy=0.75}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.75,sy=0.75}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.75,sy=0.75}
    self:updateLabelSize(info1,182)
    self:updateLabelSize(info2,167)
    self:updateLabelSize(info3,146)
    self:updateLabelSize(info4,137)
end

function WestJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function WestJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return WestJackPotBarView