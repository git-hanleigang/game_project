---
--island
--2018年4月19日
--LevelConfigData.lua
--
-- 这里所有的数据都直接从csv 文件中读取， 具体的属性名字也由csv表格中的读取

local LevelConfigData = class("LevelConfigData")

-- 这里存储普通reel 滚动列， 或者freespin model 对应列

-- 各个关卡元素对应的单个图片


LevelConfigData.m_bigWinDatas = nil
LevelConfigData.m_newPeriodDatas = nil
LevelConfigData.m_spineSymbolData = nil  -- 存储 spine symbol 信息
-----------关卡基础配置 STAET--------------
--csv中添加一个字段需要代码添加四个部分: 1.定义 2.初始化 3.读取配置 4.赋值(BaseSlotoManiaMachine搜索4.赋值区)
--LevelConfigData.p_XXX XXX为csv里面配置的key csv没有配置使用initBaseData默认值
-- 1.定义区
LevelConfigData.p_lineCount = nil --关卡线数
LevelConfigData.p_isAllLineType = nil --是否为满线关卡 
LevelConfigData.p_columnNum = nil --轮盘列数
LevelConfigData.p_rowNum = nil --轮盘行数
LevelConfigData.p_reelWidth = nil --轮盘宽度
LevelConfigData.p_reelHeight = nil --轮盘高度
LevelConfigData.p_reelRunDatas = nil --各列假滚动长度
LevelConfigData.p_autospinReelRunDatas = nil--各列autospin时假滚动长度
LevelConfigData.p_bInclScatter = nil --是否计算scatter
LevelConfigData.p_bInclBonus = nil -- 是否计算Bonus
LevelConfigData.p_bPlayScatterAction = nil -- 是否播放scatter动画
LevelConfigData.p_bPlayBonusAction = nil -- 是否播放Bonus动画
LevelConfigData.p_scatterShowCol = nil --标识哪一列会出现scatter 
LevelConfigData.p_validLineSymNum = nil --触发sf，bonus需要的数量
LevelConfigData.p_reelEffectRes = nil --配置快滚效果资源名称
LevelConfigData.p_reelBgEffectRes = nil --配置快滚背景效果资源名称
LevelConfigData.p_changeLineFrameTime = nil --连线框播放时间
LevelConfigData.p_quickStopDelayTime = nil --快停延时时间
LevelConfigData.p_reelMoveSpeed = nil --滚动速度
LevelConfigData.p_baseAutoReelMoveSpeedMul = nil --base-AutoSpin滚动速度倍数
LevelConfigData.p_freeReelMoveSpeedMul = nil --free滚动速度倍数
LevelConfigData.p_respinReelMoveSpeedMul = nil --respin滚动速度倍数
LevelConfigData.p_reelResType = nil --回弹类型
LevelConfigData.p_reelDownTime = nil --惯性向下时间
LevelConfigData.p_reelResTime = nil --回弹时间
LevelConfigData.p_reelResDis = nil --回弹距离
LevelConfigData.p_reelStopDis = nil --开始减速距离
LevelConfigData.p_reelLongRunSpeed = nil --快滚速度
LevelConfigData.p_reelLongRunTime = nil -- 快滚时间
LevelConfigData.p_reelBeginJumpTime = nil --点击spin向上跳的时间
LevelConfigData.p_reelBeginJumpHight = nil --点击spin向上跳的高度
LevelConfigData.p_musicBg = nil --背景音乐
LevelConfigData.p_musicFsBg = nil --fs背景音乐
LevelConfigData.p_musicReSpinBg = nil --respin背景
LevelConfigData.p_soundScatterTip = nil       --scatter提示音
LevelConfigData.p_soundBonusTip = nil --bonus提示音
LevelConfigData.p_soundReelDown = nil --下落音
LevelConfigData.p_soundReelDownQuickStop = nil --快停下落音
LevelConfigData.p_reelRunSound = nil --快滚音效
LevelConfigData.p_symbolBulingAnimList = nil  --配置信号的落地动画和提层
LevelConfigData.p_symbolBulingSoundList = nil --配置信号的落地音效
LevelConfigData.p_enumWildType = nil --wild类型
LevelConfigData.p_randomSmallSymbolNum = nil --数字
LevelConfigData.p_bigSymbolTypeCounts = nil --大信号类型
LevelConfigData.p_showScoreIamge = nil -- 是否显示分数的图片代替滚动时 , 0 代表不适用， 1代表使用
LevelConfigData.p_specialSymbolList = nil --放到突出显示层上的信号 超过小格子大小的信号（非大信号）
LevelConfigData.p_allBigSymbolCol = nil --全是大信号的列
LevelConfigData.p_showLinesTime = nil --显示线的间隔时间
LevelConfigData.m_reelEffectResFadeTime = nil --快滚渐隐渐显时间
LevelConfigData.m_reelBgEffectResFadeTime = nil --快滚底渐隐渐显时间
LevelConfigData.m_showLinesFadeTime = nil --连线渐隐渐显时间
-----------关卡基础配置 END--------------
-- 构造函数
function LevelConfigData:ctor()
	self.m_spineSymbolData = {}
	self:initBaseData()
