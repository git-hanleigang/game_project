--[[
    author:{author}
    time:2022-11-17 10:16:51
]]
local errInfo = {
    ["110"] = {desc = "号码已经绑定", errDesc = "The phone number has been bound to another account!"},
    ["111"] = {desc = "没传参数", errDesc = "Please re-enter your number!"},
    ["112"] = {desc = "验证码过期", errDesc = "This verification code has expired!"},
    ["113"] = {desc = "手机验证码验证失败", errDesc = "Please re-enter the verification code!"},
    -- ["114"] = {desc = "未绑定手机", errDesc = "未绑定手机"},
    -- ["115"] = {desc = "已经领取奖励", errDesc = "已经领取奖励"},
    -- ["116"] = {desc = "验证码次数超限", errDesc = "验证码次数超限"}
}

local AreaData = import(".BindPhoneAreaData")
local BindPhoneNet = import(".BindPhoneNet")
local BindPhoneData = import(".BindPhoneData")
local BindPhoneCtrl = class("BindPhoneCtrl", BaseGameControl)

function BindPhoneCtrl:ctor()
    BindPhoneCtrl.super.ctor(self)
    self:setRefName(G_REF.BindPhone)
    self.m_data = BindPhoneData:create()
    self.m_net = BindPhoneNet:create()
end

function BindPhoneCtrl:parseData(data)
    self.m_data:parseData(data)
end

function BindPhoneCtrl:getAreaData(idx)
    if not idx then
        return AreaData
    else
        return AreaData[idx]
    end
end

function BindPhoneCtrl:getBindData()
    return self.m_data
end

function BindPhoneCtrl:isBound()
    return self.m_data:isBound()
end

function BindPhoneCtrl:isCollected()
    return self.m_data:isCollected()
end

function BindPhoneCtrl:isRunning()
    local isOpen = tostring(globalData.constantData.PhoneBandingSwitch or "0")
    return (isOpen ~= "0") and self.m_data:isOpen() and (not self:isCollected()) and (not self:isOverExpireAt())
end

-- 显示绑定界面
function BindPhoneCtrl:showMainLayer(_bindSuccessFunc)
    if self:getLayerByName("BindPhoneLayer") ~= nil then
        return
    end
    local _lay = util_createView("views.BindPhone.BindPhoneLayer", _bindSuccessFunc)
    if _lay then
        _lay:setName("BindPhoneLayer")
        self:showLayer(_lay, ViewZorder.ZORDER_POPUI)
    end
    return _lay
end

-- 是否有效的号码
function BindPhoneCtrl:isValidNumber(phoneNum)
    local _len = string.len(phoneNum)
    if _len < 7 or _len > 11 then
        return nil
    end

    local format = "^[0-9]*[1-9][0-9]*$"

    local startIndex, endIndx = string.find(phoneNum, format)

    return startIndex
end

-- 是否在cd中
function BindPhoneCtrl:getSendCD()
    local cdSec = tonumber(gLobalDataManager:getStringByField("GainBindVerifyCD", "0"))
    if cdSec > math.floor(globalData.userRunData.p_serverTime / 1000) then
        -- 在CD中
        return true, cdSec
    else
        return false, nil
    end
end

-- 是否超过7天（超过7天不在邮箱显示）
function BindPhoneCtrl:isOverExpireAt()
    local expireAt = self.m_data:getExpireAt()
    if expireAt > math.floor(globalData.userRunData.p_serverTime / 1000) then
        return false
    else
        return true
    end
end

-- 获取验证码
function BindPhoneCtrl:gainVerifyCode(_areaCode, _phoneNumber)
    -- 判断手机号有效性
    local isValid = self:isValidNumber(_phoneNumber)
    if not isValid then
        self:showErrNumberDialog()
        return
    end

    -- 判断CD
    local isCd, cdSec = self:getSendCD()
    if isCd then
        -- self:showErrDescDialog("3 min分钟内只能获取一次验证码！")
        return
    end

    local fullPhoneNumber = _areaCode .. _phoneNumber
    local tbData = {
        data = {
            params = {
                operateType = "SEND",
                phoneNumber = fullPhoneNumber
            }
        }
    }

    local failFunc = function(errCode)
        self:showErrCodeDialog(errCode)
    end

    local succFunc = function(resultData)
        local _code = resultData.code
        if _code == 100 then
            self:parseData(resultData.phoneInfo)

            local cdSec = math.floor(globalData.userRunData.p_serverTime / 1000) + 180
            gLobalDataManager:setStringByField("GainBindVerifyCD", tostring(cdSec))

            gLobalNoticManager:postNotification("notify_succ_gainVerifyCode")
            -- self:showErrDescDialog("verify has send 验证码已发送至手机！")
        else
            failFunc(_code)
        end
    end

    self.m_net:reqestBindAction(tbData, succFunc, failFunc)
end

