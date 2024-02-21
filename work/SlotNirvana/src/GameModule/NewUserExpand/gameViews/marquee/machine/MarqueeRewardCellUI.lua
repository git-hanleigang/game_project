--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 20:09:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 20:09:41
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/machine/MarqueeRewardCellUI.lua
Description: 扩圈小游戏 跑马灯 格子
--]]
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local MarqueeRewardCellUI = class("MarqueeRewardCellUI", BaseView)

function MarqueeRewardCellUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Ring_piece.csb"
end

function MarqueeRewardCellUI:initUI(_idx, _rewardData)
    MarqueeRewardCellUI.super.initUI(self)
    self.m_idx = _idx
    self.m_rewardData = _rewardData

    -- 道具背景
    self:updateBgUI()
    -- 道具
    self:createItemUI()

    self:playUnChooseAni()
end

-- 道具背景
function MarqueeRewardCellUI:updateBgUI()
    local spBg = self:findChild("sp_bg")
    local resName = self.m_rewardData:getBgResName()
    local path = string.format("MarqueeGame/ui/piece_di/MarqueeGame_piece_%s.png", ExpandGameMarqueeConfig.TYPE_BG_IDX[resName])
    util_changeTexture(spBg, path)
end

-- 道具
function MarqueeRewardCellUI:createItemUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.machine.MarqueeRewardItemUI", self.m_rewardData)
    local parent = self:findChild("node_reward")
    parent:addChild(view)
    self.m_itemView = view
end

function MarqueeRewardCellUI:playChooseAni(_cb)
    self:runCsbAction("flash", false, _cb, 60)
    gLobalSoundManager:playSound(ExpandGameMarqueeConfig.SOUNDS.FLASH)
end

function MarqueeRewardCellUI:playUnChooseAni(_cb)
    self:runCsbAction("hide")
end

-- cell 置灰逻辑
function MarqueeRewardCellUI:checkGrayUI(_chooseIdx, _bGray)
    if self.m_idx == _chooseIdx then
        return
    end

    local color = cc.c3b(255, 255, 255)
    if _bGray then
        color = cc.c3b(70, 70, 70)
    end
    self:setColor(color)
end
return MarqueeRewardCellUI