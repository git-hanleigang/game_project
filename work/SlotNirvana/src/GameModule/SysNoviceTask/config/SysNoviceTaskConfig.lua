--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-09-06 11:28:24
]]
local SysNoviceTaskConfig = {}

-- 功能状态
SysNoviceTaskConfig.SYS_STATUS = {
    CLOSE = 0,  --功能未开启
    OPEN = 1, -- 功能开启中
    OVER = 2, -- 功能完成结束
}

-- 任务类型
SysNoviceTaskConfig.TASK_TYPE = {
    REACH_LEVEL = "REACH_LEVEL", --达到某个等级
    SPIN = "SPIN", -- spin
}

-- 事件
SysNoviceTaskConfig.EVENT_NAME = {
    COLLECT_SYS_NOVICE_TASK_SUCCESS = "COLLECT_SYS_NOVICE_TASK_SUCCESS", -- 新手任务领取成功
    NOTICE_SYS_NOVICE_TASK_UPDATE = "NOTICE_SYS_NOVICE_TASK_UPDATE", -- spin 任务进度更新
}

return SysNoviceTaskConfig