-- 提交验证吗
function BindPhoneCtrl:submitVerifyCode(verifyCode, _areaCode, _phoneNumber, _successFunc)
    local isValid = self:isValidNumber(_phoneNumber)
    if not isValid then
        self:showErrNumberDialog()
        return
    end

    -- 判断验证码
    if not verifyCode or verifyCode == "" then
        -- local _info = errInfo["" .. 113] or {}
        -- self:showErrDialog(_info.errDesc)
        self:showErrVerifyDialog()
        return
    end

    local fullPhoneNumber = _areaCode .. _phoneNumber

    local tbData = {
        data = {
            params = {
                operateType = "CHECK_CODE",
                phoneNumber = fullPhoneNumber,
                code = verifyCode
            }
        }
    }

    local failFunc = function(errCode)
        self:showErrVerifyDialog()
    end

    local succFunc = function(resultData)
        local _code = resultData.code
        if _code == 100 then
            self:parseData(resultData.phoneInfo)
            gLobalNoticManager:postNotification("notify_succ_bindPhone")
            if _successFunc then
                _successFunc()
            end
            -- local _lay = self:getLayerByName("BindPhoneLayer")
            -- if _lay then
            --     _lay:closeUI(
            --         function()
            --             self:showBindSuccDialog()
            --             gLobalNoticManager:postNotification("notify_succ_bindPhone")
            --         end
            --     )
            -- end
        else
            failFunc(_code)
        end
    end

    self.m_net:reqestBindAction(tbData, succFunc, failFunc)
end

-- 显示领奖界面
function BindPhoneCtrl:showBindRewardLayer(_isUserInfo)
    local _lay = nil
    if _isUserInfo then
        _lay = util_createView("views.BindPhone.BindPhoneUserInfoRewardLayer")
    else
        _lay = util_createView("views.BindPhone.BindPhoneRewardLayer")
    end
    if _lay then
        self:showLayer(_lay, ViewZorder.ZORDER_POPUI)
    end
end

-- 领取奖励
function BindPhoneCtrl:gainBindReward(succCallFun)
    if not self:isBound() then
        return
    end

    local tbData = {
        data = {
            params = {
                operateType = "COLLECT_REWARD"
            }
        }
    }

    local failFunc = function(errCode)
        self:showErrCodeDialog(
            errCode,
            function()
                gLobalNoticManager:postNotification("notify_clear_phoneNumber")
            end
        )
    end

    local succFunc = function(resultData)
        local _code = resultData.code
        if _code == 100 then
            if succCallFun then
                succCallFun()
            end
            self:parseData(resultData.phoneInfo)
        else
            failFunc(_code)
        end
    end

    self.m_net:reqestBindAction(tbData, succFunc, failFunc)
end

function BindPhoneCtrl:showErrCodeDialog(errCode, callback)
    local _info = errInfo["" .. errCode] or {}
    local errDesc = _info.errDesc or ""
    self:showErrDescDialog(errDesc, callback)
end

function BindPhoneCtrl:showErrDescDialog(errDesc, callback)
    local _lay =
        util_createView(
        "views.dialogs.DialogLayer",
        "Dialog/BindPhone_NumIssue2.csb",
        nil,
        callback,
        false,
        {
            {buttomName = "btn_submit", labelString = "CONFIRM"}
        }
    )

    if errDesc and errDesc ~= "" then
        _lay:updateContentTipUI("lb_re", errDesc)
    end

    self:showLayer(_lay, ViewZorder.ZORDER_POPUI)
end

-- 号码错误提示
function BindPhoneCtrl:showErrNumberDialog()
    local _lay =
        util_createView(
        "views.dialogs.DialogLayer",
        "Dialog/BindPhone_NumIssue2.csb",
        nil,
        function()
            gLobalNoticManager:postNotification("notify_clear_phoneNumber")
        end,
        false,
        {
            {buttomName = "btn_submit", labelString = "CONFIRM"}
        }
    )

    self:showLayer(_lay, ViewZorder.ZORDER_POPUI)
end

-- 验证码错误
function BindPhoneCtrl:showErrVerifyDialog()
    local _lay =
        util_createView(
        "views.dialogs.DialogLayer",
        "Dialog/BindPhone_NumIssue1.csb",
        nil,
        function()
            gLobalNoticManager:postNotification("notify_clear_verifyCode")
        end,
        false,
        {
            {buttomName = "btn_submit", labelString = "CONFIRM"}
        }
    )

    self:showLayer(_lay, ViewZorder.ZORDER_POPUI)
end

-- 绑定成功
function BindPhoneCtrl:showBindSuccDialog(_submitFunc)
    local _lay = util_createView("views.dialogs.DialogLayer", "Dialog/BindPhone_Congrats.csb", nil, _submitFunc, false,
        {
            {buttomName = "btn_submit", labelString = "CONFIRM"}
        }
    )
    if _lay then
        self:showLayer(_lay, ViewZorder.ZORDER_POPUI)
    end
end

return BindPhoneCtrl
