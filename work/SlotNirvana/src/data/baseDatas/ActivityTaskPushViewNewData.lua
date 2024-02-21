--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-02 16:16:26
    describe:新版大活动任务(只是一个弹板， 有这个活动open 就为true)
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ActivityTaskPushViewNewData = class("ActivityTaskPushViewNewData", BaseActivityData)

function ActivityTaskPushViewNewData:ctor()
    ActivityTaskPushViewNewData.super.ctor(self)

    self.p_open = true
end

return ActivityTaskPushViewNewData


