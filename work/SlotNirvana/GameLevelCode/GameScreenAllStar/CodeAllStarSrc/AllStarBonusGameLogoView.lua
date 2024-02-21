---
--xcyy
--2018年5月23日
--AllStarBonusGameLogoView.lua

local AllStarBonusGameLogoView = class("AllStarBonusGameLogoView",util_require("base.BaseView"))

AllStarBonusGameLogoView.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
AllStarBonusGameLogoView.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
AllStarBonusGameLogoView.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
AllStarBonusGameLogoView.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 


AllStarBonusGameLogoView.m_ActName = {"mid_wild","add_wild","double_bet","two_wild"}
AllStarBonusGameLogoView.m_TxtName = {"txt_mid_wild_1","txt_mid_wild_2"}

function AllStarBonusGameLogoView:initUI(syType)

    self:createCsbNode("AllStar_bonus_logo.csb")

    self.m_gameType = syType

    self.m_ActList = {}

    self:updateLogoImg( syType )

    self:createSpineNode()

    self.m_logoChange = util_createView("CodeAllStarSrc.AllStarLogoChangeView")
    self:findChild("mid_txt_change"):addChild(self.m_logoChange)
    self.m_logoChange:setVisible(false)
    


end
function AllStarBonusGameLogoView:createSpineNode( )
    local spineNameList = {"Socre_AllStar_bonus5","Socre_AllStar_bonus6","Socre_AllStar_bonus7","Socre_AllStar_bonus8"}

    for k,v in pairs(self.m_ActName) do
        local nodeName = v.. "_logo"
        local node =  self:findChild(nodeName)
        local spineName = spineNameList[k]
        self.spineNode = util_spineCreate(spineName , true, true)
        self.m_ActList[#self.m_ActList + 1] = self.spineNode
        node:addChild(self.spineNode)
        util_spinePlay(self.spineNode,"idle2",true)
    end
end

function AllStarBonusGameLogoView:spineNodeRunAct( index )
    for i,v in ipairs(self.m_ActList) do
        if i == index then
            util_spinePlay(v,"actionframe2",false)
            util_spineEndCallFunc(v,"actionframe2",function (  )
                util_spinePlay(v,"idle2",true)
            end)
        end
    end
end
--针对小恶魔
function AllStarBonusGameLogoView:spineNodeAct( index )
    for i,v in ipairs(self.m_ActList) do
        if i == index then
            util_spinePlay(v,"actionframe3",false)
            util_spineEndCallFunc(v,"actionframe3",function (  )
                util_spinePlay(v,"idle2",true)
            end)
        end
    end
end

function AllStarBonusGameLogoView:updateLogoImg( GMType)

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

function AllStarBonusGameLogoView:showTipTxt( id )




    for k,v in pairs(self.m_TxtName) do
        local name = v
        local node = self:findChild(name)
        if node then
            if k ==  id then
                node:setVisible(true)
            else
                node:setVisible(false)
            end
        end
    end 
end

function AllStarBonusGameLogoView:onEnter()
 

end

function AllStarBonusGameLogoView:onExit()
 
end



return AllStarBonusGameLogoView