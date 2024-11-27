local function escape_pattern(text)
    return text:gsub("([^%w])", "%%%1")
end

local patterns = {
    --- case pattern
    {
        pattern = "\\sqrt{(.-)}",
        parse = function(captures)
            local arg = captures[1]
            return string.format("sqrt(%s)", arg)
        end
    },
    {
        pattern = "\\frac{(.-)}{(.-)}",
        parse = function(captures)
            local num, den = captures[1], captures[2]
            return string.format("((%s)/(%s))", num, den)
        end
    },
    {
        pattern = "\\sqrt%[(.-)%]{(.-)}",
        parse = function(captures)
            local n, arg = captures[1], captures[2]
            return string.format("root(%s, %s)", arg, n)
        end
    },
    --- prepare and fix gaps
    {
        pattern = "([%[%(%{])%s*(.-)%s*([%]%)%}])",
        parse = function(captures)
            local arg = captures[2]
            -- remove all spaces
            arg = arg:gsub("%s+", "")
            return string.format("%s%s%s", captures[1], arg, captures[3])
        end
    },
    --- primary functions
    {
        pattern = "\\lim_{(.-)%s*}%s*(.-)%s",
        parse = function(captures)
            local var, expr, expr1 = captures[1], captures[2], captures[3]
            local var_parts = var:gsub("%s+", ""):split("\\to")
            local var_name, limit = var_parts[1], var_parts[2]
            local orientation = "+"  -- Default orientation
            if limit:find("^%+") then
                limit = limit:sub(2)
                orientation = "+"
            elseif limit:find("^%-") then
                limit = limit:sub(2)
                orientation = "-"
            end
            return string.format("lim(%s, %s, %s, %s)", expr, var_name, limit, orientation)
        end
    },
    {
        pattern = "\\log_{(.-)}{(.-)}",
        parse = function(captures)
            local base, arg = captures[1], captures[2]
            return string.format("log(%s, %s)", arg, base)
        end
    },
    {
        pattern = "\\sum_{(.-)%s*}%^{(.-)%s*}%s*(.-)%s",
        parse = function(captures)
            local start, finish, expr = captures[1], captures[2], captures[3]
            local var, start_val = start:match("(%w+)%s*=%s*(%d+)")
            finish = finish:gsub("\\infty", "oo")
            expr = expr:gsub("%s+$", "")
            return string.format("Sum(%s, %s, %s, %s)", expr, var, start_val, finish)
        end
    },
    {
        pattern = "\\prod_{(.-)%s*}%^{(.-)%s*}%s*(.-)%s",
        parse = function(captures)
            local start, finish, expr = captures[1], captures[2], captures[3]
            local var, start_val = start:match("(%w+)%s*=%s*(%d+)")
            finish = finish:gsub("\\infty", "oo")
            return string.format("Product(%s, %s, %s, %s)", expr, var, start_val, finish)
        end
    },
    {
        pattern = "\\int_{(.-)%s*}%^{(.-)%s*}%s*(.-)%s*\\,d(%w)",
        parse = function(captures)
            local lower, upper, integrand, var = captures[1], captures[2], captures[3], captures[4]
            -- Remove trailing whitespace from integrand and result
            integrand = integrand:gsub("%s+$", "")
            --result = result:gsub("%s+$", "")
            return string.format("Integral(%s, %s, %s, %s)", integrand, var, lower, upper)
        end
    },
    
}

local function find_and_replace_math_expressions(input_string)
    local output_string = input_string
    for _, pattern_data in ipairs(patterns) do
        local start_pos = 1
        while true do
            local captures = {output_string:match(pattern_data.pattern, start_pos)}
            if #captures == 0 then break end
            
            local start_index, end_index = output_string:find(pattern_data.pattern, start_pos)
             -- local original = input_string:sub(start_index, end_index)
            local parsed   = pattern_data.parse(captures)
            
            print(" | "..parsed)
            output_string = output_string:sub(1, start_index - 1) .. parsed .. output_string:sub(end_index + 1)
            
            -- Update start position
            start_pos = start_index + #parsed
        end
    end
    
    return output_string
end

local function process_string(input_string)
    local replaced_string = find_and_replace_math_expressions(input_string)
    print(replaced_string)
end

-- split strings
function string:split(sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

local test_string = "Consider \\frac{2}{9} for \\int_{0}^{1} \\frac{2}{9}y^2z^2 \\,dy = \\frac{2}{27}z^2 and the limit \\lim_{x \\to 0} f(x^2 + \\frac{x}{5x}) and calculate \\log_{2}{8}. Then find \\frac{a}{b} and \\sqrt{4}. Also, consider \\sqrt[3]{27} and \\prod_{i=1}^{n} x^i  Finally, compute \\sum_{n=1}^{\\infty} \\frac{1}{n^2} test."
process_string(test_string)
