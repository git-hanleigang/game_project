-- 小猪挑战 主界面箱子

local PigChallengeBox = class("PigChallengeBox", BaseView)

-- 宝箱展示 道具scale
local itemScale = {0.8, 0.9, 1.0, 1.0}

function PigChallengeBox:ctor()
    PigChallengeBox.super.ctor(self)
    self.m_config = G_GetMgr(ACTIVITY_REF.PiggyChallenge):getConfig()
end

function PigChallengeBox:initUI(idx, data, init_type)
    self.m_idx = idx
    self.m_data = data
    self.init_type = init_type

    local csbName = string.format(self.m_config.Box, self.m_idx)
    self:createCsbNode(csbName)

    self:createItems()
    self:updateUI()
end

function PigChallengeBox:initCsbNodes()
    self.sp_open = self:findChild("sp_complish")
    self.node_closed = self:findChild("node_unComplish")
end

-- 创建宝箱旁的道具
function PigChallengeBox:createItems()
    local items = self.m_data.items or {}
    local shopItemData = items[1]
    if shopItemData then
        local shopItemUI = gLobalItemManager:createRewardNode(shopItemData, ITEM_SIZE_TYPE.REWARD)
        local parent = self:findChild("node_showItem")
        shopItemUI:addTo(parent)
        shopItemUI:setScale(itemScale[self.m_idx] or 1)
    end
end

function PigChallengeBox:getData()
    return self.m_data
end

function PigChallengeBox:updateUI()
    self.bl_collected = self.m_data.collected
    self.sp_open:setVisible(self.m_data.collected)
    self.node_closed:setVisible(not self.m_data.collected)
end

function PigChallengeBox:onOpen()
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_data.collected = true
            self:updateUI()
        end
    )
end

-- 点击事件响应
function PigChallengeBox:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_touch" then
        if self.init_type == "pop_layer" then
            -- 弹出宝箱tips
            if self.m_data.collected then
                -- 领取后的宝箱
                return
            end
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIG_CHALLENGE_REWARD_CLICKED, {idx = self.m_idx, init_type = self.init_type})
        elseif self.init_type == "process" then
            -- 关闭小猪主界面
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIG_CHALLENGE_REWARD_CLICKED, {idx = self.m_idx, init_type = self.init_type})
        end
    end
end

return PigChallengeBox
