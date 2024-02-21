--
-- Author: island
-- Date: 2017-08-11 10:45:39
--

local SoundManager = class("SoundManager")

SoundManager.m_instance = nil
SoundManager.m_musicPath = nil --

SoundManager.m_bgMusicId = nil -- 背景音乐 id
-- SoundManager.m_preMusicName = nil -- 之前播放的背景音乐
SoundManager.m_curBgMusic = nil --当前背景音乐
SoundManager.m_soundAudioIds = nil -- 背景音乐列表
SoundManager.m_bigWinPasueId = nil --播放背景音乐时降低音量ID

SoundManager.m_platformList = nil --平台需要转换格式的声音

-- lock背景音乐
SoundManager.m_lockBgMusic = nil
-- lock背景音量
SoundManager.m_lockBgVolume = nil

local PLATFORM_DEFAULT = "ios"
function SoundManager:getInstance()
    if SoundManager.m_instance == nil then
        SoundManager.m_instace = SoundManager.new()
    end
    return SoundManager.m_instace
end

function SoundManager:ctor()
    SoundManager.m_musicPath = "sound_map_bgm1.mp3"
    --SOUND_ENUM.MUSIC_MAP_BACKGROUND_ONE
    self.m_soundAudioIds = {}
    self.m_platformList = {ios = {}, android = {}, mac = {}}

    self.m_lockBgMusic = false
    self.m_lockBgVolume = false

    -- 当前播放的背景音乐
    self.m_curBgMusic = nil
    ------------------------
    -- 场景背景音乐
    self.m_sceneBgMusic = ""
    -- 场景背景音乐音量
    self.m_sceneBgmVol = 1
    -----------------------
    -- 界面背景音乐列表
    self.m_layerBgms = {}
    -- 界面背景音乐优先级
    self.m_layerBgmOrder = {}
    -- 当前播放的界面背景音乐
    self.m_curLayerBgmInfo = nil
    -- 是否后台状态
    self.m_isInBackstage = false
end
-------------------------ios ---------------

-- function SoundManager:enterGame(key)
--     self.m_currentKey = key
-- end

-- function SoundManager:setLockBgMusic(bValue)
--     self.m_lockBgMusic = bValue
-- end

-- function SoundManager:getLockBgMusic()
--     return self.m_lockBgMusic
-- end

-- function SoundManager:setLockBgVolume(bValue)
--     self.m_lockBgVolume = bValue
-- end

--添加平台后缀变化 key关卡名称，platform平台名称 默认ios，suffixList后缀变化{"原始","修改后的"}
--例如 gLobalSoundManager:addPlatformKey("FaLao","ios",{".ogg",".mp3"}}
function SoundManager:addPlatformKey(key, platform, suffixList)
    if not platform then
        platform = PLATFORM_DEFAULT
    end
    if not suffixList then
        suffixList = {".ogg", ".mp3"}
    end
    self.m_platformList[platform][key] = suffixList
end

--移除需要变化的关卡
function SoundManager:removePlatformKey(key, platform)
    if not platform then
        platform = PLATFORM_DEFAULT
    end
    if self.m_platformList[platform][key] then
        self.m_platformList[platform][key] = nil
    end
end

--全部清理或清理指定平台
function SoundManager:clearPlatformList(platform)
    if platform then
        self.m_platformList[platform] = {}
    else
        self.m_platformList = {ios = {}, android = {}, mac = {}}
    end
end

