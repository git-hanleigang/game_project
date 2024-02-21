---
--xhkj
--2018年6月11日
--KangaroosJackpotBar.lua

local KangaroosFreeSpinBar = class("KangaroosFreeSpinBar", util_require("base.BaseView"))
-- 构造函数
KangaroosFreeSpinBar.m_updateCoinHandler = nil
KangaroosFreeSpinBar.m_showCoinTime = nil

function KangaroosFreeSpinBar:initUI(data)
    local resourceFilename="Kangaroos/Freespin_totalwin.csb"
    self:createCsbNode(resourceFilename)
    self.m_spinWinCount = 0
    self.m_winCoin1 = self.m_csbOwner["win_coin1"]
    self.m_goodLuck1 = self.m_csbOwner["goodluck1"]
    self.m_winCoin2 = self.m_csbOwner["win_coin2"]
    self.m_goodLuck2 = self.m_csbOwner["goodluck2"]
    self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount)) 
    
end

function KangaroosFreeSpinBar:initUIByType(type)
    if type then
        release_print("initUIByType type:"..type)
    else
        release_print("initUIByType type: nil")
    end

    if type == "0x" or type == "1x" then
        self.m_csbOwner["Node_normal"]:setVisible(true)
        self.m_csbOwner["Node_multip"]:setVisible(false)
    else
        self.m_csbOwner["Node_normal"]:setVisible(false)
        self.m_csbOwner["Node_multip"]:setVisible(true)
        self.m_csbOwner["Image_2x"]:setVisible(false)
        self.m_csbOwner["Image_3x"]:setVisible(false)
        self.m_csbOwner["Image_4x"]:setVisible(false)
        self.m_csbOwner["Image_"..type]:setVisible(true) 
    end
end

function KangaroosFreeSpinBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        
        if globalData.slotRunData.totalFreeSpinCount ~= nil and globalData.slotRunData.totalFreeSpinCount > 0 then
            self:notifyUpdateWinLabel(params[1],params[2],params[3])
        end
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function KangaroosFreeSpinBar:resetWinLabel()

    if self.m_updateCoinHandler ~= nil then
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))    
        self:stopAction(self.m_updateCoinHandler)
        self.m_updateCoinHandler = nil
    end
end

function KangaroosFreeSpinBar:notifyUpdateWinLabel(winCoin,isUpdateTopUI,isPlayAnim)
    self:resetWinLabel()
    if globalData.slotRunData.lastWinCoin ~= 0 then
        self.m_spinWinCount = globalData.slotRunData.lastWinCoin
    else
        self.m_spinWinCount = winCoin
    end

    local function updateComplete()
        self:resetWinLabel()
    end

    if isPlayAnim == false then
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))
        updateComplete()
        return
    end

    self.m_showCoinTime = 2
    
    local coinRiseNum =  winCoin / (self.m_showCoinTime * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AUTO_SPIN_DELAY_TIME, self.m_showCoinTime)

    coinRiseNum = math.floor(coinRiseNum ) 
    
    local curSpinCount = 0

    if globalData.slotRunData.lastWinCoin ~= 0 then
       curSpinCount = globalData.slotRunData.lastWinCoin - winCoin
    else
        curSpinCount = 0
    end

    self.m_updateCoinHandler = schedule(self,function()
        curSpinCount = curSpinCount + coinRiseNum

        if curSpinCount >= self.m_spinWinCount then
            curSpinCount = self.m_spinWinCount
            updateComplete()
        end

        self:updateWinCount(util_getFromatMoneyStr(curSpinCount))
    end,0.016)
end

function KangaroosFreeSpinBar:updateWinCount(goldCountStr)
    -- print("----------"..goldCountStr)
    if goldCountStr == "0" then
        self.m_winCoin1:setVisible(false)
        self.m_goodLuck1:setVisible(true)
        self.m_winCoin2:setVisible(false)
        self.m_goodLuck2:setVisible(true)
    else
        self.m_winCoin1:setString(goldCountStr)
        self.m_winCoin2:setString(goldCountStr)
        if self.m_goodLuck1:isVisible() then
            self.m_winCoin1:setVisible(true)
            self.m_goodLuck1:setVisible(false)
        end
        if self.m_goodLuck2:isVisible() then
            self.m_winCoin2:setVisible(true)
            self.m_goodLuck2:setVisible(false)
        end
    end
    local info1 = {label = self.m_winCoin1, sx = 1.4, sy = 1.4}
    local info2 = {label = self.m_winCoin2, sx = 1.4, sy = 1.4}
    self:updateLabelSize(info1, 380, {info2}) 
end

function KangaroosFreeSpinBar:getShowCoinTime(  )
    return self.m_showCoinTime
end

function KangaroosFreeSpinBar:show()
    -- self:runCsbAction("show")
    self.m_spinWinCount = globalData.slotRunData.lastWinCoin or 0
    self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount)) 
    self:changeFreeSpinByCount()
end

function KangaroosFreeSpinBar:hide()
    -- self:runCsbAction("over", false, function()
        self.m_spinWinCount = 0
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount)) 
    -- end)
end

---
-- 更新freespin 剩余次数
--
function KangaroosFreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function KangaroosFreeSpinBar:updateFreespinCount(leftCount,totalCount)
    self.m_csbOwner["left_free_spins1"]:setString(leftCount)
    self.m_csbOwner["total_free_spins1"]:setString(totalCount)
    self.m_csbOwner["left_free_spins2"]:setString(leftCount)
    self.m_csbOwner["total_free_spins2"]:setString(totalCount)
end

function KangaroosFreeSpinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)

    if self.m_updateCoinHandler ~= nil then
        self:stopAction(self.m_updateCoinHandler)
    end
end

return KangaroosFreeSpinBar