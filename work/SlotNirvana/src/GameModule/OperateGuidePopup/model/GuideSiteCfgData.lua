--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-01 14:29:57
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-01 15:56:29
FilePath: /SlotNirvana/src/GameModule/OperateGuidePopup/model/GuideSiteCfgData.lua
Description: 运营引导 弹板点位 表  点位表
--]]
local GuideSiteCfgData = class("GuideSiteCfgData")

function GuideSiteCfgData:ctor(_data)
    self._abGroup = _data.group or "" -- 分组
    self._site = _data.popupsPoints or "" -- 弹出点位
    self._times = _data.times or "" -- 弹出点位第几次弹出取值
    self._popupType = _data.popupsType or "" -- 弹版类型
    self._cdType = _data.cdType or -1 -- 弹出点位索引使用
    self._order = _data.sequence or 1 -- 弹出优先级
    self._siteCd = _data.popupsCd or 99999999  -- 点位CD(H)

    self._coe1 = _data.coe1 or "-1" -- 弹窗限制条件1  不需要 为 -1
    self._coe2 = _data.coe2 or "-1" -- 弹窗限制条件2  不需要 为 -1
    self._coe3 = _data.coe3 or "-1" -- 弹窗限制条件3  不需要 为 -1
end

function GuideSiteCfgData:getAbGroup()
    return self._abGroup
end
function GuideSiteCfgData:getSite()
    return self._site
end
function GuideSiteCfgData:getTimes()
    return self._times
end
function GuideSiteCfgData:getPopupType()
    return self._popupType
end
function GuideSiteCfgData:getCdType()
    return self._cdType
end
function GuideSiteCfgData:popupCfgKey()
    return string.format("%s_%s", self:getPopupType(), self:getCdType())
end
function GuideSiteCfgData:getOrder()
    return self._order
end
function GuideSiteCfgData:getSiteCd()
    return self._siteCd * 3600
end

