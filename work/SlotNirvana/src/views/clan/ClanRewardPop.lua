
-- 公会关卡奖励弹板
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanRewardPop = class("ClanRewardPop", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRewardPop:initDatas()
    self.curStep = 1

    self:setPauseSlotsEnabled(true)

    self:setLandscapeCsbName("Club/csd/Tanban/ClubBoxLevel.csb")
    self:setPortraitCsbName("Club/csd/Tanban/ClubBoxLevel_portrait.csb")
end

function ClanRewardPop:initUI()
    ClanRewardPop.super.initUI(self)
    self.clan_data = ClanManager:getClanData()
    if not self.clan_data then
        self:setVisible(false)
        performWithDelay(self, handler(self, self.closeUI), 0)
        return
    end

    -- 读取必要节点
    self:readNodes()
    self:resetRewardBox()
    self:setExtendData("ClanRewardPop")
end

function ClanRewardPop:readNodes()
    self.root = self:findChild("root")
    assert(self.root, "缺少必要节点 root")

    self.btn_anniu_continue = self:findChild("btn_anniu_continue")
    assert(self.btn_anniu_continue, "缺少必要节点3")
end

function ClanRewardPop:resetRewardBox()
    local clanData = ClanManager:getClanData()
    local taskData = clanData:getTaskData()
    if taskData and taskData.curStep and self.curStep ~= taskData.curStep then
        self.curStep = taskData.curStep
    end

    local preStep = self.curStep - 1
    for i=1, 6 do
        local spBoxOld = self:findChild("gonghui_baoxiang_old_" .. i)
        if spBoxOld then
            spBoxOld:setVisible(i == preStep)
        end
        

        local spBoxOld = self:findChild("gonghui_baoxiang_new_" .. i)
        if spBoxOld then
            spBoxOld:setVisible(i == self.curStep)
        end
    end
    
end

-- 弹窗动画
function ClanRewardPop:playShowAction()
    local userDefAction = function(callFunc)
        self:runCsbAction("show", false, callFunc, 60)
    end
    BaseLayer.playShowAction(self, userDefAction)
end

-- 隐藏动画
function ClanRewardPop:playHideAction()
    local userDefAction = function(callFunc)
        self:runCsbAction("hide", false, callFunc, 60)
    end
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    BaseLayer.playHideAction(self, userDefAction)
end

function ClanRewardPop:onShowedCallFunc()
    self:runCsbAction("idle", false, function()
        self:runCsbAction("idle1", false, nil, 60)
    end, 60)

    if gLobalViewManager:isLevelView() and globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
        performWithDelay(self, handler(self, self.closeUI), 8)
    end
    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.UNLOCK_NEXT_TASK)
end

function ClanRewardPop:clickFunc(sender)
    local btnName = sender:getName()
    if btnName == "btn_anniu_continue" then
        self:closeUI(function()
            local cb = function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            end
            ClanManager:enterClanSystem(nil, cb)
        end)
    elseif btnName == "btn_close" then
        self:closeUI()
    end
end

function ClanRewardPop:closeUI(_cb)
    if self.m_bClose then
        return
    end
    self.m_bClose = true

    if type(_cb) ~= "function" then
        local cb = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        end
        ClanRewardPop.super.closeUI(self, cb)
        return
    end
    ClanRewardPop.super.closeUI(self, _cb)
end

return ClanRewardPop
