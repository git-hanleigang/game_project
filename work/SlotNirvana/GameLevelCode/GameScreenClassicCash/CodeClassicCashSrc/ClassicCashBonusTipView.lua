---
--xcyy
--2018年5月23日
--ClassicCashBonusTipView.lua

local ClassicCashBonusTipView = class("ClassicCashBonusTipView",util_require("base.BaseView"))



ClassicCashBonusTipView.SYMBOL_MID_LOCK = 105 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 
ClassicCashBonusTipView.SYMBOL_ADD_WILD = 106 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13  
ClassicCashBonusTipView.SYMBOL_TWO_LOCK = 107 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14 
ClassicCashBonusTipView.SYMBOL_Double_BET = 108 -- TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 15 

ClassicCashBonusTipView.m_ActName = {"mid_wild","add_wild","double_bet","two_wild"}

ClassicCashBonusTipView.m_TxtName = {"text_mid_wild_1","text_mid_wild_2"}
function ClassicCashBonusTipView:initUI()

    self:createCsbNode("ClassicCash/Bonusshuoming.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听

    self.m_gameType = 1

    -- self:showViewFromType( 1 )


end

function ClassicCashBonusTipView:showViewFromType( GMType)

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

function ClassicCashBonusTipView:showTipTxt( id )

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

-- 设置倍数
function ClassicCashBonusTipView:setMul(_mul)
    local strMul = "X".._mul
    self:findChild("m_lb_num"):setString(strMul)
end

function ClassicCashBonusTipView:onEnter()
 

end


function ClassicCashBonusTipView:onExit()
 
end

--默认按钮监听回调
function ClassicCashBonusTipView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ClassicCashBonusTipView