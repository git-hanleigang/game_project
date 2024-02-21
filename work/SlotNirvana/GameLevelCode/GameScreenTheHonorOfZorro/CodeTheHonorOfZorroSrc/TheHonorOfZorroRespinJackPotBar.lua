---
--xcyy
--2018年5月23日
--TheHonorOfZorroRespinJackPotBar.lua

local TheHonorOfZorroRespinJackPotBar = class("TheHonorOfZorroRespinJackPotBar",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins1"
local MajorName = "m_lb_coins2"
local MinorName = "m_lb_coins3"
local MiniName = "m_lb_coins4" 

local TIME_SPAN =   0.08    --刷新时间间隔
local TIME_MAX = 2          --切换间隔

local JACKPOT_TYPE = {
    "major",
    "minor",
    "mini",
}

function TheHonorOfZorroRespinJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("TheHonorOfZorro_respin_jackpot.csb")

    self:runCsbAction("idle",true)

    self.m_curTime = 0
    self.m_curJackpotIndex = 1

    --锁定动效
    self.m_lockNode = util_spineCreate("TheHonorOfZorro_jackpot",true,true)
    self:findChild("Node_lock"):addChild(self.m_lockNode)
    self.m_lockNode:setVisible(false)
    self.m_lockStatus = false
end

function TheHonorOfZorroRespinJackPotBar:onEnter()

    TheHonorOfZorroRespinJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,TIME_SPAN)
end

function TheHonorOfZorroRespinJackPotBar:onExit()
    TheHonorOfZorroRespinJackPotBar.super.onExit(self)
end

function TheHonorOfZorroRespinJackPotBar:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function TheHonorOfZorroRespinJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    --检测是否切换显示
    self.m_curTime = self.m_curTime + TIME_SPAN
    -- if self.m_curTime >= TIME_MAX then
    --     self.m_curTime = 0
    --     self.m_curJackpotIndex = self.m_curJackpotIndex + 1
    --     if self.m_curJackpotIndex > #JACKPOT_TYPE then
    --         self.m_curJackpotIndex = 1
    --     end 
    --     self:updataCurJackpotShow()
    -- end

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

--[[
    刷新当前jackpot显示
]]
function TheHonorOfZorroRespinJackPotBar:updataCurJackpotShow( )
    for index = 1,#JACKPOT_TYPE do
        self:findChild("Node_"..JACKPOT_TYPE[index]):setVisible(self.m_curJackpotIndex == index)
    end
end

function TheHonorOfZorroRespinJackPotBar:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.8,sy=0.8}
    local info2={label=label2,sx=0.8,sy=0.8}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.8,sy=0.8}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.8,sy=0.8}
    self:updateLabelSize(info1,388)
    self:updateLabelSize(info2,326)
    self:updateLabelSize(info3,326)
    self:updateLabelSize(info4,326)
end

function TheHonorOfZorroRespinJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index,self.m_machine:getTotalBet())
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    初始化锁定状态
]]
function TheHonorOfZorroRespinJackPotBar:initLockStatus(isLock)
    self.m_lockStatus = isLock
    util_spinePlay(self.m_lockNode,"idle")
    self.m_lockNode:setVisible(isLock)
end

--[[
    设置锁定状态
]]
function TheHonorOfZorroRespinJackPotBar:setLockStatus(isLock)
    if self.m_lockStatus == isLock then
        return
    end

    self.m_lockNode:stopAllActions()
    if isLock then
        self.m_lockNode:setVisible(true)
        util_spinePlay(self.m_lockNode,"suoding")
    else
        util_spinePlay(self.m_lockNode,"jiesuo")
        performWithDelay(self.m_lockNode,function()
            self.m_lockNode:setVisible(false)
        end,20 / 30)
    end
    self.m_lockStatus = isLock
end


return TheHonorOfZorroRespinJackPotBar