--是否根据平台转换播放格式
function SoundManager:checkPlatformFile(file)
    if not file then
        return nil
    end
    --大厅不处理
    if gLobalViewManager:isLobbyView() then
        return file
    end
    --找不到关卡不处理
    if not globalData.slotRunData.gameModuleName then
        return file
    end
    --如果音频不带关键字不处理
    local pos = string.find(file, globalData.slotRunData.gameModuleName)
    if not pos then
        return file
    end
    --找不到平台数据不处理
    local platformData = self.m_platformList[device.platform]
    if not platformData then
        return file
    end
    --找不到转化数据不处理
    local suffixList = platformData[globalData.slotRunData.gameModuleName]
    if suffixList and #suffixList == 2 then
        local newFile = string.gsub(file, suffixList[1], suffixList[2])
        --判断文件是否存在
        -- if cc.FileUtils:getInstance():isFileExist(newFile) then
        --     return newFile
        -- else
        --     return file
        -- end
        return newFile
    else
        return file
    end
    return file
end

-------------------------Platform end---------------
--音效声音设置为0
--解决音效关闭时卡死问题
function SoundManager:muteAudioById(audioID, notBroadMsgFlag)
    if type(audioID) ~= "number" then
        return
    end
    ccexp.AudioEngine:setVolume(audioID, 0)
    if not notBroadMsgFlag then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOPSOUND, audioID)
    end
end

--停止播放音乐 或 音效
function SoundManager:stopAudio(audioID, notBroadMsgFlag)
    if self.m_lockBgMusic and self.m_bgMusicId == audioID then
        return
    end

    if type(audioID) ~= "number" then
        return
    end
    -- ccexp.AudioEngine:setLoop(audioID,false)
    ccexp.AudioEngine:setVolume(audioID, 0)
    ccexp.AudioEngine:stop(audioID)
    if self.m_bgMusicId == audioID then
        self.m_bgMusicId = nil
    end
    if not notBroadMsgFlag then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOPSOUND, audioID)
    end
end

function SoundManager:getCurrBgMusicName()
    return self.m_curBgMusic
end

--[[
    @desc: 播放子模块音乐
    author:{author}
    time:2022-03-29 15:35:17
    @return:
]]
function SoundManager:playSubmodBgm(musicName, submodName, zOrder)
    assert(submodName, "submodName in SoundManager:playSubmodBGM is nill!!!")
    local idx, bgmInfo = self:findSubmodBgm(submodName, zOrder)
    if not bgmInfo then
        bgmInfo = self:insertSubmodBgm(musicName, submodName, zOrder)
    else
        if bgmInfo.musicName ~= musicName then
            bgmInfo.musicName = musicName
        end
    end

    if not bgmInfo then
        return
    end

    local _curBgmInfo = self.m_curLayerBgmInfo
    if _curBgmInfo and (_curBgmInfo.zOrder > bgmInfo.zOrder) then
        -- 优先级没有当前的高
        return nil
    end

    self.m_curLayerBgmInfo = bgmInfo

    -- if self:getCurrBgMusicName() ~= bgmInfo.musicName then
    self:_playBgm(musicName, bgmInfo.volume or 1)
    -- end
end

-- 添加子模块背景音乐
function SoundManager:insertSubmodBgm(musicName, submodName, zOrder)
    zOrder = zOrder or 0
    local info = {submodName = submodName, musicName = musicName, zOrder = zOrder, volume = 1}

    local micList = self.m_layerBgms["" .. zOrder]
    if not micList then
        self.m_layerBgms["" .. zOrder] = {}
        -- 添加新的 order
        table.insert(self.m_layerBgmOrder, zOrder)
        -- order排序
        table.sort(
            self.m_layerBgmOrder,
            function(a, b)
                return a < b
            end
        )
    end
    table.insert(self.m_layerBgms["" .. zOrder], info)
    return info
end

--[[
    @desc: 查找子模块背景音乐
    author:{author}
    time:2022-03-31 15:03:42
    --@submodName:
	--@zOrder: 
    @return:
]]
function SoundManager:findSubmodBgm(submodName, zOrder)
    local _idx = nil
    local _info = nil
    local _findInfo = function(infos)
        for i = #infos, 1, -1 do
            _info = infos[i]
            if _info and _info.submodName == submodName then
                return i, _info
            end
        end
        return nil, nil
    end
    if not zOrder then
        -- 遍历所有优先级列表
        for _, value in pairs(self.m_layerBgms) do
            _idx, _info = _findInfo(value)
            if _idx ~= nil or _info ~= nil then
                break
            end
        end
    else
        -- 遍历指定优先级列表
        local bgmInfos = self.m_layerBgms["" .. zOrder] or {}
        _idx, _info = _findInfo(bgmInfos)
    end

    return _idx, _info