end
--初始化基础配置
--self.p_XXX XXX为csv里面配置的key
--2.初始化区
function LevelConfigData:initBaseData()
	self.p_lineCount = 50 --关卡线数
	self.p_isAllLineType = false --是否为满线关卡
	self.p_columnNum = 5 --轮盘列数
	self.p_rowNum = 3 --轮盘行数
	self.p_reelWidth = 1024 --轮盘宽度
	self.p_reelHeight = 603 --轮盘高度
	self.p_reelRunDatas = {15, 22, 29, 36, 43} --各列假滚动长度
	self.p_bInclScatter = false --是否计算scatter
	self.p_bInclBonus = false -- 是否计算Bonus
	self.p_bPlayScatterAction = false -- 是否播放scatter动画
	self.p_bPlayBonusAction = false -- 是否播放Bonus动画
	self.p_scatterShowCol = nil --标识哪一列会出现scatter 
	self.p_validLineSymNum = 3 --触发sf，bonus需要的数量
	self.p_reelEffectRes = nil --配置快滚效果资源名称
	self.p_reelBgEffectRes = nil --配置快滚背景效果资源名称
	self.p_changeLineFrameTime = 1.54 --连线框播放时间
	self.p_quickStopDelayTime = 0 --快停延时时间
	self.p_reelMoveSpeed = 2600 --滚动速度
	self.p_baseAutoReelMoveSpeedMul = 1 --base-AutoSpin滚动速度倍数
	self.p_freeReelMoveSpeedMul = 1 --free滚动速度倍数
	self.p_respinReelMoveSpeedMul = 1 --respin滚动速度倍数
	self.p_reelResType = nil --默认类型
	self.p_reelResTime = 0.2 --回弹时间
	self.p_reelDownTime = 0.3 --惯性向下时间
	self.p_reelResDis = 30 --回弹距离
	self.p_reelStopDis = 0 --开始减速距离
	self.p_reelLongRunSpeed = 4000 --快滚速度
	self.p_reelLongRunTime = 2 -- 快滚时间
	self.p_reelBeginJumpTime = 0.2 --点击spin向上跳的时间
	self.p_reelBeginJumpHight = 20 --点击spin向上跳的高度
	self.p_musicBg = nil --背景音乐
	self.p_musicFsBg = nil --fs背景音乐
	self.p_musicReSpinBg = nil --respin背景
	self.p_soundScatterTip       = nil --scatter提示音
	self.p_soundBonusTip = nil --bonus提示音
	self.p_soundReelDown = nil --下落音
	self.p_soundReelDownQuickStop = nil --快停下落音
	self.p_reelRunSound = nil --快滚音效
	self.p_symbolBulingAnimList = nil  --配置信号的落地动画和提层
	self.p_symbolBulingSoundList = nil --配置信号的落地音效
	self.p_enumWildType = TAG_SYMBOL_TYPE.SYMBOL_WILD --wild类型
	self.p_randomSmallSymbolNum = 9 --数字
	self.p_bigSymbolTypeCounts = {} --大信号类型
	self.p_allBigSymbolCol = {} -- 全是大信号的列
	self.p_showScoreIamge =  0
	self.p_specialSymbolList = {} --放到突出显示层上的信号 超过小格子大小的信号（非大信号）
	self.p_showLinesTime = nil --显示线的间隔时间
	self.p_symbolZorderLevelAyyay = {}	--根据等级配置信号Zorder
	self.m_reelEffectResFadeTime = nil --快滚渐隐渐显时间
	self.m_reelBgEffectResFadeTime = nil --快滚底渐隐渐显时间
	self.m_showLinesFadeTime = nil --连线渐隐渐显时间
