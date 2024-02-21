local UserInfoFrame = class("UserInfoFrame", BaseLayer)

function UserInfoFrame:ctor()
    UserInfoFrame.super.ctor(self)
    self:setExtendData("UserInfoFrame")
    self:setLandscapeCsbName("Activity/csd/Information_Frame/Iformation_frame_zong/Information_frame_zong.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:setShowActionEnabled(false)
    self:setMaskEnabled(false)
end

function UserInfoFrame:initView()
    self.listView = self:findChild("ListView_fram")
    self.avt_bg = self:findChild("avm_bg1")
    self.avt_txt = self:findChild("avm_txt")
    self.fram_bg = self:findChild("fram_bg1")
    self.fram_txt = self:findChild("fram_txt")
    self.head_node = self:findChild("node_frame")
    self.node_avter = self:findChild("node_avter")
    self.node_remove = self:findChild("node_remove")
    self.sp_kuang = self:findChild("sp_kuang")
    self.listView_txtSys = self:findChild("ListView_txt")
    self.listView_txtSys:setScrollBarEnabled(false)
    self.m_ListTxtSize = self.listView_txtSys:getContentSize()
    self.txt_sysym = self:findChild("txt_sysym")
    self.txt_sysym:ignoreContentAdaptWithSize(true)
    self.btn_apply = self:findChild("btn_apply")
    self.listView:setVisible(false)
    self.m_lbFrameDescTime = self:findChild("lb_desTime")
    self:updataButton(self.ManGer:getFrameItem())

    schedule(self, handler(self, self.onUpdateSec), 1)
end

function UserInfoFrame:onUpdateSec()
    if not self.m_resufhAvrData or self.m_resufhAvrData.frameType ~= "item" then
        return
    end

    -- 限时头像框刷新倒计时
    local timeStr = self.ManGer:getAvrPropTimeEndDes(self.m_resufhAvrData.prop_id)
    if timeStr then
        self.m_lbFrameDescTime:setString(timeStr)
    end
end

function UserInfoFrame:updataButton(_idx)
    self.m_lbFrameDescTime:setVisible(false)

    local path = "Activity/img/Information_Frame/"
    if _idx == 1 then
        self.ManGer:setFrameItem(1)
        util_changeTexture(self.avt_bg,path..self.config.imagePath1[1])
        util_changeTexture(self.avt_txt,path..self.config.imagePath1[2])
        util_changeTexture(self.fram_bg,path..self.config.imagePath1[3])
        util_changeTexture(self.fram_txt,path..self.config.imagePath1[4])
        self.node_remove:setVisible(false)
        self:setTextAreaString("System Avatar")
        if self.m_tableView then
            self.m_tableView:setVisible(true)
            local avrId = globalData.userRunData.avatarFrameId
            if avrId ~= nil then
                self:reshFrame(avrId)
            else
                self.node_avter:setVisible(false)
            end
            local hd = self.ManGer:getHeadIndex()
            if hd ~= 0 then
                self:reshHead(hd)
            end
        else
            self:updataFrame()
        end
        if self.m_avterView then
            self.m_avterView:setVisible(false)
        end
        self:reshHeadBtn()
        if self.ManGer:getNewStatus() then
            self.ManGer:setIsNew()
        end
    else
        self:setButtonLabelContent("btn_apply", "APPLY")
        self.btn_apply:setTouchEnabled(true)
        self.ManGer:setFrameItem(2)
        util_changeTexture(self.avt_bg,path..self.config.imagePath2[1])
        util_changeTexture(self.avt_txt,path..self.config.imagePath2[2])
        util_changeTexture(self.fram_bg,path..self.config.imagePath2[3])
        util_changeTexture(self.fram_txt,path..self.config.imagePath2[4])
        self.node_avter:setVisible(true)
        if self.m_avterView then
            self.m_avterView:setVisible(true)
            local data = self.ManGer:getAvrDataById(self.ManGer:getChooseAvr())
            if data then
                self:resufhAvr(data)
                self:reshFrame(data.id)
            end
        else
            self:updataAvter()
        end
        local headId = tonumber(globalData.userRunData.HeadName or 1)
        self:reshHead(headId)
        if self.m_tableView then
            self.m_tableView:setVisible(false)
        end
        local avrId = globalData.userRunData.avatarFrameId
        self.node_remove:setVisible(false)
        if avrId ~= nil and avrId == self.ManGer:getChooseAvr() then
            self.node_remove:setVisible(true)
        end
    end
end

--刷新头像列表
function UserInfoFrame:updataFrame()
    local size = self.listView:getContentSize()
    local posx = self.listView:getPositionX()
    local posy = self.listView:getPositionY()
    local param = {
        tableSize = size,
        parentPanel = self:findChild("node_tabview"),
        directionType = 2
    }
    self.m_tableView = util_require("views.UserInfo.view.UserInfoHeadTableView").new(param)
    self:findChild("node_tabview"):addChild(self.m_tableView)
    self.m_tableView:setPosition(390,30)
    local headResList = self.ManGer:getData():getHeadList()
    if headResList and #headResList > 0 then
        self.m_tableView:reload(headResList,1)
    end

    local headId = tonumber(globalData.userRunData.HeadName or 1)
    if headId == 0 then
        self:setTextAreaString("Facebook Avatar")
    end
    if gLobalSendDataManager:getIsFbLogin() then
        local head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(globalData.userRunData.facebookBindingID, headId, nil, false, cc.size(150,150), true)
        if head_sprite then
            self.head_node:addChild(head_sprite)
            head_sprite:setName("head_FrameUid")
        end
    else
        local head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(nil, headId, nil, false, cc.size(150,150), false)
        if head_sprite then
            self.head_node:addChild(head_sprite)
            head_sprite:setName("head_FrameUid")
        end
    end

    local avrId = globalData.userRunData.avatarFrameId
    if avrId ~= nil and avrId ~= "" then
        local avr_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(tonumber(avrId),true)
        avr_sprite:setScale(0.66)
        self.node_avter:addChild(avr_sprite)
        avr_sprite:setName("head_AvterUid")
        self.sp_kuang:setVisible(false)
    end
end

--刷新头像框
function UserInfoFrame:updataAvter()
    local size = self.listView:getContentSize()
    local posx = self.listView:getPositionX()
    local posy = self.listView:getPositionY()
    local param = {
        tableSize = size,
        parentPanel = self:findChild("node_tabview"),
        directionType = 2
    }
    self.m_avterView = util_require("views.UserInfo.view.UserInfoHeadTableView").new(param)
    self:findChild("node_tabview"):addChild(self.m_avterView)
    self.m_avterView:setPosition(390,30)
    local avterList = self.ManGer:getCfAllList()
    if avterList and #avterList > 0 then
        self.m_avterView:reload(avterList,2)
    end

    local headId = self.ManGer:getChooseAvr()
    if globalData.userRunData.avatarFrameId ~= nil and globalData.userRunData.avatarFrameId ~= "" then
        headId = tonumber(globalData.userRunData.avatarFrameId)
    end
    if globalData.userRunData.avatarFrameId == nil or globalData.userRunData.avatarFrameId == "" then
        self.btn_apply:setTouchEnabled(false)
        self:setButtonLabelAction(self.btn_apply, true)
    end
    local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(headId,true)
    if head_sprite then
        self.node_avter:removeAllChildren()
        head_sprite:setScale(0.66)
        self.node_avter:addChild(head_sprite)
        head_sprite:setName("head_AvterUid")
        self.sp_kuang:setVisible(false)
    end

    local defult_avr = self.ManGer:getData():getDefultAvr()
    self:resufhAvr(defult_avr)
end

function UserInfoFrame:resufhAvr(_data)
    local str = self.ManGer:getAvrDes(_data.slot_id,_data.frame_level,_data.id)
    if _data.frameType == "item" then
        str = _data.propFrame_desc

        local timeStr = self.ManGer:getAvrPropTimeEndDes(_data.prop_id)
        self.m_lbFrameDescTime:setString(timeStr or "")
        self.m_lbFrameDescTime:setVisible(timeStr ~= nil)
    else
        self.m_lbFrameDescTime:setVisible(false)
    end
    
    self:setTextAreaString(str)
    local status = self.ManGer:getStatus(_data.id)
    if status == 0 then
        self.btn_apply:setTouchEnabled(false)
        self:setButtonLabelAction(self.btn_apply, true)
    else
        self.btn_apply:setTouchEnabled(true)
        self:setButtonLabelAction(self.btn_apply, false)
    end

    self.m_resufhAvrData = _data
end

function UserInfoFrame:registerListener()
    gLobalNoticManager:addObserver(self,function(self, itemData)
        self:resufhAvr(itemData)
        self:reshFrame(itemData.id)
        local avrId = globalData.userRunData.avatarFrameId
        if avrId ~= nil and avrId == self.ManGer:getChooseAvr() then
            self.node_remove:setVisible(true)
        else
            self.node_remove:setVisible(false)
        end
    end,self.config.ViewEventType.AVR_ITEM_CLICK)

    gLobalNoticManager:addObserver(self,function(self, itemData)
       self:reshHead(itemData)
       self:reshHeadBtn()
       if itemData == 0 and gLobalSendDataManager:getIsFbLogin() then
          self:setTextAreaString("Facebook Avatar")
       else
          self:setTextAreaString("System Avatar")
       end
    end,self.config.ViewEventType.FRAME_ITEM_CLICK)

    gLobalNoticManager:addObserver(self,function(self, itemData)
        local avrId = globalData.userRunData.avatarFrameId
        if avrId ~= nil and avrId == self.ManGer:getChooseAvr() then
            if self.ManGer:getFrameItem() == 2 then
                self.node_remove:setVisible(true)
            end
        else
            self.node_remove:setVisible(false)
        end
        if self.ManGer:getFrameItem() == 1 then
            self:reshHeadBtn()
        end
    end,self.config.ViewEventType.NOTIFY_USERINFO_MODIFY_SUCC)

    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            self:updataButton(self.ManGer:getFrameItem())
        end,
        self.config.ViewEventType.MAIN_IN
    )

    -- 头像框资源下载结束
    gLobalNoticManager:addObserver(
        self, 
        function()
            -- 刷新自己身上的头像框
            self:reshFrame(self.m_chooseId or globalData.userRunData.avatarFrameId)

            -- 刷新头像框列表
            local avterList = self.ManGer:getCfAllList()
            if self.m_avterView and avterList and #avterList > 0 then
                self.m_avterView:reload(avterList,2)
            end
        end, 
        ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE
    )
    --头像卡到期卸下自己的头像框
    gLobalNoticManager:addObserver(self, function()
        if self.node_remove:isVisible() then
            self.node_remove:setVisible(false)
            local defult_avr = self.ManGer:getData():getDefultAvr()
            self:resufhAvr(defult_avr)
        end
    end, ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI)