end

--[[
    @desc: 更改背景音乐
    author:{author}
    time:2022-03-31 14:48:58
    --@musicName:
	--@submodName:
	--@zOrder: 
    @return:
]]
function SoundManager:changeSubmodBgm(musicName, submodName, zOrder)
    zOrder = zOrder or 0
    local idx, bgmInfo = self:findSubmodBgm(submodName, zOrder)
    if idx and bgmInfo then
        local oldBgm = bgmInfo.musicName
        bgmInfo.musicName = musicName

        local _curBgmInfo = self.m_curLayerBgmInfo
        -- if _curBgmInfo and oldBgm ~= musicName then
        if _curBgmInfo then
            -- 当前播放的子模块背景音乐改变
            local audioId = self:_playBgm(musicName, _curBgmInfo.volume or 1)
            self.m_curLayerBgmInfo = bgmInfo
        end
    end
end

--[[
    @desc: 移除子模块音乐
    author:{author}
    time:2022-03-29 15:37:43
    @return:
]]
function SoundManager:removeSubmodBgm(submodName, isRunNow)
    local executFunc = function()
        local _info = nil
        -- 查找要移除的背景音乐
        for key, value in pairs(self.m_layerBgms) do
            for i = #value, 1, -1 do
                _info = value[i]
                if _info.submodName == submodName then
                    table.remove(value, i)
                    break
                end
            end
        end
        if _info then
            -- 处理列表
            local order = _info.zOrder
            if not (#self.m_layerBgms["" .. order] > 0) then
                self.m_layerBgms["" .. order] = nil
                table.removebyvalue(self.m_layerBgmOrder, order)
            end
        end

        if self.m_curLayerBgmInfo and submodName == self.m_curLayerBgmInfo.submodName then
            self:_switchSubmodBgm()
        end
    end

    if isRunNow then
        executFunc()
    else
        util_nextFrameFunc(executFunc)
    end
end

-- 切换子模块背景音乐
function SoundManager:_switchSubmodBgm()
    local _info = nil
    -- 按优先级高到底查找
    for k = #self.m_layerBgmOrder, 1, -1 do
        local order = self.m_layerBgmOrder[k]
        local _gbMusics = self.m_layerBgms["" .. order] or {}
        local nCount = #_gbMusics
        if nCount > 0 then
            _info = _info or _gbMusics[nCount]
            break
        end
    end

    if _info then
        self:_playBgm(_info.musicName, _info.volume or 1)
        self.m_curLayerBgmInfo = _info
    else
        self:_playBgm(self.m_sceneBgMusic, self.m_sceneBgmVol)
        self.m_curLayerBgmInfo = nil
    end
end

--[[
    @desc: 播放场景背景音乐
    author:{author}
    time:2022-03-29 15:49:45
    --@musicName: 
    @return:
]]
function SoundManager:playBgMusic(musicName)
    if self.m_sceneBgMusic ~= musicName then
        self.m_sceneBgmVol = 1
    end

    self.m_sceneBgMusic = musicName

    if not self.m_curLayerBgmInfo then
        local audioId = self:_playBgm(musicName, self.m_sceneBgmVol)
        return audioId
    end
    return nil
end

--[[
    @desc:
    author: 播放背景音乐
    time:2018-07-26 17:09:29
    @return: audio id
]]
function SoundManager:_playBgm(musicName, volume)
    volume = volume or 1
    local audioId = nil
    local curBMG = self:getCurrBgMusicName()

    self.m_curBgMusic = musicName

    -- local factorVolume = 1
    if gLobalDataManager:getBoolByField(kMusic_Backgroud_Switch, true) ~= true then
        if DEBUG == 2 then
            release_print("背景音乐是关闭的")
        end

        return
    end

    if (curBMG ~= musicName) or not self.m_bgMusicId then
        if self.m_bgMusicId ~= nil then
            self:stopAudio(self.m_bgMusicId, true)
            self.m_bgMusicId = nil
        end
        if musicName ~= "" then
            audioId = self:playAudio(musicName, volume, true)
            self.m_bgMusicId = audioId
        end

        if self:isInBackstage() then
            -- 在后台
            self:pauseAndSaveBgMusic()
        end
    else
        -- 即将播放文件和当前文件相同
        self:setBgmVolume(volume)
        audioId = self.m_bgMusicId
    end

    local preMusicName = ""
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAYBGMUSIC, {preMusicName, musicName})
    if device.platform == "ios" then
        if gLobalAdsControl ~= nil and gLobalAdsControl:getPlayingAdFlag() then
            self:pauseBgMusic()
        end
    end

    return audioId
