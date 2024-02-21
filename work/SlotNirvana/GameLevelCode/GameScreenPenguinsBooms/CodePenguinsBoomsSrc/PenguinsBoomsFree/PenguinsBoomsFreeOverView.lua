local PenguinsBoomsFreeOverView = class("PenguinsBoomsFreeOverView",util_require("Levels.BaseDialog"))

function PenguinsBoomsFreeOverView:openDialog()
    self.m_allowClick = false
    PenguinsBoomsFreeOverView.super.openDialog(self)
end

function PenguinsBoomsFreeOverView:showidle()
    PenguinsBoomsFreeOverView.super.showidle(self)
    self.m_allowClick = true
end

return PenguinsBoomsFreeOverView