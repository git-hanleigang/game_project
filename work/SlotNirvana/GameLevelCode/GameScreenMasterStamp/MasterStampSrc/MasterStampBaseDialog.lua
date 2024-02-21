local MasterStampBaseDialog = class("MasterStampBaseDialog", util_require("Levels.BaseDialog"))

--初始化ccbi
function MasterStampBaseDialog:initNode()
    MasterStampBaseDialog.super.initNode(self)
    if self.m_type_name == self.DIALOG_TYPE_FREESPIN_OVER then
        self.m_btnTouchSound = "MasterStampSounds/MasterStampSounds_btn_click.mp3"
        if self:findChild("spine") then
            self.m_spine = util_spineCreate("MasterStamp_tanban", false, true)
            self:findChild("spine"):addChild(self.m_spine)
        end
    end
end

function MasterStampBaseDialog:showStart()
    MasterStampBaseDialog.super.showStart(self)
    if self.m_type_name == self.DIALOG_TYPE_FREESPIN_OVER and self.m_spine then
        gLobalSoundManager:playSound("MasterStampSounds/MasterStampSounds_FreeSpinOverShow.mp3")
        util_spinePlay(self.m_spine, self.m_start_name, false)
    end
end

function MasterStampBaseDialog:showidle()
    MasterStampBaseDialog.super.showidle(self)
    if self.m_type_name == self.DIALOG_TYPE_FREESPIN_OVER and self.m_spine then
        util_spinePlay(self.m_spine, self.m_idle_name, true)
    end
end

function MasterStampBaseDialog:showOver()
    MasterStampBaseDialog.super.showOver(self)
    if self.m_type_name == self.DIALOG_TYPE_FREESPIN_OVER and self.m_spine then
        gLobalSoundManager:playSound("MasterStampSounds/MasterStampSounds_FreeSpinOverHide.mp3")
        util_spinePlay(self.m_spine, self.m_over_name, false)
    end
end

return MasterStampBaseDialog
