
local GoldenGhostManyBonusReSpinStart = class("GoldenGhostManyBonusReSpinStart", util_require("base.BaseView"))

function GoldenGhostManyBonusReSpinStart:initUI()
    self:createCsbNode("GoldenGhost/ManyBonus_ReSpinStart.csb")
    self:runCsbAction("start",false,function ( ... )
        -- body
        self:runCsbAction("idle",true)
        self.touch = self:findChild("touch")
        self:addClick(self.touch)
    end)
    self.bonusNumLab = self.m_csbOwner["BitmapFontLabel_4"]
    self.multNumLab = self.m_csbOwner["BitmapFontLabel_3"]
end

function GoldenGhostManyBonusReSpinStart:updateUI()
    self.bonusNumLab:setString(tostring(self.m_machine.m_bonusNum))
    self.multNumLab:setString('x' .. tostring(self.m_machine.m_bonusNum - 9))
    performWithDelay(self,function ( ... )
        -- body
        self:clickFunc(self.touch)
    end,2)
end

function GoldenGhostManyBonusReSpinStart:setExtraInfo(machine, callBack)
    self.m_machine = machine
    self.callBack = callBack
    self:updateUI()
    -- self.m_machine:closeBonusPopUpUI()
end

function GoldenGhostManyBonusReSpinStart:clickFunc(sender)
    -- if sender == self.touch then
    --     self.touch:setEnabled(false)
    -- end
    if sender == self.touch then
        self.touch:setEnabled(false)
        self:runCsbAction("over",false,function ( ... )
            -- body
            if self.callBack ~= nil then
                self.callBack(1)
            end
            self:removeFromParent()
        end)
    end
end

return GoldenGhostManyBonusReSpinStart