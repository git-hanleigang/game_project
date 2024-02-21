--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-15 12:22:49
    describe:新版大活动任务锁节点
]]
local TaskProgressLockNew = class("TaskProgressLockNew", util_require("base.BaseView"))

function TaskProgressLockNew:initUI(_params)
    self.m_data = _params.data
    self.m_proStr = _params.proStr or ""
    self.m_isInAnimation = false
    self:createCsbNode(_params.csbName)
    self:initNode()
    self:initView()
end

--初始化节点
function TaskProgressLockNew:initNode()
    self.m_node_lock = self:findChild("node_lock")
    assert(self.m_node_lock, "锁节点为空")
    self.m_node_num = self:findChild("node_num")
    assert(self.m_node_num, "文本节点为空")
    self.m_lb_num = self:findChild("lb_num")
    assert(self.m_lb_num, "文本为空")
end

--初始化spine
function TaskProgressLockNew:initView()
    if self.m_proStr == "LOCKED" then
        self.m_node_lock:setVisible(true)
        self.m_node_num:setVisible(false)
    else
        self.m_node_lock:setVisible(false)
        self.m_node_num:setVisible(true)
        self:setLabelString(self.m_proStr)
    end
end

--播放解锁动画
function TaskProgressLockNew:playUnlock(_cb)
    if self.m_node_lock:isVisible() then
        if self.m_isInAnimation then
            if _cb then
                _cb()
            end
            return
        end
        self.m_isInAnimation = true
        self:runCsbAction("jiesuo", false, function()
            if not tolua.isnull(self) then
                self.m_node_lock:setVisible(false)
                self.m_node_num:setVisible(true)
                if _cb then
                    _cb()
                end
            end
        end, 60)
    else
        if _cb then
            _cb()
        end
    end
end

function TaskProgressLockNew:setLabelString(str)
    if self.m_lb_num then
        local _str = str or ""
        self.m_lb_num:setString(_str)
    end
end

return TaskProgressLockNew