end

-- 特意配置的关卡 修改滚动节奏的表，优先级最高
function LevelConfigData:parseCsvRunDataConfigData()
	
	local CsvRunDataTypeList = {"reelRunDatas","reelMoveSpeed","reelDownTime","reelResTime",
				"reelResDis","reelBeginJumpTime","reelBeginJumpHight"}


	for i=1,#CsvRunDataTypeList do
		local dataKey = CsvRunDataTypeList[i]
		local dataValue = nil
		if dataKey == "reelRunDatas" then
		
			dataValue = globalData.levelRunData:getReelRunCofingData( globalData.slotRunData.gameMachineConfigName , globalData.levelRunData.p_reelRunDatas )  
	
			if dataValue then
				self.p_reelRunDatas = util_string_split(dataValue,";",true) --各列假滚动长度
			end
			
		elseif dataKey == "reelMoveSpeed" then
			dataValue = globalData.levelRunData:getReelRunCofingData( globalData.slotRunData.gameMachineConfigName , globalData.levelRunData.p_reelMoveSpeed )  
			
			if dataValue then
				self.p_reelMoveSpeed = tonumber(dataValue) or 2600 --滚动速度
			end

		elseif dataKey == "reelDownTime" then
			dataValue = globalData.levelRunData:getReelRunCofingData( globalData.slotRunData.gameMachineConfigName , globalData.levelRunData.p_reelDownTime )   
			
			if dataValue then
				self.p_reelDownTime = tonumber(dataValue)-- 惯性向下时间
			end

			
		elseif dataKey == "reelResTime" then
			dataValue = globalData.levelRunData:getReelRunCofingData( globalData.slotRunData.gameMachineConfigName , globalData.levelRunData.p_reelResTime )   
			
			if dataValue then
				self.p_reelResTime = tonumber(dataValue) or 0.2 --回弹时间
			end
			
		elseif dataKey == "reelResDis" then
			dataValue = globalData.levelRunData:getReelRunCofingData( globalData.slotRunData.gameMachineConfigName , globalData.levelRunData.p_reelResDis )   
			if dataValue then
				self.p_reelResDis = tonumber(dataValue) or 30 --回弹距离
			end
			
		elseif dataKey == "reelBeginJumpTime" then
			dataValue = globalData.levelRunData:getReelRunCofingData( globalData.slotRunData.gameMachineConfigName , globalData.levelRunData.p_reelBeginJumpTime ) 
			if dataValue then
				self.p_reelBeginJumpTime = tonumber(dataValue) or 0.2 --点击spin向上跳的时间
			end
			
		elseif dataKey == "reelBeginJumpHight" then
			dataValue = globalData.levelRunData:getReelRunCofingData( globalData.slotRunData.gameMachineConfigName , globalData.levelRunData.p_reelBeginJumpHigh )   
			
			if dataValue then
				self.p_reelBeginJumpHight = tonumber(dataValue) or 20 --点击spin向上跳的高度
			end

		end
	end
	

end

