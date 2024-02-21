---
--xcyy
--2018年5月23日
--FairyDragonJackpotTips.lua

local FairyDragonJackpotTips = class("FairyDragonJackpotTips",util_require("base.BaseView"))


function FairyDragonJackpotTips:initUI(_type)
    local strName = "FairyDragon_Jackpot_wanfa_mini.csb"
    if _type == 1 then
        strName = "FairyDragon_Jackpot_wanfa_mini.csb"
    elseif _type == 2 then
        strName = "FairyDragon_Jackpot_wanfa_minor.csb"
    elseif _type == 3 then
        strName = "FairyDragon_Jackpot_wanfa_major.csb"
    elseif _type == 4 then
        strName = "FairyDragon_Jackpot_wanfa_grand.csb"
    end
    self:createCsbNode(strName)


    if _type == 4 then
        
        self.m_jpGrandDarkImg = self:findChild("an")
        self.m_jpGrandSuo = util_createAnimation("FairyDragon_suo.csb")
        self:findChild("suo"):addChild(self.m_jpGrandSuo)
        self.m_jpGrandDarkImg:setVisible(false)
        self.m_jpGrandSuo:setVisible(false)


    end
end


function FairyDragonJackpotTips:onEnter()
 

end

function FairyDragonJackpotTips:getLabNode()
    local lab = self:findChild("BitmapFontLabel_1")
    return lab
end

function FairyDragonJackpotTips:onExit()
 
end



return FairyDragonJackpotTips