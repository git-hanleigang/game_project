--[[
    游戏功能基本控制类
    author: 徐袁
    time: 2021-07-01 18:19:09
]]
-- local Facade = require("GameMVC.core.Facade")
local ResCacheMgr = require("GameInit.ResCacheMgr.ResCacheMgr")
local Notifier = require("GameMVC.patterns.Notifier")
local _BaseGameControl = class("BaseGameControl", BaseSingleton, Notifier)

function _BaseGameControl:ctor()
    _BaseGameControl.super.ctor(self)
    self.m_refName = ""
    -- 数据模块
    self.m_dataModule = ""
    -- 显示界面的列表
    self.m_tbLayer = {}
    -- 加载的Plist资源列表
    -- self.m_tbResPlist = {}
    -- 资源是否在整包内
    self.m_isResInApp = false
    -- 下载的额外资源列表
    self.m_extendDLKeyList = {}
end

function _BaseGameControl:getInstance()
    local ctrl = _BaseGameControl.super.getInstance(self)
    local refName = ctrl:getRefName()
    -- if not Facade:getInstance():getCtrl(refName) then
    --     Facade:getInstance():registerCtrl(ctrl)
    -- end
    if not Notifier.getMgr(self, refName) then
        Notifier.registerCtrl(self, ctrl)
    end
    return ctrl
end

function _BaseGameControl:onEnter()
    printInfo("_BaseGameControl onEnter: " .. self.__cname)
end

function _BaseGameControl:onExit()
    printInfo("_BaseGameControl onExit: " .. self.__cname)
    if self.m_exitCallFunc then
        self.m_exitCallFunc()
        self.m_exitCallFunc = nil
    end
end

function _BaseGameControl:onCleanUp()
    printInfo("_BaseGameControl onCleanUp: " .. self.__cname)
    ResCacheMgr:getInstance():removeUnusedResCache()
end

-- 退出模块玩法
function _BaseGameControl:exitGame(callback)
    printInfo("_BaseGameControl exitGame: " .. self.__cname)
    for key, value in pairs(self.m_tbLayer) do
        if value and value.closeUI then
            value:closeUI()
        end
    end
    self.m_exitCallFunc = callback
end

-- =========== 图层管理相关 =======================
-- 显示图层
function _BaseGameControl:showLayer(layer, zOrder, showTouchLayer)
    if not layer then
        return
    end

    gLobalViewManager:showUI(layer, zOrder, showTouchLayer)

    self:registerLayer(layer)
end

-- 获得图层
function _BaseGameControl:getLayerByName(layerName)
    return gLobalViewManager:getViewByName(layerName)
end

-- 注册图层
function _BaseGameControl:registerLayer(layer)
    if not layer then
        return
    end

    local layerName = layer:getName()
    if not layerName or layerName == "" then
        layerName = layer.__cname
        layer:setName(layerName)
    end

    if self:getLayerInfo(layerName) then
        -- 不重复注册
        printError("layer %s has existed, Do not register event again!!!", layerName)
        return
    end

    -- 注册Exit回调
    addExitListenerNode(
        layer,
        function()
            self:removeLayer(layerName)
        end
    )

    -- 注册cleanup回调
    addCleanupListenerNode(
        layer,
        function()
            local layerCount = table.nums(self.m_tbLayer)
            if layerCount > 0 then
                return
            end
            self:onCleanUp()
        end
    )
    -- 列表大小
    local _oldCount = table.nums(self.m_tbLayer)
    self:addLayerInfo(layerName, layer)
    local _newCount = table.nums(self.m_tbLayer)

    if _oldCount == 0 and _newCount > 0 then
        self:onEnter()
    end
end

-- 移除图层
function _BaseGameControl:removeLayer(layerName)
    -- 列表大小
    local _oldCount = table.nums(self.m_tbLayer)

    self:removeLayerInfo(layerName)

    local _newCount = table.nums(self.m_tbLayer)
    if _oldCount > 0 and _newCount == 0 then
        self:onExit()
    end
end

-- 添加图层信息
function _BaseGameControl:addLayerInfo(layerName, layer)
    self.m_tbLayer[layerName] = layer
end

function _BaseGameControl:getLayerInfo(layerName)
    return self.m_tbLayer[layerName]
end

-- 移除图层信息
function _BaseGameControl:removeLayerInfo(layerName)
    self.m_tbLayer[layerName] = nil
