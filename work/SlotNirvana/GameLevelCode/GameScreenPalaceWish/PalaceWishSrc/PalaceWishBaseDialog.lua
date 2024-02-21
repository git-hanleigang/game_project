---
--xcyy
--2018年5月23日
--PalaceWishBaseDialog.lua

local PalaceWishBaseDialog = class("PalaceWishBaseDialog",util_require("Levels.BaseDialog"))

function PalaceWishBaseDialog:setOverActBeginCallFunc( func )
    self.m_OverActBeginCallFunc = func
end

function PalaceWishBaseDialog:clickFunc(sender)
    local name
    if sender then
        name = sender:getName()
    end

    --改
    if self.m_status == self.STATUS_START then
        return
    end


    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if  self.m_status==self.STATUS_START or self.m_status==self.STATUS_IDLE or self.m_status==self.STATUS_AUTO then
        self:showOver(name)
    end
end

--结束
function PalaceWishBaseDialog:showOver(name)
    if self.m_status == self.STATUS_OVER then
        return
    end
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_click.mp3")
    
    self.m_status=self.STATUS_OVER
    if self.m_OverActBeginCallFunc then
        self.m_OverActBeginCallFunc()
        self.m_OverActBeginCallFunc = nil
    end
    self:runCsbAction(self.m_over_name,false,function(  )
        if self.m_callfunc then
            self.m_callfunc()
            self.m_callfunc=nil
        end
        self:removeFromParent()
    end)

end


--用于屏蔽点击时 去点击效果
function PalaceWishBaseDialog:showStart()

    local button = self:findChild("Button_1")
    if button then
        if button and button.setTouchEnabled then
            button:setTouchEnabled(false)
        end
    end
    PalaceWishBaseDialog.super.showStart(self)
end

function PalaceWishBaseDialog:showidle()
    local button = self:findChild("Button_1")
    if button then
        if button and button.setTouchEnabled then
            button:setTouchEnabled(true)
        end
    end
    PalaceWishBaseDialog.super.showidle(self)
end

return PalaceWishBaseDialog