local UserInfoChangeName = class("UserInfoChangeName", BaseLayer)

function UserInfoChangeName:ctor()
    UserInfoChangeName.super.ctor(self)
    self:setExtendData("UserInfoChangeName")
    self:setLandscapeCsbName("Activity/csd/Information/Iformation_Editname.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
end

function UserInfoChangeName:initCsbNodes()
    self.name_field = self:findChild("name_field")
    self.text_left = self:findChild("txt_desc2")
    self.placeHolder = self:findChild("placeHolder")
    self.btn_confirm = self:findChild("btn_confirm")
end

function UserInfoChangeName:initView()
    if util_isSupportVersion("1.3.7") then
        -- edibox
        self.m_EditBoxName = self.config.convertTextFiledToEditBox(self.name_field, nil, handler(self, self.onDescEdit))
        --self.m_EditBoxName:onEditHandler(handler(self, self.onDescEdit))
    else
        self.m_EditBoxName = self.name_field
    end
    self:refreshNickNameCountdown()
    self:refreshNickNameSaveUI()
    self:updateLbCharater()
    self.btn_confirm:setTouchEnabled(false)
    self:setButtonLabelAction(self.btn_confirm, true)
end

function UserInfoChangeName:onDescEdit(event,sender)
    if event == "began" then
        self.placeHolder:setVisible(false)
        self.m_EditBoxName:setPlaceHolder("")
    elseif event == "changed" then
        -- 改变字数
        local newDesc = sender:getText()
        self:updateLbCharater()
    elseif event == "return" then
        local newDesc = sender:getText()
        local sensitiveStr = self.config.getSensitiveStr(newDesc)
        self.m_EditBoxName:setText(sensitiveStr or "")
    end
end

--刷新字符提示
function UserInfoChangeName:updateLbCharater()
    local sCurStr = ""
    -- if util_isSupportVersion("1.3.7") then
    --     sCurStr = self.name_field:getText()
    -- else
    --     sCurStr = self.name_field:getString()
    -- end
    sCurStr = self.m_EditBoxName:getText()

    local curLen = self.config.getStrUtf8Len(sCurStr)
    local num = 14 - curLen
    self.text_left:setString("" .. num .. " characters left")
    util_scaleCoinLabGameLayerFromBgWidth(self.m_EditBoxName, 450)
    if self.m_changeNameleftTime <= 0 and string.len(sCurStr) > 0 then
        self.btn_confirm:setTouchEnabled(true)
        self:setButtonLabelAction(self.btn_confirm, false)
    else
        self.btn_confirm:setTouchEnabled(false)
        self:setButtonLabelAction(self.btn_confirm, true)
    end
end

function UserInfoChangeName:closeUI()
    UserInfoChangeName.super.closeUI(self)
end

function UserInfoChangeName:refreshNickNameCountdown()
    local curTime = math.floor(util_getCurrnetTime()) -- 当前时间戳
    local lastUpdateNickNameTime = globalData.userRunData.lastUpdateNickNameTime or 0
    self.m_changeNameleftTime = 0
    if lastUpdateNickNameTime > 0 then
        local lock_time = 7 * 24 * 3600
        self.m_changeNameleftTime = lock_time - (curTime - lastUpdateNickNameTime)
    end
    self.m_changeNameleftTime = self.m_changeNameleftTime < 0 and 0 or self.m_changeNameleftTime
end

-- 刷新保存名字的按钮倒计时
function UserInfoChangeName:refreshNickNameSaveUI()
    local sCurStr = ""
    if util_isSupportVersion("1.3.7") then
        sCurStr = self.m_EditBoxName:getText()
    else
        sCurStr = self.m_EditBoxName:getString()
    end
    local lbChangeLeft = self:findChild("lbChangeLeft")
    local btnChangeName = self:findChild("btn_confirm")
    local imgSave = self:findChild("img_save")
    local leftTimeStr, bLockLabel = self.config.getTimeStr(self.m_changeNameleftTime)
    lbChangeLeft:setString(leftTimeStr)
    lbChangeLeft:setVisible(self.m_changeNameleftTime > 0)
    lbChangeLeft:setScale(0.8)
    imgSave:setVisible(self.m_changeNameleftTime > 0)
    self:setButtonLabelContent("img_save", "")
    --self:setButtonLabelDisEnabled("img_save", false)
    imgSave:setTouchEnabled(false)
    self:setButtonLabelAction(imgSave, true)
    -- btnChangeName:setEnabled(self.m_changeNameleftTime <= 0 and string.len(sCurStr) > 0)
    if self.m_changeNameleftTime <= 0 and string.len(sCurStr) > 0 then
        self.btn_confirm:setTouchEnabled(true)
        self:setButtonLabelAction(self.btn_confirm, false)
    else
        self.btn_confirm:setTouchEnabled(false)
        self:setButtonLabelAction(self.btn_confirm, true)
    end
    if not bLockLabel then
        if self.m_countdownAction then
            self:stopAction(self.m_countdownAction)
            self.m_countdownAction = nil
        end
        self.m_countdownAction =
            schedule(
            self,
            function()
                if self.m_changeNameleftTime < 0 then
                    return
                end
                self.m_changeNameleftTime = self.m_changeNameleftTime - 1
                local str = self.config.getTimeStr(self.m_changeNameleftTime)
                lbChangeLeft:setString(str)
                if self.m_changeNameleftTime <= 0 then
                    lbChangeLeft:setVisible(false)
                    imgSave:setVisible(false)
                    if self.m_changeNameleftTime <= 0 and string.len(sCurStr) > 0 then
                        btnChangeName:setTouchEnabled(true)
                        self:setButtonLabelAction(btnChangeName, false)
                    else
                        btnChangeName:setTouchEnabled(false)
                        self:setButtonLabelAction(btnChangeName, true)
                     end
                    self:stopAction(self.m_countdownAction)
                    self.m_countdownAction = nil
                end
            end,
            1
        )
    end
end

function UserInfoChangeName:clickFunc(sender)
    local sBtnName = sender:getName()
    if sBtnName == "btn_close" then
        self:closeUI()
    elseif sBtnName == "btn_confirm" then
        local sCurStr = ""
        if util_isSupportVersion("1.3.7") then
            sCurStr = self.m_EditBoxName:getText()
        else
            sCurStr = self.m_EditBoxName:getString()
        end
        local head_id = tonumber(globalData.userRunData.HeadName or 1)
        self.ManGer:saveNickName(sCurStr,"",head_id,false)
        self:closeUI()
    end
end

return UserInfoChangeName