end

-- 设置子模块音量
function SoundManager:setSubmodBgmVolume(volume, submodName)
    if not volume then
        return
    end

    submodName = submodName or ""

    local curSubmodBgmInfo = self.m_curLayerBgmInfo
    if curSubmodBgmInfo then
        if curSubmodBgmInfo.submodName == submodName then
            -- 处理当前使用的子模块
            curSubmodBgmInfo.volume = volume

            if self.m_curBgMusic == curSubmodBgmInfo.musicName then
                self:setBgmVolume(volume)
            end
        elseif submodName ~= "" then
            -- 设置指定子模块
            local _, info = self:findSubmodBgm(submodName)
            if info then
                info.volume = volume
            end
        end
    end
end

--[[
    @desc: 设置场景背景音乐音量
    author:{author}
    time:2020-07-07 14:37:00
    --@volume:
	--@ignoreLock: 是否忽略音量锁
    @return:
]]
function SoundManager:setBackgroundMusicVolume(volume, ignoreLock)
    if self.m_lockBgVolume and not ignoreLock then
        return
    end

    self.m_sceneBgmVol = volume

    if self.m_curBgMusic == self.m_sceneBgMusic then
        self:setBgmVolume(self.m_sceneBgmVol)
    end
end

function SoundManager:setBgmVolume(volume)
    volume = volume or 1
    if self.m_bgMusicId ~= nil then
        ccexp.AudioEngine:setVolume(self.m_bgMusicId, volume)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SETBGMUSICVOLUME, self.m_bgMusicId)
    end
end

-- 背景音乐有渐变效果
function SoundManager:isFadeBgMusic()
    return self.m_isFadeBgMusic
end

-- 渐隐背景音乐
function SoundManager:fadeOutBgMusic(delay)
    delay = delay or 0

    -- 当前有效果，返回
    if self.m_isFadeBgMusic then
        return
    end

    local volume = self:getBackgroundMusicVolume()
    if volume > 0 then
        self.m_isFadeBgMusic = true

        self.m_soundHandlerId =
            scheduler.performWithDelayGlobal(
            function()
                self.m_soundHandlerId = nil

                self.m_soundGlobalId =
                    scheduler.scheduleGlobal(
                    function()
                        --播放广告过程中暂停逻辑
                        if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                            return
                        end

                        if volume <= 0 then
                            volume = 0
                        end

                        print("缩小音量 = " .. tostring(volume))
                        gLobalSoundManager:setBackgroundMusicVolume(volume)

                        if volume <= 0 then
                            -- self:stopBgMusic()
                            if self.m_soundGlobalId ~= nil then
                                scheduler.unscheduleGlobal(self.m_soundGlobalId)
                                self.m_soundGlobalId = nil
                            end
                            self.m_isFadeBgMusic = false
                        end

                        volume = volume - 0.04
                    end,
                    0.1
                )
            end,
            delay,
            "SoundHandlerId"
        )
    else
        -- 音量为0，直接停止
        -- self:stopBgMusic()
    end
