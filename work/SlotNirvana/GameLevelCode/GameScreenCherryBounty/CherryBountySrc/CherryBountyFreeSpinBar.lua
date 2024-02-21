--[[
    free计数栏
]]
local CherryBountyFreeSpinBar = class("CherryBountyFreeSpinBar", util_require("base.BaseView"))

function CherryBountyFreeSpinBar:initUI()
    self.m_coins      = 0
    self.m_mult       = 0
    self.m_curTimes   = 0
    self.m_totalTimes = 0

    self:createCsbNode("CherryBounty_free_bar.csb")
    self.m_timesCsb = util_createAnimation("CherryBounty_freespinbar.csb")
    self:findChild("Node_times"):addChild(self.m_timesCsb)
    self.m_leftLab  = self.m_timesCsb:findChild("m_lb_num1")
    self.m_rightLab = self.m_timesCsb:findChild("m_lb_num2")
    
    --文本适配
    local leftLabSize = self.m_leftLab:getContentSize()
    local rightLabSize = self.m_rightLab:getContentSize()
    self.m_leftInfo = {
        label = self.m_leftLab, 
        sx    = self.m_leftLab:getScaleX(),
        sy    = self.m_leftLab:getScaleY(),
        width = leftLabSize.width
    }
    self.m_rightInfo = {
        label = self.m_rightLab, 
        sx    = self.m_rightLab:getScaleX(),
        sy    = self.m_rightLab:getScaleY(),
        width = rightLabSize.width
    }
end

function CherryBountyFreeSpinBar:onEnter()
    CherryBountyFreeSpinBar.super.onEnter(self)
    --刷新free次数
    gLobalNoticManager:addObserver(self,function(params)  
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

--刷新free次数
function CherryBountyFreeSpinBar:changeFreeSpinByCount()
    --递增
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end
function CherryBountyFreeSpinBar:updateFreespinCount(_curTimes, _totalTimes)
    self.m_curTimes   = _curTimes
    self.m_totalTimes = _totalTimes
    self.m_leftLab:setString(_curTimes)
    self.m_rightLab:setString(_totalTimes)
    self:updateLabelSize(self.m_leftInfo, self.m_leftInfo.width)
    self:updateLabelSize(self.m_rightInfo, self.m_rightInfo.width)
end

--金额文本-初始化玩法金额
function CherryBountyFreeSpinBar:initFreeBarLabelCoins(_coins, _mult)
    self.m_coins = _coins
    self.m_mult  = _mult
    local labCoins = self:findChild("m_lb_coins")
    local labMult  = self:findChild("m_lb_mult")
    local sCoins   = util_formatCoinsLN(_coins, 3)
    local sMult    = string.format("X%d", _mult)
    labCoins:setString(sCoins)
    labMult:setString(sMult)
    self:updateLabelSize({label=labCoins, sx=0.78, sy=0.78}, 92)
end


return CherryBountyFreeSpinBar