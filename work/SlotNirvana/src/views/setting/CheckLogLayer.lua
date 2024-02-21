--测试日志界面
local CheckLogLayer = class("CheckLogLayer", BaseLayer)

function CheckLogLayer:ctor()
    CheckLogLayer.super.ctor(self)
    self.m_errMsg = ""

    -- 横屏资源
    self:setLandscapeCsbName("Option/checkLogLayer.csb")
    self:setShowBgOpacity(192)
end

function CheckLogLayer:initCsbNodes()
    self.m_root = self:findChild("root")
    self.m_scrollview = self:findChild("ScrollView1")
    self.m_label = self:findChild("label_log")
    self.m_test = self:findChild("Text_6")
end

function CheckLogLayer:initView(errMsg)
    self.m_fontSize = self.m_test:getContentSize()
    if errMsg then
        self:findChild("btn_fresh"):setVisible(false)
        self.m_errMsg = errMsg
    end
end

function CheckLogLayer:onEnter()
    CheckLogLayer.super.onEnter(self)
    self:updataUI()
end

function CheckLogLayer:getTextString()
    local len = 1
    local str = ""
    if GD.DebugLogList ~= nil then
        for i = 1,#GD.DebugLogList do
            local v = GD.DebugLogList[i]
            local m,n = string.gsub(v.buffer, "\n", "\n")
            if n == 0 then
                v.buffer = v.buffer .. "\n"
                n = 1
            end
            str = str..v.buffer
            self.m_test:setString(v.buffer)
            local width = self.m_test:getContentSize().width
            local offet = math.ceil(width/1310)
            --local offet = math.ceil(v.len/115)
            len = len + n + offet - 1
        end
    end
    return str,len
end

function CheckLogLayer:updataUI()
    local _str, _len, _height
    local _size = self.m_root:getContentSize()
    if self.m_errMsg == "" then
        _str, _len = self:getTextString()
        _height = self.m_fontSize.height * _len
    else
        _str = self.m_errMsg
        _height = _size.height
    end
    
    self.m_scrollview:setInnerContainerSize(cc.size(_size.width, _height))
    self.m_label:setContentSize(cc.size(_size.width, _height))
    self.m_label:setPositionY(_height)
    self.m_label:setString(_str)
end

-- function CheckLogLayer:ceshi()
--     GD.DebugLogList = {}
--     for i=1,100 do
--         local a = {}
--         a.buffer = i.."地方撒的发dsdsdsdsdsdsdsdsdsdsdsds顺丰JFISJDGKLMDDDDFDFMKMFSAJFISJDGKLMDdfdfDDDFDFMKMFSAJFISJDGKLMDLKSFMKSNFKLNASKFN"
--         a.len = string.len(a.buffer)
--         table.insert(GD.DebugLogList,a)
--     end
-- end

function CheckLogLayer:clickFunc(_sander)
    local name = _sander:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_fresh" then
        --刷新最新消息
        self:updataUI()
    end
end

return CheckLogLayer