end

function UserInfoFrame:reshFrame(id)
    local shop1 = self.node_avter:getChildByName("head_AvterUid")
    if shop1 ~= nil and not tolua.isnull(shop1) then
        self.node_avter:removeAllChildren()
    end
    if id == "" then
        return
    end
    local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(id,true)
    head_sprite:setScale(0.66)
    self.node_avter:addChild(head_sprite)
    head_sprite:setName("head_AvterUid")
    self.m_chooseId = id
end

function UserInfoFrame:reshHead(id)
    local shop1 = self.head_node:getChildByName("head_FrameUid")
    if shop1 ~= nil and not tolua.isnull(shop1) then
        self.head_node:removeAllChildren()
    end
    local head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(nil, id, nil, false, cc.size(150,150), false)
    if id == 0 then
        if gLobalSendDataManager:getIsFbLogin() then
            head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(globalData.userRunData.facebookBindingID, id, nil, false, cc.size(150,150), true)
        end
    end
    self.head_node:addChild(head_sprite)
    head_sprite:setName("head_FrameUid")
end

function UserInfoFrame:reshHeadBtn()
    local headId = tonumber(globalData.userRunData.HeadName or 1)
    if self.ManGer:getHeadIndex() == headId then
        self:setButtonLabelContent("btn_apply", "APPLIED")
        self.btn_apply:setTouchEnabled(false)
        self:setButtonLabelAction(self.btn_apply, true)
    else
        self:setButtonLabelContent("btn_apply", "APPLY")
        self.btn_apply:setTouchEnabled(true)
        self:setButtonLabelAction(self.btn_apply, false)
    end
