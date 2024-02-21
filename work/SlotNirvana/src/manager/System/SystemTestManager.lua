--[[
    @desc: 创建文件夹使用的测试文件 外部不需要引用
    author:{author}
    time:2020-12-28 11:02:24
    @return:
]]
local SystemTestManager = class("SystemTestManager")

SystemTestManager.m_instance = nil
function SystemTestManager:getInstance()
    if SystemTestManager.m_instance == nil then
        SystemTestManager.m_instance = SystemTestManager.new()
    end
    return SystemTestManager.m_instance
end
-- 构造函数
function SystemTestManager:ctor()

end

return SystemTestManager
