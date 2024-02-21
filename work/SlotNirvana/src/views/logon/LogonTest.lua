--[[
    author:{author}
    time:2021-11-18 20:05:48
]]
local LoginMgr = require("GameLogin.LoginMgr")
local LogonTest = class("LogonTest", util_require("base.BaseView"))

function LogonTest:initUI(parent)
    self:createCsbNode("Logon/LogonTest.csb")
    self.m_parent = parent
    --显示选择联网模式
    self.m_node_selLink = self:findChild("node_link")
    self.m_node_selLink:setVisible(false)

    --显示选择资源
    self.m_node_selRes = self:findChild("node_mode")
    self.m_node_selRes:setVisible(false)

    --显示服务器选择
    self.m_node_selServer = self:findChild("node_select")
    self.m_node_selServer:setVisible(false)

    -- 是否使用线上资源验证服务器
    self.m_checkBox_onlineRes = self:findChild("CheckBox_onlineRes")
    if self.m_checkBox_onlineRes then
        local bCheck = gLobalDataManager:getBoolByField("user_choose_onlin_res", false)
        self.m_checkBox_onlineRes:setSelected(bCheck)
        LoginMgr:getInstance():setIsTestOnlineRes(bCheck)
        self:addClick(self.m_checkBox_onlineRes)
    end

    self.m_checkBox_adsDebug = self:findChild("CheckBox_adsDebug")
    if self.m_checkBox_adsDebug then
        local bCheck = gLobalDataManager:getBoolByField("test_adsDebug", false)
        self.m_checkBox_adsDebug:setSelected(bCheck)
        LoginMgr:getInstance():setAdsDebug(bCheck)
        self:addClick(self.m_checkBox_adsDebug)
    end
end

function LogonTest:updateTestView(isReStart)
    self.m_isReStart = isReStart
    self:checkView()
end

function LogonTest:checkView()
    local _mgr = LoginMgr:getInstance()

    -- 是否已选择链接模式
    if not _mgr:isSeledLinkMode() then
        self:showSelLinkView()
        return
    end

    -- 是否选择了资源模式
    if not _mgr:isSeledResMode() then
        --显示选择资源模式
        self:showSelResView()
        return
    end

    -- 区分版本号
    local bVersion = util_isSupportVersion("1.6.5")
    if device.platform == "android" then
        bVersion = util_isSupportVersion("1.5.7")
    end

    -- 是否热更重启
    if self.m_isReStart and bVersion then
        local _serverId = gLobalDataManager:getStringByField("TestServerId", "")
        if _serverId ~= "" then
            self:loginToServer(_serverId)
        end
    end

    self:showSelServerView()
end

-- 选择联网模式
function LogonTest:onSelLinkMode(linkMode)
    -- 默认局域网L2L访问
    LoginMgr:getInstance():selLinkMode(linkMode)
    self:checkView()
end

-- 设置资源更新模式
function LogonTest:onSelResMode(_mode)
    local isSucc = LoginMgr:getInstance():selResMode(_mode)
    if isSucc then
        self:checkView()
    end
end

-- 显示测试服务器
-- function LogonTest:setTestServerView()
--     local _mgr = LoginMgr:getInstance()
--     if not _mgr:isSeledResMode() then
--         --显示资源地址选择
--         self:showSelResView()
--     else
--         --显示服务器选择
--         self:showSelServerView()
--     end
-- end

function LogonTest:setNodesVisible(nodeNames, isVisible)
    if type(nodeNames) ~= "table" then
        return
    end

    for i = 1, #nodeNames do
        local _btn = self:findChild(nodeNames[i])
        if _btn then
            _btn:setVisible(isVisible)
        end
    end
end

-- 显示联网模式
function LogonTest:showSelLinkView()
    --显示选择资源
    self.m_node_selRes:setVisible(false)
    -- 隐藏联网模式
    self.m_node_selLink:setVisible(true)
    --显示服务器选择
    self.m_node_selServer:setVisible(false)
end

--显示资源模式
function LogonTest:showSelResView()
    --显示选择资源
    self.m_node_selRes:setVisible(true)
    -- 隐藏联网模式
    self.m_node_selLink:setVisible(false)
    --显示服务器选择
    self.m_node_selServer:setVisible(false)

    local _mgr = LoginMgr:getInstance()
    if _mgr:getLinkType() == "W2L" then
        self:setNodesVisible({"btn_4", "btn_5"}, false)
    else
        self:setNodesVisible({"btn_3", "btn_4"}, true)
    end
end

