--[[
Author: cxc
Date: 2022-04-22 17:44:35
LastEditTime: 2022-04-22 17:45:21
LastEditors: cxc
Description: 头像框 任务 奖励信息 弹板
FilePath: /SlotNirvana/src/views/AvatarFrame/reward/AvatarFrameSlotTaskRewardInfoLayer.lua
--]]
local AvatarFrameSlotTaskRewardInfoLayer = class("AvatarFrameSlotTaskRewardInfoLayer", BaseLayer)
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")

function AvatarFrameSlotTaskRewardInfoLayer:ctor()
    AvatarFrameSlotTaskRewardInfoLayer.super.ctor(self)

    self:setPauseSlotsEnabled(true) 
    self:setExtendData("AvatarFrameSlotTaskRewardInfoLayer")
    self:setLandscapeCsbName("Activity/csb/Frame_reward2.csb")
    self:setPortraitCsbName("Activity/csb/Frame_reward_vertical2.csb")
end

function AvatarFrameSlotTaskRewardInfoLayer:initDatas(_taskData)
    AvatarFrameSlotTaskRewardInfoLayer.super.initDatas(self)

    self.m_taskData = _taskData
end

-- 初始化节点
function AvatarFrameSlotTaskRewardInfoLayer:initCsbNodes()
    AvatarFrameSlotTaskRewardInfoLayer.super.initCsbNodes(self)

    self.m_nodeAvatar = self:findChild("node_avatar")
    self.m_lbTaskDesc = self:findChild("txt_challenge")
    self.m_nodeReward = self:findChild("node_reward")
    self.m_lbRewardCount = self:findChild("lb_reward")

    self.m_nodeReward:setVisible(false)
    self.m_lbTaskDesc:setVisible(false)
end

function AvatarFrameSlotTaskRewardInfoLayer:initView()
    AvatarFrameSlotTaskRewardInfoLayer.super.initView(self)

    -- 更新 头像 头像框
    self:updateAvatarUI()
    
    -- 任务描述
    self:updateTaskDescUI()

    self:runCsbAction("idle", true)
    self:FbLog("Popup")
end

function AvatarFrameSlotTaskRewardInfoLayer:onShowedCallFunc()
    gLobalSoundManager:playSound(AvatarFrameConfig.SOUND_ENUM.SLOT_TASK_COMPLETE_REWARD)
end

-- 更新 头像 头像框
function AvatarFrameSlotTaskRewardInfoLayer:updateAvatarUI()
    self.m_nodeAvatar:removeAllChildren()

    local frameId = self.m_taskData:getFrameId() 
    local size = cc.size(140, 140)
    local node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
        globalData.userRunData.facebookBindingID, 
        globalData.userRunData.HeadName, 
        frameId, nil, size)
    self.m_nodeAvatar:addChild(node)
end

-- 任务描述 奖励
function AvatarFrameSlotTaskRewardInfoLayer:updateTaskDescUI()
    -- 0未激活， 1正在进行， 2已完成
    local status = self.m_taskData:getStatus()
    if status ~= 2 then
        return
    end
    
    local str = "GAME GOAL: " .. self.m_taskData:getDesc()
    local limitW = 450
    if globalData.slotRunData.isPortrait then
        limitW = 530
    end
    self:updateTaskRewardNum()
    self.m_lbTaskDesc:setString(str)
    self.m_lbTaskDesc:setVisible(true)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbTaskDesc, limitW) 
end

function AvatarFrameSlotTaskRewardInfoLayer:updateTaskRewardNum()
    local count = self.m_taskData:getRewardFrameMiniGameCount()
    if count < 1 then
        return
    end

    self.m_lbRewardCount:setString("X" .. count)
    self.m_nodeReward:setVisible(true)
end

function AvatarFrameSlotTaskRewardInfoLayer:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        local cb = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        end
        self:closeUI(cb)
    elseif name == "btn_reward" then
        -- 跳转到个人信息页
        local cb = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            G_GetMgr(G_REF.UserInfo):showMainLayer(2)
        end
        self:closeUI(cb)
    elseif name == "btn_fbshare" then
        --分享
        self:ShareFB()
    end
end

function AvatarFrameSlotTaskRewardInfoLayer:ShareFB()
    if self.fb_click then
        return
    end
    self.fb_click = true
    local fileName = "frame_screen.png"
    local size = cc.Director:getInstance():getWinSize()
    local scale = self:getUIScalePro()
    local rect = cc.rect(display.width/2 - size.width/2*scale, display.height/2 - size.height/2*scale, size.width*scale, size.height*scale)
    self:findChild("node_button"):setVisible(false)
    self:findChild("node_button2"):setVisible(false)
    self:findChild("btn_close"):setVisible(false)
    local node_mask = self:findChild("node_mask")
    if device.platform == "ios" then
        local layer = cc.LayerColor:create(cc.c3b(0, 0, 0), display.width, display.height)
        node_mask:addChild(layer)
        layer:setPosition(-display.width/2,-display.height/2)
    end
    
    local sp, rt = util_createTargetScreenSprite(self:findChild("root"), rect)
    local callback = function (filePath)
        if device.platform == "ios" then
            node_mask:removeAllChildren()
        end
        self:findChild("node_button"):setVisible(true)
        self:findChild("node_button2"):setVisible(true)
        self:findChild("btn_close"):setVisible(true)
        local shareCallback = function (_message)
            gLobalViewManager:removeLoadingAnima()
            self.fb_click = false
             -- if not _message or _message == "" then
             --        return
             -- end
             -- local msg = cjson.decode(_message)
            local type = "PortraitShare"
            local sst = "Success"
            gLobalSendDataManager:getLogFbFun():sendFbActLog(type, "Click", "", "", "", sst)
        end
        globalFaceBookManager:facebookSharePicture(filePath, shareCallback)
    end
    rt:saveToFileLua(fileName, true, callback)
end

function AvatarFrameSlotTaskRewardInfoLayer:FbLog(_actionType)
    local type = "PortraitShare"
    local sst = "Success"
    gLobalSendDataManager:getLogFbFun():sendFbActLog(type, _actionType, "", "", "", sst)
end

return AvatarFrameSlotTaskRewardInfoLayer