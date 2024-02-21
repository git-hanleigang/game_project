---
--xcyy
--2018年5月23日
--AllStarBonusTipView.lua

local AllStarBonusTipView = class("AllStarBonusTipView",util_require("base.BaseView"))



AllStarBonusTipView.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
AllStarBonusTipView.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
AllStarBonusTipView.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
AllStarBonusTipView.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 

AllStarBonusTipView.m_ActName = {"mid_wild","add_wild","double_bet","two_wild"}

AllStarBonusTipView.m_TxtName = {"text_mid_wild_1","text_mid_wild_2"}
function AllStarBonusTipView:initUI()

    self:createCsbNode("AllStar/Bonusshuoming.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听

    self.m_gameType = 1

    -- self:showViewFromType( 1 )
    --创建爆点
    self.boomNode = util_createView("CodeAllStarSrc.AllStarEffectNode")
    self:findChild("Node_effect"):addChild(self.boomNode)
    self.boomNode:setVisible(false)

end

function AllStarBonusTipView:showViewFromType( GMType)

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

function AllStarBonusTipView:showTipTxt( id )


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

function AllStarBonusTipView:showTipTxtForMulple(mulple)
    local newMulple = tonumber(mulple)
    self:findChild("double_bet_lab"):setString("X" .. newMulple)
end

function AllStarBonusTipView:getNumberPos( )
    local numberPos = nil
    local effectNode = self:findChild("Node_effect")
    if effectNode then
        numberPos = cc.p(effectNode:getPositionX(),effectNode:getPositionY())
    end
    return numberPos
end

function AllStarBonusTipView:setBoomNodeVisible(isVisible)
    self.boomNode:setVisible(isVisible)
end


function AllStarBonusTipView:showBoomEffect( )
    self.boomNode:stopAllActions()
    self.boomNode:runCsbAction("actionframe",false,function (  )
        self:setBoomNodeVisible(false)
    end)
end

function AllStarBonusTipView:onEnter()
 

end


function AllStarBonusTipView:onExit()
 
end

--默认按钮监听回调
function AllStarBonusTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AllStarBonusTipView