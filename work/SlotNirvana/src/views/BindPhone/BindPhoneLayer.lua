--[[

]]
-- local BindPhoneCtrl = require("views.BindPhone.BindPhoneCtrl")
local BindPhoneLayer = class("BindPhoneLayer", BaseLayer)

function BindPhoneLayer:initDatas(_bindSuccessFunc)
    -- 绑定成功后回调方法
    self.m_bindSuccessFunc = _bindSuccessFunc
    -- 横屏资源
    local csbName = "Dialog/BindPhone.csb"
    self:setLandscapeCsbName(csbName)
end

function BindPhoneLayer:initCsbNodes()
    -- self.m_phoneNum = util_convertTextFiledToEditBox(self:findChild("lb_phoneNum"), nil, handler(self, self.editBoxEvent_phoneNumber))
    self.m_phoneInput = self:findChild("lb_phone_input")
    self.m_phoneInput:addEventListener(handler(self, self.editBoxEvent_phoneInput))
    self.m_phoneInput:setOpacity(0)
    self.m_phoneNum = self:findChild("lb_phoneNum")
    -- self.m_phoneNum:setFontColor(cc.c3b(254, 227, 255))
    self.m_phoneHolder = self:findChild("lb_phoneHolder")
    self.m_verifyCodes = {}
    for i = 1, 6 do
        self.m_verifyCodes[i] = self:findChild("lb_shuru_" .. i)
    end
    self.m_leftTimes = self:findChild("lb_left")
    self.m_txtVerify = self:findChild("TextField_2")
    self.m_txtVerify:setOpacity(0)
    self.m_txtVerify:addEventListener(handler(self, self.editBoxEvent_verifyCode))

    self.m_ckAgree = self:findChild("check_agree")
    self:addClick(self.m_ckAgree)
    self.m_btnSubmit = self:findChild("btn_submit")
    self.m_btnGainVerify = self:findChild("btn_gainVerify")

    local nodeCode = self:findChild("node_code")
    self.m_nodeArea = util_createFindView("views/BindPhone/BindPhoneAreaNode")
    nodeCode:addChild(self.m_nodeArea)
end

function BindPhoneLayer:initView()
    self:clearPhoneInput()
    self:clearVerifyInput()
    self:updateResidueTimes()
end

function BindPhoneLayer:onEnter()
    BindPhoneLayer.super.onEnter(self)

    self:updateBtnPhoneState()

    -- 重置手机号
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:clearPhoneInput()
        end,
        "notify_clear_phoneNumber"
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:clearVerifyInput()
        end,
        "notify_clear_verifyCode"
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            self:updateResidueTimes()
            self:updateBtnPhoneState()
        end,
        "notify_succ_gainVerifyCode"
    )
end

-- 剩余次数
function BindPhoneLayer:updateResidueTimes()
    local _data = G_GetMgr(G_REF.BindPhone):getBindData()
    if _data then
        local _times = _data:getLastTimes()
        self.m_leftTimes:setString("Verification codes left for today: " .. _times)
    end
end

-- function BindPhoneLayer:editBoxEvent_phoneNumber(eventName, sender)
--     if eventName == "began" then
--         printInfo("--xy--" .. eventName)
--     elseif eventName == "ended" then
--         printInfo("--xy--" .. eventName)
--     elseif eventName == "return" then
--         printInfo("--xy--" .. eventName)
--     elseif eventName == "changed" then
--         printInfo("--xy--" .. eventName)
--         local phoneNum = sender:getText()
--         if string.len(phoneNum) > 0 then
--             self.m_phoneHolder:setVisible(false)
--         else
--             self.m_phoneHolder:setVisible(true)
--         end
--     end
-- end

function BindPhoneLayer:editBoxEvent_phoneInput(sender, eventType)
    local event = {}
    if eventType == 0 then
        event.name = "ATTACH_WITH_IME"
    elseif eventType == 1 then
        event.name = "DETACH_WITH_IME"
    elseif eventType == 2 then
        event.name = "INSERT_TEXT"
        local phoneNum = sender:getString()
        self:setPhoneNum(phoneNum)
    elseif eventType == 3 then
        event.name = "DELETE_BACKWARD"
        local phoneNum = sender:getString()
        self:setPhoneNum(phoneNum)
    end
end

-- 设置手机号
function BindPhoneLayer:setPhoneNum(phoneNum)
    local _len = string.len(phoneNum)
    if _len > 0 then
        self.m_phoneHolder:setVisible(false)
    else
        self.m_phoneHolder:setVisible(true)
    end
    self.m_phoneNum:setString(phoneNum)
end

-- function BindPhoneLayer:editBoxEvent_verifyCode(eventName, sender)
--     if eventName == "began" then
--         printInfo("--xy2--" .. eventName)
--     elseif eventName == "ended" then
--         printInfo("--xy2--" .. eventName)
--     elseif eventName == "return" then
--         printInfo("--xy2--" .. eventName)
--     elseif eventName == "changed" then
--         printInfo("--xy2--" .. eventName)
--         local strInput = sender:getText()
--         local strLen = math.min(string.len(strInput) + 1, 6)
--         local curF = sender:getCurrentFocusedWidget()
--         local nextF = sender:findNextFocusedWidget()
--         sender:setFocused(false)
--         self.m_verifyCodes[strLen]:setFocused(true)
--     end
-- end

