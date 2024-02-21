--[[

    author:{author}
    time:2021-09-28 14:22:08
]]
local PigChallengeMgr = class("PigChallengeMgr", BaseActivityControl)

PigChallengeMgr.THEMES = {
    -- 常规主题
    COMMON = "Activity_PigChallenge",
    -- 独立日主题
    JULY_4TH = "Activity_PigChallenge_July4th",
    -- 墨西哥节主题
    CINCODEMAYO = "Activity_PigChallenge_Cincodemayo",
    -- 2周年主题
    TWO_YEARS = "Activity_PigChallenge_2Years",
    -- 劳动节主题
    LABOR = "Activity_PigChallenge_Labor",
    -- 万圣节主题
    HALLOWEEN = "Activity_PigChallenge_Halloween",
    -- 感恩节主题
    THANKSGIVING = "Activity_PigChallenge_ThanksGiving",
    -- 圣诞节主题
    CHRISTMAS = "Activity_PigChallenge_Christmas",
    -- 超级碗主题
    SUPERBOWL22 = "Activity_PigChallenge_SuperBowl22"
}

function PigChallengeMgr:ctor()
    PigChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PiggyChallenge)

    self.theme_config = {}
end

function PigChallengeMgr:getConfig()
    local themeName = self:getThemeName()
    if not themeName then
        printError("获取主题名失败")
        return
    end

    if not self.theme_config[themeName] then
        if themeName == PigChallengeMgr.THEMES.COMMON then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallengeConfig")
        elseif themeName == PigChallengeMgr.THEMES.JULY_4TH then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallenge_July4thConfig")
        elseif themeName == PigChallengeMgr.THEMES.CINCODEMAYO then
            assert("PigChallengeMgr getConfig 需要填充对应的配置文件 并在填充以后去掉这条断言 " .. themeName)
        elseif themeName == PigChallengeMgr.THEMES.TWO_YEARS then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallenge_2YearsConfig")
        elseif themeName == PigChallengeMgr.THEMES.LABOR then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallenge_LaborConfig")
        elseif themeName == PigChallengeMgr.THEMES.HALLOWEEN then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallenge_HalloweenConfig")
        elseif themeName == PigChallengeMgr.THEMES.THANKSGIVING then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallenge_ThanksGivingConfig")
        elseif themeName == PigChallengeMgr.THEMES.CHRISTMAS then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallenge_ChristmasConfig")
        elseif themeName == PigChallengeMgr.THEMES.SUPERBOWL22 then
            self.theme_config[themeName] = util_require("activities.Activity_PiggyChallenge.config.Activity_PigChallenge_SuperBowl22Config")
        end
    end

    return self.theme_config[themeName]
end

return PigChallengeMgr
