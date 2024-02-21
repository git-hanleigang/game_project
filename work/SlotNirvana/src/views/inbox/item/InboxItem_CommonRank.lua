--[[
    通用排行榜奖励邮件
]]
local InboxItem_CommonRank = class("InboxItem_CommonRank", util_require("views.inbox.item.InboxItem_baseReward"))

--图片
local THEME_PICNAME = {
    [ACTIVITY_REF.OutsideCave] = "img_OutsideCave.png",
    [ACTIVITY_REF.EgyptCoinPusher] = "img_EgyptCoinPusher.png"
}

local comPath = "InBox/ui_CommonRank/"

function InboxItem_CommonRank:getCsbName()
    return "InBox/InboxItem_CommonRank.csb"
end

function InboxItem_CommonRank:initCsbNodes()
    InboxItem_CommonRank.super.initCsbNodes(self)
    self.picture = self:findChild("sp_icon")
end

function InboxItem_CommonRank:initView()
    InboxItem_CommonRank.super.initView(self)
    local pngPath = self:getPicturePath()
    if pngPath and self.picture then
        util_changeTexture(self.picture, pngPath)
    end
end

-- 如果有掉卡，在这里设置来源
function InboxItem_CommonRank:getCardSource()
    return {"Rank Rewards"}
end

-- 描述说明
function InboxItem_CommonRank:getDescStr()
    local extra = self.m_mailData.title
    local strRank = ""
    if extra ~= nil and extra ~= "" then
        strRank = string.format("%s", extra)
    else
        extra = self.m_mailData.extra
        if extra ~= nil and extra ~= "" then
            local extraData = cjson.decode(extra)
            self.m_rankNum = extraData.rank --名次
            strRank = string.format("RANK %s REWARD", self.m_rankNum)
        end
    end
    return strRank
end


--获取图片路径
function InboxItem_CommonRank:getPicturePath()
    local extra = self.m_mailData.extra
    local path = nil
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        -- 活动主题
        local theme = extraData.theme
        if theme and THEME_PICNAME[theme] then
            path = comPath .. THEME_PICNAME[theme]
        end
    end
    return path
end

return InboxItem_CommonRank