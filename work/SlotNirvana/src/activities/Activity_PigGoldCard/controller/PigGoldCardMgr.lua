
--[[
    author:{author}
    time:2021-09-28 14:22:08
]]
local PigGoldCardMgr = class("PigGoldCardMgr", BaseActivityControl)

-- PigGoldCardMgr.THEMES = {
--     -- 常规主题
--     COMMON = "Activity_PigGoldCard",
--     -- 圣帕特里克主题
--     PATRICK = "Activity_PigGoldCard_Patrick",
--     -- 复活节主题
--     EASTER22 = "Activity_PigGoldCard_Easter22"
-- }

function PigGoldCardMgr:ctor()
    PigGoldCardMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PigGoldCard)

    -- self.theme_config = {}
end

-- function PigGoldCardMgr:getConfig()
--     local themeName = self:getThemeName()
--     if not themeName then
--         printError("获取主题名失败")
--         return
--     end

--     if not self.theme_config[themeName] then
--         if themeName == PigGoldCardMgr.THEMES.COMMON then
--             self.theme_config[themeName] = util_require("activities.Activity_PigGoldCard.config.PigGoldCardConfig")
--         elseif themeName == PigGoldCardMgr.THEMES.PATRICK then
--             self.theme_config[themeName] = util_require("activities.Activity_PigGoldCard.config.Activity_PigGoldCard_PatrickConfig")
--         elseif themeName == PigGoldCardMgr.THEMES.EASTER22 then
--             self.theme_config[themeName] = util_require("activities.Activity_PigGoldCard.config.Activity_PigGoldCard_Easter22Config")
--         end
--     end

--     return self.theme_config[themeName]
-- end
return PigGoldCardMgr
