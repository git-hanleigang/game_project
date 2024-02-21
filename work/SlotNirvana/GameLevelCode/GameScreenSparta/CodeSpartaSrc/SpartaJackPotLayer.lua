---
--SpartaJackPotLayer.lua
local SpartaJackPotLayer = class("SpartaJackPotLayer", util_require("base.BaseView"))

function SpartaJackPotLayer:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Sparta_jackpot.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("animation0",true)
end

function SpartaJackPotLayer:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("BitmapFontLabel_1"),5,true)
    self:changeNode(self:findChild("BitmapFontLabel_2"),4,true)
    self:changeNode(self:findChild("BitmapFontLabel_3"),3,true)
    self:changeNode(self:findChild("BitmapFontLabel_4"),2,true)
    self:changeNode(self:findChild("BitmapFontLabel_5"),1,true)
    -- self:updateSize()

    self:updateLabelSize({label=self:findChild("BitmapFontLabel_1"),sx=1,sy=1},123)
    self:updateLabelSize({label=self:findChild("BitmapFontLabel_2"),sx=1,sy=1},123)
    self:updateLabelSize({label=self:findChild("BitmapFontLabel_3"),sx=1,sy=1},127)
    self:updateLabelSize({label=self:findChild("BitmapFontLabel_4"),sx=1,sy=1},127)
    self:updateLabelSize({label=self:findChild("BitmapFontLabel_5"),sx=1,sy=1},190)

end

--jackpot算法
function SpartaJackPotLayer:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,50))
end

function SpartaJackPotLayer:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

return SpartaJackPotLayer