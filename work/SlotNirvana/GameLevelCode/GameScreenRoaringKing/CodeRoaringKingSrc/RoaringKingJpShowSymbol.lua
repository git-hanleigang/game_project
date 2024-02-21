---
--xcyy
--2018年5月23日
--RoaringKingJpShowSymbol.lua

local RoaringKingJpShowSymbol = class("RoaringKingJpShowSymbol",util_require("base.BaseView"))

RoaringKingJpShowSymbol.m_symbolType = nil
RoaringKingJpShowSymbol.m_iCol = nil
RoaringKingJpShowSymbol.m_iRow = nil
RoaringKingJpShowSymbol.m_animNodeType = nil
RoaringKingJpShowSymbol.SpineType = "Spine"
RoaringKingJpShowSymbol.CsbType   = "Csb"

RoaringKingJpShowSymbol.m_otherSpine_1 = nil

function RoaringKingJpShowSymbol:initUI(ccbName,iCol,iRow,symbolType,index,machine)

    self.m_symbolType = symbolType
    self.m_iCol  = iCol
    self.m_iRow  = iRow
    self.m_index = index
    self.m_ccbName = ccbName
    self.m_machine = machine

    self.m_animNode = nil
    self.m_otherSpine_1 = nil

    local hasSymbolCCB = cc.FileUtils:getInstance():isFileExist(ccbName .. ".csb")
    local hasSpine = cc.FileUtils:getInstance():isFileExist(ccbName .. ".atlas")

    if hasSpine then
        self.m_animNodeType = self.SpineType
        self.m_animNode = util_spineCreate(ccbName,true,true)
        self:addChild(self.m_animNode)
    elseif hasSymbolCCB then
        self.m_animNodeType = self.CsbType
        self.m_animNode = util_createAnimation(ccbName .. ".csb")
        self:addChild(self.m_animNode)
    end


end

function RoaringKingJpShowSymbol:createOtherSpine( )
    if self.m_machine:isSpecailSymbol( self.m_symbolType ) then
        self.m_otherSpine_1 = util_spineCreate("Socre_RoaringKing_6",true,true)
        self.m_animNode:findChild("Node_2"):addChild(self.m_otherSpine_1,-1)
        self.m_animNode:findChild("Node_1"):setVisible(false)
    end
end


function RoaringKingJpShowSymbol:runAnim(animName,loop,func)

    if self.m_animNodeType == self.SpineType then
        util_spinePlay(self.m_animNode,animName,loop)
        if func then
            util_spineEndCallFunc(self.m_animNode,animName,func)
        end
    elseif self.m_animNodeType == self.CsbType then
        self.m_animNode:runCsbAction(animName,loop,func)
    end
   
    if self.m_otherSpine_1 then
        if  animName == "actionframe" or 
                animName == "actionframe2" or 
                    animName == "idleframe" then
            util_spinePlay(self.m_otherSpine_1,animName,loop)
        end
    end
end


return RoaringKingJpShowSymbol