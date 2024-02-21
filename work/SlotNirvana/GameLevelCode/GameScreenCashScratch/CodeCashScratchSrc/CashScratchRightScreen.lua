---
--xcyy
--2018年5月23日
--CashScratchRightScreen.lua

local CashScratchRightScreen = class("CashScratchRightScreen",util_require("Levels.BaseLevelDialog"))

function CashScratchRightScreen:initUI(_machine)
    self:createCsbNode("CashScratch_right_screen.csb")

    self:initCollectFreeTimesStar()

    self.m_machine = _machine

    self.m_freespinCurtTimes = 0
    self.m_freespinTotalTimes = 0

    self:changeShowByModel("base")
end


function CashScratchRightScreen:onEnter()
    CashScratchRightScreen.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end



function CashScratchRightScreen:changeShowByModel(_modelName)
    local baseNode      = self:findChild("screen_base")
    local freeNode      = self:findChild("screen_free")
    local superFreeNode = self:findChild("screen_super")
    local bonusNode     = self:findChild("screen_card")

    baseNode:setVisible("base" == _modelName)
    freeNode:setVisible("free" == _modelName)
    superFreeNode:setVisible("superFree" == _modelName)
    bonusNode:setVisible("bonus" == _modelName)
    
end

--[[
    base
]]
function CashScratchRightScreen:initCollectFreeTimesStar()
    self.m_freeStar = {}
    for i=1,10 do
        local star = util_createAnimation("CashScratch_right_screen_star.csb") 
        local starParent = self:findChild( string.format("star_%d", i-1) )
        starParent:addChild(star)
        table.insert(self.m_freeStar, star)
    end
end
function CashScratchRightScreen:updateCollectFreeTimes(_playAnim)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}

    local curTimes   = selfData.triggerTimes or 0
    local totalTimes = selfData.totalFreespinCount or 10

    local bPlayAnim = false
    for _times,_star in ipairs(self.m_freeStar) do
        local isVisible = _star:isVisible()
        util_setCsbVisible(_star, _times <= curTimes)
        if _times <= curTimes then
            
            if not isVisible and _playAnim then
                bPlayAnim = true
                _star:runCsbAction("start", false)
            else
                _star:runCsbAction("idle", false)
            end
            
        end
    end

    local animTime = bPlayAnim and 100/60 or 0
    if bPlayAnim then
        gLobalSoundManager:playSound("CashScratchSounds/sound_CashScratch_free_addStar.mp3")
    end
    
    return animTime
end


--[[
    free
]]
function CashScratchRightScreen:changeFreeSpinByCount(params)
    local collectTotalCount = globalData.slotRunData.totalFreeSpinCount
    local collectLeftCount = globalData.slotRunData.freeSpinCount
    local leftCount = collectTotalCount - collectLeftCount
    
    self.m_freespinCurtTimes = leftCount
    self.m_freespinTotalTimes = collectTotalCount

    self:updateFreespinCount(leftCount, collectTotalCount)
end

function CashScratchRightScreen:updateFreespinCount(curtimes, totaltimes)
    local labFreeLeft       = self:findChild("m_lb_num_free")
    local labFreeTotal      = self:findChild("m_lb_num_free_0")
    local labSuperFreeLeft  = self:findChild("m_lb_num_super")
    local labSuperFreeTotal = self:findChild("m_lb_num_super_0")

    labFreeLeft:setString(curtimes)
    labSuperFreeLeft:setString(curtimes)
    labFreeTotal:setString(totaltimes)
    labSuperFreeTotal:setString(totaltimes)
end

function CashScratchRightScreen:playFreeSpinMoreAnim()
    self:runCsbAction("actionframe", false)
end
--[[
    superFree
]]
return CashScratchRightScreen