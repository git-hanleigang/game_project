--[[
    生日宣传 管理层
]]
local BirthdayPubilcityMgr = class("BirthdayPubilcityMgr", BaseActivityControl)

function BirthdayPubilcityMgr:ctor()
    BirthdayPubilcityMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BirthdayPublicity)
end

function BirthdayPubilcityMgr:isCanShowLayer()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return false
    end
    -- 集卡新手期
    local isNovice = CardSysManager:isNovice()
    if isNovice then
        return false
    end
    if globalData.userRunData.levelNum < 40 then
        return false
    end
    local data = G_GetMgr(ACTIVITY_REF.Birthday):getRunningData()
    if not data then
        return false
    end
    local isEditBirthdayInfo =  data:isEditBirthdayInfo()
    if isEditBirthdayInfo then
        return false
    end
    if not self:isCoolDown() then
        return false
    end
    if not self:isOverPopMaxNus() then
        return false
    end
    return true
end

function BirthdayPubilcityMgr:showMainLayer(_param)
    -- 判断资源是否下载
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("Activity_Birthday_Publicity") then
        return nil
    end
    local view = util_createFindView("Activity_Birthday_Publicity/Activity_Birthday_Publicity")
    -- 检查资源完整性
    if view then
        self:setCoolDownTime()
        self:setPopMaxNus()
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function BirthdayPubilcityMgr:isCoolDown()
    local bPop = false
    local cdTime = gLobalDataManager:getNumberByField("BirthdayPubilcityPopCD", 0)
    local curTime = util_getCurrnetTime()
    if curTime - cdTime > 0 then
        bPop = true
    end
    return bPop
end

function BirthdayPubilcityMgr:setCoolDownTime()
    local curTime = util_getCurrnetTime()
    gLobalDataManager:setNumberByField("BirthdayPubilcityPopCD", curTime + 24 * 60 * 60)
end

-- 是否超过弹出最大次数
function BirthdayPubilcityMgr:isOverPopMaxNus()
    local bOver = false
    local nums = gLobalDataManager:getNumberByField("BirthdayPubilcityPopNums", 0)
    if nums < 2 then
        bOver = true
    end
    return bOver
end

-- 设置弹出最大次数
function BirthdayPubilcityMgr:setPopMaxNus()
    local nums = gLobalDataManager:getNumberByField("BirthdayPubilcityPopNums", 0)
    nums = nums + 1
    gLobalDataManager:setNumberByField("BirthdayPubilcityPopNums", nums)
end

function BirthdayPubilcityMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

return BirthdayPubilcityMgr
