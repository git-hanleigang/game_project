---
--island
--2018年4月12日
--GoldExpressSpinTimes.lua
---- respin 玩法结算时中 mini mijor等提示界面
local GoldExpressSpinTimes = class("GoldExpressSpinTimes", util_require("base.BaseView"))
GoldExpressSpinTimes.m_iJackpotNum = nil
GoldExpressSpinTimes.m_bIsRespinFirst = nil

function GoldExpressSpinTimes:initUI(data)
    local resourceFilename = "GoldExpress_GameScreenFreespin.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:setOpacity(0)
    self:setVisible(false)
    self.m_spinMode = "freespin"
    self:runCsbAction("idleframe", true)
end

function GoldExpressSpinTimes:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function GoldExpressSpinTimes:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function GoldExpressSpinTimes:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    self:updateSpinNum(leftFsCount)
end

function GoldExpressSpinTimes:resetUIBuyMode(mode)
    self.m_spinMode = mode
    self:findChild("last_spin"):setVisible(false)
    self:findChild("respin"):setVisible(false)
    self:findChild("last_respin"):setVisible(false)
    self:findChild("freespin"):setVisible(false)
    self:findChild("last_freespin"):setVisible(false)

    self:findChild(self.m_spinMode):setVisible(true)
end

function GoldExpressSpinTimes:updateSpinNum(num)
    if num == 0 then
        self:findChild(self.m_spinMode):setVisible(false)
        self:findChild("last_"..self.m_spinMode):setVisible(false)
        self:findChild("last_spin"):setVisible(true)
    elseif num == 1 then
        self:findChild(self.m_spinMode):setVisible(false)
        self:findChild("last_"..self.m_spinMode):setVisible(true)
    else
        self:findChild("lab_"..self.m_spinMode):setString(num)
        
        if self:findChild(self.m_spinMode):isVisible() == false then
            self:findChild(self.m_spinMode):setVisible(true)
        end
        if self:findChild("last_"..self.m_spinMode):isVisible() == true then
            self:findChild("last_"..self.m_spinMode):setVisible(false)
        end
        if self:findChild("last_spin"):isVisible() == true then
            self:findChild("last_spin"):setVisible(false) 
        end
        
    end
end

function GoldExpressSpinTimes:addRespinEffect()
    local effect, act = util_csbCreate("GoldExpress_shanguang.csb")
    self:findChild(self.m_spinMode):addChild(effect)
    effect:setPosition(-32,28)

    util_csbPlayForKey(act, "actionframe", false, function()
        effect:removeFromParent()
    end)
end

function GoldExpressSpinTimes:showBar()
    self:setVisible(true)
    self:runAction(cc.FadeIn:create(2/3))
end

function GoldExpressSpinTimes:hideBar()
    self:runAction(cc.Sequence:create(cc.FadeOut:create(2/3), cc.CallFunc:create(function()
        self:setVisible(false)
    end)))
end
--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return GoldExpressSpinTimes