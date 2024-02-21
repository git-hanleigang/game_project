local CashDisyCell = class("CashDisyCell", BaseView)

local ITEM_TYPE = {
    LEVEL_ITEM = 1,
    FRAME_ITEM = 2
}
function CashDisyCell:initUI()
    self:createCsbNode("Activity/csd/Information_FramePartII/FramePartII_MainUI/FramePartII_MainUI_level.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:initView()
end

function CashDisyCell:initView()
    self.node_level = self:findChild("node_level")
    local spbg = self:findChild("icon_framebg")
    spbg:setVisible(true)
    self:runCsbAction("idle")
    self:registerListener()
end

function CashDisyCell:updataCell(_data,type,_index)
    self._type = type
    self.data = _data
    self._index = _index
    self:updataLevel(_data)
end

function CashDisyCell:updataLevel(_data)
    self.btn_level = self:findChild("btn_level")
    self.btn_level:setSwallowTouches(false)
    self.btn_level:setTouchEnabled(true)
    local splock = self.node_level:getChildByName("sp_lock")
    self.node_icon = self.node_level:getChildByName("node_icon")
    local lb_progress = self.node_level:getChildByName("lb_progress")
    local lb_desc1 = self.node_level:getChildByName("lb_desc1")
    lb_desc1:setVisible(false)
    splock:setVisible(false)
    if _data == "99999" then
        local hd_spite = util_createSprite("Activity/img/Information_FramePartII/FramePartII_MainUI/FramePartII_Main_icon1.png")
        self.node_icon:addChild(hd_spite)
        local item_head = self.ManGer:getCfHoldList()
        local totalNum = self.ManGer:getCfItemList()
        lb_progress:setString(#item_head.."/"..#totalNum)
    else
        local data = G_GetMgr(G_REF.AvatarFrame):getData()
        self.m_slotTaskData = data:getSlotTaskBySlotId(_data)
        local frameStaticData = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData() 
        local iconPath = frameStaticData:getSlotImgPath(_data)
        if iconPath and iconPath ~= "" then
            local hd_spite = util_createSprite(iconPath)
            hd_spite:setPositionY(9)
            self.node_icon:addChild(hd_spite)
        end
        self:updateProgresUI(lb_progress)
        self:updateLock(splock,lb_desc1,_data)
    end
end

function CashDisyCell:updataFrame(_data)
    -- body
end
-- 更新 任务进度
function CashDisyCell:updateProgresUI(_ui)
    if not self.m_slotTaskData then
        return
    end
    
    local completeNum = self.m_slotTaskData:getCompleteNum()
    local totalNum = self.m_slotTaskData:getTotalNum()
    _ui:setString(completeNum .. "/" .. totalNum)
end
-- 更新 任务等级
function CashDisyCell:updateLock(splok,lb_lok,_slotid)
    self.m_lock = false
    local d_a = globalData.slotRunData:getLevelInfoById(_slotid)
    if not d_a then
        return
    end
    local cam = self.ManGer:getRecmd(d_a.p_name)
    local num = self.m_slotTaskData:getCompleteNum()
    if globalData.userRunData.levelNum < d_a.p_openLevel and not cam and num == 0 then
        --self.btn_level:setTouchEnabled(false)
        splok:setVisible(true)
        local str = "Unlock".."\n".."at  Iv "..d_a.p_openLevel
        lb_lok:setString(str)
        lb_lok:setVisible(true)
        self.m_lock = true
        -- self:runCsbAction("dark")
        -- util_setCascadeColorEnabledRescursion(self.node_icon, true)
    end
end
function CashDisyCell:clickCell()
end

function CashDisyCell:clickStartFunc(sender)
end

function CashDisyCell:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self:runCsbAction("start",false,function()
            self:runCsbAction("idle",true)
        end)
    end,self.config.ViewEventType.CASH_AVMENT_ANIFRAME)
end

function CashDisyCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_level" then
        if self.m_lock then
            if self.click_lock then
                return
            end
            self.click_lock = true
            self:runCsbAction("darkstart",false,function()
                self.click_lock = false
                self:runCsbAction("idle",true)
            end)
            return
        end
        local param = {}
        param.data = self.data
        param.index = self._index
        gLobalNoticManager:postNotification(self.config.ViewEventType.FRAME_AVMENT_LEVEL,param)
    end
end

return CashDisyCell