function BindPhoneLayer:editBoxEvent_verifyCode(sender, eventType)
    local event = {}
    if eventType == 0 then
        event.name = "ATTACH_WITH_IME"
    elseif eventType == 1 then
        event.name = "DETACH_WITH_IME"
    elseif eventType == 2 then
        event.name = "INSERT_TEXT"
        -- self._CoinsData[name] = textField:getString()
        self:setVerifyCode(sender:getString())
    elseif eventType == 3 then
        event.name = "DELETE_BACKWARD"
        self:setVerifyCode(sender:getString())
    end
end

-- 设置验证码
function BindPhoneLayer:setVerifyCode(txtCode)
    for i = 1, 6 do
        local ch = ""
        ch = string.sub(txtCode, i, i)
        self.m_verifyCodes[i]:setString(ch)
    end
    -- self.m_btnSubmit:setEnabled(self:isBtnSubmitEnable())
    self:setButtonLabelDisEnabled("btn_submit", self:isBtnSubmitEnable())
end

function BindPhoneLayer:isBtnSubmitEnable()
    local _len = string.len(self.m_txtVerify:getString())
    if _len < 6 or (not self.m_ckAgree:isSelected()) then
        return false
    else
        return true
    end
end

function BindPhoneLayer:isBtnPhoneEnable()
    local isSel = self.m_ckAgree:isSelected()

    local isCd, _ = G_GetMgr(G_REF.BindPhone):getSendCD()

    local hasSend = false
    local _data = G_GetMgr(G_REF.BindPhone):getBindData()
    if _data then
        local _times = _data:getLastTimes()
        hasSend = (_times > 0)
    end

    return isSel and (not isCd) and hasSend
end

function BindPhoneLayer:updateBtnPhoneState()
    self:updateBtnPhoneCd()
    self:setButtonLabelDisEnabled("btn_gainVerify", self:isBtnPhoneEnable())
end

function BindPhoneLayer:updateBtnPhoneCd()
    local isCd, cdSecs = G_GetMgr(G_REF.BindPhone):getSendCD()
    if isCd then
        self.m_cdSecs = cdSecs

        local _freshCdTxt = function()
            local _sec = self.m_cdSecs - math.floor(globalData.userRunData.p_serverTime / 1000)
            if _sec >= 0 then
                self:setButtonLabelContent("btn_gainVerify", util_count_down_str(_sec))
            end
            return _sec
        end
        _freshCdTxt()

        if not self.m_cdSch then
            self.m_cdSch =
                schedule(
                self,
                function()
                    local _sec = _freshCdTxt()
                    if _sec < 0 then
                        self:stopAction(self.m_cdSch)
                        self.m_cdSecs = 0
                        self.m_cdSch = nil

                        self:setButtonLabelDisEnabled("btn_gainVerify", self:isBtnPhoneEnable())
                        local _strGold = gLobalLanguageChangeManager:getStringByKey("BindPhoneLayer:btn_gainVerify")
                        self:setButtonLabelContent("btn_gainVerify", _strGold)
                    end
                end,
                1
            )
        end
    end
end

function BindPhoneLayer:clearVerifyInput()
    self:setVerifyCode("")
    self.m_txtVerify:setString("")
end

function BindPhoneLayer:clearPhoneInput()
    self:setPhoneNum("")
    self.m_phoneInput:setString("")
end

function BindPhoneLayer:clickFunc(_sander)
    local name = _sander:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_gainVerify" then
        local _areaCode = self.m_nodeArea:getAreaCode()
        local _phoneNumber = self.m_phoneNum:getString()
        G_GetMgr(G_REF.BindPhone):gainVerifyCode(_areaCode, _phoneNumber)
    elseif name == "btn_submit" then
        local _verifyCode = self.m_txtVerify:getString()
        local _areaCode = self.m_nodeArea:getAreaCode()
        local _phoneNumber = self.m_phoneNum:getString()
        G_GetMgr(G_REF.BindPhone):submitVerifyCode(_verifyCode, _areaCode, _phoneNumber, function()
            if not tolua.isnull(self) then
                self:closeUI(self.m_bindSuccessFunc)
            end
        end)
    elseif name == "check_agree" then
        util_nextFrameFunc(
            function()
                -- self:setBtnEnable(self.m_btnSubmit, self:isBtnSubmitEnable())
                -- self:setBtnEnable(self.m_btnGainVerify, self:isBtnPhoneEnable())
                self:setButtonLabelDisEnabled("btn_submit", self:isBtnSubmitEnable())
                self:setButtonLabelDisEnabled("btn_gainVerify", self:isBtnPhoneEnable())
            end
        )
    elseif name == "btn_privacy" then
        cc.Application:getInstance():openURL(PRIVACY_POLICY)
    end
end

return BindPhoneLayer
