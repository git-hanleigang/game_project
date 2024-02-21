---
--xcyy
--2018年5月23日
--ClassicCashBonusGameLogoView.lua

local ClassicCashBonusGameLogoView = class("ClassicCashBonusGameLogoView",util_require("base.BaseView"))

ClassicCashBonusGameLogoView.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
ClassicCashBonusGameLogoView.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
ClassicCashBonusGameLogoView.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
ClassicCashBonusGameLogoView.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 


ClassicCashBonusGameLogoView.m_ActName = {"mid_wild","add_wild","double_bet","two_wild"}

function ClassicCashBonusGameLogoView:initUI(syType)

    self:createCsbNode("ClassicCash_bonus_logo.csb")

    self.m_gameType = syType

    self:updateLogoImg( syType )

    self:createSpineNode()

    self.m_midWild_1 = self:findChild("txt_mid_wild_1")
    self.m_midWild_2 = self:findChild("txt_mid_wild_2")

    self.m_logoChange = util_createView("CodeClassicCashSrc.ClassicCashLogoChangeView")
    self:findChild("mid_txt_change"):addChild(self.m_logoChange)
    self.m_logoChange:setVisible(false)
end

function ClassicCashBonusGameLogoView:createSpineNode( )
    local spineNameList = {"Socre_ClassicCash_bonus5","Socre_ClassicCash_bonus6","Socre_ClassicCash_bonus7","Socre_ClassicCash_bonus8"}

    for k,v in pairs(self.m_ActName) do
        local nodeName = v.. "_logo"
        local node =  self:findChild(nodeName)
        local spineName = spineNameList[k]
        local spineNode = util_spineCreate(spineName , true, true)
        node:addChild(spineNode)
        util_spinePlay(spineNode,"idle",true)
    end
end



function ClassicCashBonusGameLogoView:updateLogoImg( GMType)

    for k,v in pairs(self.m_ActName) do
        local nodename = v
        local logo = self:findChild(nodename)
        if logo then
            logo:setVisible(false)
        end
    end

    local name = self.m_ActName[1]

    if GMType == self.SYMBOL_MID_LOCK  then
        name = self.m_ActName[1]
    elseif GMType == self.SYMBOL_ADD_WILD then
        name = self.m_ActName[2]
    elseif GMType == self.SYMBOL_TWO_LOCK then
        name = self.m_ActName[4]
    elseif GMType == self.SYMBOL_Double_BET then
        name = self.m_ActName[3] 
    end

    local node = self:findChild(name)
    if node then
        node:setVisible(true)
    end

end

function ClassicCashBonusGameLogoView:showTipTxt( id )
    self.m_midWild_1:setOpacity(255)
    self.m_midWild_2:setOpacity(255)
    if id == 1 then
        self.m_midWild_1:setVisible(true)
        self.m_midWild_2:setVisible(false)
    else
        if self.m_midWild_2:isVisible() then
            self.m_midWild_1:setVisible(false)
            return
        end
        self.m_midWild_2:setVisible(true)
        self.m_midWild_1:stopAllActions()
        self.m_midWild_2:stopAllActions()
        self.m_midWild_2:setOpacity(0)
        local delayTimeFade = 0.8
        local tblMidList_1 = {}
        
        -- m_midWild_1
        local fadeOut = cc.FadeOut:create(delayTimeFade)
        self.m_midWild_1:runAction(fadeOut)

        -- m_midWild_2
        local tblMidList_2 = {}
        local fadeIn = cc.FadeIn:create(delayTimeFade)
        self.m_midWild_2:runAction(fadeIn)
    end
end

function ClassicCashBonusGameLogoView:onEnter()
 

end

function ClassicCashBonusGameLogoView:onExit()
 
end



return ClassicCashBonusGameLogoView