--[[
    @desc: 
    author:{author}
    time:2020-12-28 11:02:24
    @return:
]]
local CommonTestManager = class("CommonTestManager")

CommonTestManager.m_instance = nil
function CommonTestManager:getInstance()
    if CommonTestManager.m_instance == nil then
        CommonTestManager.m_instance = CommonTestManager.new()
    end
    return CommonTestManager.m_instance
end
-- 构造函数
function CommonTestManager:ctor()

end

return CommonTestManager
