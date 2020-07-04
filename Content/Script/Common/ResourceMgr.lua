if ResourceMgr ~= nil then
	return ResourceMgr
end

ResourceMgr = {}


function ResourceMgr:OnInit()
end

function ResourceMgr:UnInit()
end


function ResourceMgr:LoadClassByFullPath(fullPath)
    return UClass.Load(fullPath);
end

function ResourceMgr:LoadClassByBlueprintsPath(Path)

    local fullPath = self:GetFullPath(Path);
    return UClass.Load(fullPath);
end


function ResourceMgr:GetFullPath(Path)

    local fileName = Path..".txt";
    fileName = string.match(fileName, ".+/([^/]*%.%w+)$")
    
    if fileName ~= nil then
        local idx = fileName:match(".+()%.%w+$")
        fileName = fileName:sub(1, idx-1)  

        local res = "/Game/"..Path.."."..fileName.."_C"
        return res
    end

    return Path;
end

return ResourceMgr;