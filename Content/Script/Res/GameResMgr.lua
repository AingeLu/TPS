require("Res/Tdr/Ds_keywords")
require("Res/Tdr/Ds_Res")

if GameResMgr ~= nil then
	return GameResMgr
end

GameResMgr            =   {}
local PreInitResFuncs		= 	{}
local FilePath 			 	= 	"./Res/Tdr/"


function GameResMgr:OnInit()
	self.All_res_map = {}
	self.Init_funcs = {}

	self:RegistGameResInfo(self)

	for _, v in pairs(self.Init_funcs) do
		self:LoadResFile(v.res_name, v.func)
	end
end

function GameResMgr:UnInit()
	self.All_res_map = nil;
	self.Init_funcs = nil;
end

function GameResMgr:GetGameResDataByResID(res_name, resID)
    local res_map = self.All_res_map[res_name]
    assert(res_map, res_name .. " is not exist !")
    local res_item = nil;
    if (res_map) then
        res_item = res_map[resID]
    end

    assert(res_item, res_name .. " is not exist resID " .. resID)

    return res_item
end

function GameResMgr:GetGameResDataArray(res_name)
	local res_map = self.All_res_map[res_name]
	assert(res_map, res_name .. " is not exist !")
	return res_map
end


function GameResMgr:RegisterRes(res_name, func)
	assert((not self.Init_funcs[res_name]), "Register GameRes " .. res_name .. " again !!")
	self.Init_funcs[res_name] = {res_name = res_name, func = func}
end

function GameResMgr:LoadResFile(res_name)
	assert(self.Init_funcs[res_name], "Load GameRes " .. res_name .. " failed !!")

	-- hot update
	package.loaded[res_name] = nil
	
	local t = nil;
	local filename = FilePath .. res_name
	require(filename)

	local func = self.Init_funcs[res_name].func
	if (func) then
		t = func(_ENV[res_name])
	end

	-- default ResID as hash
	if (t == nil) then
		local tRes = {}
		local canHash = false
		if (type(_ENV[res_name]) == "table") then
			for _, v in ipairs (_ENV[res_name]) do
				if (type(v) == "table") then
					if (v.ResID) then
						tRes[v.ResID] = v
						canHash = true
					end
				end
			end
		end

		if (canHash) then
			t = tRes
		end
	end

	if (t == nil) then
		t = _ENV[res_name]
	end

	self.All_res_map[res_name] = t
	return true
end


-- 注册的初始化函数需要返回初始后的 table, 没有注册默认使用 ResID 作为 key
function GameResMgr:RegistGameResInfo()
	self:RegisterRes("CharacterDesc_Res", PreInitResFuncs.CharacterDesc_Res)
	self:RegisterRes("SceneDesc_Res")
    self:RegisterRes("ItemDesc_Res")
    self:RegisterRes("WeaponDesc_Res")
	self:RegisterRes("SystemRandomPlayerNameDesc_Res")

end


PreInitResFuncs.CharacterDesc_Res = function(tRes)
	local t = {}
	for _, v in ipairs(tRes) do
		t[v.ResID] = v
	end
	return t
end


 return GameResMgr
