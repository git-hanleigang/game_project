----
-- 基础弹窗
--
local DialogLayer = class("DialogLayer", BaseLayer)
function DialogLayer:initUI(csb_path, okFunc, otherFunc, isHold, params)
    self.m_isHold = false
    self.m_okFunc = okFunc
    self.m_otherFunc = otherFunc
    self.m_isOnkeyBack = true
    self.m_params = params

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName(csb_path)
    self:setPortraitCsbName(csb_path)

    DialogLayer.super.initUI(self)
end

function DialogLayer:initCsbNodes()
    if self.m_params and table.nums(self.m_params) > 0 then
        for i, v in ipairs(self.m_params) do
            self:setButtonLabelContent(v.buttomName, v.labelString)
        end
    end
end

function DialogLayer:setEnableOnkeyBack(enable)
    self.m_isOnkeyBack = enable
end

function DialogLayer:onKeyBack()
    if not self.m_isOnkeyBack then
        return
    end
    --点击其他按钮回调
    if self.m_otherFunc then
        self.m_otherFunc()
    end

    --是否移除自己 默认移除
    if not self.m_isHold then
        -- self:closeUI()
        DialogLayer.super.onKeyBack(self)
    end
end

function DialogLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    local callbackFunc = function()
        -- 尝试重新连接 network
        if name == "btn_ok" then
            --点击OK按钮回调
            release_print("!!! click DialogLayer btn_ok")
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

function DialogLayer:updateContentTipUI(_lbName, _repStr)
    if not _lbName or not _repStr then
        return
    end

    local lb = self:findChild(_lbName)
    if lb then
        lb:setString(_repStr)
    end
end

return DialogLayer