end

-- 停止渐变背景音乐
function SoundManager:stopFadeBgMusic()
    if not self.m_isFadeBgMusic then
        return
    end

    if self.m_soundHandlerId then
        scheduler.unscheduleGlobal(self.m_soundHandlerId)
        self.m_soundHandlerId = nil
    end

    if self.m_soundGlobalId ~= nil then
        scheduler.unscheduleGlobal(self.m_soundGlobalId)
        self.m_soundGlobalId = nil
    end

    self.m_isFadeBgMusic = false

    self:setBackgroundMusicVolume(1, true)
end

function SoundManager:getSoundVolume(soundID)
    return soundID ~= nil and ccexp.AudioEngine:getVolume(soundID) or 0
end

function SoundManager:getBackgroundMusicVolume()
    return self:getSoundVolume(self.m_bgMusicId)
end

function SoundManager:getBGMusicId()
    return self.m_bgMusicId
end

-- 开启背景音乐
function SoundManager:openBgMusic()
    gLobalDataManager:setBoolByField(kMusic_Backgroud_Switch, true)
    self:setBackgroundMusicVolume(1, true)
end

-- 关闭背景音乐， 注：关闭不是停止，只是声音为0
function SoundManager:closeBgMusic()
    self:setBackgroundMusicVolume(0, true)
    gLobalDataManager:setBoolByField(kMusic_Backgroud_Switch, false)
end

function SoundManager:isCloseBgMusic()
    if gLobalDataManager:getBoolByField(kMusic_Backgroud_Switch, true) ~= true then
        return true
    else
        return false
    end
end

--暂停背景音乐但保存当前播放名字
function SoundManager:pauseBgMusic()
    if self.m_bgMusicId ~= nil then
        self.m_bigWinPasueId = self.m_bgMusicId
        -- if not self:isCloseBgMusic() then
        ccexp.AudioEngine:setVolume(self.m_bigWinPasueId, 0)
        -- end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSESOUND)
    end
end

--重新播放背景音乐
function SoundManager:resumeBgMusic()
    if self.m_bigWinPasueId ~= nil then
        -- if not self:isCloseBgMusic() then
        ccexp.AudioEngine:setVolume(self.m_bigWinPasueId, 1)
        -- end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUMESOUND)
    end
end

--
function SoundManager:restartBgMusic()
    if self.m_curBgMusic then
        self:_playBgm(self.m_curBgMusic, self.m_sceneBgmVol)
    end
end

-- 停止播放背景音乐
function SoundManager:stopBgMusic()
    if self.m_bgMusicId ~= nil then
        self:stopAudio(self.m_bgMusicId, false)
    -- self.m_bgMusicId = nil
    -- release_print("SoundManager -- stopBGM:" .. self.m_curBgMusic)
    end
end

function SoundManager:playSound(soundName, isLoop)
    if DEBUG == 2 then
    -- release_print("SoundManager:playSound name = "..soundName)
    end
    if gLobalDataManager:getBoolByField(kSound_Effect_switdh, true) ~= true then
        if DEBUG == 2 then
            release_print("音效是关闭的")
        end
        return
    end

    if isLoop == nil then
        isLoop = false
    end
    local audioId = self:playAudio(soundName, 1, isLoop)

    self.m_soundAudioIds[audioId] = audioId

    return audioId
end

