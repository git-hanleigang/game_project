--[[
    author:{author}
    time:2022-11-17 10:16:51
]]
local errInfo = {
    ["110"] = {desc = "号码已经绑定", errDesc = "The phone number has been bound to another account!"},
    ["111"] = {desc = "没传参数", errDesc = "Please re-enter your number!"},
    ["112"] = {desc = "验证码过期", errDesc = "This verification code has expired!"},
    ["113"] = {desc = "手机验证码验证失败", errDesc = "Please re-enter the verification code!"}
    -- ["114"] = {desc = "未绑定手机", errDesc = "未绑定手机"},
    -- ["115"] = {desc = "已经领取奖励", errDesc = "已经领取奖励"},
    -- ["116"] = {desc = "验证码次数超限", errDesc = "验证码次数超限"}
}

local AreaData = require("views.BindPhone.BindPhoneAreaData")
local CollectPhoneNet = require("activities.Activity_CollectPhone.net.CollectPhoneNet")
local CollectPhoneMgr = class("CollectPhoneMgr", BaseActivityControl)

function CollectPhoneMgr:ctor()
    CollectPhoneMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CollectPhone)
    self.m_net = CollectPhoneNet:create()
end

function CollectPhoneMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function CollectPhoneMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function CollectPhoneMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

function CollectPhoneMgr:getAreaData(idx)
    if not idx then
        return AreaData
    else
        return AreaData[idx]
    end
end

function CollectPhoneMgr:getBindData()
    return self:getRunningData()
end

-- 是否有效的号码
function CollectPhoneMgr:isValidNumber(phoneNum)
    local _len = string.len(phoneNum)
    if _len < 7 or _len > 11 then
        return nil
    end

    local format = "^[0-9]*[1-9][0-9]*$"

    local startIndex, endIndx = string.find(phoneNum, format)

    return startIndex
end

-- 是否在cd中
function CollectPhoneMgr:getSendCD()
    local cdSec = tonumber(gLobalDataManager:getStringByField("CollectPhoneVerifyCD", "0"))
    if cdSec > math.floor(globalData.userRunData.p_serverTime / 1000) then
        -- 在CD中
        return true, cdSec
    else
        return false, nil
    end
end

-- 获取验证码
function CollectPhoneMgr:gainVerifyCode(_areaCode, _phoneNumber)
    -- 判断手机号有效性
    local isValid = self:isValidNumber(_phoneNumber)
    if not isValid then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_PHONE_CLEAR_PHONE_NUMBER)
        return
    end

    -- 判断CD
    local isCd, cdSec = self:getSendCD()
    if isCd then
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
        local _info = errInfo["" .. errCode] or {}
        local errDesc = _info.errDesc or ""
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_PHONE_VERIFY_CODE, {isSuc = false, errDesc = errDesc})
    end

    local succFunc = function(resultData)
        local _code = resultData.code
        if _code == 100 then
            local cdSec = math.floor(globalData.userRunData.p_serverTime / 1000) + 180
            gLobalDataManager:setStringByField("CollectPhoneVerifyCD", tostring(cdSec))

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_PHONE_VERIFY_CODE, {isSuc = true})
        else
            failFunc(_code)
        end
    end

    self.m_net:reqestBindAction(tbData, succFunc, failFunc)
end

-- 提交验证吗
function CollectPhoneMgr:submitVerifyCode(verifyCode, _areaCode, _phoneNumber, _successFunc)
    local isValid = self:isValidNumber(_phoneNumber)
    if not isValid then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_PHONE_CLEAR_PHONE_NUMBER)
        return
    end

    -- 判断验证码
    if not verifyCode or verifyCode == "" then
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
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_PHONE_CLEAR_VERIFY_CODE)
    end

    local succFunc = function(resultData)
        local _code = resultData.code
        if _code == 100 then
            if _successFunc then
                _successFunc()
            end
        else
            failFunc(_code)
        end
    end

    self.m_net:reqestBindAction(tbData, succFunc, failFunc)
end

-- 显示领奖界面
function CollectPhoneMgr:showBindRewardLayer(_coins, _items)
    -- 道具列表
    local itemDataList = {}
    -- 金币道具
    local coins = _coins or toLongNumber(0)
    if coins > toLongNumber(0) then
        local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
        itemData:setTempData({p_limit = 3})
        itemDataList[#itemDataList + 1] = itemData
    end
    -- 通用道具
    local items = _items or {}
    if #items > 0 then
        for i, v in ipairs(items) do
            local itemData = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            itemDataList[#itemDataList + 1] = itemData
        end
    end

    if #itemDataList <= 0 then
        return
    end

    local clickFunc = function()
        if CardSysManager:needDropCards("Collect Phone") then
            CardSysManager:doDropCards("Collect Phone")
        end
    end
    local view = gLobalItemManager:createRewardLayer(itemDataList, clickFunc, coins, true)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

return CollectPhoneMgr
