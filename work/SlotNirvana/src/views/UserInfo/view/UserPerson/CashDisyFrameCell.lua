local CashDisyFrameCell = class("CashDisyFrameCell", BaseView)
function CashDisyFrameCell:initUI()
    self:createCsbNode("Activity/csd/Information_FramePartII/FramePartII_MainUI/FramePartII_MainUI_level.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:initView()
end

function CashDisyFrameCell:initView()
    self.node_frame = self:findChild("node_level")
    self:registerListener()
end

function CashDisyFrameCell:updataCell(_data,_isCan)
    self._type = _isCan
    self.data = _data
    self.ani_str = "start"
    self.node_frame:setVisible(true)
    self:updataFrame(_data,_isCan)
end

function CashDisyFrameCell:updataFrame(_data,_isCan)
    self.icon_frame = self:findChild("node_icon")
    self.sp_lock2 = self:findChild("sp_lock")
    self.lb_name = self:findChild("lb_progress")
    self.lb_name:setScale(0.9)
    self.sp_lock2:setVisible(false)
    self.lb_progress_1 = self:findChild("lb_progress_2")
    if _isCan ~= nil  then
        local head_spr = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(_data)
        head_spr:setScale(0.7)
        self.icon_frame:addChild(head_spr)
        self.lb_name:setString("EVENT")
        if _isCan then
            
            self.lb_progress_1:setVisible(false)
            --self:runCsbAction("idle")
        else
            self.ani_str = "darkstart"
            --self:runCsbAction("dark")
        end
        util_setCascadeColorEnabledRescursion(self.icon_frame, true)
    else
        local frameId = _data:getFrameId()
        local view = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(frameId)
        if not view then
            return
        end
        view:setScale(0.7)
        self.icon_frame:addChild(view)
        self:updateStatus(_data)
        self:initProgresUI(_data)
        self:updateTaskLevelUI(_data)
    end
end
-- 更新 任务进度
function CashDisyFrameCell:initProgresUI(_data)
    -- 进度文本
    local curNum = _data:getProgress()
    local limitNum = _data:getLimitNum()
    local percent = 0
    if limitNum > 0 then
        percent = math.floor(curNum / limitNum * 100)
    end
    if percent ~= 0 then
        self.lb_progress_1:setString(percent .. "%")
    end
end

-- 更新状态
function CashDisyFrameCell:updateStatus(_data)
    local status = _data:getStatus()
    -- 0未激活， 1正在进行， 2已完成
    if status == 0 or status == 1 then
        self.lb_progress_1:setVisible(true)
        --self:runCsbAction("dark")
        self.ani_str = "darkstart"
    elseif status == 2 then
        self.lb_progress_1:setVisible(false)
        --self:runCsbAction("idle")
    end

    util_setCascadeColorEnabledRescursion(self.icon_frame, true)
end
-- 头像框 任务等级
function CashDisyFrameCell:updateTaskLevelUI(_data)
    local frameId = _data:getFrameId()
    local desc = _data:getFrameLevelDesc()
    self.lb_name:setString(desc)
end

function CashDisyFrameCell:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self:runCsbAction(self.ani_str,false,function()
            --self:runCsbAction(self.ani_str,true)
        end)
    end,self.config.ViewEventType.CASH_AVMENT_ANIFRAME)
end

function CashDisyFrameCell:clickCell()
end

function CashDisyFrameCell:clickStartFunc(sender)
end

function CashDisyFrameCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_level" then
        local param = {}
        param.data = self.data
        param.type = 2
        if self._type ~= nil then
            param.type = self._type
        end
        self.ManGer:showAchieveRule(param)
    end
end

return CashDisyFrameCell