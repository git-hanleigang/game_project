--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-01 14:29:57
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-01 15:56:01
FilePath: /SlotNirvana/src/GameModule/OperateGuidePopup/model/PopupLayerCfgData.lua
Description: 运营引导 弹板点位 表  弹窗
--]]
local PopupLayerCfgData = class("PopupLayerCfgData")

function PopupLayerCfgData:ctor(_data)
    self._abGroup = _data.group or "" -- 分组
    self._popupType = _data.popupsType or "" -- 弹版类型
    self._cdType = _data.cdType or -1 -- 弹出点位索引使用
    self._popupCd = _data.popupsCd or 0  -- 弹窗CD(H)
end

function PopupLayerCfgData:getAbGroup()
    return self._abGroup
end
function PopupLayerCfgData:getPopupType()
    return self._popupType
end
function PopupLayerCfgData:getCdType()
    return self._cdType
end
function PopupLayerCfgData:getPopupCd()
    return self._popupCd * 3600
end

function PopupLayerCfgData:getKey()
    return string.format("%s_%s", self._popupType, self._cdType)
end

-- 查看 本条 弹板配置 cd限制 是否满足
function PopupLayerCfgData:checkCanUseCfg(_site, _subSite)
    local type = self:getPopupType()
    local addCD = 0
    if type == "Score" and _site == "GrandWin" then
        -- 不需要判断 是否 评论过
    elseif type == "NativeScore" and _site == "LegendaryWinV2" then
        if not globalData.rateUsData:checkIsRateUs() then
            -- 没有  RateUs 评分过 不弹了
            return false
        end

        if device.platform == "android" and (MARKETSEL == AMAZON_MARKET or (not util_isSupportVersion("1.9.5", "android"))) then
            -- 亚马逊平台 或者 google低版本 不支持应用内评价
            return false
        end

        return true
    elseif type == "Score" and _site == "SpecialSpinWin" then
        if globalData.constantData.RATE_US_LAYER_SPECIAL_SPIN_WIN_FORCE_POP then
            -- 特殊大赢 不用考虑CD 不用管 是否评论过
            return true
        end

        -- RateUs 评分过了 不弹了
        if globalData.rateUsData:checkIsRateUs() then
            return false
        end

        -- 特殊大赢 不用考虑CD
        return true
    elseif type == "Score" then
        -- RateUs 评分过了 不弹了
        if globalData.rateUsData:checkIsRateUs() then
            return false
        end

        -- cxc 2023年12月11日14:45:12 点击不同星 延长 评分弹板 被动弹出CD
        addCD = addCD + G_GetMgr(G_REF.OperateGuidePopup):getRateUsPopupAddCD() * 3600
    elseif type == "FB" then
        -- 绑定过 fb 了 不弹了
        if string.len(tostring(globalData.userRunData.facebookBindingID)) > 2 then
            return false
        end
    elseif type == "Mail" then
        -- 绑定过 邮箱了 不弹了
        if string.len(tostring(globalData.userRunData.mail)) > 2 then
            return false
        end
    elseif type == "OpenPush" then
        -- 通知权限打开状态 不弹了
        if globalLocalPushManager:isNotifyEnabled() then
            return false
        end
    end

    local lastPopupTime = G_GetMgr(G_REF.OperateGuidePopup):getArchiveData():getLastPopupTime(self:getPopupType())
    if lastPopupTime > 0 and (os.time() - lastPopupTime) < (self:getPopupCd() + addCD) then
        return false
    end 

    return true
end

return PopupLayerCfgData