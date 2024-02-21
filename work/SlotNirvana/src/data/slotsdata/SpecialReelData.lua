---
--island
--2017年11月15日
--SpecialReelData.lua
--

local SpecialReelData = class("SpecialReelData")
SpecialReelData.SymbolType = nil
SpecialReelData.Zorder = nil
SpecialReelData.Width = nil
SpecialReelData.Height = nil
SpecialReelData.Last = nil
SpecialReelData.AnchorPointY = nil


function SpecialReelData:ctor()
    printInfo("xcyy : %s","")
end

function SpecialReelData:reset()
    self.SymbolType = nil
    self.Zorder = nil
    self.Width = nil
    self.Height = nil
    self.Last = nil
    self.AnchorPointY = nil
end

function SpecialReelData:clear()
end

return SpecialReelData