end
-- ====================================================
-- =============== 合图Plist资源相关 ===================
-- 添加plist资源信息
-- function _BaseGameControl:insertPlistInfo(info)
--     if not info or type(info) ~= "table" or #info ~= 2 then
--         return
--     end

--     table.insert(self.m_tbResPlist, info)
-- end

-- 合并plist资源列表
-- function _BaseGameControl:mergePlistInfos(infos)
--     infos = infos or {}
--     for i = 1, #infos do
--         self:insertPlistInfo(infos[i])
--     end
-- end

-- 清理plist资源列表
-- function _BaseGameControl:clearPlists()
--     self.m_tbResPlist = {}
-- end

-- 清理Plist内存
-- function _BaseGameControl:cleanupPlistCache()
--     for i = 1, #self.m_tbResPlist do
--         local plistInfo = self.m_tbResPlist[i]
--         if plistInfo and #plistInfo == 2 then
--             display.removeSpriteFrames(plistInfo[1], plistInfo[2])
--         end
--     end
-- end
-- ====================================================

function _BaseGameControl:getCtrlName()
    return self:getRefName()
end

-- 设置引用名
function _BaseGameControl:setRefName(_name)
    self.m_refName = _name or ""
end

-- 引用名
function _BaseGameControl:getRefName()
    return self.m_refName
end

-- 主题名
function _BaseGameControl:getThemeName(refName)
    refName = refName or self:getRefName()
    local _data = self:getData(refName)
    if _data and _data.getThemeName then
        return _data:getThemeName()
    else
        return self:getRefName()
    end
end

-- 获得控制对象
function _BaseGameControl:getMgr(refName)
    refName = refName or self:getRefName()
    -- return Facade:getInstance():getCtrl(refName)
    return Notifier.getMgr(self, refName)
end

-- 获得数据对象
function _BaseGameControl:getData(refName)
    refName = refName or self:getRefName()
    -- return Facade:getInstance():getModel(refName)
    return Notifier.getData(self, refName)
end

-- 设置数据模块
function _BaseGameControl:setDataModule(module)
    self.m_dataModule = module or ""
end

-- 创建数据对象
function _BaseGameControl:createDataModule()
    local status, result =
        pcall(
        function()
            -- 创建数据模块
            return require(self.m_dataModule):create()
        end
    )
    if not status then
        printInfo("create module " .. self:getRefName() .. " error; module path:" .. self.m_dataModule)
        if DEBUG == 0 then
            release_print(result)
        else
            printError(result)
        end
        return nil
    else
        return result
    end
end

-- 初始化配置数据
function _BaseGameControl:parseConfigData(model, data)
end

-- 解析数据对象
function _BaseGameControl:parseData(data, ...)
    local refName = self:getRefName()
    -- if globalData and globalData.GameConfig and globalData.GameConfig:isIgnoreRef(refName) then
    --     return
    -- end

    if not data then
        return
    end

    local dataObj = self:getData()
    if not dataObj then
        local _model = self:createDataModule()
        if _model then
            self:parseConfigData(_model, data)
            _model:parseData(data, ...)
            _model:setRefName(refName)
            self:registerData(_model)
        end
    else
        dataObj:parseData(data, ...)
    end
end

-- 注册数据对象
function _BaseGameControl:registerData(data)
    if not data then
        return
    end
    local refName = data:getRefName()
    if not refName or refName == "" then
        printError("数据模型不存在引用名!!!!")
        return
    end

    Notifier.registerData(self, data)
end

-- 获得执行中的数据对象
function _BaseGameControl:getRunningData(refName)
    local _data = self:getData(refName)

    if not _data then
        return nil
    end

    if _data.isRunning and not _data:isRunning() then
        return nil
    end

    return _data
end

function _BaseGameControl:onRegister()
end

function _BaseGameControl:onRemove()
end

-- 是否执行
function _BaseGameControl:isRunning()
    local _data = self:getRunningData()
    if not _data then
        return false
    end

    -- 判断资源是否下载
    -- if not self:isDownloadRes() then
    --     return false
    -- end

    return true
end

--右边条活动数据 有特殊情况的处理一下
function _BaseGameControl:getRightFrameRunningData(refName)
    return self:getRunningData(refName)
end

