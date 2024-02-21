----
-- 弹窗
--
local FirendDialogLayer = class("FirendDialogLayer", BaseLayer)
function FirendDialogLayer:initUI(okFunc, otherFunc, isHold, params)
    self.m_isHold = isHold
    self.m_okFunc = okFunc
    self.m_otherFunc = otherFunc
    self.m_isOnkeyBack = true
    self.m_params = params

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Friends/csd/Activity_FriendsConfirm.csb")
    self:setPortraitCsbName("Friends/csd/Activity_FriendsConfirm.csb")

    FirendDialogLayer.super.initUI(self)
end

function FirendDialogLayer:initCsbNodes()
    if self.m_params and table.nums(self.m_params) > 0 then
        for i, v in ipairs(self.m_params) do
            self:setButtonLabelContent(v.buttomName, v.labelString)
        end
    end
end

function FirendDialogLayer:setEnableOnkeyBack(enable)
    self.m_isOnkeyBack = enable
end

function FirendDialogLayer:onKeyBack()
    if not self.m_isOnkeyBack then
        return
    end
    --点击其他按钮回调
    if self.m_otherFunc then
        self.m_otherFunc()
    end

    --是否移除自己 默认移除
    if not self.m_isHold then
        self:closeUI()
    end
end

function FirendDialogLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    local callbackFunc = function()
        -- 尝试重新连接 network
        if name == "btn_ok" then
            --点击OK按钮回调
            release_print("!!! click FirendDialogLayer btn_ok")
            if self.m_okFunc then
                self.m_okFunc(sender)
            end
        else
            --点击其他按钮回调
            if self.m_otherFunc then
                self.m_otherFunc(sender)
            end
        end
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    --是否移除自己 默认移除
    if not tolua.isnull(self) then
        if self.m_isHold then
            callbackFunc()
        else
            sender:setTouchEnabled(false)
            self:closeUI(
                function()
                    callbackFunc()
                end
            )
        end
    end
end

function FirendDialogLayer:updateContentTipUI(_lbName, _repStr)
    if not _lbName or not _repStr then
        return
    end

    self.lb_name = self:findChild(_lbName)
    self.lb_sname = self:findChild("lb_sname")
    self.lb_layer = self:findChild("layout_sw")
    self.lb_contentsize = self.lb_layer:getContentSize()
    self:updataName(_repStr)
end

function FirendDialogLayer:updataName(name)
    self.lb_name:setString(name)
    self.lb_sname:setString(name)

    local lbSize = self.lb_name:getContentSize()
    if lbSize.width > self.lb_contentsize.width then
        self.lb_name:setVisible(false)
        self.lb_layer:setVisible(true)
        util_wordSwing(self.lb_sname, 1, self.lb_layer, 2, 48, 2) 
    else
        self.lb_name:setVisible(true)
        self.lb_layer:setVisible(false)
        self.lb_sname:stopAllActions()
    end
end

return FirendDialogLayer
