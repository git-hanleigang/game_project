--[[
    @desc: 创建文件夹使用的测试文件 外部不需要引用
    author:{author}
    time:2020-12-28 11:02:24
    @return:
]]
local ActivityTestManager = class("ActivityTestManager")

ActivityTestManager.m_instance = nil
function ActivityTestManager:getInstance()
    if ActivityTestManager.m_instance == nil then
        ActivityTestManager.m_instance = ActivityTestManager.new()
    end
    return ActivityTestManager.m_instance
end
-- 构造函数
function ActivityTestManager:ctor()

end

return ActivityTestManager