-- ===============资源相关==============
-- 资源是否在整包内
function _BaseGameControl:isResInApp(refName)
    refName = refName or self.m_refName
    if refName ~= self.m_refName then
        local _mgr = self:getMgr(refName)
        if _mgr then
            return _mgr:isResInApp()
        end
    end

    return self.m_isResInApp
end

function _BaseGameControl:setResInApp(isInApp)
    self.m_isResInApp = isInApp or false
end

-- 资源是否下载完成
function _BaseGameControl:isDownloadRes(refName)
    if self:isResInApp(refName) then
        return true
    end

    local themeName = self:getThemeName(refName)
    return self:isDownloadTheme(themeName)
end
-- 资源是否下载完成
function _BaseGameControl:isDownloadTheme(themeName)
    themeName = themeName or ""

    if not self:checkRes(themeName) then
        return false
    end

    local isDownloaded = self:checkDownloaded(themeName)
    if not isDownloaded then
        return false
    end

    if self:checkRes(themeName .. "_Code") or self:checkRes(themeName .. "Code") then
        -- 存在代码资源包才判断
        isDownloaded = self:checkDownloaded(themeName .. "_Code") or self:checkDownloaded(themeName .. "Code")
        if not isDownloaded then
            return false
        end
    end

    -- 关联下载 列表
    local bDlExtendOver = self:checkDLExtendOver(themeName)
    return bDlExtendOver
end

-- 关联下载 列表 是否下载完
function _BaseGameControl:checkDLExtendOver(themeName)
    for _, dlKey in pairs(self.m_extendDLKeyList) do
        -- code 已检查完不用检查了
        if dlKey ~= themeName .. "_Code" and dlKey ~= themeName .. "Code" and self:checkRes(dlKey) and not self:checkDownloaded(dlKey) then
            return false
        end
    end

    return true
end

-- 是否已下载loading资源；大厅轮播、展示、弹板资源判断
function _BaseGameControl:isDownloadLoadingRes(refName)
    if self:isResInApp(refName) then
        return true
    end

    local themeName = self:getThemeName(refName)

    if not self:checkRes(themeName) then
        return false
    end

    if self:checkRes(themeName .. "_loading") or self:checkRes(themeName .. "_Loading") then
        -- 存在loading资源包才判断
        local isDownloaded = self:checkDownloaded(themeName .. "_loading") or self:checkDownloaded(themeName .. "_Loading")
        if not isDownloaded then
            return false
        end
    end

    return true
end

-- 检查资源是否存在
function _BaseGameControl:checkRes(resName)
    local datas = globalData.GameConfig.dynamicData or {}
    local data = datas[resName]
    if not data then
        return false
    else
        return true
    end
end

-- 检查下载的资源
function _BaseGameControl:checkDownloaded(resName)
    return globalDynamicDLControl:checkDownloaded(resName)
end

-- 大厅展示资源判断
function _BaseGameControl:isDownloadLobbyRes()
    -- 默认使用活动主体资源判断
    return self:isDownloadRes()
end

-- 是否可显示主资源Layer界面
function _BaseGameControl:isCanShowLayer()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return false
    end

    local _data = self:getRunningData()
    if not _data or (_data.isSleeping and _data:isSleeping()) then
        -- 无数据或在睡眠中
        return false
    end

    return true
end

-- 是否可显示Lobby资源Layer界面
function _BaseGameControl:isCanShowLobbyLayer()
    -- 判断资源是否下载
    if not self:isDownloadLobbyRes() then
        return false
    end

    local _data = self:getRunningData()
    if not _data or (_data.isSleeping and _data:isSleeping()) then
        -- 无数据或在睡眠中
        return false
    end

    return true
end

-- 是否是新手期功能
function _BaseGameControl:isNovice()
    local _data = self:getRunningData()
    if not _data then
        return false
    end

    return _data:isNovice()
end

-- =============入口相关===================
-- 是否可显示展示页
function _BaseGameControl:isCanShowHall()
    return true
end
-- 大厅展示图名
function _BaseGameControl:getHallName()
    return self:getThemeName()
end

-- 大厅展示入口
function _BaseGameControl:getHallModule(...)
    return ""
end

-- 是否可显示轮播页
function _BaseGameControl:isCanShowSlide()
    return true
end

-- 轮播图名
function _BaseGameControl:getSlideName()
    return self:getThemeName()
end

