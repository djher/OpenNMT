local tds = require('tds')

--[[ Separate words and features (if any). ]]
local function extract(tokens)
  local words = {}
  local features = {}
  local numFeatures = nil

  for t = 1, #tokens do
    local field = onmt.utils.String.split(tokens[t], '￨')
    local word = field[1]

    if word:len() > 0 then
      table.insert(words, word)

      if numFeatures == nil then
        numFeatures = #field - 1
      else
        assert(#field - 1 == numFeatures,
               'all words must have the same number of features')
      end

      if #field > 1 then
        for i = 2, #field do
          if features[i - 1] == nil then
            features[i - 1] = {}
          end
          table.insert(features[i - 1], field[i])
        end
      end
    end
  end
  return words, features, numFeatures or 0
end

--[[ Reverse operation: attach features to tokens. ]]
local function annotate(tokens, features)
  if not features or #features == 0 then
    return tokens
  end

  for i = 1, #tokens do
    for j = 1, #features do
      tokens[i] = tokens[i] .. '￨' .. features[j][i]
    end
  end

  return tokens
end

--[[ Check that data contains the expected number of features. ]]
local function check(label, dicts, data)
  local expected = #dicts
  local got = 0
  if data ~= nil then
    got = #data
  end

  assert(expected == got, "expected " .. expected .. " " .. label .. " features, got " .. got)
end

--[[ Generate source sequences from labels. ]]
local function generateSource(dicts, src, cdata)
  check('source', dicts, src)

  local srcId
  if cdata then
    srcId = tds.Vec()
  else
    srcId = {}
  end

  for j = 1, #dicts do
    srcId[j] = dicts[j]:convertToIdx(src[j], onmt.Constants.UNK_WORD)
  end

  return srcId
end

--[[ Generate target sequences from labels. ]]
local function generateTarget(dicts, tgt, cdata)
  check('source', dicts, tgt)

  local tgtId
  if cdata then
    tgtId = tds.Vec()
  else
    tgtId = {}
  end

  for j = 1, #dicts do
    -- Target features are shifted relative to the target words.
    -- Use EOS tokens as a placeholder.
    table.insert(tgt[j], 1, onmt.Constants.BOS_WORD)
    table.insert(tgt[j], 1, onmt.Constants.EOS_WORD)
    tgtId[j] = dicts[j]:convertToIdx(tgt[j], onmt.Constants.UNK_WORD)
    table.remove(tgt[j], 1)
    table.remove(tgt[j], 1)
  end

  return tgtId
end

return {
  extract = extract,
  annotate = annotate,
  generateSource = generateSource,
  generateTarget = generateTarget
}
