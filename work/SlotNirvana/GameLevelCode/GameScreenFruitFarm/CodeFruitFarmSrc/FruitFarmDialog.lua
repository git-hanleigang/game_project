---
--xcyy
--2018年5月23日
--FruitFarmView.lua

local FruitFarmDialog = class("FruitFarmDialog",util_require("Levels.BaseDialog"))

--默认按钮监听回调
function FruitFarmDialog:clickFunc(sender)
    if not self.m_allowClick then
        return 
    end

    local name
    if sender then
        name = sender:getName()
    end
    gLobalSoundManager:playSound(self.m_btnTouchSound)

    if self.m_clickCallFunc then
        self.m_clickCallFunc()
    end
    
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if  self.m_status==self.STATUS_START or self.m_status==self.STATUS_IDLE or self.m_status==self.STATUS_AUTO then
        self:showOver(name)
    end

end

--设置点击前回调
function FruitFarmDialog:setClickFunc(func)
    self.m_clickCallFunc = func
end


return FruitFarmDialog