-- 轮播入口
function _BaseGameControl:getSlideModule(...)
    return ""
end

-- 大厅底部入口名
function _BaseGameControl:getLobbyBottomName()
    return self:getRefName() .. "LobbyNode"
end

-- 大厅底部入口
function _BaseGameControl:getLobbyBottomModule(...)
    return ""
end

-- 关卡内入口名
function _BaseGameControl:getEntryName()
    return self:getRefName()
end

-- 是否可显示入口
function _BaseGameControl:isCanShowEntry()
    if not self:isDownloadRes() then
        return false
    end

    local _data = self:getRunningData()
    if not _data or not _data:isCanShowEntry() then
        return false
    end

    return true
end

-- 关卡内入口
function _BaseGameControl:getEntryModule(...)
    return ""
end

-- 关卡内右下入口名
-- function _BaseGameControl:getRBFrameName()
--     return self:getRefName()
-- end

-- 关卡内右下入口
-- function _BaseGameControl:getRBFrameModule(...)
--     return ""
-- end

-- 关卡BET上的气泡
function _BaseGameControl:isCanShowBetBubble()
    if not self:isDownloadRes() then
        return false
    end

    local _data = self:getRunningData()
    if not (_data and _data.isCanShowBetBubble and _data:isCanShowBetBubble()) then
        return false
    end

    return true
end

function _BaseGameControl:getBetBubbleName()
    return self:getRefName()
end

function _BaseGameControl:getBetBubblePath()
    return ""
end

-- 关卡BET上的气泡
function _BaseGameControl:getBetBubbleLuaPath(...)
    if not self:isDownloadRes() then
        return ""
    end

    local _betBubbleName = self:getBetBubbleName()
    if _betBubbleName ~= "" then
        local _filePath = self:getBetBubblePath(_betBubbleName)
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            local _module, count = string.gsub(_filePath, "/", ".")
            return _module
        end
    end
    return ""
end

-- 弹板名
function _BaseGameControl:getPopName()
    return self:getThemeName()
end

function _BaseGameControl:getPopPath(popName)
    return "Activity/" .. popName
end

-- 弹板入口
function _BaseGameControl:getPopModule()
    if not self:isDownloadLobbyRes() then
        return ""
    end

    local _popName = self:getPopName()
    if _popName ~= "" then
        local _filePath = self:getPopPath(_popName)
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            local _module, count = string.gsub(_filePath, "/", ".")
            return _module
        end
    end
    return ""
end

-- 创建弹板
function _BaseGameControl:createPopLayer(popInfo, ...)
    if not self:isCanShowLobbyLayer() then
        return nil
    end

    local luaFileName = self:getPopModule()
    if luaFileName == "" then
        return nil
    end

    return util_createView(luaFileName, popInfo, ...)
end

-- 是否可在活动总入口中显示
function _BaseGameControl:isCanShowInEntrance()
    return self:isRunning() and self:isDownloadLobbyRes()
end

-- ==============显示界面==================
-- 显示大厅弹板
function _BaseGameControl:showPopLayer(popInfo, callback)
    local themeName = self:getThemeName()

    -- 主题名
    if popInfo and type(popInfo) == "table" then
        popInfo.refName = themeName
    end

    if not self:isCanShowPop() then
        return nil
    end

    local uiView = self:createPopLayer(popInfo)
    if uiView ~= nil then
        uiView:setOverFunc(
            function()
                if callback ~= nil then
                    callback()
                end
            end
        )

        local refName = self:getRefName()
        -- 大厅弹窗不属于进入系统内部
        gLobalViewManager:showUI(uiView, gLobalActivityManager:getUIZorder(refName))
    end
    return uiView
end

-- 显示主界面
function _BaseGameControl:showMainLayer(...)
    return nil
end

-- 显示购买后弹板
function _BaseGameControl:showBuyPopLayer(...)
    return nil
end

-- 是否可显示弹板
function _BaseGameControl:isCanShowPop(...)
    return true
end

-- 下载的额外资源列表
function _BaseGameControl:addExtendResList(...)
    if type(...) == "table" then
        table.insertto(self.m_extendDLKeyList, ...)
    else
        table.insertto(self.m_extendDLKeyList, {...})
    end
end
function _BaseGameControl:getExtendResList()
    return self.m_extendDLKeyList
end

return _BaseGameControl
