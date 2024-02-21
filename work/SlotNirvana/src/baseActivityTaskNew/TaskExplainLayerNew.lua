--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-05 17:36:14
]]
local TaskExplainLayerNew = class("TaskExplainLayerNew", BaseLayer)

function TaskExplainLayerNew:ctor()
    TaskExplainLayerNew.super.ctor(self)
    self.m_currentPage = 1
end

function TaskExplainLayerNew:initDatas(_csbName, _pageNum)
    assert(_csbName, "TaskExplainLayerNew 传入的csb资源为空")
    self:setLandscapeCsbName(_csbName)
    self.m_pageNum = _pageNum or 2
end

--初始化节点
function TaskExplainLayerNew:initCsbNodes()
    self.m_btn_right = self:findChild("btn_right")
    self.m_btn_left = self:findChild("btn_left")
end

function TaskExplainLayerNew:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function TaskExplainLayerNew:initView()
    self:initPage()
end

function TaskExplainLayerNew:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_right" then
        self:updatePage(1)
    elseif name == "btn_left" then
        self:updatePage(-1)
    end
end

function TaskExplainLayerNew:initPage()
    local pageNum = self.m_pageNum
    for i = 1, pageNum do
        local node = self:findChild("node_explain" .. i)
        if node then
            if i == self.m_currentPage then
                node:setVisible(true)
            else
                node:setVisible(false)
            end
        end
    end
end

function TaskExplainLayerNew:updatePage(val)
    local pageNum = self.m_pageNum
    self.m_currentPage = self.m_currentPage + val
    if self.m_currentPage > pageNum then
        self.m_currentPage = 1
    end
    if self.m_currentPage < 1 then
        self.m_currentPage = pageNum
    end
    for i = 1, pageNum do
        local node = self:findChild("node_explain" .. i)
        if node then
            if i == self.m_currentPage then
                node:setVisible(true)
            else
                node:setVisible(false)
            end
        end
    end
end

return TaskExplainLayerNew
