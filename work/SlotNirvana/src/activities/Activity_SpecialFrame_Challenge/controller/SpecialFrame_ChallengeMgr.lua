--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-18 18:08:41
    describe:品质头像框挑战
]]

local SpecialFrame_ChallengeMgr = class("SpecialFrame_ChallengeMgr", BaseActivityControl)

function SpecialFrame_ChallengeMgr:ctor()
    SpecialFrame_ChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.SpecialFrame_Challenge)
end

-- 更新spin后的数据
function SpecialFrame_ChallengeMgr:parseSlotsData(_data)
    local challengeData = self:getRunningData()
    if challengeData and challengeData:isRunning() then
        challengeData:parseSlotsData(_data)
    end
end

-- 检查 是否弹出弹板
function SpecialFrame_ChallengeMgr:checkIsPopup()
    local serverData = self:getRunningData()
    if not serverData then
        return false
    end 

    return serverData:checkIsPopup()
end

-- 检查 是否弹出弹板
function SpecialFrame_ChallengeMgr:setIsPopup(bool)
    local serverData = self:getRunningData()
    if not serverData then
        return
    end 
    
    serverData:setIsPopup(bool)
end

return SpecialFrame_ChallengeMgr