--解析基础配置
--self.p_XXX XXX为csv里面配置的key
--3.读取配置区
function LevelConfigData:parseBaseConfigData(dataKey, dataValue)
	if dataKey == "lineCount" then
        	self.p_lineCount = tonumber(dataValue) or 50 --关卡线数
	elseif dataKey == "isAllLineType" then
		--是否为满线关卡
		local flag = tonumber(dataValue)
		if flag and flag ==1 then
			self.p_isAllLineType = true
		end
   	elseif dataKey == "columnNum" then
        	self.p_columnNum = tonumber(dataValue) or 5  --轮盘列数
    	elseif dataKey == "rowNum" then
		self.p_rowNum = tonumber(dataValue) or 3   --轮盘行数
	elseif dataKey == "reelWidth" then
		self.p_reelWidth = tonumber(dataValue) or 1024   --轮盘宽度
	elseif dataKey == "reelHeight" then
		self.p_reelHeight = tonumber(dataValue) or 603   --轮盘高度	
	elseif dataKey == "reelRunDatas" then
		self.p_reelRunDatas = util_string_split(dataValue,";",true) --各列假滚动长度
	elseif dataKey == "autospinReelRunDatas" then
		self.p_autospinReelRunDatas = util_string_split(dataValue,";",true) --各列autospin时假滚动长度
	elseif dataKey == "fsReelRunDatas" then
		self.p_freespinReelRunDatas = util_string_split(dataValue,";",true) --各列freespin时假滚动长度
	elseif dataKey == "bInclScatter" then
		--是否计算scatter
		local flag = tonumber(dataValue)
		if flag and flag ==1 then
			self.p_bInclScatter = true
		end
	elseif dataKey == "bInclBonus" then
		--是否计算Bonus
		local flag = tonumber(dataValue)
		if flag and flag ==1 then
			self.p_bInclBonus = true
		end
	elseif dataKey == "bPlayScatterAction" then
		--是否播放scatter动画
		local flag = tonumber(dataValue)
		if flag and flag ==1 then
			self.p_bPlayScatterAction = true
		end
	elseif dataKey == "bPlayBonusAction" then
		--是否播放Bonus动画
		local flag = tonumber(dataValue)
		if flag and flag ==1 then
			self.p_bPlayBonusAction = true
		end
    	elseif dataKey == "scatterShowCol" then
        	self.p_scatterShowCol = util_string_split(dataValue,";",true) --标识哪一列会出现scatter
    	elseif dataKey == "validLineSymNum" then
        	self.p_validLineSymNum = tonumber(dataValue) or 3 --触发sf，bonus需要的数量
    	elseif dataKey == "reelEffectRes" then
			self.p_reelEffectRes = dataValue --配置快滚效果资源名称
		elseif dataKey == "reelBgEffectRes" then
			self.p_reelBgEffectRes = dataValue
    	elseif dataKey == "changeLineFrameTime" then
       	 self.p_changeLineFrameTime = tonumber(dataValue) or 1.54 --连线框播放时间
    	elseif dataKey == "quickStopDelayTime" then
		self.p_quickStopDelayTime = tonumber(dataValue) or 0 --快停延时时间
	elseif dataKey == "reelMoveSpeed" then
		self.p_reelMoveSpeed = tonumber(dataValue) or 2600 --滚动速度
	elseif dataKey == "fsReelMoveSpeed" then
		self.p_fsReelMoveSpeed = tonumber(dataValue) or (2600 * 1.1)--free滚动速度
	elseif dataKey == "baseAutoReelMoveSpeedMul" then
		self.p_baseAutoReelMoveSpeedMul = tonumber(dataValue) or 1 --base-AutoSpin滚动速度倍数
	elseif dataKey == "freeReelMoveSpeedMul" then
		self.p_freeReelMoveSpeedMul = tonumber(dataValue) or 1 --free滚动速度倍数
	elseif dataKey == "respinReelMoveSpeedMul" then
		self.p_respinReelMoveSpeedMul = tonumber(dataValue) or 1 --respin滚动速度倍数
	elseif dataKey == "reelResType" then
		self.p_reelResType = tonumber(dataValue)-- 回弹类型
	elseif dataKey == "reelDownTime" then
		self.p_reelDownTime = tonumber(dataValue)-- 惯性向下时间
	elseif dataKey == "reelResTime" then
        	self.p_reelResTime = tonumber(dataValue) or 0.2 --回弹时间
	elseif dataKey == "reelResDis" then
		self.p_reelResDis = tonumber(dataValue) or 30 --回弹距离
	elseif dataKey == "reelStopDis" then
		self.p_reelStopDis = tonumber(dataValue) or 0 --减速距离
    	elseif dataKey == "reelLongRunSpeed" then
        	self.p_reelLongRunSpeed = tonumber(dataValue) or 4000 --快滚速度
    	elseif dataKey == "reelLongRunTime" then
        	self.p_reelLongRunTime = tonumber(dataValue) or 2.5 -- 快滚时间
	elseif dataKey == "reelBeginJumpTime" then
        	self.p_reelBeginJumpTime = tonumber(dataValue) or 0.2 --点击spin向上跳的时间
	elseif dataKey == "reelBeginJumpHight" then
        	self.p_reelBeginJumpHight = tonumber(dataValue) or 20 --点击spin向上跳的高度
    	elseif dataKey == "musicBg" then
        	self.p_musicBg = dataValue --背景音乐
    	elseif dataKey == "musicFsBg" then
        	self.p_musicFsBg = dataValue --fs背景音乐
    	elseif dataKey == "musicReSpinBg" then
        	self.p_musicReSpinBg = dataValue --respin背景
   	elseif dataKey == "soundScatterTip" then
        self.p_soundScatterTip    = dataValue                       --scatter提示音
    elseif dataKey == "soundBonusTip" then
        	self.p_soundBonusTip = dataValue       --bonus提示音
	elseif dataKey == "soundReelDown" then
			if not self.p_soundReelDown then
				self.p_soundReelDown = dataValue   --下落音
			end
    elseif dataKey == "commonSoundReelDown" then
		self.p_soundReelDown = dataValue          --下落音（新）
	elseif dataKey == "soundReelDownQuickStop" then
		self.p_soundReelDownQuickStop = dataValue          --快停下落音
	elseif dataKey == "reelRunSound" then
		self.p_reelRunSound = dataValue --快滚音效	
    	elseif dataKey == "enumWildType" then
        	self.p_enumWildType = tonumber(dataValue) --wild类型
    	elseif dataKey == "randomSmallSymbolNum" then
		self.p_randomSmallSymbolNum = tonumber(dataValue) or 9--数字
	elseif dataKey == "showScoreImage" then
		self.p_showScoreIamge = tonumber(dataValue)
	elseif dataKey == "showLinesTime" then
		self.p_showLinesTime = tonumber(dataValue)
	elseif dataKey == "bigSymbolTypeCounts" then
		local strlist = util_string_split(dataValue,";")
		for key,var in ipairs(strlist) do 
			local dic = util_string_split(var,"-",true)
			if dic and #dic==2 then
				self.p_bigSymbolTypeCounts[dic[1]] = dic[2] --大信号类型
			end
		end
	elseif dataKey == "specialSymbolList" then
		self.p_specialSymbolList = util_string_split(dataValue,";",true) --放到突出显示层上的信号 超过小格子大小的信号（非大信号）
	elseif dataKey == "allBigSymbolCol" then
		local strlist = util_string_split(dataValue,";")
		for key,var in ipairs(strlist) do 
			self.p_allBigSymbolCol[tonumber(var)] = 1 -- 全是大信号的列
		end
	elseif dataKey == "Symbol_Zorder_Level" then -- 根据等级配置信号Zorder
		local strlist = util_string_split(dataValue,";")
		for key,var in ipairs(strlist) do 
			local dic = util_string_split(var,":")
			if dic and #dic==2 then
				local zorderLevel = tonumber(dic[1])
				local symbolArray = util_string_split(dic[2],"-",true)
				for index, symbolType in pairs(symbolArray) do
					self.p_symbolZorderLevelAyyay[symbolType] = zorderLevel	--信号类型+等级
				end
			end
		end
	elseif dataKey == "reelEffectResFadeTime" then
		self.m_reelEffectResFadeTime = tonumber(dataValue) or 0.3 --快滚渐隐渐显时间
	elseif dataKey == "reelBgEffectResFadeTime" then
		self.m_reelBgEffectResFadeTime = tonumber(dataValue) or 0.3 --快滚底渐隐渐显时间
	elseif dataKey == "showLinesFadeTime" then
		self.m_showLinesFadeTime = tonumber(dataValue) or 0.3 --连线渐隐渐显时间
	end
