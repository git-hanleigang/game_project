--[[
local CalacasParadeView = class("CalacasParadeView", cc.Node)
local CalacasParadeView = class("CalacasParadeView")

function CalacasParadeView:initData_(_data)
    self.m_data = _data
    self:initUI()
end
]]
-- local PublicConfig = require "CalacasParadePublicConfig"
local CalacasParadeView = class("CalacasParadeView", util_require("Levels.BaseLevelDialog"))


function CalacasParadeView:initUI()
    self:createCsbNode("xxxx/xxxxxxx.csb")

    --[[
        self.m_xxxSpine = util_spineCreate(spineName, true, true)
        self.m_xxxSpine = util_spineCreate(spineName, true, false)
        self:findChild("xxx"):addChild(self.m_xxxSpine)
        util_spinePlay(self.m_xxxSpine, "idle", false)
        util_spineEndCallFunc(self.m_xxxSpine,  "idle", function() end)
    ]]
    --[[
        self.m_xxxCsb = util_createAnimation("CalacasParade_LinkLabel.csb")
        self:findChild("xxx"):addChild(self.m_xxxCsb)
        self.m_xxxCsb:runCsbAction("actionframe")
    ]]
    -- 非按钮节点 手动绑定监听
    -- self:addClick("xxx") 

    -- 延时函数
    -- self:stopAllActions()
    -- performWithDelay(self, function ()
    -- end, 0.5)

    -- 定时器
    -- schedule(view,function ()
    -- end, 0.08)

    -- 淡入淡出
    -- util_setCascadeOpacityEnabledRescursion(self, true)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CalacasParadeView:initSpineUI()
    
end




return CalacasParadeView