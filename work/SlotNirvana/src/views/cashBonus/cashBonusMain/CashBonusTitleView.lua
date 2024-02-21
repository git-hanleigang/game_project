--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-23 14:51:54
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-23 14:51:57
FilePath: /SlotNirvana/src/views/cashBonus/cashBonusMain/CashBonusTitleView.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local CashBonusTitleView = class("CashBonusTitleView", BaseView)

function CashBonusTitleView:getCsbName()
    return "NewCashBonus/CashBonusNew/CashBonus_title.csb"
end

function CashBonusTitleView:initUI()
    CashBonusTitleView.super.initUI(self)
    self:initView()
end

function CashBonusTitleView:initView()
    self:runCsbAction("idle", true)
end

return CashBonusTitleView