end

function UserInfoFrame:onEnter()
    self:registerListener()
end

function UserInfoFrame:clickStartFunc(sender)
end

function UserInfoFrame:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_avt" then
        --头像页
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:updataButton(1)
    elseif name == "btn_fram" then
        --头像框页
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:updataButton(2)
    elseif name == "btn_apply" then
        --发送更换头像请求
        if self.ManGer:getFrameItem() == 1 then
            local _frameId = nil
            if globalData.userRunData.avatarFrameId ~= nil then
                _frameId = tonumber(globalData.userRunData.avatarFrameId)
            end
            self.ManGer:saveNickName(globalData.userRunData.nickName,"",self.ManGer:getHeadIndex(),false,false,_frameId)
        else
            local headId = tonumber(globalData.userRunData.HeadName or 1)
            self.ManGer:saveNickName(globalData.userRunData.nickName,"",headId,false,false,self.ManGer:getChooseAvr(),1)
        end
    elseif name == "btn_remove" then
        self.ManGer:saveNickName(globalData.userRunData.nickName,"",globalData.userRunData.HeadName,false,false,nil,nil,999)
    end
end

-- textArea 文本优化
function UserInfoFrame:setTextAreaString(_str)
    self.txt_sysym:setTextAreaSize(cc.size(self.m_ListTxtSize.width-4, 0))
    self.txt_sysym:setString(_str or "")
    local textSize = self.txt_sysym:getContentSize()
    if textSize.height <= self.m_ListTxtSize.height then
        self.txt_sysym:setTextAreaSize(self.m_ListTxtSize)
    end
    self.listView_txtSys:requestDoLayout()
end

return UserInfoFrame