end


--[[
    @desc: 解析普通状态下 滚轮数据
    time:2018-11-28 14:30:00
    --@colValue: 
    --@reelType: 1  普通模式， 2 fs模式
    @return:
]]
function LevelConfigData:parseReelDatas( colKey ,  colValue , reelType )

	if reelType == 1 then
  
	    local colIndexStr = string.sub( colKey, string.len( "Normal_Reel_" ) + 1, string.len( colKey ))
	    local colIndex = tonumber(colIndexStr)
  
	    if self.reelDataNormal == nil then
		  self.reelDataNormal = util_require("data.slotsdata.ReelStripData"):create()
	    end
	    self.reelDataNormal:parseReelDatas(colIndex,colValue)
	else
	    local colIndexStr = string.sub( colKey, string.len( "FreeSpin_Reel_" ) + 1, string.len( colKey ))
	    local colIndex = tonumber(colIndexStr)
  
	    if self.reelDataFs == nil then
		  self.reelDataFs = util_require("data.slotsdata.ReelStripData"):create()
	    end
	    self.reelDataFs:parseReelDatas(colIndex,colValue)
	end
	
end
--[[
    @desc: 解析关卡的信号落地动画
    time:2021-12-07 12:23:00
    @return:
]]
function LevelConfigData:parseSymbolBulingAnimDatas(key,value)
	if not self.p_symbolBulingAnimList then
		self.p_symbolBulingAnimList = {}
	end
	
	local symbolType = string.sub( key, string.len( "SymbolBulingAnim_" ) +1, string.len( key ) )
	symbolType = tonumber(symbolType)
	local symbolData = util_string_split(value,"-")
	symbolData[1] = "1" == symbolData[1]

	-- symbolData = {是否提层(1:true 0:false), 落地动画名称}
	self.p_symbolBulingAnimList[symbolType] = symbolData
