--[[

]]

local DailyMissionPassBuyCouponRewardLayer = class("DailyMissionPassBuyCouponRewardLayer", BaseLayer)

function DailyMissionPassBuyCouponRewardLayer:ctor()
    DailyMissionPassBuyCouponRewardLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYPASS_RES_PATH.BuyCouponRewardLayer)
    self:setPortraitCsbName(DAILYPASS_RES_PATH.BuyCouponRewardLayerVertical)

    self:addClickSound({"btn_collect"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function DailyMissionPassBuyCouponRewardLayer:initUI(_itemData, _overCall)
    DailyMissionPassBuyCouponRewardLayer.super.initUI(self)

    self.m_overCall = _overCall

    local newItemNode = gLobalItemManager:createRewardNode(_itemData, ITEM_SIZE_TYPE.REWARD)
    self.m_nodeReward:addChild(newItemNode)
end

function DailyMissionPassBuyCouponRewardLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_reward")
end

function DailyMissionPassBuyCouponRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

-- 重写父类方法
function DailyMissionPassBuyCouponRewardLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    DailyMissionPassBuyCouponRewardLayer.super.playShowAction(self, "start")
end

function DailyMissionPassBuyCouponRewardLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_collect" or name == "btn_close" then
        self:closeUI(function ()
            if self.m_overCall then
                self.m_overCall()
            end
        end)
    end
end

return DailyMissionPassBuyCouponRewardLayer
