--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 10:32:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 10:32:52
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/ExpandGameMarqueeTitleBuffUI.lua
Description: 扩圈小游戏 跑马灯 标题BuffUI
--]]
local ExpandGameMarqueeTitleBuffUI = class("ExpandGameMarqueeTitleBuffUI", BaseView)

function ExpandGameMarqueeTitleBuffUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Buff.csb"
end

function ExpandGameMarqueeTitleBuffUI:updateUI(_curGameMul)
    if not _curGameMul or _curGameMul == 0 then
        self:setVisible(false)
        return
    end

    self:setVisible(true)

    -- 成倍buff
    local lbBuff = self:findChild("lb_coin_small")
    lbBuff:setString("X" .. _curGameMul)
end

return ExpandGameMarqueeTitleBuffUI