--新版本
-- 音乐音效播放 file文件名(必须填写),factorVolume音量（0~1）,isloop是否循环
function SoundManager:playAudio(file, factorVolume, isloop)
    --2021.07.26 添加音效文件检测减少闪退问题
    if not file or not CCFileUtils:sharedFileUtils():isFileExist(file) then
        local fileName = file or "nil"
        local msg = string.format("[SoundManager:playAudio] file = (%s)", fileName)
        release_print(msg)
        print(msg)
        release_print(debug.traceback())
        print(debug.traceback())
        return -1
    end

    if not factorVolume then
        factorVolume = 1
    end

    local newFile = self:checkPlatformFile(file)

    local audio_id = ccexp.AudioEngine:play2d(newFile, isloop, factorVolume)

    return audio_id
end

-- 预加载加载音乐
function SoundManager:loadAudio(...)
    for _, v in ipairs(...) do
        ccexp.AudioEngine:preload(v)
    end
end

--清理所有音乐缓存
function SoundManager:uncacheAll()
    ccexp.AudioEngine:uncacheAll()
end

--停止所有音乐播放
function SoundManager:stopAllAuido()
    -- self:stopAllSounds()
    ccexp.AudioEngine:stopAll()
    -- 当前播放的背景音乐
    self.m_curBgMusic = nil
    -- 场景背景音乐
    self.m_sceneBgMusic = ""
    -- 当前播放的界面背景音乐
    self.m_curLayerBgmInfo = nil

    self.m_bgMusicId = nil
    -- self.m_preMusicName = nil
    self.m_soundAudioIds = {}
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOPSOUND)
end
--[[
    @desc: 停止所有音效
    time:2018-07-26 17:51:40
    @return:
]]
function SoundManager:stopAllSounds()
    local count = table_length(self.m_soundAudioIds)
    local index = 0
    for i, v in pairs(self.m_soundAudioIds) do
        index = index + 1
        self:stopAudio(v, index ~= count)

        self.m_soundAudioIds[i] = nil
    end
end
--获取总时间
function SoundManager:getDuration(audioID)
    if not audioID then
        return -1
    end
    return ccexp.AudioEngine:getDuration(audioID)
end
--当前播放时间
function SoundManager:getCurrentTime(audioID)
    if not audioID then
        return -1
    end
    return ccexp.AudioEngine:getCurrentTime(audioID)
end
--设置播放时间
function SoundManager:setCurrentTime(audioID, time)
    if not audioID then
        return
    end
    ccexp.AudioEngine:setCurrentTime(audioID, time)
end

-- 设置后台状态
function SoundManager:setInBackstage(isInBack)
    if self.m_isInBackstage ~= isInBack then
        if isInBack then
            self:pauseAndSaveBgMusic()
        else
            self:resumeSaveBgMusic()
        end
    end
    self.m_isInBackstage = isInBack
end

function SoundManager:isInBackstage()
    return self.m_isInBackstage
end

--暂停背景音乐  同时保存音乐名字和音量
function SoundManager:pauseAndSaveBgMusic()
    if self.m_bgMusicId ~= nil then
        self.m_bigWinPasueId = self.m_bgMusicId
        -- if not self:isCloseBgMusic() then
        self.m_soundVol = ccexp.AudioEngine:getVolume(self.m_bigWinPasueId)
        ccexp.AudioEngine:setVolume(self.m_bigWinPasueId, 0)
        -- end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSESOUND)
    end
end

--重新播放背景音乐  恢复到暂停之前的音乐和音量
function SoundManager:resumeSaveBgMusic()
    if self.m_bigWinPasueId ~= nil then
        -- if not self:isCloseBgMusic() then
        if self.m_soundVol then
            ccexp.AudioEngine:setVolume(self.m_bigWinPasueId, self.m_soundVol)
        else
            ccexp.AudioEngine:setVolume(self.m_bigWinPasueId, 1)
        end
        -- end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUMESOUND)
    end
end

--[[
    根据soundID设置音量大小
]]
function SoundManager:setSoundVolumeByID(soundID,volume)
    ccexp.AudioEngine:setVolume(soundID, volume)
end

return SoundManager
