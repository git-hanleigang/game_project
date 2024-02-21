--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-29 15:46:12
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-29 15:46:35
FilePath: /SlotNirvana/src/GameModule/OperateGuidePopup/model/OperateGuidePopupData.lua
Description: 运营引导 弹板点位 表数据
--]]
local BaseGameModel = util_require("GameBase.BaseGameModel")
local OperateGuidePopupData = class("OperateGuidePopupData", BaseGameModel)
local GuideSiteCfgData = util_require("GameModule.OperateGuidePopup.model.GuideSiteCfgData")
local PopupLayerCfgData = util_require("GameModule.OperateGuidePopup.model.PopupLayerCfgData")

function OperateGuidePopupData:ctor()
    OperateGuidePopupData.super.ctor(self)

    self._popupLayerCfgList = {}
    self._guideSiteCfgList = {}
    self._spinWinCountMap = {}
end

function OperateGuidePopupData:parseData(_data)
    -- 引导弹窗分组
    self._abGroup = globalData.GameConfig:getABtestGroup("RateusV2")
    if self._abGroup == "" then
        self._abGroup = "A" -- 默认A组
    end

    self:parsePopupLayerCfgList(_data.configList or {})
    self:parseGuideSiteCfgList(_data.pointList or {})
end

-- 弹板类型配置
function OperateGuidePopupData:parsePopupLayerCfgList(_list)
    self._popupLayerCfgList = {}
    for i,v in ipairs(_list) do
        local cfgData = PopupLayerCfgData:create(v)
        if cfgData:getAbGroup() == self._abGroup then
            self._popupLayerCfgList[cfgData:getKey()] = cfgData
        end
    end
end

-- 引导弹板点位 配置
-- [
--     site: 点位
--     [
--         tiems: 点位限制次数
--         [
--             配置： 按order排序好的
--         ]
--     ]
-- ]
function OperateGuidePopupData:parseGuideSiteCfgList(_list)
    self._guideSiteCfgList = {}
    for i,v in ipairs(_list) do

        local cfgData = GuideSiteCfgData:create(v)
        while cfgData:getAbGroup() == self._abGroup do
            local key = cfgData:getSite()
            local timesStr = cfgData:getTimes()
            if key == "" or timesStr == "" then
                break
            end

            if not self._guideSiteCfgList[key] then
                self._guideSiteCfgList[key] = {}
            end
            if not self._guideSiteCfgList[key][timesStr] then
                self._guideSiteCfgList[key][timesStr] = {}
            end


            table.insert(self._guideSiteCfgList[key][timesStr], cfgData)
            break
        end
        
    end

    -- 档位对应 弹窗按优先级排序
    for i,v in ipairs(self._guideSiteCfgList) do

        local timesKey = v:getTimes()
        local list = v[timesKey]
        if v then
            table.sort(list, function(a, b) 
                return a:getOrder() < b:getOrder() 
            end)
        end

    end

end

-- 获取 可使用的 弹板配置
function OperateGuidePopupData:getPopupLayerInfo(_site, _subSite)
    local siteInfoList = self._guideSiteCfgList[_site]
    if not siteInfoList then
        return
    end

    local recordSiteCount = G_GetMgr(G_REF.OperateGuidePopup):getArchiveData():getSiteCount(_site)
    local siteCount = recordSiteCount + 1
    local timesInfoList = {}
    for timesStr, v in pairs(siteInfoList) do
        local timeList = {}
        if string.find(timesStr, "-") then
            local tempList = string.split(timesStr, "-")
            timeList = {tonumber(tempList[1]) or 0, tonumber(tempList[2]) or 0}
        else
            timeList = {tonumber(timesStr) or 0, tonumber(timesStr) or 0}
        end

        -- 在 限制次数 闭区间内检查弹板信息
        if siteCount >= timeList[1] and siteCount <= timeList[2] then
            timesInfoList = v
            break
        end

    end

    if not timesInfoList or not timesInfoList[1] then
        return
    end

    local popupLayerCfg = nil
    for i=1, #timesInfoList do
        local siteInfo = timesInfoList[i]
        if not siteInfo then
            return
        end
        -- 查看 本条 点位配置 是否满足需求
        if siteInfo:checkCanUseCfg(_site, _subSite) then
            local popupCfgKey = siteInfo:popupCfgKey()
            local popupCfg = self._popupLayerCfgList[popupCfgKey]
            if popupCfg and popupCfg:checkCanUseCfg(_site, _subSite) then
                popupLayerCfg = popupCfg
                break
            end
        end

    end
    return popupLayerCfg
end

-- 大赢 类型记录的 触发次数 
function OperateGuidePopupData:addSpinWinTypeCount(_bigWinType)
    for i=1, _bigWinType do
        if not self._spinWinCountMap[i] then
            self._spinWinCountMap[i] = 0
        end
        self._spinWinCountMap[i] = self._spinWinCountMap[i] + 1
    end
end
function OperateGuidePopupData:resetSpinWinTypeCount(_bigWinType)
    for i=1, _bigWinType do
        self._spinWinCountMap[i] = 0
    end
end

return OperateGuidePopupData