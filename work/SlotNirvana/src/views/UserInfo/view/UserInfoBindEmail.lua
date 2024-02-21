--绑定邮箱
local UserInfoBindEmail = class("UserInfoBindEmail", BaseLayer)

function UserInfoBindEmail:ctor()
    UserInfoBindEmail.super.ctor(self)
    self:setExtendData("UserInfoBindEmail")
    self:setLandscapeCsbName("Activity/csd/Information/Iformation_EmailConnect.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
end

function UserInfoBindEmail:initCsbNodes()
    self.m_CheckBox = self:findChild("CheckBox_1")
    self.m_spError = self:findChild("sp_error")
    self.textField = self:findChild("TextField_1")
    self.btn_save = self:findChild("btn_save")
    self.check_dui = self:findChild("check_dui")
end

function UserInfoBindEmail:initView()
     --勾选框
    self.m_isCheckBox = true
    self.m_CheckBox:setSelected(true)
    self.m_CheckBox:onEvent(
        function(event)
            self:checkBoxEvent(event)
        end
    )
    self.btn_save:setTouchEnabled(false)
    self:setButtonLabelAction(self.btn_save, true)

    --输入邮箱
    
    local sMail = globalData.userRunData.mail
    if sMail ~= nil and string.len(sMail) > 0 then
        self.textField:setPlaceHolder(sMail)
    end
    if util_isSupportVersion("1.3.7") then
        -- edibox
        self.m_EditBoxEmail = self.config.convertTextFiledToEditBox(self.textField, nil, nil, cc.EDITBOX_INPUT_MODE_EMAILADDR)
        self.m_EditBoxEmail:onEditHandler(handler(self, self.onDescEdit))
    else
        self.m_EditBoxEmail = self.textField
    end

    --邮箱输入错误提示文字
    self.m_spError:setVisible(false)
end

function UserInfoBindEmail:onDescEdit( event )    
    local sender = event.target
    if event.name == "began" then
        
    elseif event.name == "changed" then
        -- 改变字数
        local newDesc = sender:getText()
        self:updateLbCharater()
    elseif event.name == "return" then
        local newDesc = sender:getText() 
        self:updateLbCharater()
    end
end

function UserInfoBindEmail:updateLbCharater()
    -- body
    local str = ""
    if util_isSupportVersion("1.3.7") then
        str = self.m_EditBoxEmail:getText()
    else
        str = self.m_EditBoxEmail:getString()
    end
    if string.len(str) > 0 then
        self.btn_save:setTouchEnabled(true)
        self:setButtonLabelAction(self.btn_save, false)
    else
        self.btn_save:setTouchEnabled(false)
        self:setButtonLabelAction(self.btn_save, true)
    end
end

--玩家是否勾选
function UserInfoBindEmail:checkBoxEvent(event)
    if event.name == "selected" then
        self.m_CheckBox:setSelected(true)
        self.m_isCheckBox = true
        self.check_dui:setVisible(true)
    elseif event.name == "unselected" then
        self.m_CheckBox:setSelected(false)
        self.m_isCheckBox = false
        self.check_dui:setVisible(false)
    end
end

function UserInfoBindEmail:onExit()
end

function UserInfoBindEmail:registerLogonMessage()
end

-- function UserInfoBindEmail:closeUI()
--     local root = self:findChild("root")
--     self:commonHide(
--         root,
--         function()
--             self:removeFromParent(true)
--         end
--     )
-- end

function UserInfoBindEmail:clickFunc(sender)
    local sBtnName = sender:getName()
    if sBtnName == "btn_close" then
        self:closeUI()
    elseif sBtnName == "btn_save" then
        local sEmail = ""
        if util_isSupportVersion("1.3.7") then
            -- edibox
            sEmail = self.m_EditBoxEmail:getText()
        else
            sEmail = self.m_EditBoxEmail:getString()
        end
        sEmail = string.gsub(sEmail, " ", "") -- 字符串 trim() 邮箱没空格
        sEmail = string.gsub(sEmail, "\n", "") -- 字符串 回车替换 为""
        if self:isRightEmail(sEmail) then
            if self:isComOld(sEmail) then
                self.ManGer:saveNickName("", sEmail, "", self.m_isCheckBox)
                self:closeUI()
            else
                self.m_spError:setString("The email has been bound to another account.")
                self.m_spError:setVisible(true)
            end
        else
            self.m_spError:setString("Format error! Please check and input again.")
            self.m_spError:setVisible(true)
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
    end
end

function UserInfoBindEmail:isComOld(sEmail)
    if sEmail == globalData.userRunData.mail then
        return false
    end
    return true
end

function UserInfoBindEmail:isRightEmail(str)
    if string.len(str or "") < 6 then
        return false
    end

    --lua中%w 仅代表数字字母(谷歌邮箱可以用点 （字母 数字 点 下划线 中划线）再有这邮箱也太恶心了)
    local startIdx, endIdx = string.find(str, "^[%w_%-%.]+[%w_%-%.]+@[%w_%-%.]+[%w_%-%.]$")

    return startIdx
end

return UserInfoBindEmail
