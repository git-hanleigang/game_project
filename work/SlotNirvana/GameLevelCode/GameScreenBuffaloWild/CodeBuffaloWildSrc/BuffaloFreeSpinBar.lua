local BuffaloFreeSpinBar = class("BuffaloFreeSpinBar", util_require("base.BaseView"))
-- 构造函数
function BuffaloFreeSpinBar:initUI(data)
    local resourceFilename="BuffaloWild_fs_cishu.csb"
    self:createCsbNode(resourceFilename)
    self:setScale(0.9)
end

function BuffaloFreeSpinBar:onEnter()

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)


    gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
        self:changeFreeSpinByCountOutLine(params,num)
    end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)
    
end

---
-- 重连更新freespin 剩余次数
--
function BuffaloFreeSpinBar:changeFreeSpinByCountOutLine(params,changeNum)
    if changeNum and type(changeNum) == "number" then
        if globalData.slotRunData.totalFreeSpinCount == changeNum then
            return
        end
        local leftFsCount = globalData.slotRunData.freeSpinCount - changeNum
        local totalFsCount = globalData.slotRunData.totalFreeSpinCount
        self:updateFreespinCount(leftFsCount,totalFsCount)
    end
end

---
-- 更新freespin 剩余次数
--
function BuffaloFreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function BuffaloFreeSpinBar:updateFreespinCount(leftCount,totalCount)
    -- self.m_csbOwner["m_lb_num"]:setString("FREE SPINS: "..leftCount)
    self.m_csbOwner["m_lb_num"]:setString(leftCount)
    self.m_csbOwner["m_lb_total_num"]:setString(totalCount)
end

function BuffaloFreeSpinBar:changeFreeSpinTimes()
    self:runCsbAction("chufa")
    performWithDelay(self, function()
        gLobalSoundManager:playSound("BuffaloWildSounds/sound_buffalo_wild_add_freespintimes.mp3", false)
        performWithDelay(self,function (  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end,1.5)

        self:changeFreeSpinByCount()
    end, 0.2)
end

function BuffaloFreeSpinBar:onExit()

    gLobalNoticManager:removeAllObservers(self)
end
return BuffaloFreeSpinBar