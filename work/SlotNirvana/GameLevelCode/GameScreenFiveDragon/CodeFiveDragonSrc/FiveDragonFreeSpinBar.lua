---
--island
--2018年4月12日
--FreeSpinBar.lua
--
-- FreeSpinBar top bar

local FreeSpinBar = class("FreeSpinBar", util_require("base.BaseView"))

FreeSpinBar.m_nowCount = nil
FreeSpinBar.m_upEndCallBack = nil
-- 构造函数
function FreeSpinBar:initUI(machine)
    self.m_machine=machine
    local resourceFilename="FiveDragon/FreeSpinBar.csb"
    self:createCsbNode(resourceFilename)
    
    self.m_nowCount = 0
end

function FreeSpinBar:showFsBar()
    self:runCsbAction("start")
end

function FreeSpinBar:changeFsCount(nowCount)
    self.m_nowCount = nowCount
    self.m_csbOwner["lb_fs_num"]:setString(nowCount) 
end

function FreeSpinBar:setUpEndCallBackFun(callBackFun)
    self.m_upEndCallBack = callBackFun
end

---
-- 更新freespin 剩余次数
--
function FreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function FreeSpinBar:updateFreespinCount(totleCount)
    -- self.m_csbOwner["m_lb_num"]:setString(leftCount)
    self.m_upFsTimeaction = util_schedule(self, function(  )
        self.m_nowCount = self.m_nowCount + 1
        if self.m_nowCount == 20 or self.m_nowCount == 1 or self.m_nowCount == 50 then
            self:runCsbAction("animation0")
        end
        if self.m_nowCount >= 0   then
            if self.m_nowCount <= 20 then
                gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_Num_change_1.mp3")
            elseif self.m_nowCount > 20 and self.m_nowCount <= 50  then
                gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_Num_change_2.mp3")
            elseif self.m_nowCount > 50 and self.m_nowCount <= 100  then
                gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_Num_change_3.mp3")
            else
                gLobalSoundManager:playSound("FiveDragonSounds/sound_FiveDragon_Num_change_4.mp3")
            end
        end
        self.m_csbOwner["lb_fs_num"]:setString(self.m_nowCount)
        local scaleAction = cc.ScaleBy:create(0.04,1.2)

        self.m_csbOwner["lb_fs_num"]:runAction(cc.Sequence:create(scaleAction,scaleAction:reverse()))
        if self.m_nowCount == totleCount then
            if self.m_upFsTimeaction ~= nil then
                self:stopAction(self.m_upFsTimeaction)
            end
            if self.m_upEndCallBack ~= nil then
                self.m_upEndCallBack()
            end
        end
    end, 0.1)
end

function FreeSpinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
return FreeSpinBar