end
--[[
    @desc: 解析关卡的信号落地音效
    time:2021-12-07 16:36:27
    @return:
]]
function LevelConfigData:parseSymbolBulingSoundDatas(key,value)
	if not self.p_symbolBulingSoundList then
		self.p_symbolBulingSoundList = {}
	end

	local symbolType = string.sub( key, string.len( "SymbolBulingSound_" ) +1, string.len( key ) )
	symbolType = tonumber(symbolType)
	--[[
		symbolData = {
			音效名称, 
			最大数量(文件数量对应列数，如果信号只在 2,3,4 列出现，文件命名后缀应该也是 _2,_3_4 不能从_1开始。 数量为0时，全列使用一个音效)
		}
	]]
	local symbolData = util_string_split(value,"-")

	local bulingSoundList = {}
	local maxCol = tonumber(symbolData[2]) or 0
	-- 每列提供一个音效文件
	for iCol=1,maxCol do
		bulingSoundList[iCol] = string.format(symbolData[1], iCol)
	end
	-- 全列只提供一个音效文件
	if table_length(bulingSoundList) < 1 then
		bulingSoundList["auto"] = symbolData[1]
	end

	self.p_symbolBulingSoundList[symbolType] = bulingSoundList
end

--[[
    @desc: 解析 big win 的reel 信息
    time:2018-12-29 17:46:10
    --@colValue: 
    @return:
]]
function LevelConfigData:parseBigWinReelData( colValue )
	if self.m_bigWinDatas == nil then
		self.m_bigWinDatas = {}
	end

	local bigWinDatas = util_string_split(colValue, ";" , true)

	self.m_bigWinDatas[#self.m_bigWinDatas + 1] = bigWinDatas
end
--[[
    @desc: 随机获取大赢数据信息
    time:2018-12-29 17:47:38
    @return:
]]
function LevelConfigData:getRandomBigWinData( )

	if self.m_bigWinDatas == nil or  #self.m_bigWinDatas == 0 then
		return nil
	end

	local index = util_random(1,#self.m_bigWinDatas)
	
	return self.m_bigWinDatas[index]

end
--[[
    @desc: 解析score 分数的image图片信息
    time:2019-05-07 17:03:38
    --@imageStr: 
    @return:
]]
function LevelConfigData:parseScoreImage( colKey, imageStr )

	local iamgeStrs = util_string_split(imageStr,";")
	if iamgeStrs == nil or #iamgeStrs == 1 then
		self[colKey] = iamgeStrs[1]
	elseif #iamgeStrs > 1 then
		self[colKey] = iamgeStrs
	end
	
end

--[[
    @desc: 随机获取大赢数据信息
    time:2018-12-29 17:47:38
    @return:
]]
function LevelConfigData:getBigWinData( )
	return self.m_bigWinDatas
end

--[[
	获取新手期数据
]]
function LevelConfigData:parseNewsPeriodData(colName,colValue)
	local verStrs = util_string_split(colValue,";")
	local verLen = #verStrs

	self.symbolCount = #verStrs
	if self.m_newPeriodDatas == nil then
		self.m_newPeriodDatas = {}
	end	

	if self.m_newPeriodDatas[colName] == nil then
		self.m_newPeriodDatas[colName] = {}
	end
	
	for index = 1,self.symbolCount do
	    local value = verStrs[index]

	    local vecScores = util_string_split(value,"-",true)
	    local vecScoresLen = #vecScores
	    local reelData = {}

	    for i = 1,vecScoresLen, 1 do		  
		 reelData[#reelData + 1] = tonumber(vecScores[i])
	    end
	    
	    self.m_newPeriodDatas[colName][#self.m_newPeriodDatas[colName] + 1] = reelData
	end
end
--[[
    @desc: 解析本关卡 spine 的元素，非Symbol的不用配置在这里
    time:2019-01-17 19:44:45
    --@key:
	--@value: 
    @return:
]]
function LevelConfigData:parseSpineSymbolInfo( key,value )

	local symbolType = string.sub( key, string.len( "SpineSymbol_" ) +1, string.len( key ) )
	symbolType = tonumber(symbolType)
	local symbolData = util_string_split(value,"-")
	if symbolData[2] ==  "true" then
		symbolData[2] = true
	else
		symbolData[2] = false
	end
	self.m_spineSymbolData[symbolType] = symbolData
end
--[[
    @desc: 获取spine 信号信息
    time:2019-01-17 19:58:07
    --@symbolType: 
    @return:
]]
function LevelConfigData:getSpineSymbol( symbolType )
	return self.m_spineSymbolData[symbolType]
end

function LevelConfigData:getAllNewsPersiodReelData(payOut)
	if payOut == ENUM_CTRL_PAYOUT.PAYOUT_1P2 then
		if self.m_newPeriodDatas.news_period_12 == nil then
			print("新手期 1p2 序列为 nil !")
		end 
		return self.m_newPeriodDatas.news_period_12
	elseif payOut == ENUM_CTRL_PAYOUT.PAYOUT_1P0 then
		if self.m_newPeriodDatas.news_period_1 == nil then
			print("新手期 1p0 序列为 nil !")
		end 
		return self.m_newPeriodDatas.news_period_1
	elseif payOut == ENUM_CTRL_PAYOUT.PAYOUT_0P9 then
		if self.m_newPeriodDatas.news_period_095 == nil then
			print("新手期 1p0 序列为 nil !")
		end 
		return self.m_newPeriodDatas.news_period_095
	end

	print("该赔率表 没有配置新手期 序列 !")
	return nil 
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelConfigData:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelConfigData:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	return self[colKey]
end

---
--获取普通情况下respin假滚动数据
---@param 
function LevelConfigData:getNormalRespinCloumnByColumnIndex(columnIndex)
	local colKey = "respinCloumn_"..columnIndex
	return self[colKey]
end
  
---
--获取Freespin情况下respin假滚动数据
---@param 
function LevelConfigData:getNormalFreeSpinRespinCloumnByColumnIndex(columnIndex)
	local colKey = "freespinRespinCloumn_"..columnIndex
	local data = self[colKey]
	if data == nil then
		data = self:getNormalRespinCloumnByColumnIndex(columnIndex)
	end
	return data
end
  
---
-- 根据ccb name 获取信号图片
--
function LevelConfigData:getSymbolImageByCCBName(ccbName)
	if self.p_showScoreIamge == 0 then  -- 表明不使用图片滚动的方式来代替Node创建
		return nil
	end
	if self[ccbName] == nil then
		-- do nothing
		return nil
	end

	return self[ccbName]
end

---
--
--
function LevelConfigData:parseSelfConfigData(colKey,colValue)

end

function LevelConfigData:parsePro( value )
	local verStrs = util_string_split(value,";")
  
	local proValues = {}
	local totalWeight = 0
	for i=1,#verStrs do
	    local proValue = verStrs[i]
	    local vecPro = util_string_split(proValue,"-" , true)
  
	    proValues[#proValues + 1] = vecPro
	    totalWeight = totalWeight + vecPro[2]
	end
	return proValues , totalWeight
end

function LevelConfigData:getValueByPro( proValues , totalWeight )
	local random = util_random(1,totalWeight)
	local preValue = 0
  
	for i=1,#proValues do
	    local value = proValues[i]
	    if value ~= 0 then
		  if random > preValue and random <= preValue + value then
			return i
		  end
		  preValue = preValue + value
	    end
	end
end
  

function LevelConfigData:getValueByPros( proValues , totalWeight )
	local random = util_random(1,totalWeight)
	local preValue = 0
	local triggerValue = -1
	for i=1,#proValues do
	    local value = proValues[i]
	    if value[2] ~= 0 then
		  if random > preValue and random <= preValue + value[2] then
			triggerValue = value
			break
		  end
		  preValue = preValue + value[2]
	    end
	end
  
	return triggerValue
end

---
-- 解析 自定义字段
--
function LevelConfigData:parseSelfDefinePron(colValue)
	local vecPros = util_string_split(colValue,";",true)
	return  vecPros 
end

--需要提高层级的类型
function LevelConfigData:checkSpecialSymbol(symbolType)
	if not symbolType then
		return false
	end
	
	--是否所有关卡SCATTER都提高层级
	-- if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
	-- 	return true
	-- end

	if not self.p_specialSymbolList or #self.p_specialSymbolList== 0 then
		return false
	end
	--配置的特殊层级信号
	for i=1,#self.p_specialSymbolList do
		if self.p_specialSymbolList[i] == symbolType then
			return true
		end
	end
	return false
end

function LevelConfigData:getShowLinesTime()
	return self.p_showLinesTime
end

--[[
      获取初始轮盘
]]
function LevelConfigData:getInitReel()
	local initReelData = {}
	for iCol = 1,self.p_columnNum do
		  initReelData[iCol] = self["init_reel"..iCol]
	end
	return initReelData
end

--[[
	根据列数获取初始轮盘数据
]]
function LevelConfigData:getInitReelDatasByColumnIndex(colIndex)
	return self["init_reel"..colIndex]
end

--[[
	初始轮盘配置是否存在
]]
function LevelConfigData:isHaveInitReel()
	local initReel = self["init_reel1"]
	if not initReel or (initReel and #initReel <= 0) then
		return false
	end
	return true
end

return LevelConfigData