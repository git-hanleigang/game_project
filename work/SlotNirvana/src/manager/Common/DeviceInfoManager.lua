--[[
    @desc: DeviceInfoManager 专门用来管理原先版本的获取设备信息的类

	@这里会把原先直接调用 c++ ， 使用lua PlatformManager 调用 底层获取信息的接口再这里做一套版本号判断

	@目的是为了重新规划所有的基础信息的方法名,对外接口名称已经属性重新定义，方便之后维护

	@列举出来每个原先的方法调用的含义

	@在这里会判断是否使用上新的 XSDKDeviceInfoManager 方式来获取设备基础信息
]]

-- 旋转转化后回调
GD.orientationTransitionCallFunc = function(result)
    -- release_print("===xy===orientationTransitionCallFunc result = " .. result)
    -- local oriStatue = xcyy.GameBridgeLua:getOrientationStatus()
    -- release_print("--xy--ori statue = " .. oriStatue)
    -- local safeAreaInfo = xcyy.GameBridgeLua:getSafeAreaInfo()
    -- release_print("--xy--ori safeAreaInfo = " .. safeAreaInfo)
    local _height = util_getBangScreenHeight()
    if _height > 0 then
        -- 有刘海才触发事件
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROTATE_SCREEN_COMPLETED, result)
    end
end

local DeviceInfoManager = class("DeviceInfoManager")
DeviceInfoManager.m_instance = nil
function DeviceInfoManager:ctor()
    -- 当前已经存在的app 状态列表
	self.m_checkAppExistStatusList = {}

	-- 初始化需要背检测的app队列
	self:initAppExistStatus({"WeChat","AliPay","QQ"})
end

function DeviceInfoManager:getInstance()
	if DeviceInfoManager.m_instance == nil then
		DeviceInfoManager.m_instance = DeviceInfoManager.new()
	end
	return DeviceInfoManager.m_instance
end
-------------------------------------------- 内部 方法 ----------------------------------------------
function DeviceInfoManager:initAppExistStatus(_initList)
	for i = 1 ,#_initList do
		self:checkApkExist(_initList[i])
	end
end

-- 拼接当前已经存在的app 返回  例 WeChat|AliPay .. WeChat .. WeChat|QQ... 打点方日志要求
function DeviceInfoManager:getAppExistStatusString(_appList)
	local strExist = ""
	for i = 1 , #_appList do
		local appScheme = _appList[i]
		local appExistStatus = self:checkExistAppStatus(appScheme)
		if appExistStatus == true then
			if strExist == "" then
				strExist = strExist ..appScheme
			else
				strExist = strExist .. "|" ..appScheme
			end
		end
	end
	return strExist
end
--[[
    @desc: 
	注意这里 返回的是 nil / false / true 
	nil代表当前app 没有被检测过,需要被检测 
	false true 都代表被检测过
]]
function DeviceInfoManager:checkExistAppStatus(_keyName)
	if not self.m_checkAppExistStatusList then
		self.m_checkAppExistStatusList = {}
	end
	return self.m_checkAppExistStatusList[_keyName]
end

function DeviceInfoManager:saveAppExistStatus(_keyName,_status)
    self.m_checkAppExistStatusList = self.m_checkAppExistStatusList or {}
	self.m_checkAppExistStatusList[_keyName] = _status
end
-------------------------------------------- 对外 方法 ----------------------------------------------
-- 服务器登录需求新增信息打点
function DeviceInfoManager:getLogonExtraJsonData()
    local _push = self:isNotifyEnabled()
	local data = {
		st = self:getIsEmulator() and 1 or 0,
		tz = self:getDeviceTimeZone(),
		lg = self:getDeviceLanguage(),
		vpn = self:getDeviceUseVPN() and 1 or 0,
		apps = self:getAppExistStatusString({"WeChat","AliPay","QQ"}),
        push = _push
	}
	local jsonData = cjson.encode(data)
	return jsonData
end
-- 获取当前设备的时区
function DeviceInfoManager:getDeviceTimeZone()
	if globalXSDKDeviceInfoManager and globalXSDKDeviceInfoManager:isUseNewXcyySDK() then
		return globalXSDKDeviceInfoManager:getDeviceTimeZone()
	else
		return ""
	end
end

-- 获取当前设备的系统语言
function DeviceInfoManager:getDeviceLanguage()
	if globalXSDKDeviceInfoManager and globalXSDKDeviceInfoManager:isUseNewXcyySDK() then
		return globalXSDKDeviceInfoManager:getDeviceLanguage()
	else
		return ""
	end
end

-- 获取当前设备是否使用vpn
function DeviceInfoManager:getDeviceUseVPN()
	if globalXSDKDeviceInfoManager and globalXSDKDeviceInfoManager:isUseNewXcyySDK() then
		return globalXSDKDeviceInfoManager:getDeviceUseVPN()
	else
		return false
	end
end

--[[
    @desc: 获取当前设备是否安装了 xxx 应用
    author: csc
    time:2022-02-10 21:55:16
    --@_appScheme: 检测的app名称
    @ 注意事项： 先检索当前传入的待检测的app名称列表是否已经检测过,如果已经检测过 直接返回，降低走 i/o 带来的消耗
]]
function DeviceInfoManager:checkApkExist(_appScheme)
	if globalXSDKDeviceInfoManager and globalXSDKDeviceInfoManager:isUseNewXcyySDK() then
        -- 暂时注释，不使用缓存的数据检查
		-- local appExistStatus = self:checkExistAppStatus(_appScheme)
		-- if appExistStatus ~= nil then
		-- 	return appExistStatus
		-- end
		local appExistStatus = globalXSDKDeviceInfoManager:checkApkExist(_appScheme)
		self:saveAppExistStatus(_appScheme,appExistStatus)
		return appExistStatus
	else
		return false
	end
end

-- 获取当前设备是否为模拟器
function DeviceInfoManager:getIsEmulator()
	if globalXSDKDeviceInfoManager and globalXSDKDeviceInfoManager:isUseNewXcyySDK() then
		return globalXSDKDeviceInfoManager:getIsEmulator()
	else
		return false
	end
end

-- 获取当前网络状态
function DeviceInfoManager:getNetWorkType()
	if globalXSDKDeviceInfoManager and globalXSDKDeviceInfoManager:isUseNewXcyySDK() then
		return globalXSDKDeviceInfoManager:getNetWorkType()
	else
		return globalPlatformManager:getSystemNetWork() or ""
	end
end

-- 刷新当前玩家的网络状态 -- 只有登录的时候读取一次
function DeviceInfoManager:readSystemNetWork()
	if globalXSDKDeviceInfoManager and globalXSDKDeviceInfoManager:isUseNewXcyySDK() then
		globalXSDKDeviceInfoManager:refreshIpAndNetWorkType()
	else
		globalPlatformManager:readSystemNetWork()
	end
end

-- 判新是否开启了推送功能
function DeviceInfoManager:isNotifyEnabled()
    if isMac() then
        return false
    end
    
    local msg = globalXSDKDeviceInfoManager:getNotifiyStatus()
    if msg and msg == "open" then
        release_print("isNotifyEnabled open true")
        return true
    end
    -- if msg then
    --     release_print("---isNotifyEnabled=" .. msg)
    -- end
    release_print("isNotifyEnabled open false")
    return false
end


return DeviceInfoManager