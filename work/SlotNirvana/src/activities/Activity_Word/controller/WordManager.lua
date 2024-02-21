-- 字独数据管理器

local WordNet = require("activities.Activity_Word.net.WordNet")
local WordManager = class("WordManager", BaseActivityControl)

-- 存一些本地数据
function WordManager:ctor()
    WordManager.super.ctor(self)
    self.play_data = {}
    self.bl_playAuto = false -- 是否自动抽奖
    self.bl_buffShow = false -- 是否可以显示buff击中抽奖机特效
    self:setRefName(ACTIVITY_REF.Word)
    self.m_wordNet = WordNet:getInstance()
end

-- function WordManager:getInstance()
--     if not self._instance then
--         self._instance = WordManager.new()
--     end
--     return self._instance
-- end

function WordManager:getConfig()
    if not self.WordConfig then
        self.WordConfig = util_require("Activity.WordGame.WordConfig")
    end
    return self.WordConfig
end

-- 获取字母
function WordManager:play()
    local function successCallFun(result)
        if result.status == "success" then
            self:setPlayData(result)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WORD_PLAY_RESULT, {flag = true, data = result})
        else
            print("---------> 字独活动获取字母信息消息返回异常 " .. result.message)
            release_print(result.message)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WORD_PLAY_RESULT, {flag = false, data = result.message})
        end
    end

    local function failedCallFun()
        local errorMsg = "parse word play json error"
        print(errorMsg)
        release_print(errorMsg)
        gLobalViewManager:showReConnect()
    end

    self.m_wordNet:requestPlay(successCallFun, failedCallFun)
end

-- local play_data = {
--     chapterFinish = false,
--     currentChapterNum = 1,
--     playResult = {
--         [1] = {
--             character = "A",
--             characterNum = 27,
--             playStatus = "target",
--             position = 33
--         }
--     }
-- }
function WordManager:setPlayData(play_data)
    local wordData = self:getRunningData()
    if not wordData then
        return
    end
    wordData:setPlayData(play_data)
end

function WordManager:getPlayResult()
    local wordData = self:getRunningData()
    if not wordData then
        return
    end
    return wordData:getPlayResult()
end

function WordManager:resetPlayResult()
    local wordData = self:getRunningData()
    if not wordData then
        return
    end
    return wordData:resetPlayResult()
end

function WordManager:getPlayRewards()
    local wordData = self:getRunningData()
    if not wordData then
        return
    end
    return wordData:getPlayRewards()
end

function WordManager:getJackpotData()
    local wordData = self:getRunningData()
    if not wordData then
        return
    end
    return wordData:getJackpotData()
end

function WordManager:getJackpotPlayData()
    local wordData = self:getRunningData()
    if not wordData then
        return
    end
    return wordData:getJackpotPlayData()
end

-- 发送获取排行榜消息
function WordManager:getRank(loadingLayerFlag)
    -- 数据不全 不执行请求
    if not self:getRunningData() then
        return
    end

    local function successCallFunc(rankData)
        if rankData ~= nil then
            local wordData = self:getRunningData()
            if wordData then
                wordData:parseWordRankConfig(rankData)
            end
        end
    end

    local function failedCallFun()
        if loadingLayerFlag then
            gLobalViewManager:removeLoadingAnima()
        end
        gLobalViewManager:showReConnect()
    end

    if loadingLayerFlag then
        gLobalViewManager:addLoadingAnima()
    end

    self.m_wordNet:requestRank(successCallFunc, failedCallFun)
end

-- function WordManager:getUserDefaultKey()
--     return "WordManager" .. globalData.userRunData.uid
-- end

function WordManager:getInTreasureBuff()
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_WORD_TREASURE)
    return leftTimes and leftTimes > 0
end

------------------------------ 活动中用到的一些标记位 ------------------------------
-- 是否展示过buff击中抽奖机的特效
function WordManager:isShowBuffEffect()
    if not self.bl_buffShow then
        local data = self:getRunningData()
        if data and data:getHits() > 1 then
            self.bl_buffShow = true
        else
            self.bl_buffShow = false
        end
    end
    return self.bl_buffShow
end

function WordManager:setShowBuffEffect(bl_show)
    self.bl_buffShow = bl_show
end

-- play的自动状态
function WordManager:setPlayAuto(bl_auto)
    self.bl_playAuto = bl_auto
end

function WordManager:getPlayAuto()
    return self.bl_playAuto
end

function WordManager:showMainLayer(param)
    if not self:isCanShowLayer() then
        return nil
    end

    local wordMainUI = nil
    if gLobalViewManager:getViewByExtendData("WordMainUI") == nil then
        wordMainUI = util_createFindView("Activity/WordGame/MainUI/WordMainUI", param)
        if wordMainUI ~= nil then
            self:showLayer(wordMainUI, ViewZorder.ZORDER_UI)
        end
    end

    return wordMainUI
end

function WordManager:showLevelChooseLayer(param)
    if not self:isCanShowLayer() then
        return nil
    end

    local wordChooseUI = nil
    if gLobalViewManager:getViewByExtendData("WordLevel") == nil then
        wordChooseUI = util_createFindView("Activity/WordGame/LevelUI/WordLevel", param)
        if wordChooseUI ~= nil then
            gLobalViewManager:showUI(wordChooseUI, ViewZorder.ZORDER_UI)
        end
    end

    return wordChooseUI
end

return WordManager
