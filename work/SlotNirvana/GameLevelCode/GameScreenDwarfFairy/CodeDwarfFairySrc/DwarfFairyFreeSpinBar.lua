---
--xhkj
--2018年6月11日
--DwarfFairyJackpotBar.lua

local DwarfFairyFreeSpinBar = class("DwarfFairyFreeSpinBar", util_require("base.BaseView"))
-- 构造函数
DwarfFairyFreeSpinBar.m_updateCoinHandler = nil
DwarfFairyFreeSpinBar.m_showCoinTime = nil
DwarfFairyFreeSpinBar.m_goodLuck = nil
DwarfFairyFreeSpinBar.m_winCoin = nil

function DwarfFairyFreeSpinBar:initUI(data)
    local resourceFilename="DwarfFairy_10.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idle")
    self.m_spinWinCount = 0
    self.m_winCoin = self.m_csbOwner["win_coin"]
    self.m_goodLuck = self.m_csbOwner["goodluck"]
    self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount)) 
    self:updateLabelSize( {label=self.m_winCoin,sx=0.55,sy=0.55},957) 
end

function DwarfFairyFreeSpinBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        
        if globalData.slotRunData.totalFreeSpinCount ~= nil and globalData.slotRunData.totalFreeSpinCount > 0 then
            self:notifyUpdateWinLabel(params[1],params[2],params[3])
        end
        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function DwarfFairyFreeSpinBar:resetWinLabel()

    if self.m_updateCoinHandler ~= nil then
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount))    
        self:stopAction(self.m_updateCoinHandler)
        self.m_updateCoinHandler = nil
    end
end

function DwarfFairyFreeSpinBar:notifyUpdateWinLabel(winCoin,isUpdateTopUI,isPlayAnim)
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

    -- local totalBet = (globalData.slotRunData.vecLineBetnum)[globalData.slotRunData.iLastBetIdx] * globalData.slotRunData.runCsvData.line_num
    -- local winRate = winCoin / totalBet
    self.m_showCoinTime = 2
    -- if winRate <= 1 then
    --     self.m_showCoinTime = 1
    -- elseif winRate > 1 and winRate <= 3 then
    --     self.m_showCoinTime = 1.5
    -- elseif winRate > 3 and winRate <= 6 then
    --     self.m_showCoinTime = 2.5
    -- elseif winRate > 6 then
    --     self.m_showCoinTime = 4
    -- end
    local coinRiseNum =  winCoin / (self.m_showCoinTime * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    

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

function DwarfFairyFreeSpinBar:updateWinCount(goldCountStr)
    -- print("----------"..goldCountStr)
    if goldCountStr == "0" then
        self.m_winCoin:setVisible(false)
        self.m_goodLuck:setVisible(true)
    else
        self.m_winCoin:setString(goldCountStr)
        self:updateLabelSize( {label=self.m_winCoin,sx=0.55,sy=0.55},957) 
        if self.m_goodLuck:isVisible() then
            self.m_winCoin:setVisible(true)
            self.m_goodLuck:setVisible(false)
        end
    end
end

function DwarfFairyFreeSpinBar:getShowCoinTime(  )
    return self.m_showCoinTime
end

function DwarfFairyFreeSpinBar:show()
    self:runCsbAction("show")
    self.m_spinWinCount = globalData.slotRunData.lastWinCoin or 0
    self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount)) 
    self:changeFreeSpinByCount()
end

function DwarfFairyFreeSpinBar:hide()
    self:runCsbAction("over", false, function()
        self.m_spinWinCount = 0
        self:updateWinCount(util_getFromatMoneyStr(self.m_spinWinCount)) 
    end)
end

---
-- 更新freespin 剩余次数
--
function DwarfFairyFreeSpinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

function DwarfFairyFreeSpinBar:updateFreespinCount(leftCount,totalCount)
    self.m_csbOwner["left_free_spins"]:setString(leftCount)
    self.m_csbOwner["total_free_spins"]:setString(totalCount)
end

function DwarfFairyFreeSpinBar:onExit()
    gLobalNoticManager:removeAllObservers(self)

    if self.m_updateCoinHandler ~= nil then
        self:stopAction(self.m_updateCoinHandler)
    end
end

return DwarfFairyFreeSpinBar