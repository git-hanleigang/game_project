--[[
]]
local PokerDoubleGameMgr = require("activities.Activity_Poker.controller.PokerDoubleGameMgr")
local PokerMainGuideMgr = require("activities.Activity_Poker.controller.PokerGuideMgr_Main")
local PokerDoubleGuideMgr = require("activities.Activity_Poker.controller.PokerGuideMgr_Double")
local PokerConfig = require("activities.Activity_Poker.config.PokerConfig")
local PokerNet = require("activities.Activity_Poker.net.PokerNet")
local PokerMgr = class("PokerMgr", BaseActivityControl)

function PokerMgr:ctor()
    PokerMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Poker)

    self.m_net = PokerNet:getInstance()
    self.m_config = PokerConfig:getInstance()

    self.m_doubleGameMgr = PokerDoubleGameMgr:getInstance()

    self.m_guideMgr = PokerMainGuideMgr:getInstance()
    self.m_doubleGuideMgr = PokerDoubleGuideMgr:getInstance()
end

function PokerMgr:getNet()
    return self.m_net
end

function PokerMgr:getConfig()
    return self.m_config
end

function PokerMgr:getDoubleMgr()
    return self.m_doubleGameMgr
end

function PokerMgr:getGuideMgr()
    return self.m_guideMgr
end

function PokerMgr:getDoubleGuideMgr()
    return self.m_doubleGuideMgr
end

function PokerMgr:getUserDefaultKey()
    local refName = self:getRefName()
    local data = G_GetMgr(refName):getData()
    if data then
        local id = data:getExpireAt()
        return refName .. "_" .. id
    end
    return nil
end

function PokerMgr:getUserDefaultValue(_key)
    local defKey = self:getUserDefaultKey()
    if defKey then
        return gLobalDataManager:getNumberByField(defKey .. _key, 0)
    end
    return 0
end

function PokerMgr:setUserDefaultValue(_key, _value)
    local defKey = self:getUserDefaultKey()
    if defKey then
        gLobalDataManager:setNumberByField(defKey .. _key, _value)
    end
end

--[[-----------------------------------------------------------
    章节，轮次奖励
]]
-- 一次游戏后，清除draw的数据
function PokerMgr:clearResultData()
    self.p_resultData = nil
end
function PokerMgr:getResultData()
    return self.p_resultData
end
function PokerMgr:setResultData(_result)
    local PokerResultData = require("activities.Activity_Poker.model.PokerResultData")
    local result = PokerResultData:create()
    result:parseData(_result)
    self.p_resultData = result
end
function PokerMgr:clearResultDetailData()
    self.m_resultDetailData = nil
end
function PokerMgr:setResultDetailData(_resultDetail)
    local PokerDetailData = require("activities.Activity_Poker.model.PokerDetailData")
    local detail = PokerDetailData:create()
    detail:parseData(_resultDetail)
    self.m_resultDetailData = detail
end
function PokerMgr:getResultDetailData()
    return self.m_resultDetailData
end

function PokerMgr:getPokerDetail()
    local pokerDetail = nil
    local rData = self:getResultData()
    if rData and (rData:hasRoundRewards() or rData:hasChapterRewards()) then
        -- 换章节
        pokerDetail = self:getResultDetailData()
    else
        local data = self:getData()
        if data then
            pokerDetail = data:getPokerDetail()
        end
    end
    return pokerDetail
end

-- 判断一次游戏是否赢筹码
function PokerMgr:isWinChip()
    local pdData = self:getPokerDetail()
    if pdData and pdData:getRealChips() > 0 then
        return true
    end
    return false
end

function PokerMgr:getWinChip()
    local pdData = self:getPokerDetail()
    return pdData and pdData:getRealChips()
end
--]]-----------------------------------------------------------

--[[-----------------------------------------------------------
    连续未赢5局，npc气泡
]]
function PokerMgr:setUnWinCount()
    if not self.m_unwinCount then
        self.m_unwinCount = 0
    end
    local data = self:getData()
    if data then
        if data:getPokerDetail():getRealChips() > 0 then
            self.m_unwinCount = 0
        else
            self.m_unwinCount = self.m_unwinCount + 1
        end
    end
end
function PokerMgr:getUnWinCount()
    return self.m_unwinCount or 0
end
function PokerMgr:clearUnWinCount()
    self.m_unwinCount = 0
end
--]]-----------------------------------------------------------

-- 过场动画
function PokerMgr:showPokerCGSpine()
    if gLobalViewManager:getViewLayer():getChildByName("Poker_ruchang") ~= nil then
        return
    end
    local spineUI = util_spineCreate(self.m_config.otherPath .. "spine/Poker_ruchang", true, true, 1)
    gLobalViewManager:getViewLayer():addChild(spineUI, ViewZorder.ZORDER_SPECIAL)
    spineUI:setPosition(cc.p(display.cx, display.cy))
    spineUI:setName("Poker_ruchang")
    util_spinePlay(spineUI, "ruchang", false)
    util_spineEndCallFunc(
        spineUI,
        "ruchang",
        function()
            if spineUI and spineUI.runAction then
                spineUI:runAction(
                    cc.Sequence:create(
                        cc.FadeTo:create(10 / 60, 0),
                        cc.DelayTime:create(4 / 60),
                        cc.CallFunc:create(
                            function()
                                if spineUI and spineUI.removeFromParent then
                                    spineUI:removeFromParent()
                                    spineUI = nil
                                end
                            end
                        )
                    )
                )
            end
        end
    )
