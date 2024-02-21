---
--xcyy
--2018年5月23日
--MrCashJpGameWinBar.lua

local MrCashJpGameWinBar = class("MrCashJpGameWinBar",util_require("base.BaseView"))


function MrCashJpGameWinBar:initUI()

    self:createCsbNode("MrCash_FS_jackpotxz.csb")


    self.m_WinBarLight = util_createAnimation("MrCash_FS_jackpotxz_guang.csb")
    self:findChild("guangmang"):addChild(self.m_WinBarLight)
    self.m_WinBarLight:runCsbAction("actionframe",true)
    self.m_WinBarLight:setVisible(false)

    self.m_WinBarShouJi= util_createAnimation("MrCash_FS_jackpotxz_shouji.csb")
    self:findChild("Node_Shouji"):addChild(self.m_WinBarShouJi)
    self.m_WinBarShouJi:setVisible(false)
end


function MrCashJpGameWinBar:onEnter()
 

end


function MrCashJpGameWinBar:onExit()
 
end



return MrCashJpGameWinBar