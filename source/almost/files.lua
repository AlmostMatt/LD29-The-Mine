local shell=os.execute
local lfs=love.filesystem
 
function mkdir(targetDir,dirName)
        local bat=lfs.newFile('temp.bat')
        source="@echo off\ncd "..targetDir.."\n".."mkdir "..dirName
        source:gsub("\n","\r\n")
        bat:open('w')
        bat:write(source)
        bat:close()
        shell(lfs.getSaveDirectory().."\\"..'temp')
        lfs.remove('temp.bat')
end
 
function mkfile(targetDir,dirName,fileContents)
        local bat=lfs.newFile('temp.bat')
        local _,count=fileContents:gsub("\n",'')
        source="@echo off\ncd "..targetDir.."\n"
        local q=0
        for str in fileContents:gmatch("[^\n]+") do
                q=q+1
                local appendOrWrite=" >> "
                if q==1 then
                        appendOrWrite=" > "
                end
                source=source.."echo "..str:gsub("\n",'')..appendOrWrite..dirName.."\n"
        end
        source:gsub("\n","\r\n")
        bat:open('w')
        bat:write(source)
        bat:close()
        shell(lfs.getSaveDirectory().."\\"..'temp')
        lfs.remove('temp.bat')
end
 
function userDir()
        return lfs.getUserDirectory()
end
 
function saveDir()
        return lfs.getSaveDirectory()
end