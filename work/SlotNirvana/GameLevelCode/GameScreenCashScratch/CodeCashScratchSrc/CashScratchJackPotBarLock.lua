local CashScratchJackPotBarLock = class("CashScratchJackPotBarLock",util_require("Levels.BaseLevelDialog"))

--[[
    _initData = {
        index,      -- 0
        machine,    -- CodeGameScreenCashScratchMachine

    }
]]
function CashScratchJackPotBarLock:initDatas(_initData)
    self.m_initData   = _initData

    self.m_unLockCoin = 0
end
function CashScratchJackPotBarLock:initUI()
    self:createCsbNode("CashScratch_jackpot_lock.csb")

    self:addClick(self:findChild("lay_unLock"))
end

function CashScratchJackPotBarLock:setUnLockCoin(_coin)
    self.m_unLockCoin = _coin
end


--结束监听
function CashScratchJackPotBarLock:clickEndFunc(sender)
    if not self:isCanClick() then
        return
    end

    local name = sender:getName()

    if name == "lay_unLock" then
        self:clickUnLockBet()
    end
end


function CashScratchJackPotBarLock:clickUnLockBet()
    local machine = self.m_initData[2]
    machine:clickUnLockBet(self.m_unLockCoin)
end

function CashScratchJackPotBarLock:isCanClick()
    local machine = self.m_initData[2]
    return machine:isCanUnLockJackpot(self.m_unLockCoin)
end

return CashScratchJackPotBarLock