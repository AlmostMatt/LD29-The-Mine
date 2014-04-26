function fold(func,array) --only works for commutative functions like + or min
    if #array == 0 then
        return nil
    end
    result = table.remove(array)
    for i,v in ipairs(array) do
        result = func(result,v)
    end
    return result
end

function map(func, array, array2)
  local new_array = {}
  for i,v in ipairs(array) do
	if array2 then
		new_array[i] = func(v,array2[i])
	else
		new_array[i] = func(v)
	end
  end
  return new_array
end

function keymap(func, hash)
  local new_array = {}
  for k,v in pairs(hash) do
    new_array[k] = func(v)
  end
  return new_array
end

function keyconcat(hash, sep)
  local new = ""
  for k,v in pairs(hash) do
    if new ~= "" then
        new = new .. sep
    end
    new = new .. v
  end
  return new
end


function join(t1,t2) --array like tables with int indices
    local new = {}
    for i,v in ipairs(t1) do
        table.insert(new,v)
    end
    for i,v in ipairs(t2) do
        table.insert(new,v)
    end
    return new
end

function table.copy(t)
    local n = {}
    for i,p in ipairs(t) do
        n[i] = p
    end
    return n
end