local M = {}

local templates = {
    general = {
        prompt = [[You are a HOLE FILLER. You are provided with a file containing holes, formatted as '{{HOLE_NAME}}'. Your TASK is to complete with a string to replace this hole with, inside a <COMPLETION/> XML tag, including context-aware indentation, if needed.  All completions MUST be truthful, accurate, well-written and correct.

## EXAMPLE QUERY:

<QUERY>
function sum_evens(lim) {
    var sum = 0;
    for (var i = 0; i < lim; ++i) {
        {{FILL_HERE}}
    }
    return sum;
}
</QUERY>

TASK: Fill the {{FILL_HERE}} hole.

## CORRECT COMPLETION

<COMPLETION>if (i %% 2 === 0) {
      sum += i;
    }</COMPLETION>

## EXAMPLE QUERY:

<QUERY>
def sum_list(lst):
    total = 0
    for x in lst:
    {{FILL_HERE}}
    return total

print sum_list([1, 2, 3])
</QUERY>

## CORRECT COMPLETION:

<COMPLETION>  total += x</COMPLETION>

## EXAMPLE QUERY:

<QUERY>
// data Tree a = Node (Tree a) (Tree a) | Leaf a

// sum :: Tree Int -> Int
// sum (Node lft rgt) = sum lft + sum rgt
// sum (Leaf val)     = val

// convert to TypeScript:
{{FILL_HERE}}
</QUERY>

## CORRECT COMPLETION:

<COMPLETION>type Tree<T>
  = {$:"Node", lft: Tree<T>, rgt: Tree<T>}
  | {$:"Leaf", val: T};

function sum(tree: Tree<number>): number {
  switch (tree.$) {
    case "Node":
      return sum(tree.lft) + sum(tree.rgt);
    case "Leaf":
      return tree.val;
  }
}</COMPLETION>

## EXAMPLE QUERY:

The 5th {{FILL_HERE}} is Jupiter.

## CORRECT COMPLETION:

<COMPLETION>planet from the Sun</COMPLETION>

## EXAMPLE QUERY:

function hypothenuse(a, b) {
  return Math.sqrt({{FILL_HERE}}b ** 2);
}

## CORRECT COMPLETION:

<COMPLETION>a ** 2 + </COMPLETION>`


<QUERY>\n%s{{FILL_HERE}}%s</QUERY>\nTASK: Fill the {{FILL_HERE}} hole. Answer only with the CORRECT completion, and NOTHING ELSE. Do it now.\n</COMPLETION>]],
        stop = {"</COMPLETION>"}
    },
    codegemma = {
        prompt = "<|fim_prefix|>%s<|fim_suffix|>%s<|fim_middle|>",
        stop = { "<|fim_prefix|>", "<|fim_suffix|>", "<|fim_middle|>", "<|file_separator|>" }
    },
    codellama = {
        prompt = "<PRE>%s<SUF>%s<MID>",
        stop = { "<EOT>"}
    },
    edwardzcodegemmaq6 = {
        prompt = "<|fim_prefix|>%s<|fim_suffix|>%s<|fim_middle|>",
        stop = { "<|fim_prefix|>", "<|fim_suffix|>", "<|fim_middle|>", "<|file_separator|>" }
    },
    starcoder2 = {
        prompt = "<fim_prefix>%s<fim_suffix>%s<fim_middle>",
        stop = { "<fim_prefix>", "<fim_suffix>", "<fim_middle>", "<|endoftext|>", "<file_sep>", },
    },
}

local function splitString(str)
    local colonIndex = string.find(str, ":")
    if colonIndex then
        return string.sub(str, 1, colonIndex - 1)
    else
        return str
    end
end

function M.getTemplate(modelname)

    local name = splitString(modelname)
    local name = string.gsub(name, "/", "")
    local template = templates[name]
    if template ~= nil then
        return template
    else
        return templates["general"]
    end
     
end

return M
