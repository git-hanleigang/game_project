---
--xcyy
--2018年5月23日
--FourInOneSlotsReelRunData.lua

local FourInOneSlotsReelRunData = class("FourInOneSlotsReelRunData",util_require("data.slotsdata.SlotsReelRunData"))

--得到特殊图标是否参加长滚判断 是否播放动画
function FourInOneSlotsReelRunData:getSpeicalSybolRunInfo(symbolType)
    if symbolType == self.m_machine:getScatterSymbolType(  )  then
        
        return self.m_bInclScatter, self.m_bPlayScatterAction
        
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    
        return self.m_bInclBonus, self.m_bPlayBonusAction
        
    end
end

function FourInOneSlotsReelRunData:setMachine( machine )
    self.m_machine = machine
end


return FourInOneSlotsReelRunData