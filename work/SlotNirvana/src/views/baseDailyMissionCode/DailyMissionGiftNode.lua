--[[
    --新版每日任务pass主界面 任务界面礼物节点
    csc 2021-06-22
]]
local DailyMissionGiftNode = class("DailyMissionGiftNode", util_require("base.BaseView"))
function DailyMissionGiftNode:initUI(_source,_data)
    self.m_type = _source
    -- 根据当前任务类型创建不同的节点
    local csbPath = DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_GiftNode_daily.csb"
    if _source == "Season" then
        csbPath = DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_GiftNode_season.csb"
    end
    self:createCsbNode(csbPath)
    
    self.m_btnTouch = self:findChild("btn_touch")
    self.m_sprGiftIcon = self:findChild("sp_dailyGift")

    -- panel 触摸按钮
    self:addClick(self.m_btnTouch)

    self:runCsbAction("idle", true, nil, 60)

    self.m_data = _data
    self.m_doingGetReward = false
end

function DailyMissionGiftNode:clickFunc(_sender)
    local name = _sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_touch" then
        if self.m_doingGetReward then
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_SHOW_REWARD_INFO,{giftType = self.m_type})
    end
end

function DailyMissionGiftNode:updateView(_source)
    self.m_type = _source
end

function DailyMissionGiftNode:playFlyAction()
    self.m_doingGetReward = true
    self:runCsbAction("fly", false, function()
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("over", false, function()
                -- 这里需要将存在manager里的缓存数据清一下，此时已经领取过，新数据已经产生
                if self.m_type == "Season" then
                    gLobalDailyTaskManager:saveLastTaskData(nil)
                end
                self:removeFromParent()
            end,60)
            -- -- 打开收集界面
            -- gLobalDailyTaskManager:openRewardLayer(_rewardData,"mission")
        end,60)
    end, 60)
end

return DailyMissionGiftNode