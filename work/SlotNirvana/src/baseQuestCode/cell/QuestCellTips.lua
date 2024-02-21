-- 气泡里面的奖励内容

local QuestCellTips = class("QuestCellTips", BaseView)

function QuestCellTips:getCsbName()
    return QUEST_RES_PATH.QuestCellTips
end

function QuestCellTips:initDatas(phase_idx, stage_idx)
    self.phase_idx = phase_idx
    self.stage_idx = stage_idx
end

function QuestCellTips:initUI()
    QuestCellTips.super.initUI(self)

    self:initRewards()
end

function QuestCellTips:initCsbNodes()
    self.sp_bg = self:findChild("sp_bg")
    assert(self.sp_bg, "QuestCellTips 节点不存在1")
    self.sp_arrow = self:findChild("sp_arrow")
    assert(self.sp_arrow, "QuestCellTips 节点不存在2")
end

function QuestCellTips:initRewards()
    if not self.rewardsItems then
        local rewards = util_createView(QUEST_CODE_PATH.QuestCellTipRewards, self.phase_idx, self.stage_idx)
        if rewards then
            rewards:addTo(self.sp_bg)
            self.rewardsItems = rewards
        end
        local bg_size = self.sp_bg:getContentSize()
        -- self.sp_arrow:setPositionY(bg_size.height / 2)   -- 为了让三角可以往下挪动一点，不写死
    end
end

function QuestCellTips:showTipView(callback)
    self:setVisible(true)
    if self.rewardsItems then
        self.rewardsItems:resetUI()
        local rewardWidth = self.rewardsItems:getWidth()
        local rewardHeight = self.rewardsItems:getHeight()
        local width_offset = 20
        local height_offset = 20
        if self.stage_idx == 6 then
            width_offset = 40
            height_offset = 40
        end
        self.sp_bg:setContentSize(cc.size(rewardWidth + width_offset, rewardHeight + height_offset))
        self.rewardsItems:setPositionX(width_offset / 2)
        self.rewardsItems:setPositionY((rewardHeight + height_offset) / 2)

        local bg_size = self.sp_bg:getContentSize()
        -- self.sp_arrow:setPositionY(bg_size.height / 2)  -- 为了让三角可以往下挪动一点，不写死
        if self.stage_idx == 6 then
            self.sp_arrow:setScale(0.7)
        end
    end
    self:runCsbAction("idle", false)
    if callback ~= nil then
        callback()
    end
end

function QuestCellTips:hideTipView(callback)
    self:setVisible(false)
    if callback ~= nil then
        callback()
    end
end

function QuestCellTips:setFlippedX(bl_flip)
    local scaleX = self:getScaleX()
    local cur_flip = scaleX < 0
    if cur_flip == bl_flip then
        return
    end
    self:setScaleX(scaleX * -1)

    local item_scaleX = self.rewardsItems:getScaleX()
    self.rewardsItems:setScaleX(item_scaleX * -1)

    local cur_scaleX = self:getScaleX()
    if cur_scaleX > 0 then
        self.rewardsItems:setPositionX(0)
    else
        local size = self.sp_bg:getContentSize()
        self.rewardsItems:setPositionX(size.width)
    end
end

return QuestCellTips