-- 查看 本条 配置 是否满足需求
function GuideSiteCfgData:checkCanUseCfg(_site, _subSite)
    local siteCd = self:getSiteCd()
    local lastSiteTime = G_GetMgr(G_REF.OperateGuidePopup):getArchiveData():getSiteTime(_site) or 0
    local recordSiteCount = G_GetMgr(G_REF.OperateGuidePopup):getArchiveData():getSiteCount(_site)
    local siteCount = recordSiteCount + 1
    if siteCount ~= 1 and (os.time() - lastSiteTime) < siteCd then
        return false
    end

    local site = self:getSite()
    local bEnable = true
    if site == "LegendaryWinV2" then
        if not _subSite then
            return false
        end

        local bigWinType = tonumber(string.match(_subSite, "SpinWin_(%d+)")) or 1
        G_GetMgr(G_REF.OperateGuidePopup):getData():addSpinWinTypeCount(bigWinType)
        
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
        if bEnable and (tonumber(self._coe2) or -1) > -1 then
            bEnable = globalData.rateUsData:getSpinCount() >= tonumber(self._coe2)
        end
        if bEnable and (tonumber(self._coe3) or -1) > -1 then
            -- SpinWin 定位触发了引导弹板 3次以上
            local spinWinTriggerCount = G_GetMgr(G_REF.OperateGuidePopup):getSpinWinTriggerCount()
            bEnable = spinWinTriggerCount >= tonumber(self._coe3)
        end
    elseif site == "SpecialSpinWin" then
        if not _subSite then
            return false
        end

        local bigWinType = tonumber(string.match(_subSite, "SpinWin_(%d+)")) or 1
        G_GetMgr(G_REF.OperateGuidePopup):getData():addSpinWinTypeCount(bigWinType)
        
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
        if bEnable and (tonumber(self._coe2) or -1) > -1 then
            bEnable = globalData.rateUsData:getSpinCount() >= tonumber(self._coe2)
        end
        if bEnable and (tonumber(self._coe3) or -1) > -1 then
            -- SpinWin 定位触发了引导弹板 3次以上
            local spinWinTriggerCount = G_GetMgr(G_REF.OperateGuidePopup):getSpinWinTriggerCount()
            bEnable = spinWinTriggerCount >= tonumber(self._coe3)
        end
    elseif site == "SpinWin" then
        -- spin大赢 level >= coe1  spin次数 >= coe2 大赢类型 >= coe3
        if not _subSite then
            return false
        end

        local bigWinType = tonumber(string.match(_subSite, "SpinWin_(%d+)")) or 1
        G_GetMgr(G_REF.OperateGuidePopup):getData():addSpinWinTypeCount(bigWinType)
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
        if bEnable and (tonumber(self._coe2) or -1) > -1 then
            bEnable = globalData.rateUsData:getSpinCount() >= tonumber(self._coe2)
        end
        if bEnable and (tonumber(self._coe3) or -1) > -1 then
            bEnable = bigWinType >= tonumber(self._coe3)
        end
    elseif site == "Card" then
        -- 完成一轮卡册并领奖 次数 == coe1
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = siteCount == tonumber(self._coe1)
        end

    elseif site == "Quest" then
        -- 完成一个章节Quest并领奖  章节 idx == coe1
        if not _subSite then
            return false
        end

        if (tonumber(self._coe1) or -1) > -1 then
            local chapterIdx = tonumber(string.match(_subSite, "QuestChapter_(%d+)")) or 0
            bEnable = chapterIdx == tonumber(self._coe1)
        end
    elseif site == "Bankruptcy" then
        -- 破产 coe1次 且未付款之后
        if (tonumber(self._coe1) or -1) > -1 then
            local noPayCount = tonumber(string.match(_subSite, "BankruptcyNoPay_(%d+)")) or 0
            bEnable = noPayCount >= tonumber(self._coe1)
        end
    elseif site == "Levelup" then
        -- 升级  等级为数 == coe1 * 100倍的
        if (tonumber(self._coe1) or -1) > -1 then
            local len = string.len( tonumber(self._coe1) * 100 )
            bEnable = string.sub(tostring(globalData.userRunData.levelNum), len * -1) == tostring(tonumber(self._coe1) * 100)
        end
    elseif site == "Cashbonus" then
        if not _subSite then
            return false
        end

        -- 领取Cash Bonus coe1  1: 银箱子， 2:金箱子， 3: 轮盘
        if (tonumber(self._coe1) or -1) > -1 then
            local selType = tonumber(string.match(_subSite, "Cashbonus_(%d+)")) or 0
            bEnable = selType == tonumber(self._coe1)
        end
    elseif site == "CashMoneyWin" then
        -- 20级以上，在Cash Money游戏游玩过程中，在免费游戏中中1000点的钞票或在付费游戏中中10000点钞票，玩家游戏结算完成回到大厅之后弹出
        -- cashMoeny 检测弹板 20级以上
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
    elseif site == "NadoMachineWin" then
        -- 20级以上，在NadoMachine中，获得Epic Nado Prize后，所有结算全部完成之后，弹出
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
    elseif site == "JillionJackpotWin" then
        -- 公共Jackpot活动中，中Super Jackpot，结算完成所有金币，弹出
    elseif site == "SuperSpinWin" then
        -- 50刀档位及以上，购买SuperSpin，中20倍的倍数，在所有弹版弹出之后，弹出
        -- 50刀
        if (tonumber(self._coe1) or -1) > -1 then
            local price = globalData.luckySpinV2:getPrice()
            if tonumber(price) < tonumber(self._coe1) then
                bEnable = false
            end
        end
        -- 20倍
        if (tonumber(self._coe2) or -1) > -1 then
            local multiple = globalData.luckySpinV2:getWinMultiple()
            if tonumber(multiple or 0) < tonumber(self._coe2) then
                bEnable = false
            end
        end
    elseif site == "DuckShotWin" then
        -- 20级以上，打鸭子游戏中，击中转盘中Grand，结算完金币和付费之后，弹出
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
    elseif site == "MINZWin" then
        -- MINZ中，玩家结算玩法，获得400倍以上Win，在结算玩金币之后，弹出
        if not _subSite then
            return false
        end

        -- 赢钱倍数 >= coe1
        local winMultiple = tonumber(string.match(_subSite, "MINZWin_(%d+)")) or 0
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = winMultiple >= tonumber(self._coe1)
        end
    elseif site == "DartsWin" then
        -- 20级以上，飞镖小游戏中，获得Grand，结算完金币和付费之后，弹出
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
    elseif site == "BlastGrandWin" then
        -- 20级以上，在阿凡达Blast中，中Grand之后，结算完成之后弹出
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
    elseif site == "PipeGrandWin" then
        -- 20级以上，在接水管中，中Grand之后，结算完成之后弹出
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
    elseif site == "DIYWin" then
        if not _subSite then
            return false
        end

        -- 赢钱倍数 >= coe1
        local winMultiple = tonumber(string.match(_subSite, "DIYWin_(%d+)")) or 0
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = winMultiple >= tonumber(self._coe1)
        end
    elseif site == "MergeActOverChapter" then
        if not _subSite then
            return false
        end
        -- 每一个赛季，合成完成第1章和第2章，领取奖励，回到关卡或大厅的时候弹出  点位CD48小时	引导评论>弹窗>FB
        -- 完成章节
        local chapterId = string.match(_subSite, "MergeActOverChapter_(%d+)")
        if chapterId and string.find(tostring(self._coe1), "|") then
            local coeList = string.split(tostring(self._coe1), "|")
            bEnable = false
            for k,v in pairs(coeList) do
                if tonumber(v) == tonumber(chapterId) then
                    bEnable = true
                    break
                end
            end
        end
    elseif site == "LevelDash" then
        if not _subSite then
            return false
        end
        local winMultiple = tonumber(string.match(_subSite, "LevelDash_(%d+)")) or 0
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = winMultiple >= tonumber(self._coe1)
        end
    elseif site == "LevelRoadGameWin" then
        -- LevelRoad小游戏，累积获得200倍以上奖励（包括付费之后的情况），结算完成之后弹出
        if not _subSite then
            return false
        end

        -- 赢钱倍数 >= coe1
        local winMultiple = tonumber(string.match(_subSite, "LevelRoadGameWin_(%d+)")) or 0
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = winMultiple >= tonumber(self._coe1)
        end
    elseif site == "PassCollect" then
        if not _subSite then
            return false
        end
        -- 领奖数目 >= coe1
        local passCollect = tonumber(string.match(_subSite, "PassCollect_(%d+)")) or 0

        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = passCollect >= tonumber(self._coe1)
        end
    elseif site == "GrandWin" then
        -- 20级以上，在关卡中Grand的档次Spin结算之后弹出，触发优先级高于SpinWin、SpecailWin和SpecailWinV2，触发的时候不会触发前面几个点。单独弹板，弹板CD为0，点位CD24小时。触发的时候重置SpinWin和SpecailWin的点位CD。另外，没有Grand分享或没有Grand的关卡不弹。
        if (tonumber(self._coe1) or -1) > -1 then
            bEnable = globalData.userRunData.levelNum >= tonumber(self._coe1)
        end
    end

    return bEnable
end



return GuideSiteCfgData