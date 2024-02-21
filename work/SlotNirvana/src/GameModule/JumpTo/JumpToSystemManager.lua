--[[
Author: cxc
Date: 2022-03-25 17:08:10
LastEditTime: 2022-03-25 17:08:12
LastEditors: cxc
Description: 跳转功能 系统 mgr
FilePath: /SlotNirvana/src/GameModule/JumpTo/JumpToSystemManager.lua
--]]
local JumpToSystemManager = class("JumpToSystemManager")

-- 系统
-- 1 商城
-- 2. 小猪银行
-- 3. 高倍场
-- 4. 签到
-- 5. 公会
-- 6. 邮件
-- 7. 转盘
-- 8. 乐透
-- 9. vip
-- 10. 个人信息页
function JumpToSystemManager:jumpToFeature(_info, _params)
    if not _info then
        return
    end

    local subType = _info[2]
    local view = nil
    if subType == 1 then
        view = self:showShopLayer(_params)
    elseif subType == 2 then
        view = self:showPiggyBank(_params)
    elseif subType == 3 then
        view = globalDeluxeManager:showDeluexeClubView()
    elseif subType == 4 then
        view = self:showDailyBouns(_params)
    elseif subType == 5 then
        view = self:showTeamView(_params)
    elseif subType == 6 then
        view = self:showInboxView(_params)
    elseif subType == 7 then
    elseif subType == 8 then
        view = G_GetMgr(G_REF.Lottery):showMainLayer()
    elseif subType == 9 then
        view = self:showVipView(_params)
    elseif subType == 10 then
        view = self:showUserInfoView(_params)
    end

    self:sendPopupViewLog(_params)
    return view
end

-- 显示商城
function JumpToSystemManager:showShopLayer(_params)
    local view = G_GetMgr(G_REF.Shop):showMainLayer(_params)
    return view
end

-- 显示小猪银行
function JumpToSystemManager:showPiggyBank(_params)
    -- 谨慎使用返回的view，小猪没有返回值
    local view = G_GetMgr(G_REF.PiggyBank):showMainLayer()
    return view
end

-- 显示签到
function JumpToSystemManager:showDailyBouns(_params)
    local view = nil
    
    local mgr = G_GetMgr(G_REF.NoviceSevenSign)
    if mgr and mgr:isRunning() then
        view = mgr:showMainLayer()
    elseif globalData.dailyBonusNoviceData and globalData.dailyBonusNoviceData:isHasData() then
        local dailyBonusNoviceMgr = require("manager.DailyBonusNoviceMgr")
        if dailyBonusNoviceMgr then
            view = dailyBonusNoviceMgr:getInstance():showMainLayer()
        end
    else
        local dailyBonusMgr = require("manager.DailySignBonusManager")
        if dailyBonusMgr then
            view = dailyBonusMgr:getInstance():showMainLayer()
        end
    end
    return view
end

-- 显示公会
function JumpToSystemManager:showTeamView(_params)
    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    local view = ClanManager:enterClanSystem()
    return view
end

-- 显示邮件
function JumpToSystemManager:showInboxView(_params)
    G_GetMgr(G_REF.Inbox):showInboxLayer()
    return nil
end

-- 显示Vip
function JumpToSystemManager:showVipView(_params)
    local view = G_GetMgr(G_REF.Vip):showMainLayer()
    return view
end

-- 显示个人信息页
function JumpToSystemManager:showUserInfoView(_params)
    G_GetMgr(G_REF.UserInfo):showMainLayer()
    return view
end

function JumpToSystemManager:sendPopupViewLog(_params, _view)
    if _view and _params.touchTargetName then
        gLobalSendDataManager:getLogPopub():addNodeDot(_view, _params.touchTargetName, DotUrlType.UrlName, false)
    end
end

return JumpToSystemManager
