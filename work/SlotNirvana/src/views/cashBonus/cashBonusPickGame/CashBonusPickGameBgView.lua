--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-07-05 11:01:42
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-07-05 11:01:46
FilePath: /SlotNirvana/src/views/cashBonus/cashBonusPickGame/CashBonusPickGameBgView.lua
Description: 策划要区分金银宝箱光效所以加了这个
--]]
local CashBonusPickGameBgView = class("CashBonusPickGameBgView",BaseView)

function CashBonusPickGameBgView:initDatas(_type)
    self.m_type = _type
end

function CashBonusPickGameBgView:initUI()
    CashBonusPickGameBgView.super.initUI(self)
end

function CashBonusPickGameBgView:getCsbName()
    return "NewCashBonus/CashBonusNew/CashPickGameBg.csb"
end

function CashBonusPickGameBgView:initCsbNodes()
    self.m_nodeGold = self:findChild("Image_10")
    self.m_nodeSliver = self:findChild("Image_1")
    self.m_nodeGold:setVisible(false)
    self.m_nodeSliver:setVisible(false)
end

function CashBonusPickGameBgView:playNodeAction()
    if self.m_type then

        if self.m_type == "GOLD" then
            self.m_nodeGold:setVisible(true)
        elseif self.m_type == "SILVER" then
            self.m_nodeSliver:setVisible(true)
        end

        self:runCsbAction("show",false,function ()
            self:runCsbAction("idle",true)
        end,60)
    else
        self.m_nodeGold:setVisible(true)
        self.m_nodeSliver:setVisible(true)
    end
end

return CashBonusPickGameBgView