--显示服务器选择
function LogonTest:showSelServerView()
    --隐藏资源地址
    self.m_node_selRes:setVisible(false)

    -- 隐藏联网模式
    self.m_node_selLink:setVisible(false)

    --显示服务器选择
    self.m_node_selServer:setVisible(true)

    --获取自定义url
    local lb_input = self:findChild("lb_input")
    if lb_input then
        local testSelfUrl = gLobalDataManager:getStringByField("TestServerId", "70")
        lb_input:setString(testSelfUrl)
    end

    local _mgr = LoginMgr:getInstance()
    -- 显示选择的联网模式
    local m_lb_link = self:findChild("m_lb_link")
    if m_lb_link then
        local _linkInfo = _mgr:getLinkModeInfo()
        if _linkInfo then
            m_lb_link:setString("当前网络:" .. _linkInfo.name)
        end
    end

    -- 显示当前选定的资源地址
    local m_lb_test = self:findChild("m_lb_test")
    if m_lb_test then
        local _resInfo = _mgr:getResModeInfo()
        if _resInfo then
            m_lb_test:setString(_resInfo.name)
        end
    end

    self:setNodesVisible({"btn_online_s"}, false)
    if not isMac() then
        if _mgr:isSelReleaseRes() or _mgr:isSelOnlineRes() then
            -- 上线分支
            if lb_input then
                lb_input:setVisible(false)
            end

            if _mgr:isSelOnlineRes() then
                self:setNodesVisible({"btn_online_s"}, true)
            end

            self:setNodesVisible({"btn_self", "btn_62", "btn_63"}, false)

            local resMode = _mgr:getResMode()
            if resMode == ResMode.ReleaseB.key then
                self:findChild("btn_70"):setTitleText("71")
            end
        else
            self:setNodesVisible({"btn_70"}, false)
        end
    end
end

function LogonTest:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")

    if name == "btn_online" then
        self:onSelLinkMode(LinkMode.Online)
    elseif name == "btn_l2l" then
        self:onSelLinkMode(LinkMode.L2L)
    elseif name == "btn_w2l" then
        self:onSelLinkMode(LinkMode.W2L)
    elseif name == "btn_1" then
        self:onSelResMode(ResMode.Alpha)
    elseif name == "btn_2" then
        self:onSelResMode(ResMode.Beta)
    elseif name == "btn_3" then
        self:onSelResMode(ResMode.Release)
    elseif name == "btn_4" then
        self:onSelResMode(ResMode.ReleaseB)
    elseif name == "btn_5" then
        self:onSelResMode(ResMode.Uploader)
    elseif name == "btn_62" then
        self:loginToServer("62")
    elseif name == "btn_63" then
        --63服务器
        self:loginToServer("63")
    elseif name == "btn_70" then
        if isMac() then
            self:loginToServer("70")
        else
            local resMode = LoginMgr:getInstance():getResMode()
            if resMode == ResMode.Release.key then
                --70服务器
                self:loginToServer("70")
            elseif resMode == ResMode.ReleaseB.key then
                --71服务器
                self:loginToServer("71")
            end
        end
    elseif name == "btn_online_s" then
        local _dataUrl = LinkConfig.Online.dataUrl
        self:loginToServer(_dataUrl)
    elseif name == "btn_self" then
        --苹果登录
        local lb_input = self:findChild("lb_input")
        if lb_input then
            LoginMgr:setTestAddress(lb_input:getString())
            self:loginToServer(lb_input:getString())
        end
    elseif name == "btn_clear" then
        --清除手机缓存
        util_removeAllLocalData()
        globalPlatformManager:rebootGame()
    elseif name == "btn_selectSeverURL" then
        local _isVisible = self.m_node_selServer:isVisible()
        if _isVisible then
            self.m_node_selServer:setVisible(false)
        else
            self.m_node_selServer:setVisible(true)
        end
    elseif name == "CheckBox_onlineRes" then
        local bState = not self.m_checkBox_onlineRes:isSelected()
        gLobalDataManager:setBoolByField("user_choose_onlin_res", bState)
        LoginMgr:getInstance():setIsTestOnlineRes(bState)
    elseif name == "CheckBox_adsDebug" then
        local bState = not self.m_checkBox_adsDebug:isSelected()
        LoginMgr:getInstance():setAdsDebug(bState)
        gLobalDataManager:setBoolByField("test_adsDebug", bState)
    end
end

-- 进入服务器
function LogonTest:loginToServer(serverId)
    -- local _st, _ed = string.find(tostring(serverId), "^http")
    -- if not _st then
    --     LoginMgr:getInstance():selDataServer(serverId)
    -- else
    --     LoginMgr:getInstance():setDataUrl(serverId)
    -- end
    LoginMgr:getInstance():setDataServer(serverId)
    gLobalDataManager:setStringByField("TestServerId", serverId)

    self:checkUpgrade()
end

function LogonTest:checkUpgrade()
    if self.m_parent then
        self.m_parent:checkUpgrade()
    end
end

return LogonTest