end

-- 说明界面
function PokerMgr:showInfoLayer()
    if gLobalViewManager:getViewByName("PokerInfoUI") ~= nil then
        return
    end
    local view = util_createView(self.m_config.luaPath .. "PokerInfo.PokerInfoUI")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    view:setName("PokerInfoUI")
    return view
end

-- 章节界面
function PokerMgr:showChapterLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("PokerUI_Main") ~= nil then
        return
    end
    local data = self:getData()
    if not data then
        return
    end

    local view = util_createView(self.m_config.luaPath .. "PokerUI_Main", 1, _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    view:setName("PokerUI_Main")
    return view
end

-- 主界面
function PokerMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("PokerUI_Main") ~= nil then
        return
    end
    local data = self:getData()
    if not data then
        return
    end

    local view = util_createView(self.m_config.luaPath .. "PokerUI_Main", 2, _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    view:setName("PokerUI_Main")
    return view
end

-- 溢出奖励
function PokerMgr:showBeyondChipRewardLayer(_overCall)
    if gLobalViewManager:getViewByName("PokerBeyondChipRewardUI") ~= nil then
        if _overCall then
            _overCall()
        end
        return
    end
    local result = self:getResultData()
    local view = util_createView(self.m_config.luaPath .. "PokerReward.PokerBeyondChipRewardUI", result, _overCall)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    view:setName("PokerBeyondChipRewardUI")
end

-- 章节奖励界面
function PokerMgr:showChapterRewardLayer(_overCall)
    if gLobalViewManager:getViewByName("PokerChapterRewardUI") ~= nil then
        if _overCall then
            _overCall()
        end
        return
    end
    local result = self:getResultData()
    local view = util_createView(self.m_config.luaPath .. "PokerReward.PokerChapterRewardUI", result, _overCall)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    view:setName("PokerChapterRewardUI")
end

-- 轮次奖励界面
function PokerMgr:showRoundRewardLayer(_overCall)
    if gLobalViewManager:getViewByName("PokerRoundRewardUI") ~= nil then
        if _overCall then
            _overCall()
        end
        return
    end
    local result = self:getResultData()
    local view = util_createView(self.m_config.luaPath .. "PokerReward.PokerRoundRewardUI", result, _overCall)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    view:setName("PokerRoundRewardUI")
end

-- 特殊金币奖励界面
function PokerMgr:showSpecialRewardLayer(_coins, _overCall)
    if gLobalViewManager:getViewByName("PokerSpecialRewardUI") ~= nil then
        if _overCall then
            _overCall()
        end
        return
    end
    local result = {p_coins = _coins}
    local view = util_createView(self.m_config.luaPath .. "PokerReward.PokerSpecialRewardUI", result, _overCall)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    view:setName("PokerSpecialRewardUI")
end

-- 引导界面
function PokerMgr:showGuideLayer(_key, _guideType)
    if not self:isCanShowLayer() then
        return nil
    end
    local uiName = nil
    if _guideType == "main" then
        uiName = "PokerGuideUI_Main"
    elseif _guideType == "double" then
        uiName = "PokerGuideUI_Double"
    end
    local view = gLobalViewManager:getViewByName(uiName)
    assert(view == nil, "引导界面还没有被移除，_key = " .. _key)
    local ui = util_createView(self.m_config.luaPath .. "PokerGuide." .. uiName, _key)
    ui:setName(uiName)
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_GUIDE)
    ui:setPosition(cc.p(display.cx, display.cy))
    return ui
end

-- 播放配音
-- win和complete的章节可能不对
function PokerMgr:playDubbing(_pos, _chapterId)
    if self.m_dubbingId then
        gLobalSoundManager:stopAudio(self.m_dubbingId)
        self.m_dubbingId = nil
    end
    if _chapterId == nil then
        local data = self:getData()
        if not data then
            return
        end
        _chapterId = data:getCurChapterIndex()
    end
    local pDetail = self:getPokerDetail()
    if not pDetail then
        return
    end
    local chapterNames = {"Cat", "BeerGirl", "Zues", "Devil", "CashMan", "Cat", "BeerGirl", "Zues", "Devil", "CashMan"}
    local filePath = nil
    if _pos == "welcome" then
        filePath = self.m_config.otherPath .. "music/dubbing_welcome/EnterChapter_" .. _chapterId .. ".mp3"
    elseif _pos == "win" then
        if pDetail:isPayTableWinHigher() then
            filePath = self.m_config.otherPath .. "music/dubbing_win/BigWin_" .. chapterNames[_chapterId] .. ".mp3"
        else
            filePath = self.m_config.otherPath .. "music/dubbing_win/SmallWin_" .. chapterNames[_chapterId] .. ".mp3"
        end
    elseif _pos == "lose" then
        filePath = self.m_config.otherPath .. "music/dubbing_lose/" .. chapterNames[_chapterId] .. ".mp3"
    elseif _pos == "double" then
        filePath = self.m_config.otherPath .. "music/dubbing_double/" .. chapterNames[_chapterId] .. ".mp3"
    elseif _pos == "complete" then
        filePath = self.m_config.otherPath .. "music/dubbing_complete/" .. chapterNames[_chapterId] .. ".mp3"
    end
    if filePath and util_IsFileExist(filePath) then
        self.m_dubbingId = gLobalSoundManager:playSound(filePath)
    end
end

return PokerMgr
